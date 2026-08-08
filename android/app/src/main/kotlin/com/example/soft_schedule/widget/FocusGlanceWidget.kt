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
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.text.Text
import com.example.soft_schedule.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.actionStartActivity

class FocusGlanceWidget : GlanceAppWidget() {

    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            FocusContent(context, currentState())
        }
    }
}

@Composable
private fun FocusContent(context: Context, state: HomeWidgetGlanceState) {
    val prefs = state.preferences
    val accent = WidgetTheme.accent(WidgetData.accentColorHex(prefs))
    val openFocus = actionStartActivity<MainActivity>(
        context,
        Uri.parse("jujuschedule://focus"),
    )

    Column(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(WidgetTheme.background)
            .padding(WidgetTheme.padding),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = WidgetData.focusTitle(prefs), style = WidgetTheme.titleStyle)
        Spacer(GlanceModifier.height(8.dp))
        Text(text = WidgetData.focusDuration(prefs), style = WidgetTheme.lineStyle)
        Spacer(GlanceModifier.height(12.dp))
        Box(
            modifier = GlanceModifier
                .fillMaxWidth()
                .background(accent)
                .padding(vertical = 10.dp, horizontal = 12.dp)
                .clickable(onClick = openFocus),
            contentAlignment = Alignment.Center,
        ) {
            Text(text = WidgetData.openFocusLabel(prefs), style = WidgetTheme.buttonStyle)
        }
    }
}
