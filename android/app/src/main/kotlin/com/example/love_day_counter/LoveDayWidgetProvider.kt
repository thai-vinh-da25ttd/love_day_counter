package com.example.love_day_counter

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

class LoveDayWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val days = widgetData.getInt("love_days", 1)
            val photoPath = widgetData.getString("couple_photo_path", null)

            val views = RemoteViews(context.packageName, R.layout.love_day_widget).apply {
                setTextViewText(R.id.widget_days, "$days ngày")
                setTextViewText(R.id.widget_title, "Love Day ❤️")

                val photo = photoPath?.let { path ->
                    val file = File(path)
                    if (file.exists()) BitmapFactory.decodeFile(file.absolutePath) else null
                }
                if (photo != null) {
                    setImageViewBitmap(R.id.widget_photo, photo)
                }

                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
