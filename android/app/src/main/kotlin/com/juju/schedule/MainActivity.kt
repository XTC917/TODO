package com.juju.schedule

import android.os.Bundle
import com.juju.schedule.reminder.ReminderRefreshScheduler
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        ReminderRefreshScheduler.ensureScheduled(this)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ReminderNativeBridge.register(flutterEngine, this)
    }
}
