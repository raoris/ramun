package com.example.helloworld.config

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class RemoteConfig(
    val schemaVersion: Int,
    val minimumAppVersion: Int = 1,
    val theme: ThemeConfig,
    val features: Map<String, Boolean> = emptyMap(),
    val components: List<UiComponent>
)

@Serializable
data class ThemeConfig(
    val light: Palette,
    val dark: Palette
)

@Serializable
data class Palette(
    val background: String,
    val surface: String,
    val text: String,
    val accent: String
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
