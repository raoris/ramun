package com.example.helloworld.config

import java.net.HttpURLConnection
import java.net.URL

class ConfigNotModifiedException : Exception()

data class ConfigPayload(
    val json: String,
    val signature: String,
    val etag: String?
)

class ConfigRemoteDataSource {
    fun fetch(etag: String?): ConfigPayload {
        val configResponse = request(CONFIG_URL, etag)
        if (configResponse.status == HttpURLConnection.HTTP_NOT_MODIFIED) {
            throw ConfigNotModifiedException()
        }
        val signatureResponse = request(SIGNATURE_URL, null)
        return ConfigPayload(configResponse.body, signatureResponse.body.trim(), configResponse.etag)
    }

    private fun request(url: String, etag: String?): ConfigResponse {
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.connectTimeout = 10_000
        connection.readTimeout = 10_000
        connection.setRequestProperty("Accept", "text/plain")
        connection.setRequestProperty("Cache-Control", "no-cache")
        if (!etag.isNullOrBlank()) {
            connection.setRequestProperty("If-None-Match", etag)
        }
        return try {
            val status = connection.responseCode
            val body = if (status in 200..299) {
                connection.inputStream.bufferedReader().use { it.readText() }
            } else {
                connection.errorStream?.bufferedReader()?.use { it.readText() }.orEmpty()
            }
            ConfigResponse(status, body, connection.getHeaderField("ETag"))
        } finally {
            connection.disconnect()
        }
    }
}

private data class ConfigResponse(
    val status: Int,
    val body: String,
    val etag: String?
)

private const val CONFIG_URL = "https://raw.githubusercontent.com/raoris/ramun/main/config/app_config.json"
private const val SIGNATURE_URL = "https://raw.githubusercontent.com/raoris/ramun/main/config/app_config.sig"
