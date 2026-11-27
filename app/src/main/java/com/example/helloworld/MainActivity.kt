package com.example.helloworld

import android.graphics.Color
import android.os.Bundle
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.WindowInsetsControllerCompat
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.lifecycleScope
import com.example.helloworld.ui.ConfigRenderer
import com.example.helloworld.ui.DraggableMenuGrid
import com.example.helloworld.ui.MainViewModel
import com.example.helloworld.update.AppUpdater
import kotlinx.coroutines.launch

class MainActivity : AppCompatActivity() {
    private lateinit var viewModel: MainViewModel
    private lateinit var renderer: ConfigRenderer
    private lateinit var root: FrameLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.BLACK
        window.navigationBarColor = Color.BLACK
        WindowCompat.getInsetsController(window, window.decorView)?.apply {
            hide(WindowInsetsCompat.Type.systemBars())
            systemBarsBehavior = WindowInsetsControllerCompat.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
        }
        viewModel = ViewModelProvider(this)[MainViewModel::class.java]
        renderer = ConfigRenderer()
        val content = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        root = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        val overlay = FrameLayout(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        content.addView(root)
        content.addView(overlay)
        setContentView(content)
        overlay.addView(DraggableMenuGrid(this))

        viewModel.state.observe(this) { result ->
            renderer.render(root, result.config, ::handleAction)
        }
        viewModel.load(forceRefresh = true)
    }

    private fun handleAction(action: String) {
        when (action) {
            "refresh" -> viewModel.load(forceRefresh = true)
            "update_app" -> lifecycleScope.launch {
                AppUpdater(this@MainActivity).downloadAndInstall()
            }
        }
    }
}
