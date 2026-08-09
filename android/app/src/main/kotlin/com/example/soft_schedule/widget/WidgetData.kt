package com.example.soft_schedule.widget

import android.content.SharedPreferences
import org.json.JSONArray

object WidgetData {
    data class TodoLine(val id: Int, val title: String, val done: Boolean)
    data class TimelineLine(
        val id: Int,
        val title: String,
        val time: String,
        val done: Boolean,
    )

    fun accentColorHex(prefs: SharedPreferences): String =
        prefs.getString("juju_accent_hex", "E8A0A0") ?: "E8A0A0"

    fun todoTitle(prefs: SharedPreferences): String =
        prefs.getString("juju_label_todo_title", "Todos") ?: "Todos"

    fun scheduleTitle(prefs: SharedPreferences): String =
        prefs.getString("juju_label_schedule_title", "Schedule") ?: "Schedule"

    fun focusTitle(prefs: SharedPreferences): String =
        prefs.getString("juju_label_focus_title", "Focus") ?: "Focus"

    fun startFocusLabel(prefs: SharedPreferences): String =
        prefs.getString("juju_label_start_focus", "Start focus") ?: "Start focus"

    fun emptyLabel(prefs: SharedPreferences): String =
        prefs.getString("juju_label_empty", "Nothing here") ?: "Nothing here"

    fun todoProgress(prefs: SharedPreferences): String =
        prefs.getString("juju_label_todo_progress", "") ?: ""

    fun focusDuration(prefs: SharedPreferences): String =
        prefs.getString("juju_label_focus_duration", "0 min") ?: "0 min"

    fun openFocusLabel(prefs: SharedPreferences): String =
        prefs.getString("juju_label_open_focus", "Open focus") ?: "Open focus"

    fun focusPendingLabel(prefs: SharedPreferences): String =
        prefs.getString("juju_label_focus_pending", "") ?: ""

    fun todos(prefs: SharedPreferences): List<TodoLine> {
        val raw = prefs.getString("juju_todos_json", "[]") ?: "[]"
        return parseTodos(raw)
    }

    fun timeline(prefs: SharedPreferences): List<TimelineLine> {
        val raw = prefs.getString("juju_schedules_json", "[]") ?: "[]"
        return parseTimeline(raw)
    }

    private fun parseTodos(raw: String): List<TodoLine> {
        return try {
            val array = JSONArray(raw)
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    add(
                        TodoLine(
                            id = obj.optInt("id", 0),
                            title = obj.optString("title", ""),
                            done = obj.optBoolean("done", false),
                        ),
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }

    private fun parseTimeline(raw: String): List<TimelineLine> {
        return try {
            val array = JSONArray(raw)
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    add(
                        TimelineLine(
                            id = obj.optInt("id", 0),
                            title = obj.optString("title", ""),
                            time = obj.optString("time", ""),
                            done = obj.optBoolean("done", false),
                        ),
                    )
                }
            }
        } catch (_: Exception) {
            emptyList()
        }
    }
}
