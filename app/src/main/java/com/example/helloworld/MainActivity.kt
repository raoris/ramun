package com.example.helloworld

import android.graphics.Color
import android.os.Bundle
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import com.example.helloworld.config.RemoteConfig
import com.example.helloworld.patient.PatientStore
import com.example.helloworld.patient.PatientViews
import com.example.helloworld.ui.ConfigRenderer
import com.example.helloworld.ui.MainViewModel
import com.example.helloworld.update.AppUpdater
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity(), ConfigRenderer.Callbacks {
    private lateinit var viewModel: MainViewModel
    private lateinit var renderer: ConfigRenderer
    private lateinit var root: FrameLayout
    private val patientViews by lazy { PatientViews(this, PatientStore(this)) }
    private var config: RemoteConfig? = null
    private var currentScreen: String = HOME_SCREEN

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel = ViewModelProvider(this)[MainViewModel::class.java]
        renderer = ConfigRenderer()
        root = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        setContentView(root)
        applySystemBars(Color.parseColor("#078F91"))

        viewModel.state.observe(this) { result ->
            config = result.config
            applySystemBars(parseColor(result.config.activePalette.primary, Color.parseColor("#078F91")))
            renderCurrent()
        }
        viewModel.load(forceRefresh = true)
    }

    private fun applySystemBars(primary: Int) {
        window.statusBarColor = primary
        window.navigationBarColor = Color.WHITE
        WindowCompat.getInsetsController(window, window.decorView)?.apply {
            isAppearanceLightStatusBars = false
            isAppearanceLightNavigationBars = true
        }
    }

    private fun parseColor(value: String, fallback: Int): Int = try {
        Color.parseColor(value)
    } catch (e: IllegalArgumentException) {
        fallback
    }

    private fun renderCurrent() {
        val active = config ?: return
        if (currentScreen == HOME_SCREEN) {
            renderer.renderHome(root, active, HOME_SCREEN, this)
        } else if (currentScreen == "patient_registration") {
            val content = patientViews.registration(active.activePalette) {
                showScreen("patients")
            }
            renderer.renderScreenWithContent(root, active, currentScreen, "Patient Registration", content, this)
        } else if (currentScreen == "patients") {
            val content = patientViews.list(active.activePalette) {
                showScreen("patient_registration")
            }
            renderer.renderScreenWithContent(root, active, currentScreen, "Patients", content, this)
        } else {
            renderer.renderScreen(root, active, currentScreen, this)
        }
    }

    override fun onAction(action: String) {
        when (action) {
            "refresh" -> viewModel.load(forceRefresh = true)
            "update_app" -> lifecycleScope.launch {
                AppUpdater(this@MainActivity).downloadAndInstall()
            }
            "notifications" -> showScreen("notifications")
            else -> showScreen(action)
        }
    }

    override fun onNavigate(screenId: String) {
        if (screenId == HOME_SCREEN) {
            currentScreen = HOME_SCREEN
            renderCurrent()
        } else {
            showScreen(screenId)
        }
    }

    private fun showScreen(screenId: String) {
        currentScreen = screenId
        renderCurrent()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (currentScreen != HOME_SCREEN) {
            onNavigate(HOME_SCREEN)
        } else {
            @Suppress("DEPRECATION")
            super.onBackPressed()
        }
    }

    private companion object {
        const val HOME_SCREEN = "home"
    }
}
