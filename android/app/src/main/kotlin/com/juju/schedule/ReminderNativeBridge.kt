package com.juju.schedule

import android.app.KeyguardManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale

object ReminderNativeBridge {
    private const val CHANNEL = "com.juju.schedule/reminder_native"

    fun register(engine: FlutterEngine, context: Context) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "getManufacturer" -> result.success(Build.MANUFACTURER)
                "getAutostartGuideType" -> result.success(autostartGuideType())
                "openAutostartSettings" -> {
                    result.success(openAutostartSettings(context))
                }
                "isScreenInteractive" -> {
                    result.success(isScreenInteractive(context))
                }
                "isStrictFocusScreenLock" -> {
                    result.success(isStrictFocusScreenLock(context))
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun autostartGuideType(): String {
        val manufacturer = Build.MANUFACTURER.lowercase(Locale.US)
        val brand = Build.BRAND.lowercase(Locale.US)
        return when {
            manufacturer.contains("xiaomi") ||
                brand.contains("xiaomi") ||
                brand.contains("redmi") ||
                brand.contains("poco") -> "xiaomi"
            manufacturer.contains("huawei") ||
                manufacturer.contains("honor") ||
                brand.contains("honor") -> "huawei"
            manufacturer.contains("oppo") ||
                manufacturer.contains("realme") ||
                brand.contains("oppo") ||
                brand.contains("realme") ||
                brand.contains("oneplus") -> "oppo"
            manufacturer.contains("vivo") ||
                brand.contains("vivo") ||
                brand.contains("iqoo") -> "vivo"
            manufacturer.contains("samsung") -> "samsung"
            else -> "generic"
        }
    }

    private fun openAutostartSettings(context: Context): Map<String, Any> {
        val guideType = autostartGuideType()
        for ((destination, intent) in autostartIntents(context, guideType)) {
            if (!canLaunch(context, intent)) continue
            try {
                context.startActivity(intent)
                return mapOf("opened" to true, "destination" to destination)
            } catch (_: Exception) {
                // try next
            }
        }
        return mapOf("opened" to false, "destination" to "failed")
    }

    private fun autostartIntents(
        context: Context,
        guideType: String,
    ): List<Pair<String, Intent>> {
        val pkg = context.packageName
        val intents = mutableListOf<Pair<String, Intent>>()

        fun add(destination: String, configure: Intent.() -> Unit) {
            intents.add(
                destination to
                    Intent().apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        configure()
                    },
            )
        }

        when (guideType) {
            "xiaomi" -> {
                add("miui_autostart") {
                    action = "miui.intent.action.OP_AUTO_START"
                    addCategory(Intent.CATEGORY_DEFAULT)
                    putExtra("extra_pkg", pkg)
                }
                add("miui_autostart") {
                    component =
                        ComponentName(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.autostart.AutoStartManagementActivity",
                        )
                }
                add("miui_autostart") {
                    component =
                        ComponentName(
                            "com.miui.securitycenter",
                            "com.miui.permcenter.permissions.PermissionsEditorActivity",
                        )
                    putExtra("extra_pkg", pkg)
                }
                add("miui_autostart") {
                    component =
                        ComponentName(
                            "com.miui.securitycenter",
                            "com.miui.powercenter.PowerSettings",
                        )
                }
            }
            "huawei" -> {
                add("huawei_autostart") {
                    component =
                        ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
                        )
                }
                add("huawei_autostart") {
                    component =
                        ComponentName(
                            "com.huawei.systemmanager",
                            "com.huawei.systemmanager.appcontrol.activity.StartupAppControlActivity",
                        )
                }
            }
            "oppo" -> {
                add("oppo_autostart") {
                    component =
                        ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                        )
                }
                add("oppo_autostart") {
                    component =
                        ComponentName(
                            "com.oppo.safe",
                            "com.oppo.safe.permission.startup.StartupAppListActivity",
                        )
                }
                add("oppo_autostart") {
                    component =
                        ComponentName(
                            "com.coloros.safecenter",
                            "com.coloros.safecenter.startupapp.StartupAppListActivity",
                        )
                }
            }
            "vivo" -> {
                add("vivo_autostart") {
                    component =
                        ComponentName(
                            "com.vivo.permissionmanager",
                            "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                        )
                }
                add("vivo_autostart") {
                    component =
                        ComponentName(
                            "com.iqoo.secure",
                            "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager",
                        )
                }
            }
            "samsung" -> {
                add("samsung_battery") {
                    component =
                        ComponentName(
                            "com.samsung.android.lool",
                            "com.samsung.android.sm.battery.ui.BatteryActivity",
                        )
                }
            }
        }

        add("app_details") {
            action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
            data = Uri.fromParts("package", pkg, null)
        }

        return intents
    }

    private fun canLaunch(context: Context, intent: Intent): Boolean {
        return intent.resolveActivity(context.packageManager) != null
    }

    private fun isScreenInteractive(context: Context): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return pm.isInteractive
    }

    /// True when strict focus should NOT treat background as leaving the app
    /// (keyguard locked and/or display off — includes lock screen still lit).
    private fun isStrictFocusScreenLock(context: Context): Boolean {
        val km = context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
        if (km.isKeyguardLocked) return true
        return !isScreenInteractive(context)
    }
}
