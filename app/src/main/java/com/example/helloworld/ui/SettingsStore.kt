package com.example.helloworld.ui

import android.content.Context

class SettingsStore(context: Context) {
    private val preferences = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    var darkTheme: Boolean
        get() = preferences.getBoolean(KEY_DARK_THEME, false)
        set(value) {
            preferences.edit().putBoolean(KEY_DARK_THEME, value).apply()
        }

    fun toggleDarkTheme() {
        darkTheme = !darkTheme
    }

    private companion object {
        const val PREFS_NAME = "ramun_settings"
        const val KEY_DARK_THEME = "dark_theme"
    }
}
