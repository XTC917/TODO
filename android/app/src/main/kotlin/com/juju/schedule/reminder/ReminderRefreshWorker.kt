package com.juju.schedule.reminder

import android.app.ActivityManager
import android.content.Context
import android.net.Uri
import android.os.Process
import androidx.work.Worker
import androidx.work.WorkerParameters
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class ReminderRefreshWorker(
    context: Context,
    params: WorkerParameters,
) : Worker(context, params) {
    override fun doWork(): Result {
        if (isAppInForeground(applicationContext)) {
            return Result.success()
        }
        HomeWidgetBackgroundIntent.getBroadcast(
            applicationContext,
            Uri.parse("jujuschedule://reminder/refresh"),
        ).send()
        return Result.success()
    }

    private fun isAppInForeground(context: Context): Boolean {
        val manager = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return false
        val pid = Process.myPid()
        return manager.runningAppProcesses.orEmpty().any { process ->
            process.pid == pid &&
                process.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND
        }
    }
}
