package com.example.mosque_finder.geofencing

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Bridges geofence transition events from [GeofenceBroadcastReceiver] (which can run
 * with no Flutter engine alive at all) to the Dart side's EventChannel stream when an
 * engine happens to be attached and listening. Silently drops events otherwise - the
 * persisted "active mosque" state in [GeofencePrefs] and the system notification in
 * [NotificationHelper] are the source of truth for anything that must survive the app
 * being fully closed; this stream is purely a live-UI nicety.
 */
object GeofenceEventBridge {
    @Volatile
    private var sink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun attach(eventSink: EventChannel.EventSink?) {
        sink = eventSink
    }

    fun emit(data: Map<String, Any?>) {
        val currentSink = sink ?: return
        mainHandler.post {
            try {
                currentSink.success(data)
            } catch (_: Exception) {
                // Engine detached between the null-check and this post; nothing to do.
            }
        }
    }
}
