package com.example.helloworld.config

import android.content.Context
import com.example.helloworld.R
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

enum class ConfigSource {
    REMOTE,
    CACHE,
    BUNDLED
}

data class ConfigResult(
    val config: RemoteConfig,
    val source: ConfigSource,
    val message: String? = null
)

class ConfigRepository(context: Context) {
    private val applicationContext = context.applicationContext
    private val decoder = Json { ignoreUnknownKeys = true }
    private val dataSource = ConfigRemoteDataSource()
    private val store = ConfigStore(applicationContext)
    private val bundledJson = applicationContext.resources
        .openRawResource(R.raw.default_config)
        .bufferedReader()
        .use { it.readText() }
    private val bundledConfig = decode(bundledJson)

    suspend fun load(forceRefresh: Boolean = false): ConfigResult = withContext(Dispatchers.IO) {
        val cached = store.read()?.let { safeDecode(it.json) }
        if (!forceRefresh && cached != null) {
            ConfigResult(cached, ConfigSource.CACHE)
        } else {
            try {
                val payload = dataSource.fetch(if (forceRefresh) null else store.read()?.etag)
                if (!ConfigVerifier.verify(payload.json, payload.signature)) {
                    throw SecurityException("Config signature verification failed")
                }
                val config = decode(payload.json)
                if (config.schemaVersion != SUPPORTED_SCHEMA_VERSION) {
                    throw IllegalArgumentException("Unsupported config schema")
                }
                if (config.minimumAppVersion > appVersion()) {
                    throw IllegalArgumentException("Config requires a newer app version")
                }
                store.save(payload.json, payload.etag)
                ConfigResult(config, ConfigSource.REMOTE)
            } catch (e: ConfigNotModifiedException) {
                cached?.let { ConfigResult(it, ConfigSource.CACHE) }
                    ?: ConfigResult(bundledConfig, ConfigSource.BUNDLED, e.message)
            } catch (e: Exception) {
                cached?.let { ConfigResult(it, ConfigSource.CACHE, e.message) }
                    ?: ConfigResult(bundledConfig, ConfigSource.BUNDLED, e.message)
            }
        }
    }

    private fun decode(value: String): RemoteConfig = decoder.decodeFromString(value)

    private fun safeDecode(value: String): RemoteConfig? = try {
        decode(value)
    } catch (e: Exception) {
        null
    }

    @Suppress("DEPRECATION")
    private fun appVersion(): Int = applicationContext.packageManager
        .getPackageInfo(applicationContext.packageName, 0)
        .versionCode
        .toInt()

    private companion object {
        const val SUPPORTED_SCHEMA_VERSION = 1
    }
}
