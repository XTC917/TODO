package com.example.soft_schedule.widget

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import org.json.JSONArray
import java.io.File

object WidgetNativeToggle {

    fun toggleTodo(context: Context, eventId: Int): Boolean {
        val dbFile = File(context.applicationInfo.dataDir, "app_flutter/soft_schedule.sqlite")
        if (!dbFile.exists()) return false

        val db =
            SQLiteDatabase.openDatabase(dbFile.path, null, SQLiteDatabase.OPEN_READWRITE)
        try {
            db.rawQuery(
                "SELECT is_completed, task_type FROM events WHERE id = ?",
                arrayOf(eventId.toString()),
            ).use { cursor ->
                if (!cursor.moveToFirst()) return false
                if (cursor.getString(1) != "todo") return false
                val wasDone = cursor.getInt(0) == 1
                val nowDone = !wasDone
                val nowMs = System.currentTimeMillis()
                val values = ContentValues().apply {
                    put("is_completed", nowDone)
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
                flipTodoInWidgetPrefs(context, eventId, nowDone)
                return true
            }
        } finally {
            db.close()
        }
    }

    private fun flipTodoInWidgetPrefs(context: Context, eventId: Int, done: Boolean) {
        val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        val raw = prefs.getString("juju_todos_json", "[]") ?: "[]"
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
                prefs.edit().putString("juju_todos_json", array.toString()).apply()
            }
        } catch (_: Exception) {
        }
    }
}
