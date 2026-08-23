package com.example.mosque_finder.geofencing

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

/** One mosque candidate the geofencing system is watching for. */
data class MosqueGeofence(
    val placeId: String,
    val name: String,
    val lat: Double,
    val lng: Double,
)

/**
 * All persisted state for the mosque-geofencing feature lives here, in a dedicated
 * SharedPreferences file. This is read/written from contexts that never touch Flutter
 * at all - [GeofenceBroadcastReceiver] and [BootReceiver] run when the app process may
 * be completely stopped - so it (not any in-memory field) is the single source of
 * truth shared with [MainActivity] and [MosqueGeofenceManager].
 */
object GeofencePrefs {
    private const val FILE = "mosque_geofence_prefs"
    private const val KEY_MOSQUES = "mosques"
    private const val KEY_INSIDE_IDS = "inside_ids"
    private const val KEY_SAVED_RINGER_MODE = "saved_ringer_mode"
    private const val KEY_SILENCED = "silenced_by_app"
    private const val KEY_ACTIVE_PLACE_ID = "active_place_id"
    private const val KEY_AUTOMATION_ENABLED = "automation_enabled"

    private fun prefs(context: Context): SharedPreferences =
        context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    /** The full set of mosques currently registered as geofences (survives process death). */
    fun saveMosques(context: Context, mosques: List<MosqueGeofence>) {
        val arr = JSONArray()
        mosques.forEach { m ->
            arr.put(
                JSONObject().apply {
                    put("placeId", m.placeId)
                    put("name", m.name)
                    put("lat", m.lat)
                    put("lng", m.lng)
                },
            )
        }
        prefs(context).edit().putString(KEY_MOSQUES, arr.toString()).apply()
    }

    fun loadMosques(context: Context): List<MosqueGeofence> {
        val raw = prefs(context).getString(KEY_MOSQUES, null) ?: return emptyList()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { i ->
                val o = arr.getJSONObject(i)
                MosqueGeofence(o.getString("placeId"), o.optString("name"), o.getDouble("lat"), o.getDouble("lng"))
            }
        } catch (e: Exception) {
            emptyList()
        }
    }

    /** placeIds the device is currently believed to be dwelling inside (post-loiter-delay). */
    fun getInsideIds(context: Context): Set<String> {
        val raw = prefs(context).getString(KEY_INSIDE_IDS, null) ?: return emptySet()
        return try {
            val arr = JSONArray(raw)
            (0 until arr.length()).map { arr.getString(it) }.toSet()
        } catch (e: Exception) {
            emptySet()
        }
    }

    fun setInsideIds(context: Context, ids: Set<String>) {
        val arr = JSONArray()
        ids.forEach { arr.put(it) }
        prefs(context).edit().putString(KEY_INSIDE_IDS, arr.toString()).apply()
    }

    /** AudioManager ringer mode saved right before we silenced it; -1 means "none saved". */
    fun getSavedRingerMode(context: Context): Int = prefs(context).getInt(KEY_SAVED_RINGER_MODE, -1)

    fun setSavedRingerMode(context: Context, mode: Int) {
        prefs(context).edit().putInt(KEY_SAVED_RINGER_MODE, mode).apply()
    }

    /** Whether *this app* is the one currently holding the ringer in silent mode. */
    fun isSilencedByApp(context: Context): Boolean = prefs(context).getBoolean(KEY_SILENCED, false)

    fun setSilencedByApp(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean(KEY_SILENCED, value).apply()
    }

    /** The mosque currently attributed as "the one you're at", or null if none. */
    fun getActivePlaceId(context: Context): String? = prefs(context).getString(KEY_ACTIVE_PLACE_ID, null)

    fun setActivePlaceId(context: Context, id: String?) {
        prefs(context).edit().putString(KEY_ACTIVE_PLACE_ID, id).apply()
    }

    /** Master on/off switch the user controls from the app - not mosque selection. */
    fun isAutomationEnabled(context: Context): Boolean = prefs(context).getBoolean(KEY_AUTOMATION_ENABLED, true)

    fun setAutomationEnabled(context: Context, value: Boolean) {
        prefs(context).edit().putBoolean(KEY_AUTOMATION_ENABLED, value).apply()
    }
}
