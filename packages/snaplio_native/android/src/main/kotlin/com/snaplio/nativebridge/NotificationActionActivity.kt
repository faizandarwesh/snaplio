package com.snaplio.nativebridge

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.widget.Toast
import org.json.JSONObject

/**
 * Invisible hop for Open / Maps / Call / WhatsApp. Android 12+ blocks
 * notification trampolines (receiver → startActivity), but an Activity that
 * the notification opens directly may start another app. It also records
 * "link opened" for the weekly recap before handing off.
 */
class NotificationActionActivity : Activity() {
    companion object {
        const val EXTRA_TARGET = "target"
        const val EXTRA_KIND = "kind"
        const val EXTRA_NOTIF_ID = "notifId"
        const val EXTRA_ASSET_ID = "assetId"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val target = intent.getStringExtra(EXTRA_TARGET)
        val kind = intent.getStringExtra(EXTRA_KIND)
        SmartNotifications.cancel(this, intent.getIntExtra(EXTRA_NOTIF_ID, 0))
        if (target != null) {
            if (kind == "open") {
                val asset = intent.getStringExtra(EXTRA_ASSET_ID)
                if (asset != null) {
                    NativeState.addOp(this, JSONObject().put("op", "linkOpened").put("assetId", asset).put("url", target))
                }
            }
            val action = if (kind == "call") Intent.ACTION_DIAL else Intent.ACTION_VIEW
            val view = Intent(action, Uri.parse(target)).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            try {
                startActivity(view)
            } catch (e: ActivityNotFoundException) {
                if (kind == "maps") {
                    // No maps app: fall back to Google Maps on the web.
                    val q = Uri.parse(target).getQueryParameter("q") ?: ""
                    runCatching {
                        startActivity(
                            Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com/maps/search/?api=1&query=" + Uri.encode(q)))
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    }
                } else {
                    Toast.makeText(this, "No app found to open this", Toast.LENGTH_SHORT).show()
                }
            }
        }
        finish()
        overridePendingTransition(0, 0)
    }
}
