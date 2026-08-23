package com.example.mosque_finder.geofencing

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat

/**
 * Play services geofences do not survive a reboot - Android drops them along with
 * everything else non-persistent. This re-registers whatever mosque list was last
 * cached in [GeofencePrefs] so the feature keeps working without the app needing to be
 * opened again first.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        const val TAG = "MosqueBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        // Ringer/session bookkeeping doesn't carry meaningful information across a
        // reboot (we can't know if the user was mid-visit) - clear it defensively so a
        // later EXIT can't try to "restore" a stale saved ringer mode.
        GeofencePrefs.setInsideIds(context, emptySet())
        GeofencePrefs.setSilencedByApp(context, false)
        GeofencePrefs.setSavedRingerMode(context, -1)
        GeofencePrefs.setActivePlaceId(context, null)

        if (!GeofencePrefs.isAutomationEnabled(context)) {
            Log.i(TAG, "Automation disabled; skipping geofence re-registration after boot")
            return
        }
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "Location permission missing after boot; cannot re-register geofences")
            return
        }

        val cached = GeofencePrefs.loadMosques(context)
        if (cached.isEmpty()) {
            Log.i(TAG, "No cached mosques to re-register after boot")
            return
        }

        // GeofencePrefs' "already registered" set only reflects what's live in Play
        // services, which the reboot just wiped - clear it first so syncGeofences()
        // treats every cached mosque as new and actually re-adds all of them.
        GeofencePrefs.saveMosques(context, emptyList())
        Log.i(TAG, "Re-registering ${cached.size} mosque geofences after boot")
        MosqueGeofenceManager(context).syncGeofences(cached) { added, _, total ->
            Log.i(TAG, "Boot re-registration complete: $added geofences added, total=$total")
        }
    }
}
