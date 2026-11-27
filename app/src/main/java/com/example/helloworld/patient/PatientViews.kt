package com.example.helloworld.patient

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import com.example.helloworld.config.Palette
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class PatientViews(private val context: Context, private val store: PatientStore) {
    private var inputTextColor: Int = Color.parseColor("#263238")
    private var inputSurface: Int = Color.WHITE
    private var inputBorder: Int = Color.parseColor("#DCE5E5")

    fun registration(palette: Palette, onSaved: () -> Unit): View {
        val primary = color(palette.primary, Color.parseColor("#078F91"))
        val surface = color(palette.surface, Color.WHITE)
        val border = color(palette.border, Color.parseColor("#DCE5E5"))
        val textColor = color(palette.text, Color.parseColor("#263238"))
        val muted = color(palette.muted, Color.parseColor("#78909C"))
        inputTextColor = textColor
        inputSurface = surface
        inputBorder = border

        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            setPadding(dp(20), dp(20), dp(20), dp(24))
        }

        content.addView(
            TextView(context).apply {
                text = "New Patient Registration"
                textSize = 18f
                setTextColor(primary)
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
            }
        )
        content.addView(
            TextView(context).apply {
                text = "Please enter the patient details below."
                textSize = 12f
                setTextColor(muted)
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = dp(4) }
            }
        )

        val name = inputField("Full name", InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_WORDS)
        val age = inputField("Age", InputType.TYPE_CLASS_NUMBER)
        val bloodPressure = inputField("Blood pressure (e.g. 120/80)", InputType.TYPE_CLASS_TEXT)
        val address = inputField("Address", InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_FLAG_CAP_SENTENCES)
        val phone = inputField("Phone number", InputType.TYPE_CLASS_PHONE)
        val weight = inputField("Weight in kg (e.g. 68.5)", InputType.TYPE_CLASS_NUMBER or InputType.TYPE_NUMBER_FLAG_DECIMAL)

        listOf(name, age, bloodPressure, address, phone, weight).forEach { field ->
            content.addView(
                field.apply {
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    ).apply { topMargin = dp(12) }
                }
            )
        }

        content.addView(
            LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                background = rounded(surface, border, 8)
                setPadding(dp(12), dp(12), dp(12), dp(12))
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = dp(12) }
                addView(
                    TextView(context).apply {
                        text = "Date & time (automatic)"
                        textSize = 11f
                        setTextColor(muted)
                        layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
                    }
                )
                addView(
                    TextView(context).apply {
                        text = timestamp()
                        textSize = 12f
                        setTextColor(textColor)
                        gravity = Gravity.END
                        layoutParams = LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT
                        )
                    }
                )
            }
        )

        content.addView(
            Button(context).apply {
                text = "Save patient"
                isAllCaps = false
                background = rounded(primary, primary, 8)
                setTextColor(Color.WHITE)
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = dp(20) }
                setOnClickListener {
                    val patientName = name.text.toString().trim()
                    val patientAge = age.text.toString().trim().toIntOrNull()
                    val pressure = bloodPressure.text.toString().trim()
                    val patientAddress = address.text.toString().trim()
                    val patientPhone = phone.text.toString().trim()
                    val patientWeight = weight.text.toString().trim().toDoubleOrNull()

                    if (patientName.isEmpty()) {
                        name.error = "Name is required"
                        return@setOnClickListener
                    }
                    if (patientAge == null || patientAge !in 1..120) {
                        age.error = "Enter a valid age"
                        return@setOnClickListener
                    }
                    if (pressure.isEmpty()) {
                        bloodPressure.error = "Blood pressure is required"
                        return@setOnClickListener
                    }
                    if (patientAddress.isEmpty()) {
                        address.error = "Address is required"
                        return@setOnClickListener
                    }
                    if (patientPhone.length < 7) {
                        phone.error = "Enter a valid phone number"
                        return@setOnClickListener
                    }
                    if (patientWeight == null || patientWeight <= 0.0) {
                        weight.error = "Enter a valid weight"
                        return@setOnClickListener
                    }

                    store.add(
                        Patient(
                            id = System.currentTimeMillis(),
                            name = patientName,
                            age = patientAge,
                            bloodPressure = pressure,
                            address = patientAddress,
                            phone = patientPhone,
                            weightKg = patientWeight,
                            recordedAt = timestamp()
                        )
                    )
                    Toast.makeText(context, "Patient registered", Toast.LENGTH_SHORT).show()
                    onSaved()
                }
            }
        )
        return content
    }

    fun list(palette: Palette, onRegister: () -> Unit): View {
        val primary = color(palette.primary, Color.parseColor("#078F91"))
        val surface = color(palette.surface, Color.WHITE)
        val border = color(palette.border, Color.parseColor("#DCE5E5"))
        val textColor = color(palette.text, Color.parseColor("#263238"))
        val muted = color(palette.muted, Color.parseColor("#78909C"))

        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            setPadding(dp(20), dp(20), dp(20), dp(24))
        }
        content.addView(
            TextView(context).apply {
                text = "Registered Patients"
                textSize = 18f
                setTextColor(primary)
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
            }
        )

        val patients = store.all().sortedByDescending { it.id }
        if (patients.isEmpty()) {
            content.addView(
                TextView(context).apply {
                    text = "No patients registered yet. Add the first patient to see them here."
                    textSize = 13f
                    setTextColor(muted)
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    ).apply { topMargin = dp(16) }
                }
            )
        } else {
            patients.forEach { patient ->
                content.addView(
                    TextView(context).apply {
                        text = "${patient.name}  •  ${patient.age} yrs\n" +
                            "BP: ${patient.bloodPressure}  •  Weight: ${patient.weightKg} kg\n" +
                            "Phone: ${patient.phone}\n" +
                            "Address: ${patient.address}\n" +
                            "Recorded: ${patient.recordedAt}"
                        textSize = 12f
                        setTextColor(textColor)
                        background = rounded(surface, border, 8)
                        setPadding(dp(12), dp(12), dp(12), dp(12))
                        layoutParams = LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT
                        ).apply { topMargin = dp(12) }
                    }
                )
            }
        }

        content.addView(
            Button(context).apply {
                text = "Register new patient"
                isAllCaps = false
                background = rounded(primary, primary, 8)
                setTextColor(Color.WHITE)
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply { topMargin = dp(20) }
                setOnClickListener { onRegister() }
            }
        )
        return content
    }

    private fun inputField(hint: String, inputType: Int): EditText = EditText(context).apply {
        this.hint = hint
        this.inputType = inputType
        setTextColor(inputTextColor)
        background = rounded(inputSurface, inputBorder, 8)
        setPadding(dp(12), dp(12), dp(12), dp(12))
        setSingleLine(true)
    }

    private fun timestamp(): String =
        SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault()).format(Date())

    private fun rounded(fill: Int, stroke: Int, radiusDp: Int): GradientDrawable =
        GradientDrawable().apply {
            setColor(fill)
            setStroke(dp(1), stroke)
            cornerRadius = dp(radiusDp).toFloat()
        }

    private fun color(value: String, fallback: Int): Int = try {
        Color.parseColor(value)
    } catch (e: IllegalArgumentException) {
        fallback
    }

    private fun dp(value: Int): Int = (value * context.resources.displayMetrics.density).toInt()
}
