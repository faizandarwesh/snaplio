package com.snaplio.nativebridge

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Builds and posts notifications described by Dart (which decides *whether*
 * and *what* to show). Native only wires the actions so they work with the
 * app closed:
 *  - copy / notExpense → [ActionReceiver] (no UI)
 *  - open / maps / call / whatsapp → [NotificationActionActivity]
 *  - view / body tap → the app's launcher Activity with a snaplio:// deep link
 */
internal object SmartNotifications {
    private const val TAG = "SnapLioNotify"
    const val CHANNEL_SMART = "smart_actions"
    const val CHANNEL_RECAP = "weekly_recap"
    const val GROUP = "com.snaplio.SMART"
    private const val BRAND = 0xFF7C5CFF.toInt()

    fun ensureChannels(ctx: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val nm = ctx.getSystemService(NotificationManager::class.java) ?: return
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_SMART, "Smart actions", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Codes, receipts, links and numbers found in new screenshots"
                setShowBadge(false)
            },
        )
        nm.createNotificationChannel(
            NotificationChannel(CHANNEL_RECAP, "Weekly recap", NotificationManager.IMPORTANCE_DEFAULT).apply {
                description = "Your week in screenshots, every week"
            },
        )
    }

    fun enabled(ctx: Context): Boolean = NotificationManagerCompat.from(ctx).areNotificationsEnabled()

    /** Launcher activity with a deep link (`snaplio://screenshot/<id>` …). */
    fun deepLinkIntent(ctx: Context, link: String): Intent {
        val launch = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
        return Intent(Intent.ACTION_VIEW, Uri.parse(link)).apply {
            component = launch?.component
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
    }

    private const val PI_FLAGS = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

    @Suppress("UNCHECKED_CAST")
    fun post(ctx: Context, args: Map<String, Any?>) {
        ensureChannels(ctx)
        val id = (args["id"] as Number).toInt()
        val channel = args["channel"] as? String ?: CHANNEL_SMART
        val title = args["title"] as? String ?: return
        val body = args["body"] as? String
        val link = args["link"] as? String
        val group = args["group"] as? Boolean ?: false
        val actions = args["actions"] as? List<Map<String, Any?>> ?: emptyList()

        val b = NotificationCompat.Builder(ctx, channel)
            .setSmallIcon(R.drawable.ic_stat_snaplio)
            .setColor(BRAND)
            .setContentTitle(title)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(if (channel == CHANNEL_RECAP) NotificationCompat.CATEGORY_RECOMMENDATION else NotificationCompat.CATEGORY_STATUS)
        if (body != null) {
            b.setContentText(body).setStyle(NotificationCompat.BigTextStyle().bigText(body))
        }
        if (group) b.setGroup(GROUP)
        if (link != null) {
            b.setContentIntent(PendingIntent.getActivity(ctx, id, deepLinkIntent(ctx, link), PI_FLAGS))
        }
        actions.forEachIndexed { i, a ->
            val pi = actionIntent(ctx, id, i, a) ?: return@forEachIndexed
            b.addAction(0, a["label"] as? String ?: "", pi)
        }
        try {
            NotificationManagerCompat.from(ctx).notify(id, b.build())
        } catch (e: SecurityException) {
            // POST_NOTIFICATIONS not granted — the Dart side already checks, this is a race.
            Log.w(TAG, "Notification permission missing", e)
        }
    }

    fun cancel(ctx: Context, id: Int) = NotificationManagerCompat.from(ctx).cancel(id)

    private fun actionIntent(ctx: Context, notifId: Int, index: Int, a: Map<String, Any?>): PendingIntent? {
        val type = a["type"] as? String ?: return null
        val value = a["value"] as? String
        val req = notifId * 8 + index
        return when (type) {
            "copy", "notExpense" -> {
                val i = Intent(ctx, ActionReceiver::class.java).apply {
                    action = "com.snaplio.action.$type"
                    putExtra(ActionReceiver.EXTRA_NOTIF_ID, notifId)
                    putExtra(ActionReceiver.EXTRA_VALUE, value)
                    putExtra(ActionReceiver.EXTRA_LABEL, a["what"] as? String)
                    putExtra(ActionReceiver.EXTRA_EXPENSE_ID, (a["expenseId"] as? Number)?.toInt() ?: -1)
                }
                PendingIntent.getBroadcast(ctx, req, i, PI_FLAGS)
            }
            "view" -> value?.let { PendingIntent.getActivity(ctx, req, deepLinkIntent(ctx, it), PI_FLAGS) }
            "open", "maps", "call", "whatsapp" -> {
                val i = Intent(ctx, NotificationActionActivity::class.java).apply {
                    action = "com.snaplio.action.$type.$req"
                    putExtra(NotificationActionActivity.EXTRA_TARGET, value)
                    putExtra(NotificationActionActivity.EXTRA_KIND, type)
                    putExtra(NotificationActionActivity.EXTRA_NOTIF_ID, notifId)
                    putExtra(NotificationActionActivity.EXTRA_ASSET_ID, a["assetId"] as? String)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_ANIMATION)
                }
                PendingIntent.getActivity(ctx, req, i, PI_FLAGS)
            }
            else -> null
        }
    }
}
