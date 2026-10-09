package com.snaplio.nativebridge

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/**
 * Process-wide state shared by the plugin instances (one per engine), the
 * job service and the notification receivers.
 */
internal object NativeState {
    /** True while the app's Activity is resumed (foreground path handles new shots). */
    @Volatile
    var appInForeground = false

    private const val PREFS = "snaplio_native"
    private const val KEY_OPS = "pending_ops"
    const val KEY_SMART_ENABLED = "smart_actions_enabled"

    fun prefs(ctx: Context): SharedPreferences = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun smartEnabled(ctx: Context) = prefs(ctx).getBool(KEY_SMART_ENABLED)

    private fun SharedPreferences.getBool(k: String) = getBoolean(k, false)

    /**
     * Small queue of things the user did from a notification while no Dart was
     * running (link opened, not an expense). Dart drains it via `takePendingOps`.
     */
    @Synchronized
    fun addOp(ctx: Context, op: JSONObject) {
        val p = prefs(ctx)
        val arr = JSONArray(p.getString(KEY_OPS, "[]"))
        arr.put(op.put("at", System.currentTimeMillis()))
        p.edit().putString(KEY_OPS, arr.toString()).apply()
    }

    @Synchronized
    fun takeOps(ctx: Context): String {
        val p = prefs(ctx)
        val s = p.getString(KEY_OPS, "[]") ?: "[]"
        p.edit().putString(KEY_OPS, "[]").commit()
        return s
    }
}
