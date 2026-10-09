package com.snaplio.nativebridge

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * `snaplio/native` — available in every engine (app, background job,
 * workmanager, widgets) because Flutter registers plugins in all of them.
 * Activity-only features (deep links, permission prompt) work in the app.
 */
class SnapNativePlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.NewIntentListener,
    PluginRegistry.RequestPermissionsResultListener {

    companion object {
        private const val REQ_NOTIFICATIONS = 4711
        private val SCHEMES = setOf("snaplio", "snapsort")
        private const val EXTRA_CONSUMED = "snaplio_link_consumed"
    }

    private lateinit var context: Context
    private lateinit var channel: MethodChannel
    private var binding: ActivityPluginBinding? = null
    private var pendingPermission: MethodChannel.Result? = null
    private var lifecycle: Application.ActivityLifecycleCallbacks? = null

    override fun onAttachedToEngine(b: FlutterPlugin.FlutterPluginBinding) {
        context = b.applicationContext
        channel = MethodChannel(b.binaryMessenger, "snaplio/native")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(b: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ---------------------------------------------------------------- Activity

    override fun onAttachedToActivity(b: ActivityPluginBinding) {
        binding = b
        b.addOnNewIntentListener(this)
        b.addRequestPermissionsResultListener(this)
        val activity = b.activity
        NativeState.appInForeground = true
        lifecycle = object : Application.ActivityLifecycleCallbacks {
            override fun onActivityResumed(a: Activity) {
                if (a === activity) NativeState.appInForeground = true
            }
            override fun onActivityPaused(a: Activity) {
                if (a === activity) NativeState.appInForeground = false
            }
            override fun onActivityCreated(a: Activity, s: Bundle?) {}
            override fun onActivityStarted(a: Activity) {}
            override fun onActivityStopped(a: Activity) {}
            override fun onActivitySaveInstanceState(a: Activity, s: Bundle) {}
            override fun onActivityDestroyed(a: Activity) {
                if (a === activity) NativeState.appInForeground = false
            }
        }
        activity.application.registerActivityLifecycleCallbacks(lifecycle)
    }

    override fun onDetachedFromActivity() {
        binding?.let { b ->
            b.removeOnNewIntentListener(this)
            b.removeRequestPermissionsResultListener(this)
            lifecycle?.let { b.activity.application.unregisterActivityLifecycleCallbacks(it) }
        }
        lifecycle = null
        binding = null
        NativeState.appInForeground = false
    }

    override fun onReattachedToActivityForConfigChanges(b: ActivityPluginBinding) = onAttachedToActivity(b)
    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    private fun linkOf(intent: Intent?): String? {
        val data = intent?.data ?: return null
        return if (data.scheme in SCHEMES) data.toString() else null
    }

    override fun onNewIntent(intent: Intent): Boolean {
        val link = linkOf(intent) ?: return false
        binding?.activity?.intent = intent.putExtra(EXTRA_CONSUMED, true)
        channel.invokeMethod("onLink", link)
        return true
    }

    override fun onRequestPermissionsResult(code: Int, perms: Array<out String>, results: IntArray): Boolean {
        if (code != REQ_NOTIFICATIONS) return false
        pendingPermission?.success(results.isNotEmpty() && results[0] == PackageManager.PERMISSION_GRANTED)
        pendingPermission = null
        return true
    }

    // ----------------------------------------------------------------- Calls

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setSmartActionsEnabled" -> {
                val on = call.argument<Boolean>("enabled") ?: false
                NativeState.prefs(context).edit().putBoolean(NativeState.KEY_SMART_ENABLED, on).apply()
                if (on) ScreenshotJobService.schedule(context) else ScreenshotJobService.cancel(context)
                result.success(null)
            }
            "armScreenshotJob" -> {
                if (NativeState.smartEnabled(context)) ScreenshotJobService.schedule(context)
                result.success(null)
            }
            "postNotification" -> {
                @Suppress("UNCHECKED_CAST")
                SmartNotifications.post(context, call.arguments as Map<String, Any?>)
                result.success(null)
            }
            "cancelNotification" -> {
                SmartNotifications.cancel(context, call.argument<Int>("id") ?: 0)
                result.success(null)
            }
            "notificationsEnabled" -> result.success(SmartNotifications.enabled(context))
            "notificationPermissionState" -> result.success(permissionState())
            "requestNotificationPermission" -> requestPermission(result)
            "openNotificationSettings" -> {
                val i = if (Build.VERSION.SDK_INT >= 26) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
                } else {
                    appDetails()
                }
                result.success(start(i))
            }
            "isIgnoringBatteryOptimizations" -> {
                val pm = context.getSystemService(PowerManager::class.java)
                result.success(pm?.isIgnoringBatteryOptimizations(context.packageName) ?: true)
            }
            "requestIgnoreBatteryOptimizations" -> {
                val direct = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS, Uri.parse("package:${context.packageName}"))
                result.success(start(direct) || start(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)) || start(appDetails()))
            }
            "openAppSettings" -> result.success(start(appDetails()))
            "deviceInfo" -> result.success(mapOf("manufacturer" to Build.MANUFACTURER, "brand" to Build.BRAND, "sdk" to Build.VERSION.SDK_INT))
            "getInitialLink" -> {
                val intent = binding?.activity?.intent
                if (intent == null || intent.getBooleanExtra(EXTRA_CONSUMED, false)) {
                    result.success(null)
                } else {
                    intent.putExtra(EXTRA_CONSUMED, true)
                    result.success(linkOf(intent))
                }
            }
            "takePendingOps" -> result.success(NativeState.takeOps(context))
            else -> result.notImplemented()
        }
    }

    /** "granted" | "denied" | "unknown" (never asked). */
    private fun permissionState(): String {
        if (Build.VERSION.SDK_INT < 33) return if (SmartNotifications.enabled(context)) "granted" else "denied"
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
            return "granted"
        }
        val asked = NativeState.prefs(context).getBoolean("asked_notifications", false)
        return if (asked) "denied" else "unknown"
    }

    private fun requestPermission(result: MethodChannel.Result) {
        val activity = binding?.activity
        if (Build.VERSION.SDK_INT < 33 || activity == null) {
            result.success(SmartNotifications.enabled(context))
            return
        }
        if (permissionState() == "granted") {
            result.success(true)
            return
        }
        val asked = NativeState.prefs(context).getBoolean("asked_notifications", false)
        if (asked && !ActivityCompat.shouldShowRequestPermissionRationale(activity, Manifest.permission.POST_NOTIFICATIONS)) {
            // Permanently denied: the system won't show the prompt again.
            start(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName))
            result.success(false)
            return
        }
        NativeState.prefs(context).edit().putBoolean("asked_notifications", true).apply()
        pendingPermission?.success(false)
        pendingPermission = result
        ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQ_NOTIFICATIONS)
    }

    private fun appDetails() = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:${context.packageName}"))

    private fun start(i: Intent): Boolean {
        val from = binding?.activity
        return try {
            if (from != null) from.startActivity(i) else context.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: Exception) {
            false
        }
    }
}
