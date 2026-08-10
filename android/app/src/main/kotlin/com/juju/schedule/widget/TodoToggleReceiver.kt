package com.juju.schedule.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.glance.appwidget.GlanceAppWidgetManager
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class TodoToggleReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val eventId = intent.getIntExtra(EXTRA_EVENT_ID, -1)
        if (eventId <= 0) return

        val pendingResult = goAsync()
        CoroutineScope(SupervisorJob() + Dispatchers.Default).launch {
            try {
                val appContext = context.applicationContext
                if (WidgetNativeToggle.toggleEvent(appContext, eventId)) {
                    val manager = GlanceAppWidgetManager(appContext)
                    manager.getGlanceIds(TodoGlanceWidget::class.java).forEach { glanceId ->
                        TodoGlanceWidget().update(appContext, glanceId)
                    }
                    manager.getGlanceIds(TodoCompactGlanceWidget::class.java).forEach { glanceId ->
                        TodoCompactGlanceWidget().update(appContext, glanceId)
                    }
                    manager.getGlanceIds(ScheduleGlanceWidget::class.java).forEach { glanceId ->
                        ScheduleGlanceWidget().update(appContext, glanceId)
                    }
                    manager.getGlanceIds(FocusGlanceWidget::class.java).forEach { glanceId ->
                        FocusGlanceWidget().update(appContext, glanceId)
                    }
                    WidgetSyncScheduler.scheduleBackgroundSync(appContext, eventId)
                }
            } finally {
                pendingResult.finish()
            }
        }
    }

    companion object {
        const val EXTRA_EVENT_ID = "eventId"
    }
}
