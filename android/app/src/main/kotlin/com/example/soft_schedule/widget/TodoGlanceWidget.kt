package com.example.soft_schedule.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition

class TodoGlanceWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            TodoWidgetBody(
                context = context,
                state = currentState(),
                maxItems = 4,
                showFooter = true,
                compact = false,
            )
        }
    }
}

class TodoCompactGlanceWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            TodoWidgetBody(
                context = context,
                state = currentState(),
                maxItems = 2,
                showFooter = false,
                compact = true,
            )
        }
    }
}
