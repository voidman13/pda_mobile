package com.example.pda_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "pda_mobile/bld_scanner"
    private val eventChannelName = "pda_mobile/bld_scanner/events"
    private val resultAction = "scan.rcv.message"
    private val resultKey = "barcodeData"

    private var eventSink: EventChannel.EventSink? = null
    private var receiverRegistered = false

    private val scanReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != resultAction) return

            val value = intent.getStringExtra(resultKey)
                ?: intent.getByteArrayExtra(resultKey)?.toString(Charsets.UTF_8)
                ?: intent.getByteArrayExtra("barocode")?.toString(Charsets.UTF_8)

            if (!value.isNullOrBlank()) eventSink?.success(value)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            methodChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startScan" -> {
                    sendBroadcast(Intent("android.bld.scan.action.START_DECODE"))
                    result.success(null)
                }
                "stopScan" -> {
                    sendBroadcast(Intent("android.bld.scan.action.STOP_DECODE_IMT"))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            eventChannelName,
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
                registerScanReceiver()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                unregisterScanReceiver()
            }
        })
    }

    private fun registerScanReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter(resultAction)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(scanReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            registerReceiver(scanReceiver, filter)
        }
        receiverRegistered = true
    }

    private fun unregisterScanReceiver() {
        if (!receiverRegistered) return
        unregisterReceiver(scanReceiver)
        receiverRegistered = false
    }

    override fun onDestroy() {
        unregisterScanReceiver()
        super.onDestroy()
    }
}
