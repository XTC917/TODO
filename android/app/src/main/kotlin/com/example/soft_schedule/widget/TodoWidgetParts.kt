package com.example.soft_schedule.widget



import android.content.Context

import android.content.Intent

import android.net.Uri

import androidx.compose.runtime.Composable

import androidx.compose.ui.unit.dp

import androidx.compose.ui.unit.sp

import androidx.glance.GlanceModifier

import androidx.glance.action.clickable

import androidx.glance.appwidget.action.actionSendBroadcast

import androidx.glance.appwidget.cornerRadius

import androidx.glance.background

import androidx.glance.layout.Alignment

import androidx.glance.layout.Box

import androidx.glance.layout.Column

import androidx.glance.layout.Spacer

import androidx.glance.layout.fillMaxWidth

import androidx.glance.layout.height

import androidx.glance.layout.padding

import androidx.glance.layout.size

import androidx.glance.text.FontWeight

import androidx.glance.text.Text

import androidx.glance.unit.ColorProvider

import com.example.soft_schedule.MainActivity

import es.antonborri.home_widget.HomeWidgetGlanceState

import es.antonborri.home_widget.actionStartActivity



@Composable

fun TodoWidgetBody(

    context: Context,

    state: HomeWidgetGlanceState,

    maxItems: Int,

    showFooter: Boolean,

    compact: Boolean,

) {

    val prefs = state.preferences

    val todos = WidgetData.todos(prefs)

    val openIntent = actionStartActivity<MainActivity>(

        context,

        Uri.parse("jujuschedule://todo"),

    )

    val lineStyle = if (compact) WidgetTheme.compactLineStyle else WidgetTheme.lineStyle

    val doneLineStyle = if (compact) WidgetTheme.compactDoneLineStyle else WidgetTheme.doneLineStyle

    val checkboxSize = if (compact) 20.dp else 24.dp



    Column(

        modifier = if (compact) WidgetTheme.compactSurface() else WidgetTheme.surface(),

    ) {

        WidgetHeader(

            context = context,

            title = WidgetData.todoTitle(prefs),

            openUri = "jujuschedule://todo",

            addUri = "jujuschedule://home/add",

            compact = compact,

        )

        Spacer(GlanceModifier.height(if (compact) 4.dp else 8.dp))

        if (todos.isEmpty()) {

            Text(

                text = WidgetData.emptyLabel(prefs),

                style = WidgetTheme.subtitleStyle,

                modifier = GlanceModifier

                    .fillMaxWidth()

                    .clickable(onClick = openIntent),

            )

        } else {

            todos.take(maxItems).filter { it.id > 0 }.forEach { item ->

                TodoRow(

                    context = context,

                    item = item,

                    accentHex = WidgetData.accentColorHex(prefs),

                    openIntent = openIntent,

                    lineStyle = lineStyle,

                    doneLineStyle = doneLineStyle,

                    checkboxSize = checkboxSize,

                )

                Spacer(GlanceModifier.height(if (compact) 4.dp else 6.dp))

            }

        }

        if (showFooter) {

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

}



@Composable
fun TimelineRow(
    context: Context,
    item: WidgetData.TimelineLine,
    accentHex: String,
    openIntent: androidx.glance.action.Action,
    lineStyle: androidx.glance.text.TextStyle = WidgetTheme.lineStyle,
    doneLineStyle: androidx.glance.text.TextStyle = WidgetTheme.doneLineStyle,
    checkboxSize: androidx.compose.ui.unit.Dp = 24.dp,
) {
    val line = if (item.time.isNotEmpty()) {
        "${item.time}  ${item.title}"
    } else {
        item.title
    }
    TodoRow(
        context = context,
        item = WidgetData.TodoLine(item.id, line, item.done),
        accentHex = accentHex,
        openIntent = openIntent,
        lineStyle = lineStyle,
        doneLineStyle = doneLineStyle,
        checkboxSize = checkboxSize,
    )
}


@Composable
fun TodoRow(
    context: Context,

    item: WidgetData.TodoLine,

    accentHex: String,

    openIntent: androidx.glance.action.Action,

    lineStyle: androidx.glance.text.TextStyle = WidgetTheme.lineStyle,

    doneLineStyle: androidx.glance.text.TextStyle = WidgetTheme.doneLineStyle,

    checkboxSize: androidx.compose.ui.unit.Dp = 24.dp,

) {

    val accent = WidgetTheme.accent(accentHex)

    val toggleIntent = Intent(context, TodoToggleReceiver::class.java).apply {

        putExtra(TodoToggleReceiver.EXTRA_EVENT_ID, item.id)

    }

    val toggleAction = actionSendBroadcast(toggleIntent)

    val markSize = (checkboxSize.value * 0.78f).sp



    androidx.glance.layout.Row(

        modifier = GlanceModifier.fillMaxWidth(),

        verticalAlignment = Alignment.CenterVertically,

    ) {

        Box(

            modifier = GlanceModifier

                .padding(end = if (checkboxSize <= 20.dp) 6.dp else 8.dp)

                .clickable(onClick = toggleAction),

            contentAlignment = Alignment.Center,

        ) {

            if (item.done) {

                Box(

                    modifier = GlanceModifier

                        .size(checkboxSize)

                        .cornerRadius(checkboxSize / 2)

                        .background(accent),

                    contentAlignment = Alignment.Center,

                ) {

                    Text(text = "✓", style = WidgetTheme.checkboxMarkStyle)

                }

            } else {

                Text(

                    text = "○",

                    style = androidx.glance.text.TextStyle(

                        color = ColorProvider(accent),

                        fontSize = markSize,

                        fontWeight = FontWeight.Normal,

                    ),

                )

            }

        }

        Text(

            text = item.title,

            style = if (item.done) doneLineStyle else lineStyle,

            modifier = GlanceModifier

                .defaultWeight()

                .clickable(onClick = openIntent),

        )

    }

}


