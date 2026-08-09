package com.example.soft_schedule.widget

import android.content.Context
import android.content.SharedPreferences
import android.content.ContentValues
import android.database.sqlite.SQLiteDatabase
import org.json.JSONArray
import java.io.File

object WidgetNativeToggle {

    fun toggleEvent(context: Context, eventId: Int): Boolean {
        val dbFile = File(context.applicationInfo.dataDir, "app_flutter/soft_schedule.sqlite")
        if (!dbFile.exists()) return false

        val db =
            SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READWRITE)
        try {
            db.rawQuery(
                "SELECT is_completed FROM events WHERE id = ?",
                arrayOf(eventId.toString()),
            ).use { cursor ->
                if (!cursor.moveToFirst()) return false
                val wasDone = cursor.getInt(0) != 0
                val nowDone = !wasDone
                val nowMs = System.currentTimeMillis()
                val values = ContentValues().apply {
                    put("is_completed", if (nowDone) 1 else 0)
                    if (nowDone) {
                        put("completed_at", nowMs)
                    } else {
                        putNull("completed_at")
                    }
                    put("updated_at", nowMs)
                }
                val updated = db.update(
                    "events",
                    values,
                    "id = ?",
                    arrayOf(eventId.toString()),
                )
                if (updated <= 0) return false
                flipDoneInWidgetPrefs(context, eventId, nowDone)
                bumpDataRevision(context)
                return true
            }
        } finally {
            db.close()
        }
    }

    /** @deprecated Use [toggleEvent] — kept for call-site clarity. */
    fun toggleTodo(context: Context, eventId: Int): Boolean = toggleEvent(context, eventId)

    private fun flipDoneInWidgetPrefs(context: Context, eventId: Int, done: Boolean) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        flipJsonDone(prefs, "juju_todos_json", eventId, done)
        flipJsonDone(prefs, "juju_schedules_json", eventId, done)
    }

    private fun flipJsonDone(
        prefs: SharedPreferences,
        key: String,
        eventId: Int,
        done: Boolean,
    ) {
        val raw = prefs.getString(key, "[]") ?: "[]"
        try {
            val array = JSONArray(raw)
            var changed = false
            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)
                if (obj.optInt("id", 0) == eventId) {
                    obj.put("done", done)
                    changed = true
                    break
                }
            }
            if (changed) {
                prefs.edit().putString(key, array.toString()).apply()
            }
        } catch (_: Exception) {
        }
    }

    private fun bumpDataRevision(context: Context) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val next = prefs.getInt("juju_data_revision", 0) + 1
        prefs.edit().putInt("juju_data_revision", next).apply()
    }
}
