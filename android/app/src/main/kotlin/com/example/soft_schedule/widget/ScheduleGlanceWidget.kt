package com.example.soft_schedule.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.text.Text
import com.example.soft_schedule.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

class ScheduleGlanceWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            ScheduleContent(context, currentState())
        }
    }
}

@Composable
private fun ScheduleContent(context: Context, state: HomeWidgetGlanceState) {
    val prefs = state.preferences
    val items = WidgetData.timeline(prefs)
    val openIntent = actionStartActivity<MainActivity>(
        context,
        Uri.parse("jujuschedule://home"),
    )

    Column(modifier = WidgetTheme.surface()) {
        WidgetHeader(
            context = context,
            title = WidgetData.scheduleTitle(prefs),
            openUri = "jujuschedule://home",
            addUri = "jujuschedule://home/add",
        )
        Spacer(GlanceModifier.height(8.dp))
        if (items.isEmpty()) {
            Text(
                text = WidgetData.emptyLabel(prefs),
                style = WidgetTheme.subtitleStyle,
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .clickable(onClick = openIntent),
            )
        } else {
            items.take(4).filter { it.id > 0 }.forEach { item ->
                TimelineRow(
                    context = context,
                    item = item,
                    accentHex = WidgetData.accentColorHex(prefs),
                    openIntent = openIntent,
                )
                Spacer(GlanceModifier.height(4.dp))
            }
        }
        Spacer(GlanceModifier.height(4.dp))
        Text(
            text = "JUJU",
            style = WidgetTheme.subtitleStyle,
            modifier = GlanceModifier
                .fillMaxWidth()
                .clickable(onClick = openIntent),
        )
    }
}
