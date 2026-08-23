package com.example.mosque_finder.geofencing

import android.Manifest
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices

/**
 * Registers/unregisters mosque geofences with Play services and keeps [GeofencePrefs]
 * in sync as the source of truth for what's currently registered.
 */
class MosqueGeofenceManager(private val context: Context) {

    companion object {
        const val TAG = "MosqueGeofenceMgr"
        private const val ACTION_GEOFENCE_EVENT = "com.example.mosque_finder.ACTION_GEOFENCE_EVENT"

        /** Small enough to sit on one building, generous enough to absorb typical
         *  consumer-GPS error (5-20m) without missing a real visit. */
        const val RADIUS_METERS = 75f

        /** Minimum continuous time inside the geofence before it counts as an actual
         *  visit rather than someone walking or driving past - this, combined with
         *  only listening for DWELL (not ENTER), is what prevents pass-by triggers. */
        const val LOITER_DELAY_MS = 90_000
    }

    private val geofencingClient = LocationServices.getGeofencingClient(context)

    private val pendingIntent: PendingIntent by lazy {
        val intent = Intent(context, GeofenceBroadcastReceiver::class.java).apply {
            action = ACTION_GEOFENCE_EVENT
        }
        // Geofence PendingIntents must be mutable from Android 12 (S) on, since Play
        // services writes the GeofencingEvent extras into this exact Intent.
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        PendingIntent.getBroadcast(context, 0, intent, flags)
    }

    private fun MosqueGeofence.toGeofence(): Geofence =
        Geofence.Builder()
            .setRequestId(placeId)
            .setCircularRegion(lat, lng, RADIUS_METERS)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_DWELL or Geofence.GEOFENCE_TRANSITION_EXIT)
            .setLoiteringDelay(LOITER_DELAY_MS)
            .build()

    /**
     * Diffs [newMosques] against whatever is already registered and only adds/removes
     * the difference, so an unchanged nearby-mosque list (the common case - most app
     * opens happen in the same neighborhood) costs zero Play services calls and avoids
     * duplicate registrations.
     */
    fun syncGeofences(newMosques: List<MosqueGeofence>, callback: (added: Int, removed: Int, total: Int) -> Unit) {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "ACCESS_FINE_LOCATION not granted; cannot register geofences")
            callback(0, 0, GeofencePrefs.loadMosques(context).size)
            return
        }

        val existingIds = GeofencePrefs.loadMosques(context).map { it.placeId }.toSet()
        val incomingIds = newMosques.map { it.placeId }.toSet()
        val toRemove = (existingIds - incomingIds).toList()
        val toAdd = newMosques.filter { it.placeId !in existingIds }

        if (toRemove.isEmpty() && toAdd.isEmpty()) {
            Log.d(TAG, "Geofence set unchanged (${existingIds.size} mosques); skipping re-registration")
            callback(0, 0, existingIds.size)
            return
        }

        fun finish() {
            GeofencePrefs.saveMosques(context, newMosques)
            // Drop any "currently inside" bookkeeping for mosques that fell out of range,
            // so a stale exit event can't fire for a geofence that no longer exists.
            GeofencePrefs.setInsideIds(context, GeofencePrefs.getInsideIds(context).intersect(incomingIds))
            Log.i(TAG, "Geofences synced: -${toRemove.size} +${toAdd.size}, total=${newMosques.size}")
            callback(toAdd.size, toRemove.size, newMosques.size)
        }

        fun addNew() {
            if (toAdd.isEmpty()) {
                finish()
                return
            }
            val request = GeofencingRequest.Builder()
                // Evaluate DWELL after registration rather than firing immediately for
                // whatever we're already standing in - avoids a spurious trigger every
                // time the app re-syncs the list while the user happens to be nearby.
                .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_DWELL)
                .addGeofences(toAdd.map { it.toGeofence() })
                .build()
            try {
                geofencingClient.addGeofences(request, pendingIntent)
                    .addOnSuccessListener { finish() }
                    .addOnFailureListener { e ->
                        Log.e(TAG, "addGeofences failed", e)
                        callback(0, toRemove.size, existingIds.size - toRemove.size)
                    }
            } catch (e: SecurityException) {
                Log.e(TAG, "SecurityException registering geofences", e)
                callback(0, 0, existingIds.size)
            }
        }

        if (toRemove.isNotEmpty()) {
            geofencingClient.removeGeofences(toRemove).addOnCompleteListener { addNew() }
        } else {
            addNew()
        }
    }

    fun clearAll(callback: () -> Unit) {
        geofencingClient.removeGeofences(pendingIntent).addOnCompleteListener {
            GeofencePrefs.saveMosques(context, emptyList())
            GeofencePrefs.setInsideIds(context, emptySet())
            Log.i(TAG, "All mosque geofences cleared")
            callback()
        }
    }
}
