package com.example.helloworld.ui

import android.content.Context
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.example.helloworld.R
import com.example.helloworld.config.ActionConfig
import com.example.helloworld.config.BannerConfig
import com.example.helloworld.config.BottomNavConfig
import com.example.helloworld.config.GridConfig
import com.example.helloworld.config.HeaderConfig
import com.example.helloworld.config.NavItemConfig
import com.example.helloworld.config.Palette
import com.example.helloworld.config.RemoteConfig
import com.example.helloworld.config.ScreenConfig
import com.example.helloworld.config.UiComponent

class ConfigRenderer {

    interface Callbacks {
        fun onAction(action: String)
        fun onNavigate(screenId: String)
    }

    fun renderHome(
        container: ViewGroup,
        config: RemoteConfig,
        activeScreen: String?,
        callbacks: Callbacks
    ) {
        if (config.header == null && config.banner == null && config.grid == null) {
            renderLegacy(container, config, callbacks)
            return
        }
        container.removeAllViews()
        val context = container.context
        val palette = config.activePalette
        container.setBackgroundColor(color(palette.background, Color.WHITE))

        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = matchParent()
        }
        config.header?.let { root.addView(headerView(context, it, palette, callbacks)) }

        val scroll = ScrollView(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
            setFillViewport(true)
        }
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        config.banner?.let { content.addView(bannerView(context, it, palette, callbacks)) }
        config.grid?.let { content.addView(gridView(context, it, palette, callbacks)) }
        scroll.addView(content)
        root.addView(scroll)
        config.bottomNavigation?.let {
            root.addView(navigationView(context, it, palette, activeScreen, callbacks))
        }
        container.addView(root)
    }

    fun renderScreen(
        container: ViewGroup,
        config: RemoteConfig,
        screenId: String,
        callbacks: Callbacks
    ) {
        container.removeAllViews()
        val context = container.context
        val palette = config.activePalette
        container.setBackgroundColor(color(palette.background, Color.WHITE))
        val screen = config.screens.firstOrNull { it.id == screenId }
            ?: ScreenConfig(
                id = screenId,
                title = screenId.replace('_', ' ').replaceFirstChar { it.uppercase() },
                message = "This feature will be available soon. Please check back for updates."
            )

        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = matchParent()
        }
        root.addView(screenTopBar(context, screen, palette, callbacks))

        val scroll = ScrollView(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
            setFillViewport(true)
        }
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            setPadding(dp(context, 24), dp(context, 32), dp(context, 24), dp(context, 24))
        }
        content.addView(
            ImageView(context).apply {
                setImageResource(drawableFor(context, screen.icon ?: "ic_placeholder"))
                setColorFilter(color(palette.primary, Color.parseColor("#078F91")), PorterDuff.Mode.SRC_IN)
                layoutParams = LinearLayout.LayoutParams(dp(context, 56), dp(context, 56))
            }
        )
        content.addView(
            TextView(context).apply {
                text = screen.title
                textSize = 20f
                setTypeface(typeface, Typeface.BOLD)
                setTextColor(color(palette.text, Color.parseColor("#263238")))
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = dp(context, 16) }
            }
        )
        content.addView(
            TextView(context).apply {
                text = screen.message
                textSize = 14f
                setTextColor(color(palette.muted, Color.parseColor("#607D8B")))
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = dp(context, 10) }
            }
        )
        screen.actions.forEach { content.addView(screenAction(context, it, palette, callbacks)) }
        scroll.addView(content)
        root.addView(scroll)
        config.bottomNavigation?.let {
            root.addView(navigationView(context, it, palette, screenId, callbacks))
        }
        container.addView(root)
    }

    fun renderLegacy(container: ViewGroup, config: RemoteConfig, callbacks: Callbacks) {
        container.removeAllViews()
        val context = container.context
        val palette = config.activePalette
        container.setBackgroundColor(color(palette.background, Color.WHITE))
        val scroll = ScrollView(context).apply {
            layoutParams = matchParent()
            setFillViewport(true)
        }
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            setPadding(dp(context, 24), dp(context, 48), dp(context, 24), dp(context, 24))
        }
        config.components
            .filter { it.feature == null || config.features[it.feature] == true }
            .filter { it !is UiComponent.Button || it.action != "toggle_theme" }
            .forEach { component ->
                content.addView(
                    when (component) {
                        is UiComponent.Text -> legacyText(context, component.value, component.style, palette)
                        is UiComponent.Button -> legacyButton(
                            context,
                            component.label,
                            component.action,
                            component.style,
                            palette,
                            callbacks
                        )
                        is UiComponent.Card -> legacyCard(context, component.title, component.body, palette)
                        is UiComponent.Spacer -> View(context).apply {
                            layoutParams = LinearLayout.LayoutParams(
                                ViewGroup.LayoutParams.MATCH_PARENT,
                                dp(context, component.heightDp)
                            )
                        }
                    }
                )
            }
        scroll.addView(content)
        container.addView(scroll)
    }

    private fun headerView(
        context: Context,
        header: HeaderConfig,
        palette: Palette,
        callbacks: Callbacks
    ): View {
        val primary = color(palette.primary, Color.parseColor("#078F91"))
        val onPrimary = color(palette.onPrimary, Color.WHITE)
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(primary)
            setPadding(dp(context, 12), dp(context, 8), dp(context, 12), dp(context, 8))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(context, header.heightDp)
            )
            addView(
                ImageView(context).apply {
                    setImageResource(drawableFor(context, header.logo))
                    setColorFilter(onPrimary, PorterDuff.Mode.SRC_IN)
                    layoutParams = LinearLayout.LayoutParams(dp(context, 24), dp(context, 24))
                }
            )
            val texts = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply { leftMargin = dp(context, 10) }
            }
            texts.addView(
                TextView(context).apply {
                    text = if (header.brand.isBlank()) header.title else header.brand
                    textSize = 16f
                    setTypeface(typeface, Typeface.BOLD)
                    setTextColor(onPrimary)
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    )
                }
            )
            texts.addView(
                TextView(context).apply {
                    text = header.subtitle
                    textSize = 10f
                    setTextColor(onPrimary)
                    alpha = 0.9f
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    )
                }
            )
            addView(texts)
            if (header.showNotification) {
                val bellContainer = FrameLayout(context).apply {
                    layoutParams = LinearLayout.LayoutParams(
                        dp(context, 24),
                        dp(context, 24)
                    ).apply { leftMargin = dp(context, 8) }
                }
                bellContainer.addView(
                    ImageView(context).apply {
                        setImageResource(drawableFor(context, "ic_notifications"))
                        setColorFilter(onPrimary, PorterDuff.Mode.SRC_IN)
                        background = selectableForeground(context)
                        isClickable = true
                        layoutParams = FrameLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                        )
                        setOnClickListener { callbacks.onAction(header.notificationAction) }
                    }
                )
                bellContainer.addView(
                    View(context).apply {
                        background = rounded(
                            context,
                            Color.parseColor("#FF5252"),
                            Color.parseColor("#FF5252"),
                            6
                        )
                        layoutParams = FrameLayout.LayoutParams(
                            dp(context, 8),
                            dp(context, 8)
                        ).apply { gravity = Gravity.TOP or Gravity.END }
                    }
                )
                addView(bellContainer)
            }
        }
    }

    private fun bannerView(
        context: Context,
        banner: BannerConfig,
        palette: Palette,
        callbacks: Callbacks
    ): View {
        val bannerBackground = color(banner.backgroundColor, Color.parseColor("#E4F4F1"))
        val border = color(palette.border, Color.parseColor("#DCE5E5"))
        val primary = color(palette.primary, Color.parseColor("#078F91"))
        val textColor = color(palette.text, Color.parseColor("#263238"))
        val muted = color(palette.muted, Color.parseColor("#607D8B"))
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            background = rounded(context, bannerBackground, border, banner.cornerRadiusDp)
            setPadding(dp(context, 12), dp(context, 10), dp(context, 8), dp(context, 10))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(context, banner.heightDp)
            ).apply {
                leftMargin = dp(context, 8)
                rightMargin = dp(context, 8)
                topMargin = dp(context, 8)
            }
            if (!banner.action.isNullOrBlank()) {
                isClickable = true
                foreground = selectableForeground(context)
                setOnClickListener { callbacks.onAction(banner.action) }
            }
            val texts = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            }
            texts.addView(
                TextView(context).apply {
                    text = banner.title
                    textSize = 11f
                    setTypeface(typeface, Typeface.BOLD)
                    setTextColor(primary)
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    )
                }
            )
            texts.addView(
                TextView(context).apply {
                    text = banner.headline
                    textSize = 15f
                    setTypeface(typeface, Typeface.BOLD)
                    setTextColor(textColor)
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    ).apply { topMargin = dp(context, 6) }
                }
            )
            texts.addView(
                TextView(context).apply {
                    text = banner.body
                    textSize = 10f
                    setTextColor(muted)
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    ).apply { topMargin = dp(context, 6) }
                }
            )
            addView(texts)
            addView(
                ImageView(context).apply {
                    setImageResource(drawableFor(context, banner.image))
                    scaleType = ImageView.ScaleType.FIT_CENTER
                    layoutParams = LinearLayout.LayoutParams(
                        dp(context, 88),
                        ViewGroup.LayoutParams.MATCH_PARENT
                    ).apply { leftMargin = dp(context, 4) }
                }
            )
        }
    }

    private fun gridView(
        context: Context,
        grid: GridConfig,
        palette: Palette,
        callbacks: Callbacks
    ): View {
        val surface = color(palette.surface, Color.WHITE)
        val border = color(palette.border, Color.parseColor("#DCE5E5"))
        val primary = color(palette.primary, Color.parseColor("#078F91"))
        val textColor = color(palette.text, Color.parseColor("#263238"))
        val spacing = dp(context, grid.spacingDp)
        val columns = if (grid.columns > 0) grid.columns else 3
        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                leftMargin = dp(context, 8)
                rightMargin = dp(context, 8)
                topMargin = dp(context, 4)
            }
        }
        grid.items.filter { it.visible }.chunked(columns).forEach { rowItems ->
            val row = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    dp(context, 96)
                )
            }
            rowItems.forEach { item ->
                val cell = LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    gravity = Gravity.CENTER
                    background = rounded(context, surface, border, grid.cornerRadiusDp)
                    setPadding(dp(context, 4), dp(context, 8), dp(context, 4), dp(context, 6))
                    isClickable = true
                    foreground = selectableForeground(context)
                    layoutParams = LinearLayout.LayoutParams(
                        0,
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        1f
                    ).apply {
                        leftMargin = spacing / 2
                        rightMargin = spacing / 2
                        topMargin = spacing / 2
                        bottomMargin = spacing / 2
                    }
                    setOnClickListener { callbacks.onAction(item.action) }
                }
                cell.addView(
                    ImageView(context).apply {
                        setImageResource(drawableFor(context, item.icon))
                        setColorFilter(primary, PorterDuff.Mode.SRC_IN)
                        layoutParams = LinearLayout.LayoutParams(dp(context, 32), dp(context, 32))
                    }
                )
                cell.addView(
                    TextView(context).apply {
                        text = item.label
                        textSize = 11f
                        setTextColor(textColor)
                        gravity = Gravity.CENTER
                        layoutParams = LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT
                        ).apply { topMargin = dp(context, 6) }
                    }
                )
                row.addView(cell)
            }
            root.addView(row)
        }
        return root
    }

    private fun navigationView(
        context: Context,
        nav: BottomNavConfig,
        palette: Palette,
        activeScreen: String?,
        callbacks: Callbacks
    ): View {
        val surface = color(palette.surface, Color.WHITE)
        val border = color(palette.border, Color.parseColor("#DCE5E5"))
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            addView(
                View(context).apply {
                    setBackgroundColor(border)
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        dp(context, 1)
                    )
                }
            )
            val row = LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                setBackgroundColor(surface)
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    dp(context, nav.heightDp)
                )
            }
            nav.items.filter { it.visible }.forEach { item ->
                row.addView(navItem(context, item, palette, item.id == activeScreen, callbacks))
            }
            addView(row)
        }
    }

    private fun navItem(
        context: Context,
        item: NavItemConfig,
        palette: Palette,
        active: Boolean,
        callbacks: Callbacks
    ): View {
        val tint = if (active) {
            color(palette.primary, Color.parseColor("#078F91"))
        } else {
            color(palette.muted, Color.parseColor("#90A4AE"))
        }
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            isClickable = true
            foreground = selectableForeground(context)
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f)
            addView(
                ImageView(context).apply {
                    setImageResource(drawableFor(context, item.icon))
                    setColorFilter(tint, PorterDuff.Mode.SRC_IN)
                    layoutParams = LinearLayout.LayoutParams(dp(context, 22), dp(context, 22))
                }
            )
            addView(
                TextView(context).apply {
                    text = item.label
                    textSize = 10f
                    setTextColor(tint)
                    gravity = Gravity.CENTER
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    ).apply { topMargin = dp(context, 4) }
                }
            )
            setOnClickListener { callbacks.onNavigate(item.id) }
        }
    }

    private fun screenTopBar(
        context: Context,
        screen: ScreenConfig,
        palette: Palette,
        callbacks: Callbacks
    ): View {
        val primary = color(palette.primary, Color.parseColor("#078F91"))
        val onPrimary = color(palette.onPrimary, Color.WHITE)
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setBackgroundColor(primary)
            setPadding(dp(context, 12), dp(context, 8), dp(context, 12), dp(context, 8))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(context, 56)
            )
            addView(
                ImageView(context).apply {
                    setImageResource(R.drawable.ic_back)
                    setColorFilter(onPrimary, PorterDuff.Mode.SRC_IN)
                    background = selectableForeground(context)
                    isClickable = true
                    layoutParams = LinearLayout.LayoutParams(dp(context, 24), dp(context, 24))
                    setOnClickListener { callbacks.onNavigate("home") }
                }
            )
            addView(
                TextView(context).apply {
                    text = screen.title
                    textSize = 16f
                    setTypeface(typeface, Typeface.BOLD)
                    setTextColor(onPrimary)
                    layoutParams = LinearLayout.LayoutParams(
                        0,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                        1f
                    ).apply { leftMargin = dp(context, 12) }
                }
            )
        }
    }

    private fun screenAction(
        context: Context,
        action: ActionConfig,
        palette: Palette,
        callbacks: Callbacks
    ): Button {
        val primary = color(palette.primary, Color.parseColor("#078F91"))
        val surface = color(palette.surface, Color.WHITE)
        val border = color(palette.border, Color.parseColor("#DCE5E5"))
        val onPrimary = color(palette.onPrimary, Color.WHITE)
        val isPrimary = action.style != "secondary"
        return Button(context).apply {
            text = action.label
            isAllCaps = false
            background = rounded(context, if (isPrimary) primary else surface, if (isPrimary) primary else border, 8)
            setTextColor(if (isPrimary) onPrimary else primary)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = dp(context, 10) }
            setOnClickListener { callbacks.onAction(action.action) }
        }
    }

    private fun legacyText(
        context: Context,
        value: String,
        style: String,
        palette: Palette
    ): TextView {
        val size = when (style) {
            "title" -> 28f
            "caption" -> 13f
            else -> 16f
        }
        return TextView(context).apply {
            text = value
            textSize = size
            setTextColor(color(palette.text, Color.parseColor("#263238")))
            if (style == "title") setTypeface(typeface, Typeface.BOLD)
            if (style == "caption") alpha = 0.7f
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
    }

    private fun legacyButton(
        context: Context,
        label: String,
        action: String,
        style: String,
        palette: Palette,
        callbacks: Callbacks
    ): Button {
        val primary = color(palette.primary, Color.parseColor("#078F91"))
        val surface = color(palette.surface, Color.WHITE)
        val onPrimary = color(palette.onPrimary, Color.WHITE)
        val isPrimary = style != "secondary"
        return Button(context).apply {
            text = label
            isAllCaps = false
            background = rounded(context, if (isPrimary) primary else surface, if (isPrimary) primary else primary, 12)
            setTextColor(if (isPrimary) onPrimary else primary)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dp(context, 6)
                bottomMargin = dp(context, 6)
            }
            setOnClickListener { callbacks.onAction(action) }
        }
    }

    private fun legacyCard(
        context: Context,
        title: String,
        body: String,
        palette: Palette
    ): TextView {
        val surface = color(palette.surface, Color.WHITE)
        val border = color(palette.border, Color.parseColor("#DCE5E5"))
        return TextView(context).apply {
            text = "$title\n\n$body"
            textSize = 16f
            setTextColor(color(palette.text, Color.parseColor("#263238")))
            background = rounded(context, surface, border, 16)
            setPadding(dp(context, 16), dp(context, 16), dp(context, 16), dp(context, 16))
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
    }

    private fun matchParent(): ViewGroup.LayoutParams = ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
    )

    private fun drawableFor(context: Context, name: String): Int {
        val identifier = context.resources.getIdentifier(name, "drawable", context.packageName)
        return if (identifier != 0) identifier else R.drawable.ic_placeholder
    }

    private fun selectableForeground(context: Context): Drawable? {
        val value = TypedValue()
        return if (context.theme.resolveAttribute(android.R.attr.selectableItemBackground, value, true)) {
            ContextCompat.getDrawable(context, value.resourceId)
        } else {
            null
        }
    }

    private fun rounded(
        context: Context,
        fill: Int,
        stroke: Int,
        radiusDp: Int
    ): GradientDrawable = GradientDrawable().apply {
        setColor(fill)
        setStroke(dp(context, 1), stroke)
        cornerRadius = dp(context, radiusDp).toFloat()
    }

    private fun color(value: String, fallback: Int): Int = try {
        Color.parseColor(value)
    } catch (e: IllegalArgumentException) {
        fallback
    }

    private fun dp(context: Context, value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()
}
