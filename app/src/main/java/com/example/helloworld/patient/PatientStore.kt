package com.example.helloworld.patient

import android.content.Context
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Serializable
data class Patient(
    val id: Long,
    val name: String,
    val age: Int,
    val bloodPressure: String,
    val address: String,
    val phone: String,
    val weightKg: Double,
    val recordedAt: String
)

class PatientStore(context: Context) {
    private val preferences = context.applicationContext
        .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    private val json = Json { ignoreUnknownKeys = true }

    fun all(): List<Patient> {
        val stored = preferences.getString(KEY_PATIENTS, null) ?: return emptyList()
        return try {
            json.decodeFromString<List<Patient>>(stored)
        } catch (e: Exception) {
            emptyList()
        }
    }

    fun add(patient: Patient) {
        val updated = all() + patient
        preferences.edit().putString(KEY_PATIENTS, json.encodeToString(updated)).apply()
    }

    private companion object {
        const val PREFS_NAME = "alsefa_patients"
        const val KEY_PATIENTS = "patients"
    }
}
