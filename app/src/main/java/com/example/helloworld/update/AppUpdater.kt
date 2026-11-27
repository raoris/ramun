package com.example.helloworld.update

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.widget.Toast
import androidx.core.content.FileProvider
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class AppUpdater(private val context: Context) {

    suspend fun downloadAndInstall() {
        val result = withContext(Dispatchers.IO) {
            runCatching {
                val directory = File(context.filesDir, APK_DIRECTORY).apply { mkdirs() }
                val apk = File(directory, APK_NAME)
                val connection = URL(APK_URL).openConnection() as HttpURLConnection
                connection.requestMethod = "GET"
                connection.connectTimeout = 15_000
                connection.readTimeout = 30_000
                try {
                    if (connection.responseCode !in 200..299) {
                        throw IllegalStateException("Download failed: ${connection.responseCode}")
                    }
                    connection.inputStream.use { input ->
                        apk.outputStream().use { output -> input.copyTo(output) }
                    }
                } finally {
                    connection.disconnect()
                }
                apk
            }
        }
        result.fold(
            onSuccess = { apk -> promptInstall(apk) },
            onFailure = { error ->
                Toast.makeText(context, "Update failed: ${error.message}", Toast.LENGTH_LONG).show()
            }
        )
    }

    private fun promptInstall(apk: File) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !context.packageManager.canRequestPackageInstalls()
        ) {
            val settingsIntent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:${context.packageName}")
            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(settingsIntent)
            return
        }
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", apk)
        val installIntent = Intent(Intent.ACTION_INSTALL_PACKAGE).apply {
            setDataAndType(uri, APK_MIME_TYPE)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        context.startActivity(installIntent)
    }

    private companion object {
        const val APK_URL = "https://github.com/raoris/ramun/releases/latest/download/app-release.apk"
        const val APK_DIRECTORY = "apks"
        const val APK_NAME = "ramun-update.apk"
        const val APK_MIME_TYPE = "application/vnd.android.package-archive"
    }
}
