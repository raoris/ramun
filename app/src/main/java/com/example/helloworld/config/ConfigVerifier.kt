package com.example.helloworld.config

import android.util.Base64
import java.security.KeyFactory
import java.security.Signature
import java.security.spec.X509EncodedKeySpec

object ConfigVerifier {
    private const val PUBLIC_KEY_BASE64 = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA7YSgJtCM10wGraoZOgIdYorPxjoSItEzWL5I1P4+qIKmh+0ceJqilxEPMzBxIiC+Zg+piX7VJRvgytMkYs2O0mUJdTFXG/AtDJk2HeY4q/YXlmdEuSMH4HYgsJG2zaCeFLXxJ6dWqlx79V9H6qF5K8dgUUVsQs4Rqyb2ujjGz5oaMfoXzBTGbJ56K97G1K6NrFzuaK58PzxNA2Za/OO6rSQXr7TmQGSibE+XMIoaSq/PX16jjTe9Pg7gnvTaZILLQEJNm8I4U/pVdkyNKg2zYA2dMZUp4ba4nSPMDFZ6YU7gdpXoKQPdoZH8m5OfwllDXSjEVWHX17cIvufeBdiFSQIDAQAB"

    fun verify(payload: String, signatureBase64: String): Boolean {
        return try {
            val key = KeyFactory.getInstance("RSA")
                .generatePublic(X509EncodedKeySpec(Base64.decode(PUBLIC_KEY_BASE64, Base64.DEFAULT)))
            val signature = Signature.getInstance("SHA256withRSA")
            signature.initVerify(key)
            signature.update(payload.toByteArray(Charsets.UTF_8))
            signature.verify(Base64.decode(signatureBase64.trim(), Base64.DEFAULT))
        } catch (e: Exception) {
            false
        }
    }
}
