package dev.mazgi.app

import android.content.Context
import android.content.SharedPreferences

object DebugSettings {
    private var prefs: SharedPreferences? = null

    fun init(context: Context) {
        prefs = context.getSharedPreferences("debug_settings", Context.MODE_PRIVATE)
    }

    var apiBaseUrl: String?
        get() = prefs?.getString("api_base_url", null)
        set(value) { prefs?.edit()?.putString("api_base_url", value)?.apply() }

    var twitterAuthBaseUrl: String?
        get() = prefs?.getString("twitter_auth_base_url", null)
        set(value) { prefs?.edit()?.putString("twitter_auth_base_url", value)?.apply() }
}
