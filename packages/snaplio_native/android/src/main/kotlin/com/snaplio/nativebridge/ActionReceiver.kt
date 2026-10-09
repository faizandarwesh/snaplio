package com.snaplio.nativebridge

import android.content.BroadcastReceiver
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PersistableBundle
import android.widget.Toast
import org.json.JSONObject

/** Notification actions that need no UI: Copy and "Not an expense". */
class ActionReceiver : BroadcastReceiver() {
    companion object {
        const val EXTRA_NOTIF_ID = "notifId"
        const val EXTRA_VALUE = "value"
        const val EXTRA_LABEL = "label"
        const val EXTRA_EXPENSE_ID = "expenseId"
    }

    override fun onReceive(ctx: Context, intent: Intent) {
        val notifId = intent.getIntExtra(EXTRA_NOTIF_ID, 0)
        when (intent.action?.substringAfterLast('.')) {
            "copy" -> {
                val value = intent.getStringExtra(EXTRA_VALUE) ?: return
                val what = intent.getStringExtra(EXTRA_LABEL) ?: "Text"
                val cm = ctx.getSystemService(ClipboardManager::class.java)
                val clip = ClipData.newPlainText(what, value)
                if (what == "Code" && Build.VERSION.SDK_INT >= 33) {
                    // Keep one-time codes out of the clipboard preview.
                    clip.description.extras = PersistableBundle().apply {
                        putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true)
                    }
                }
                cm?.setPrimaryClip(clip)
                SmartNotifications.cancel(ctx, notifId)
                // Android 13+ shows its own clipboard confirmation.
                if (Build.VERSION.SDK_INT <= 32) Toast.makeText(ctx, "$what copied", Toast.LENGTH_SHORT).show()
            }
            "notExpense" -> {
                val id = intent.getIntExtra(EXTRA_EXPENSE_ID, -1)
                if (id < 0) return
                NativeState.addOp(ctx, JSONObject().put("op", "exclude").put("expenseId", id))
                SmartNotifications.cancel(ctx, notifId)
                Toast.makeText(ctx, "Removed from Spend", Toast.LENGTH_SHORT).show()
                // Apply now (headless) so totals and widgets update without opening the app.
                ScreenshotJobService.runOpsSoon(ctx)
            }
        }
    }
}
