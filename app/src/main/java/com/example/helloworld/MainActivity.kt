package com.example.helloworld

import android.os.Bundle
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.ViewModelProvider
import com.example.helloworld.config.ConfigResult
import com.example.helloworld.ui.ConfigRenderer
import com.example.helloworld.ui.MainViewModel

class MainActivity : AppCompatActivity() {
    private lateinit var viewModel: MainViewModel
    private lateinit var renderer: ConfigRenderer
    private lateinit var root: FrameLayout
    private var current: ConfigResult? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        viewModel = ViewModelProvider(this)[MainViewModel::class.java]
        renderer = ConfigRenderer(viewModel.settings)
        root = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        setContentView(root)

        viewModel.state.observe(this) { result ->
            current = result
            renderer.render(root, result.config, ::handleAction)
        }
        viewModel.load(forceRefresh = true)
    }

    private fun handleAction(action: String) {
        when (action) {
            "refresh" -> viewModel.load(forceRefresh = true)
            "toggle_theme" -> {
                viewModel.settings.toggleDarkTheme()
                current?.let { renderer.render(root, it.config, ::handleAction) }
            }
        }
    }
}
