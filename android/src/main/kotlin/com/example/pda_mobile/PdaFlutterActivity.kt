package com.example.pda_mobile

import android.content.Context
import android.view.KeyEvent
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Activity that forwards the N60 keypad when no text field is focused.
open class PdaFlutterActivity : FlutterActivity() {
    private var imeEnabled = false
    private lateinit var keyboardGuardChannel: MethodChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        keyboardGuardChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            KEYBOARD_GUARD_CHANNEL,
        )
        keyboardGuardChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setImeEnabled" -> {
                    setImeEnabled(call.argument<Boolean>("enabled") == true)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        setImeEnabled(false)
    }

    private fun setImeEnabled(enabled: Boolean) {
        imeEnabled = enabled
        if (enabled) {
            window.clearFlags(WindowManager.LayoutParams.FLAG_ALT_FOCUSABLE_IM)
            return
        }
        currentFocus?.clearFocus()
        val inputMethodManager =
            getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
        inputMethodManager.hideSoftInputFromWindow(window.decorView.windowToken, 0)
        window.addFlags(WindowManager.LayoutParams.FLAG_ALT_FOCUSABLE_IM)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (!imeEnabled && event.device?.name == N60_KEYPAD_NAME) {
            if (event.action == KeyEvent.ACTION_DOWN) {
                keyboardGuardChannel.invokeMethod(
                    "onPhysicalKey",
                    mapOf(
                        "keyCode" to event.keyCode,
                        "unicodeChar" to event.unicodeChar,
                    ),
                )
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    private companion object {
        const val KEYBOARD_GUARD_CHANNEL = "pda_mobile/keyboard_guard"
        const val N60_KEYPAD_NAME = "sn7326"
    }
}
