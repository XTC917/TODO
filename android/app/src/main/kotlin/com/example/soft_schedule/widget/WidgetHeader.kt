package com.example.soft_schedule.widget

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
import com.example.soft_schedule.MainActivity
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
            .padding(bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = if (compact) WidgetTheme.compactTitleStyle else WidgetTheme.titleStyle,
            modifier = GlanceModifier.clickable(onClick = openAction),
        )
        Spacer(GlanceModifier.defaultWeight())
        Text(
            text = "+",
            style = TextStyle(
                color = accent,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
            ),
            modifier = GlanceModifier
                .padding(start = 8.dp)
                .clickable(onClick = addAction),
        )
    }
}
