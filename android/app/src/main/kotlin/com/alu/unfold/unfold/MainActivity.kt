package com.alu.unfold.unfold

import android.os.Bundle
import com.google.firebase.FirebaseApp
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val secret = BuildConfig.APP_CHECK_DEBUG_SECRET
        if (secret.isNotEmpty()) {
            val app = FirebaseApp.getInstance()
            val name = "com.google.firebase.appcheck.debug.store.${app.persistenceKey}"
            getSharedPreferences(name, MODE_PRIVATE).edit()
                .putString("com.google.firebase.appcheck.debug.DEBUG_SECRET", secret)
                .apply()
        }
        super.onCreate(savedInstanceState)
    }
}
