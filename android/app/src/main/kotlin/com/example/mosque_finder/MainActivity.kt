package com.example.mosque_finder

import android.app.NotificationManager
import android.content.Intent
import android.provider.Settings
import com.example.mosque_finder.geofencing.GeofenceEventBridge
import com.example.mosque_finder.geofencing.GeofencePrefs
import com.example.mosque_finder.geofencing.MosqueGeofence
import com.example.mosque_finder.geofencing.MosqueGeofenceManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "mosque_finder/geofencing"
    private val eventChannelName = "mosque_finder/geofencing/events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val geofenceManager = MosqueGeofenceManager(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "registerGeofences" -> {
                        @Suppress("UNCHECKED_CAST")
                        val args = call.arguments as? List<Map<String, Any?>> ?: emptyList()
                        val mosques = args.mapNotNull { m ->
                            val placeId = m["placeId"] as? String
                            val lat = (m["latitude"] as? Number)?.toDouble()
                            val lng = (m["longitude"] as? Number)?.toDouble()
                            if (placeId == null || lat == null || lng == null) {
                                null
                            } else {
                                MosqueGeofence(placeId, m["name"] as? String ?: "", lat, lng)
                            }
                        }
                        geofenceManager.syncGeofences(mosques) { added, removed, total ->
                            result.success(mapOf("added" to added, "removed" to removed, "total" to total))
                        }
                    }

                    "clearGeofences" -> geofenceManager.clearAll { result.success(null) }

                    "getActiveMosque" -> {
                        val activeId = GeofencePrefs.getActivePlaceId(applicationContext)
                        val mosque = GeofencePrefs.loadMosques(applicationContext).firstOrNull { it.placeId == activeId }
                        result.success(mosque?.let { mapOf("placeId" to it.placeId, "name" to it.name) })
                    }

                    "getRegisteredMosqueCount" ->
                        result.success(GeofencePrefs.loadMosques(applicationContext).size)

                    "getRegisteredMosques" -> {
                        val mosques = GeofencePrefs.loadMosques(applicationContext).map {
                            mapOf(
                                "placeId" to it.placeId,
                                "name" to it.name,
                                "latitude" to it.lat,
                                "longitude" to it.lng,
                            )
                        }
                        result.success(mosques)
                    }

                    "isAutomationEnabled" ->
                        result.success(GeofencePrefs.isAutomationEnabled(applicationContext))

                    "setAutomationEnabled" -> {
                        val enabled = call.arguments as? Boolean ?: true
                        GeofencePrefs.setAutomationEnabled(applicationContext, enabled)
                        result.success(null)
                    }

                    "isNotificationPolicyAccessGranted" -> {
                        val nm = applicationContext.getSystemService(
                            android.content.Context.NOTIFICATION_SERVICE,
                        ) as NotificationManager
                        result.success(nm.isNotificationPolicyAccessGranted)
                    }

                    "openNotificationPolicySettings" -> {
                        startActivity(
                            Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
                                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        GeofenceEventBridge.attach(events)
                    }

                    override fun onCancel(arguments: Any?) {
                        GeofenceEventBridge.attach(null)
                    }
                },
            )
    }
}
