package com.juju.schedule

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ReminderNativeBridge {
    private const val CHANNEL = "com.juju.schedule/reminder_native"

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "getManufacturer" -> result.success(Build.MANUFACTURER)
                "openAutostartSettings" -> {
                    result.success(openAutostartSettings(context))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun openAutostartSettings(context: Context): Boolean {
        val intents =
            listOf(
                ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                ),
                ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.powercenter.PowerSettings",
                ),
            )
        for (component in intents) {
            try {
                val intent =
                    Intent().apply {
                        setComponent(component)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                context.startActivity(intent)
                return true
            } catch (_: Exception) {
                // try next
            }
        }
        val fallback =
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", context.packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
        context.startActivity(fallback)
        return false
    }
}
