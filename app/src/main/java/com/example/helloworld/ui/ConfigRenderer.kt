package com.example.helloworld.ui

import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import com.example.helloworld.config.Palette
import com.example.helloworld.config.RemoteConfig
import com.example.helloworld.config.UiComponent

class ConfigRenderer(private val settings: SettingsStore) {
    fun render(container: ViewGroup, config: RemoteConfig, onAction: (String) -> Unit) {
        container.removeAllViews()
        val palette = if (settings.darkTheme) config.theme.dark else config.theme.light
        container.setBackgroundColor(color(palette.background, Color.WHITE))

        val scroll = ScrollView(container.context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setFillViewport(true)
        }

        val content = LinearLayout(container.context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            val padding = dp(this, 24)
            setPadding(padding, dp(this, 48), padding, dp(this, 32))
        }

        config.components
            .filter { it.feature == null || config.features[it.feature] == true }
            .forEach { component ->
                content.addView(
                    when (component) {
                        is UiComponent.Text -> text(content, component.value, component.style, palette)
                        is UiComponent.Button -> actionButton(content, component, palette, onAction)
                        is UiComponent.Card -> card(content, component, palette)
                        is UiComponent.Spacer -> View(content.context).apply {
                            layoutParams = LinearLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                dp(this, component.heightDp)
                            )
                        }
                    }
                )
            }

        scroll.addView(content)
        container.addView(scroll)
    }

    private fun text(parent: ViewGroup, value: String, style: String, palette: Palette): TextView {
        val size = when (style) {
            "title" -> 28f
            "caption" -> 13f
            else -> 16f
        }
        return TextView(parent.context).apply {
            text = value
            textSize = size
            setTextColor(color(palette.text, Color.BLACK))
            if (style == "title") {
                setTypeface(typeface, Typeface.BOLD)
            }
            if (style == "caption") {
                alpha = 0.7f
            }
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
    }

    private fun actionButton(
        parent: ViewGroup,
        component: UiComponent.Button,
        palette: Palette,
        onAction: (String) -> Unit
    ): Button {
        val primary = component.style != "secondary"
        val background = if (primary) {
            color(palette.accent, Color.BLUE)
        } else {
            color(palette.surface, Color.WHITE)
        }
        val foreground = if (primary) {
            Color.WHITE
        } else {
            color(palette.accent, Color.BLUE)
        }
        val margin = dp(parent, 6)
        return Button(parent.context).apply {
            text = component.label
            isAllCaps = false
            setTextColor(foreground)
            background = rounded(background, dp(this, 12))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = margin
                bottomMargin = margin
            }
            setOnClickListener { onAction(component.action) }
        }
    }

    private fun card(parent: ViewGroup, component: UiComponent.Card, palette: Palette): TextView {
        val padding = dp(parent, 16)
        return TextView(parent.context).apply {
            text = "${component.title}\n\n${component.body}"
            textSize = 16f
            setTextColor(color(palette.text, Color.BLACK))
            background = rounded(color(palette.surface, Color.WHITE), dp(this, 16))
            setPadding(padding, padding, padding, padding)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
    }

    private fun rounded(fill: Int, radius: Int): GradientDrawable = GradientDrawable().apply {
        setColor(fill)
        cornerRadius = radius.toFloat()
    }

    private fun color(value: String, fallback: Int): Int = try {
        Color.parseColor(value)
    } catch (e: IllegalArgumentException) {
        fallback
    }

    private fun dp(view: View, value: Int): Int = (value * view.resources.displayMetrics.density).toInt()
}
