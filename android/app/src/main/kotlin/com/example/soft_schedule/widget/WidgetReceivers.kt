package com.example.soft_schedule.widget

import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

class TodoWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodoGlanceWidget>() {
    override val glanceAppWidget = TodoGlanceWidget()
}

class TodoCompactWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodoCompactGlanceWidget>() {
    override val glanceAppWidget = TodoCompactGlanceWidget()
}

class ScheduleWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ScheduleGlanceWidget>() {
    override val glanceAppWidget = ScheduleGlanceWidget()
}

class FocusWidgetReceiver : HomeWidgetGlanceWidgetReceiver<FocusGlanceWidget>() {
    override val glanceAppWidget = FocusGlanceWidget()
}
