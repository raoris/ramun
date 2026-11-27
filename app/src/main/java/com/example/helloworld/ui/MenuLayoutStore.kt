package com.example.helloworld.ui

import android.content.Context

class MenuLayoutStore(context: Context) {
    private val preferences = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    data class Bounds(val left: Int, val top: Int, val width: Int, val height: Int)

    var bounds: Bounds?
        get() = if (preferences.contains(KEY_LEFT)) {
            Bounds(
                preferences.getInt(KEY_LEFT, 0),
                preferences.getInt(KEY_TOP, 0),
                preferences.getInt(KEY_WIDTH, 0),
                preferences.getInt(KEY_HEIGHT, 0)
            )
        } else {
            null
        }
        set(value) {
            if (value == null) {
                preferences.edit().clear().apply()
            } else {
                preferences.edit()
                    .putInt(KEY_LEFT, value.left)
                    .putInt(KEY_TOP, value.top)
                    .putInt(KEY_WIDTH, value.width)
                    .putInt(KEY_HEIGHT, value.height)
                    .apply()
            }
        }

    private companion object {
        const val PREFS_NAME = "ramun_menu_layout"
        const val KEY_LEFT = "left"
        const val KEY_TOP = "top"
        const val KEY_WIDTH = "width"
        const val KEY_HEIGHT = "height"
    }
}
