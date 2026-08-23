package com.example.mosque_finder.geofencing

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/** Builds/updates/clears the small status notifications for this feature. */
object NotificationHelper {
    private const val CHANNEL_ID = "mosque_silent_mode"
    private const val ACTIVE_NOTIFICATION_ID = 4201
    private const val PERMISSION_NOTIFICATION_ID = 4202

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "Mosque silent mode",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Shown while your ringer is automatically silenced near a mosque"
                }
                manager.createNotificationChannel(channel)
            }
        }
    }

    private fun canPostNotifications(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return true
        return ActivityCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    }

    fun showActiveMosqueNotification(context: Context, mosque: MosqueGeofence?) {
        if (!canPostNotifications(context)) return
        ensureChannel(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode)
            .setContentTitle("Silent mode active")
            .setContentText(mosque?.let { "Ringer silenced near ${it.name}" } ?: "Ringer silenced near a mosque")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        NotificationManagerCompat.from(context).notify(ACTIVE_NOTIFICATION_ID, notification)
    }

    fun clearActiveMosqueNotification(context: Context) {
        NotificationManagerCompat.from(context).cancel(ACTIVE_NOTIFICATION_ID)
    }

    fun showPermissionNeededNotification(context: Context) {
        if (!canPostNotifications(context)) return
        ensureChannel(context)
        val settingsIntent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val contentIntent = PendingIntent.getActivity(
            context,
            0,
            settingsIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode)
            .setContentTitle("Can't enable silent mode")
            .setContentText("Grant Do Not Disturb access so Mosque Finder can silence your ringer automatically")
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
        NotificationManagerCompat.from(context).notify(PERMISSION_NOTIFICATION_ID, notification)
    }
}
