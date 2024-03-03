package com.example.firebase

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import com.clevertap.android.sdk.CleverTapAPI

import android.content.Intent
import android.os.Build

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        CleverTapAPI.setDebugLevel(CleverTapAPI.LogLevel.VERBOSE)
        super.onCreate(savedInstanceState)
    }
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)

        // On Android 12 and above, inform the notification click to get the pushClickedPayloadReceived callback on dart side.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val cleverTapDefaultInstance: CleverTapAPI? = CleverTapAPI.getDefaultInstance(this)
            if(cleverTapDefaultInstance!=null){
                print("main activity.kt")

                cleverTapDefaultInstance?.pushNotificationClickedEvent(intent!!.extras)
            }

        }
    }
}
