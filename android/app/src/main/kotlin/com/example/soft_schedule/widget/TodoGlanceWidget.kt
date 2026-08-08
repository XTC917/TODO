package com.example.soft_schedule.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.Text
import com.example.soft_schedule.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

class TodoGlanceWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            TodoContent(context, currentState())
        }
    }
}

@Composable
private fun TodoContent(context: Context, state: HomeWidgetGlanceState) {
    val prefs = state.preferences
    val todos = WidgetData.todos(prefs)
    val progress = WidgetData.todoProgress(prefs)
    val openIntent = actionStartActivity<MainActivity>(
        context,
        Uri.parse("jujuschedule://todo"),
    )

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(WidgetTheme.background)
            .padding(WidgetTheme.padding),
    ) {
        WidgetHeader(
            context = context,
            title = WidgetData.todoTitle(prefs),
            openUri = "jujuschedule://todo",
            addUri = "jujuschedule://todo/add",
        )
        if (progress.isNotEmpty()) {
            Text(
                text = progress,
                style = WidgetTheme.subtitleStyle,
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .clickable(onClick = openIntent),
            )
        }
        Spacer(GlanceModifier.height(8.dp))
        if (todos.isEmpty()) {
            Text(
                text = WidgetData.emptyLabel(prefs),
                style = WidgetTheme.subtitleStyle,
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .clickable(onClick = openIntent),
            )
        } else {
            todos.take(4).filter { it.id > 0 }.forEach { item ->
                TodoRow(
                    item = item,
                    accentHex = WidgetData.accentColorHex(prefs),
                    openIntent = openIntent,
                )
                Spacer(GlanceModifier.height(6.dp))
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

@Composable
private fun TodoRow(
    item: WidgetData.TodoLine,
    accentHex: String,
    openIntent: androidx.glance.action.Action,
) {
    val accent = WidgetTheme.accent(accentHex)
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(
            modifier = GlanceModifier
                .size(22.dp)
                .background(
                    if (item.done) accent else WidgetTheme.checkboxEmpty,
                )
                .clickable(
                    onClick = actionRunCallback<ToggleTodoAction>(
                        actionParametersOf(ToggleTodoAction.eventIdKey to item.id),
                    ),
                ),
            contentAlignment = Alignment.Center,
        ) {
            if (item.done) {
                Text(text = "✓", style = WidgetTheme.checkboxMarkStyle)
            }
        }
        Spacer(GlanceModifier.width(8.dp))
        Text(
            text = item.title,
            style = if (item.done) WidgetTheme.doneLineStyle else WidgetTheme.lineStyle,
            modifier = GlanceModifier
                .fillMaxWidth()
                .clickable(onClick = openIntent),
        )
    }
}
