package com.example.soft_schedule.widget

import android.content.Context
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.action.ActionCallback
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class ToggleTodoAction : ActionCallback {

    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters,
    ) {
        val eventId = parameters[eventIdKey] ?: return
        if (WidgetNativeToggle.toggleTodo(context, eventId)) {
            TodoGlanceWidget().update(context, glanceId)
            val manager = GlanceAppWidgetManager(context)
            manager.getGlanceIds(TodoGlanceWidget::class.java).forEach { id ->
                if (id != glanceId) {
                    TodoGlanceWidget().update(context, id)
                }
            }
        }
        val uri = Uri.parse("jujuschedule://todo/toggle?id=$eventId")
        HomeWidgetBackgroundIntent.getBroadcast(context, uri).send()
    }

    companion object {
        val eventIdKey = ActionParameters.Key<Int>("eventId")
    }
}
