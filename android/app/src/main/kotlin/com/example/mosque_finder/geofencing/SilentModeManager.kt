package com.example.mosque_finder.geofencing

import android.app.NotificationManager
import android.content.Context
import android.media.AudioManager
import android.util.Log

/**
 * Owns the actual ringer-mode side effect. Deliberately dumb/stateless beyond what's in
 * [GeofencePrefs]: [GeofenceBroadcastReceiver] decides *when* to call these (on the
 * 0-to-1 and 1-to-0 transitions of the "inside a mosque" geofence set), this just does
 * the AudioManager + persistence work once per transition.
 */
object SilentModeManager {
    private const val TAG = "SilentModeManager"

    fun enterSilentMode(context: Context, mosque: MosqueGeofence?) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (!notificationManager.isNotificationPolicyAccessGranted) {
            // Changing the ringer mode to SILENT/VIBRATE requires Do Not Disturb policy
            // access from Android 6.0 on - without it, AudioManager.setRingerMode is a
            // silent no-op. Tell the user instead of pretending it worked.
            Log.w(TAG, "Do Not Disturb access not granted - cannot silence the ringer")
            NotificationHelper.showPermissionNeededNotification(context)
            return
        }

        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        // Guard against a second DWELL while already-silenced (e.g. moving between
        // overlapping geofences) clobbering the saved mode with SILENT itself, which
        // would make the eventual restore a no-op.
        if (!GeofencePrefs.isSilencedByApp(context)) {
            GeofencePrefs.setSavedRingerMode(context, audioManager.ringerMode)
        }
        audioManager.ringerMode = AudioManager.RINGER_MODE_SILENT
        GeofencePrefs.setSilencedByApp(context, true)
        Log.i(TAG, "Entered ${mosque?.name ?: "a mosque"} geofence - ringer set to silent")
        NotificationHelper.showActiveMosqueNotification(context, mosque)
    }

    fun restoreRingerMode(context: Context) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val saved = GeofencePrefs.getSavedRingerMode(context)

        if (saved != -1) {
            if (notificationManager.isNotificationPolicyAccessGranted) {
                audioManager.ringerMode = saved
                Log.i(TAG, "Exited all mosque geofences - ringer restored to mode $saved")
            } else {
                Log.w(TAG, "Lost Do Not Disturb access while silenced; cannot auto-restore ringer mode")
            }
        }
        GeofencePrefs.setSilencedByApp(context, false)
        GeofencePrefs.setSavedRingerMode(context, -1)
        // Confirms the restore rather than just clearing the "active" notification -
        // a silently-vanishing notification wouldn't tell the user whether the ringer
        // actually came back or restoring it merely failed (e.g. saved == -1 above, or
        // DND access got revoked mid-visit).
        NotificationHelper.showRestoredNotification(context)
    }
}
