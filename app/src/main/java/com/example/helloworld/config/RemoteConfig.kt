package com.example.helloworld.config

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class RemoteConfig(
    val schemaVersion: Int,
    val minimumAppVersion: Int = 1,
    val theme: ThemeConfig,
    val features: Map<String, Boolean> = emptyMap(),
    val branding: BrandingConfig? = null,
    val header: HeaderConfig? = null,
    val banner: BannerConfig? = null,
    val grid: GridConfig? = null,
    val bottomNavigation: BottomNavConfig? = null,
    val screens: List<ScreenConfig> = emptyList(),
    val components: List<UiComponent> = emptyList()
) {
    val activePalette: Palette
        get() = if (theme.mode.equals("dark", ignoreCase = true)) theme.dark else theme.light
}

@Serializable
data class ThemeConfig(
    val mode: String = "light",
    val light: Palette,
    val dark: Palette
)

@Serializable
data class Palette(
    val background: String,
    val surface: String,
    val text: String,
    val accent: String,
    val primary: String = accent,
    val secondary: String = accent,
    val accentAlt: String = accent,
    val border: String = "#DCE5E5",
    val muted: String = "#90A4AE",
    val onPrimary: String = "#FFFFFF"
)

@Serializable
data class BrandingConfig(
    val appName: String = "Alsefa Physiotherapy Center",
    val brand: String = "ALSEFA",
    val subtitle: String = "Physiotherapy & Rehabilitation Center"
)

@Serializable
data class HeaderConfig(
    val id: String = "header",
    val brand: String = "ALSEFA",
    val title: String = "Alsefa Physiotherapy Center",
    val subtitle: String = "Physiotherapy & Rehabilitation Center",
    val logo: String = "ic_alsefa_logo",
    val showNotification: Boolean = true,
    val notificationAction: String = "notifications",
    val heightDp: Int = 48
)

@Serializable
data class BannerConfig(
    val id: String = "banner",
    val title: String,
    val headline: String,
    val body: String,
    val image: String = "ic_banner_physio",
    val action: String? = null,
    val heightDp: Int = 140,
    val cornerRadiusDp: Int = 8,
    val backgroundColor: String = "#E4F4F1"
)

@Serializable
data class GridItemConfig(
    val id: String,
    val label: String,
    val icon: String,
    val action: String,
    val visible: Boolean = true
)

@Serializable
data class GridConfig(
    val id: String = "dashboard",
    val columns: Int = 3,
    val spacingDp: Int = 8,
    val cornerRadiusDp: Int = 8,
    val items: List<GridItemConfig> = emptyList()
)

@Serializable
data class NavItemConfig(
    val id: String,
    val label: String,
    val icon: String,
    val action: String,
    val visible: Boolean = true
)

@Serializable
data class BottomNavConfig(
    val id: String = "bottom_nav",
    val heightDp: Int = 56,
    val items: List<NavItemConfig> = emptyList()
)

@Serializable
data class ActionConfig(
    val label: String,
    val action: String,
    val style: String = "primary"
)

@Serializable
data class ScreenConfig(
    val id: String,
    val title: String,
    val message: String,
    val icon: String? = null,
    val actions: List<ActionConfig> = emptyList()
)

@Serializable
sealed class UiComponent {
    abstract val id: String
    abstract val feature: String?

    @Serializable
    @SerialName("text")
    data class Text(
        override val id: String,
        val value: String,
        val style: String = "body",
        override val feature: String? = null
    ) : UiComponent()

    @Serializable
    @SerialName("button")
    data class Button(
        override val id: String,
        val label: String,
        val action: String,
        val style: String = "primary",
        override val feature: String? = null
    ) : UiComponent()

    @Serializable
    @SerialName("card")
    data class Card(
        override val id: String,
        val title: String,
        val body: String,
        override val feature: String? = null
    ) : UiComponent()

    @Serializable
    @SerialName("spacer")
    data class Spacer(
        override val id: String,
        val heightDp: Int = 16,
        override val feature: String? = null
    ) : UiComponent()
}
