package com.example.soft_schedule.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class TodoWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodoGlanceWidget>() {
    override val glanceAppWidget = TodoGlanceWidget()
}

class ScheduleWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ScheduleGlanceWidget>() {
    override val glanceAppWidget = ScheduleGlanceWidget()
}

class FocusWidgetReceiver : HomeWidgetGlanceWidgetReceiver<FocusGlanceWidget>() {
    override val glanceAppWidget = FocusGlanceWidget()
}
