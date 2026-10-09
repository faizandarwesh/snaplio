package com.snaplio.nativebridge

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.os.PersistableBundle
import android.provider.MediaStore
import android.util.Log

/**
 * Wakes up within ~2 s of any new image in MediaStore and hands the work to
 * the Dart scan pipeline running in a headless engine ([HeadlessRunner]).
 *
 * Content-URI jobs are one-shot, so there are two alternating trigger IDs:
 * when one fires, the other is armed immediately — a screenshot taken while
 * the current batch is being processed still wakes us. The job is also armed
 * on app start (Dart) and after boot / app update ([BootReceiver]).
 */
class ScreenshotJobService : JobService() {

    companion object {
        private const val TAG = "SnapLioJob"
        private const val JOB_SCAN_A = 4101
        private const val JOB_SCAN_B = 4103
        private const val JOB_OPS = 4102
        const val EXTRA_TASK = "task"

        private fun scheduler(ctx: Context) = ctx.getSystemService(JobScheduler::class.java)

        private fun triggerJob(ctx: Context, id: Int): JobInfo =
            JobInfo.Builder(id, ComponentName(ctx, ScreenshotJobService::class.java))
                .addTriggerContentUri(
                    JobInfo.TriggerContentUri(
                        MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                        JobInfo.TriggerContentUri.FLAG_NOTIFY_FOR_DESCENDANTS,
                    ),
                )
                // Batch the burst of updates MediaStore emits per screenshot…
                .setTriggerContentUpdateDelay(500)
                // …but never wait more than 2 s.
                .setTriggerContentMaxDelay(2000)
                .setExtras(PersistableBundle().apply { putString(EXTRA_TASK, "scan") })
                .build()

        /** Arms the trigger (idempotent: keeps an already-pending one). */
        fun schedule(ctx: Context) {
            val s = scheduler(ctx) ?: return
            val pending = s.allPendingJobs.map { it.id }.toSet()
            if (JOB_SCAN_A in pending || JOB_SCAN_B in pending) return
            s.schedule(triggerJob(ctx, JOB_SCAN_A))
        }

        fun cancel(ctx: Context) {
            scheduler(ctx)?.apply {
                cancel(JOB_SCAN_A)
                cancel(JOB_SCAN_B)
            }
        }

        /** Runs queued notification actions (e.g. "Not an expense") soon, headless. */
        fun runOpsSoon(ctx: Context) {
            val job = JobInfo.Builder(JOB_OPS, ComponentName(ctx, ScreenshotJobService::class.java))
                .setOverrideDeadline(0)
                .setExtras(PersistableBundle().apply { putString(EXTRA_TASK, "ops") })
                .build()
            scheduler(ctx)?.schedule(job)
        }
    }

    override fun onStartJob(params: JobParameters): Boolean {
        val task = params.extras.getString(EXTRA_TASK) ?: "scan"
        val done = { jobFinished(params, false) }
        if (task == "scan") {
            if (HeadlessRunner.busy) {
                // A batch is already being processed: fold this trigger into it.
                // Never re-arm the running id here — rescheduling a running job
                // id stops it. The runner re-arms once everything has finished.
                HeadlessRunner.run(applicationContext, task, done)
                return true
            }
            // Re-arm on the *other* id right away so nothing is missed meanwhile.
            val next = if (params.jobId == JOB_SCAN_A) JOB_SCAN_B else JOB_SCAN_A
            if (NativeState.smartEnabled(this)) scheduler(this)?.schedule(triggerJob(this, next))

            if (NativeState.appInForeground) {
                // The app is open: its own MediaStore listener processes the
                // screenshot and shows an in-app toast instead of a notification.
                Log.d(TAG, "App in foreground; skipping background scan")
                return false
            }
        }
        HeadlessRunner.run(applicationContext, task, done)
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        // The system wants its resources back. The Dart side is idempotent
        // (claims + processedAt), so the next trigger simply picks up the rest.
        HeadlessRunner.stop()
        return false
    }
}
