package com.snaplio.app.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import com.snaplio.app.MainActivity
import com.snaplio.app.R
import es.antonborri.home_widget.HomeWidgetProvider

/** Opens the app on a `snaplio://` deep link (handled by snaplio_native). */
internal fun deepLink(ctx: Context, link: String, request: Int): PendingIntent {
    val i = Intent(Intent.ACTION_VIEW, Uri.parse(link), ctx, MainActivity::class.java)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
    return PendingIntent.getActivity(ctx, request, i, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
}

/** 4x1 search pill. */
class SearchWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_search)
            v.setOnClickPendingIntent(R.id.search_root, deepLink(context, "snaplio://search", 7101))
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}

/**
 * 4x2 snapshot. Every value is pre-formatted by Dart (lib/services/widget_sync.dart)
 * and stored through home_widget, so this only binds strings.
 */
class SnapshotWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        fun s(key: String, fallback: String) = widgetData.getString(key, null) ?: fallback
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.widget_snapshot)
            v.setTextViewText(R.id.spend_label, s("spend_label", context.getString(R.string.widget_this_month)))
            v.setTextViewText(R.id.spend_total, s("spend_total", "—"))
            v.setTextViewText(R.id.spend_change, s("spend_change", ""))
            val colorRes = when (s("spend_dir", "flat")) {
                "up" -> R.color.widget_up
                "down" -> R.color.widget_down
                else -> R.color.widget_text_tertiary
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                // Resolved by the launcher, so it follows its light/dark theme.
                v.setColorStateList(R.id.spend_change, "setTextColor", colorRes)
            } else {
                v.setTextColor(R.id.spend_change, context.getColor(colorRes))
            }
            v.setTextViewText(R.id.receipt_value, s("receipt_value", "—"))
            v.setTextViewText(R.id.receipt_label, s("receipt_label", context.getString(R.string.widget_latest_receipt)))
            v.setTextViewText(R.id.clean_value, s("clean_value", "0 MB"))
            v.setTextViewText(R.id.links_value, s("links_value", "0"))
            v.setTextViewText(R.id.links_label, s("links_label", context.getString(R.string.widget_unread_links)))

            v.setOnClickPendingIntent(R.id.spend_area, deepLink(context, "snaplio://spend", 7201))
            v.setOnClickPendingIntent(R.id.receipt_cell, deepLink(context, "snaplio://spend", 7202))
            v.setOnClickPendingIntent(R.id.clean_cell, deepLink(context, "snaplio://clean", 7203))
            v.setOnClickPendingIntent(R.id.links_cell, deepLink(context, "snaplio://links", 7204))
            appWidgetManager.updateAppWidget(id, v)
        }
    }
}
