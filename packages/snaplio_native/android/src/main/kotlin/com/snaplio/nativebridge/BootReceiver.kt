package com.snaplio.nativebridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/** Content-trigger jobs are not persisted: re-arm after boot and app updates. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(ctx: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            if (NativeState.smartEnabled(ctx)) ScreenshotJobService.schedule(ctx)
        }
    }
}
