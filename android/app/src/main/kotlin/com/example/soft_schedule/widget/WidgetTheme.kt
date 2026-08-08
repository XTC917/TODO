package com.example.soft_schedule.widget

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.text.FontWeight
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

object WidgetTheme {
    val cornerRadius = 18.dp
    val buttonCornerRadius = 12.dp
    val background = Color(0xFFFFF8F4)
    val textPrimary = Color(0xFF3D3835)
    val textSecondary = Color(0xFF8A827C)
    val checkboxEmpty = Color(0xFFFFFFFF)

    fun accent(hex: String): Color {
        val cleaned = hex.trim().removePrefix("#")
        return try {
            Color(0xFF000000L or cleaned.toLong(16))
        } catch (_: Exception) {
            Color(0xFFE8A0A0)
        }
    }

    val titleStyle = TextStyle(
        color = ColorProvider(textPrimary),
        fontSize = 15.sp,
        fontWeight = FontWeight.Bold,
    )

    val subtitleStyle = TextStyle(
        color = ColorProvider(textSecondary),
        fontSize = 12.sp,
        fontWeight = FontWeight.Medium,
    )

    val lineStyle = TextStyle(
        color = ColorProvider(textPrimary),
        fontSize = 13.sp,
        fontWeight = FontWeight.Normal,
    )

    val doneLineStyle = TextStyle(
        color = ColorProvider(textSecondary),
        fontSize = 13.sp,
        fontWeight = FontWeight.Normal,
    )

    val buttonStyle = TextStyle(
        color = ColorProvider(Color.White),
        fontSize = 13.sp,
        fontWeight = FontWeight.Bold,
    )

    val checkboxMarkStyle = TextStyle(
        color = ColorProvider(Color.White),
        fontSize = 13.sp,
        fontWeight = FontWeight.Bold,
    )

    val focusPendingStyle = TextStyle(
        color = ColorProvider(textPrimary),
        fontSize = 22.sp,
        fontWeight = FontWeight.Bold,
    )

    val compactLineStyle = TextStyle(
        color = ColorProvider(textPrimary),
        fontSize = 12.sp,
        fontWeight = FontWeight.Normal,
    )

    val compactDoneLineStyle = TextStyle(
        color = ColorProvider(textSecondary),
        fontSize = 12.sp,
        fontWeight = FontWeight.Normal,
    )

    val compactTitleStyle = TextStyle(
        color = ColorProvider(textPrimary),
        fontSize = 14.sp,
        fontWeight = FontWeight.Bold,
    )

    val padding = 14.dp
    val compactPadding = 10.dp

    fun surface(modifier: GlanceModifier = GlanceModifier): GlanceModifier =
        modifier
            .fillMaxSize()
            .cornerRadius(cornerRadius)
            .background(background)
            .padding(padding)

    fun compactSurface(modifier: GlanceModifier = GlanceModifier): GlanceModifier =
        modifier
            .fillMaxSize()
            .cornerRadius(cornerRadius)
            .background(background)
            .padding(compactPadding)
}
