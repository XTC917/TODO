package com.example.soft_schedule.widget

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.text.FontWeight
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

object WidgetTheme {
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

    val padding = 14.dp
}
