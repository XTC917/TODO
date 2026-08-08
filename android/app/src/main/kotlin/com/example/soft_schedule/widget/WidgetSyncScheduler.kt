package com.example.soft_schedule.widget

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

object WidgetSyncScheduler {
    private const val SYNC_DELAY_MS = 1400L
    private val handler = Handler(Looper.getMainLooper())
    private var pendingSync: Runnable? = null

    fun scheduleBackgroundSync(context: Context, eventId: Int) {
        pendingSync?.let { handler.removeCallbacks(it) }
        val appContext = context.applicationContext
        pendingSync = Runnable {
            HomeWidgetBackgroundIntent.getBroadcast(
                appContext,
                Uri.parse("jujuschedule://todo/sync?id=$eventId&drop=1"),
            ).send()
        }
        handler.postDelayed(pendingSync!!, SYNC_DELAY_MS)
    }
}
