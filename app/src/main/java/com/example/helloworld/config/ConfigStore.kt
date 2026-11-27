package com.example.helloworld.config

import android.content.Context

data class CachedConfig(
    val json: String,
    val etag: String?
)

class ConfigStore(context: Context) {
    private val preferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun read(): CachedConfig? {
        val json = preferences.getString(KEY_JSON, null) ?: return null
        return CachedConfig(json, preferences.getString(KEY_ETAG, null))
    }

    fun save(json: String, etag: String?) {
        preferences.edit()
            .putString(KEY_JSON, json)
            .putString(KEY_ETAG, etag)
            .putLong(KEY_SAVED_AT, System.currentTimeMillis())
            .apply()
    }

    private companion object {
        const val PREFS_NAME = "ramun_config"
        const val KEY_JSON = "json"
        const val KEY_ETAG = "etag"
        const val KEY_SAVED_AT = "saved_at"
    }
}
