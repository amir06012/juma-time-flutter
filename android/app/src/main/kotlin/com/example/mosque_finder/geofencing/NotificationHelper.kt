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
import com.example.mosque_finder.R

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
                    context.getString(R.string.notif_channel_name),
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = context.getString(R.string.notif_channel_desc)
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

    /** Posted the moment the ringer actually goes silent - ongoing (can't be swiped
     *  away) so it stays as visible, standing proof of *why* the phone is quiet for as
     *  long as it stays that way, not just a one-off toast the user might miss. */
    fun showActiveMosqueNotification(context: Context, mosque: MosqueGeofence?) {
        if (!canPostNotifications(context)) return
        ensureChannel(context)
        val text = mosque?.let { context.getString(R.string.notif_active_text_named, it.name) }
            ?: context.getString(R.string.notif_active_text_generic)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode)
            .setContentTitle(context.getString(R.string.notif_active_title))
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        NotificationManagerCompat.from(context).notify(ACTIVE_NOTIFICATION_ID, notification)
    }

    fun clearActiveMosqueNotification(context: Context) {
        NotificationManagerCompat.from(context).cancel(ACTIVE_NOTIFICATION_ID)
    }

    /** Posted on exit, replacing the ongoing "active" notification (same id) with a
     *  brief, dismissible confirmation that the ringer is back to normal - without
     *  this the user only sees the silent-mode notification vanish, with nothing
     *  telling them the ringer was actually restored rather than, say, still silent
     *  because restoring it failed. */
    fun showRestoredNotification(context: Context) {
        if (!canPostNotifications(context)) return
        ensureChannel(context)
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_lock_silent_mode)
            .setContentTitle(context.getString(R.string.notif_restored_title))
            .setContentText(context.getString(R.string.notif_restored_text))
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
        NotificationManagerCompat.from(context).notify(ACTIVE_NOTIFICATION_ID, notification)
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
            .setContentTitle(context.getString(R.string.notif_permission_title))
            .setContentText(context.getString(R.string.notif_permission_text))
            .setContentIntent(contentIntent)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .build()
        NotificationManagerCompat.from(context).notify(PERMISSION_NOTIFICATION_ID, notification)
    }
}
