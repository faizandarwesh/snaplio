package com.snaplio.nativebridge

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Owns at most one headless Flutter engine running the Dart
 * `backgroundMain` entrypoint (lib/main.dart). All classification and
 * extraction stays in Dart; this class only starts the engine, feeds it
 * tasks ("scan", "ops"), and shuts it down when the queue is empty.
 *
 * Protocol on `snaplio/background`:
 *   Dart → `ready`            once handlers are installed
 *   native → `run {task}`     returns when the task is done
 *   native → `dispose`        Dart closes the database
 */
internal object HeadlessRunner {
    private const val TAG = "SnapLioHeadless"
    private const val TIMEOUT_MS = 3 * 60 * 1000L

    private val main = Handler(Looper.getMainLooper())
    private var appContext: Context? = null
    private var engine: FlutterEngine? = null
    private var channel: MethodChannel? = null
    private var ready = false
    private var running = false
    private val queue = ArrayDeque<String>()
    private val callbacks = mutableListOf<() -> Unit>()
    private val timeout = Runnable {
        Log.w(TAG, "Background work timed out")
        destroy()
    }

    /** True while an engine exists (starting, running or draining). */
    val busy: Boolean get() = engine != null

    private fun onMain(block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) block() else main.post(block)
    }

    fun run(ctx: Context, task: String, onDone: () -> Unit) = onMain {
        appContext = ctx.applicationContext
        if (!queue.contains(task)) queue.addLast(task)
        callbacks.add(onDone)
        when {
            engine == null -> start(ctx.applicationContext)
            ready && !running -> next()
        }
    }

    fun stop() = onMain { destroy() }

    private fun start(ctx: Context) {
        try {
            val e = FlutterEngine(ctx)
            val loader = FlutterInjector.instance().flutterLoader()
            val ch = MethodChannel(e.dartExecutor.binaryMessenger, "snaplio/background")
            ch.setMethodCallHandler { call, result ->
                if (call.method == "ready") {
                    ready = true
                    result.success(null)
                    next()
                } else {
                    result.notImplemented()
                }
            }
            engine = e
            channel = ch
            main.postDelayed(timeout, TIMEOUT_MS)
            e.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "backgroundMain"),
            )
        } catch (t: Throwable) {
            Log.e(TAG, "Could not start headless engine", t)
            destroy()
        }
    }

    private fun next() {
        val ch = channel ?: return destroy()
        val task = queue.removeFirstOrNull()
        if (task == null) {
            // Queue drained: let Dart close the DB, then tear down.
            val fallback = Runnable { destroy() }
            main.postDelayed(fallback, 3000)
            ch.invokeMethod("dispose", null, object : MethodChannel.Result {
                override fun success(r: Any?) = done()
                override fun error(c: String, m: String?, d: Any?) = done()
                override fun notImplemented() = done()
                private fun done() {
                    main.removeCallbacks(fallback)
                    destroy()
                }
            })
            return
        }
        running = true
        ch.invokeMethod("run", mapOf("task" to task), object : MethodChannel.Result {
            override fun success(r: Any?) = after()
            override fun error(c: String, m: String?, d: Any?) {
                Log.w(TAG, "Task $task failed: $c $m")
                after()
            }
            override fun notImplemented() = after()
            private fun after() {
                running = false
                next()
            }
        })
    }

    private fun destroy() {
        main.removeCallbacks(timeout)
        try {
            engine?.destroy()
        } catch (t: Throwable) {
            Log.w(TAG, "Engine destroy failed", t)
        }
        engine = null
        channel = null
        ready = false
        running = false
        queue.clear()
        val cbs = callbacks.toList()
        callbacks.clear()
        cbs.forEach { runCatching { it() } }
        // Every job has finished; arm the trigger for the next screenshot.
        val ctx = appContext ?: return
        main.post { if (NativeState.smartEnabled(ctx)) ScreenshotJobService.schedule(ctx) }
    }
}
