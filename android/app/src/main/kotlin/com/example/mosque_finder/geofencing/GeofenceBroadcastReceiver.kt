package com.example.mosque_finder.geofencing

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

/**
 * Fired by Play services (via the PendingIntent registered in [MosqueGeofenceManager])
 * whenever the device dwells inside, or exits, a registered mosque geofence. Runs
 * independent of the Flutter engine, which is what makes silent mode work while the
 * app is backgrounded, minimized, or the device is locked - not just in the foreground.
 */
class GeofenceBroadcastReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "MosqueGeofenceReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        // The AudioManager + SharedPreferences work below is fast, but this can run
        // with the app process fully stopped, so goAsync() gives a safety margin
        // beyond the receiver's normal execution window.
        val pendingResult = goAsync()
        try {
            handle(context, intent)
        } finally {
            pendingResult.finish()
        }
    }

    private fun handle(context: Context, intent: Intent) {
        val event = GeofencingEvent.fromIntent(intent)
        if (event == null) {
            Log.w(TAG, "Received intent with no geofencing event: ${intent.action}")
            return
        }
        if (event.hasError()) {
            Log.e(TAG, "Geofencing error: ${GeofenceStatusCodes.getStatusCodeString(event.errorCode)}")
            return
        }
        if (!GeofencePrefs.isAutomationEnabled(context)) {
            Log.i(TAG, "Automatic silent mode is disabled by the user; ignoring transition")
            return
        }

        val triggeringIds = event.triggeringGeofences?.mapNotNull { it.requestId } ?: emptyList()
        if (triggeringIds.isEmpty()) {
            Log.w(TAG, "Transition event had no triggering geofences")
            return
        }

        val mosquesById = GeofencePrefs.loadMosques(context).associateBy { it.placeId }
        val insideIds = GeofencePrefs.getInsideIds(context).toMutableSet()

        when (event.geofenceTransition) {
            Geofence.GEOFENCE_TRANSITION_DWELL -> {
                // DWELL only fires after ~90s of continuous presence (see
                // MosqueGeofenceManager.LOITER_DELAY_MS) - this is what filters out
                // someone simply walking or driving past.
                insideIds.addAll(triggeringIds)
                Log.i(TAG, "Dwell confirmed inside: $triggeringIds")
            }
            Geofence.GEOFENCE_TRANSITION_EXIT -> {
                insideIds.removeAll(triggeringIds.toSet())
                Log.i(TAG, "Exited geofence(s): $triggeringIds")
            }
            else -> {
                Log.d(TAG, "Ignoring transition type ${event.geofenceTransition}")
                return
            }
        }
        GeofencePrefs.setInsideIds(context, insideIds)

        val wasSilenced = GeofencePrefs.isSilencedByApp(context)

        if (insideIds.isEmpty()) {
            GeofencePrefs.setActivePlaceId(context, null)
            if (wasSilenced) {
                SilentModeManager.restoreRingerMode(context)
                GeofenceEventBridge.emit(mapOf("type" to "exit", "placeId" to null, "name" to null))
            }
            return
        }

        // More than one geofence can be "inside" at once (overlapping mosque
        // complexes, or duplicate Places listings for the same building). Pick the one
        // nearest to where the transition actually fired as the "most likely" mosque.
        val triggerLoc = event.triggeringLocation
        val active = insideIds.mapNotNull { mosquesById[it] }.minByOrNull { m ->
            if (triggerLoc != null) distanceMeters(triggerLoc.latitude, triggerLoc.longitude, m.lat, m.lng) else 0.0
        }
        GeofencePrefs.setActivePlaceId(context, active?.placeId)

        if (!wasSilenced) {
            SilentModeManager.enterSilentMode(context, active)
            GeofenceEventBridge.emit(mapOf("type" to "enter", "placeId" to active?.placeId, "name" to active?.name))
        } else if (active != null) {
            // Already silenced from a previous DWELL in this overlapping cluster - just
            // refresh which mosque we're attributing it to, don't re-toggle the ringer
            // (that's what avoids a duplicate silent-mode trigger, per requirement 14).
            NotificationHelper.showActiveMosqueNotification(context, active)
            GeofenceEventBridge.emit(mapOf("type" to "update", "placeId" to active.placeId, "name" to active.name))
        }
    }
}
