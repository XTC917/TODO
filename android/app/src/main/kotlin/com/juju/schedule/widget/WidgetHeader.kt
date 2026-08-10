package com.juju.schedule.widget

import android.content.Context
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.layout.Alignment
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.juju.schedule.MainActivity
import es.antonborri.home_widget.actionStartActivity

@Composable
fun WidgetHeader(
    context: Context,
    title: String,
    openUri: String,
    addUri: String,
    compact: Boolean = false,
) {
    val openAction = actionStartActivity<MainActivity>(
        context,
        Uri.parse(openUri),
    )
    val addAction = actionStartActivity<MainActivity>(
        context,
        Uri.parse(addUri),
    )
    val accent = ColorProvider(
        WidgetTheme.accent(
            context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                .getString("juju_accent_hex", "E8A0A0") ?: "E8A0A0",
        ),
    )

    Row(
        modifier = GlanceModifier
            .fillMaxWidth()
            .padding(
                end = if (compact) 4.dp else 0.dp,
                bottom = 4.dp,
            ),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = if (compact) WidgetTheme.compactTitleStyle else WidgetTheme.titleStyle,
            modifier = GlanceModifier
                .defaultWeight()
                .clickable(onClick = openAction),
        )
        Text(
            text = "+",
            style = TextStyle(
                color = accent,
                fontSize = if (compact) 20.sp else 22.sp,
                fontWeight = FontWeight.Bold,
            ),
            modifier = GlanceModifier
                .padding(start = 4.dp, end = if (compact) 2.dp else 0.dp)
                .clickable(onClick = addAction),
        )
    }
}
