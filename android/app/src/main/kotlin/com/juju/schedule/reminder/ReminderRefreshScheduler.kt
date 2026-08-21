package com.juju.schedule.reminder

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

object ReminderRefreshScheduler {
    private const val UNIQUE_WORK = "juju_reminder_refresh"

    fun ensureScheduled(context: Context) {
        val request =
            PeriodicWorkRequestBuilder<ReminderRefreshWorker>(1, TimeUnit.DAYS)
                .setInitialDelay(6, TimeUnit.HOURS)
                .build()
        WorkManager.getInstance(context.applicationContext)
            .enqueueUniquePeriodicWork(
                UNIQUE_WORK,
                ExistingPeriodicWorkPolicy.KEEP,
                request,
            )
    }
}
