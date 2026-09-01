package com.example.pda_mobile

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PdaMobilePlugin : FlutterPlugin, MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler {
    private lateinit var context: Context
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var receiverRegistered = false

    private val scanReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.action != RESULT_ACTION) return
            val value = intent.getStringExtra(RESULT_KEY)
                ?: intent.getByteArrayExtra(RESULT_KEY)?.toString(Charsets.UTF_8)
                ?: intent.getByteArrayExtra("barocode")?.toString(Charsets.UTF_8)
            if (!value.isNullOrBlank()) eventSink?.success(value)
        }
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startScan" -> {
                context.sendBroadcast(Intent(START_ACTION))
                result.success(null)
            }
            "stopScan" -> {
                context.sendBroadcast(Intent(STOP_ACTION))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        registerReceiver()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        unregisterReceiver()
    }

    private fun registerReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter(RESULT_ACTION)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            context.registerReceiver(scanReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("DEPRECATION")
            context.registerReceiver(scanReceiver, filter)
        }
        receiverRegistered = true
    }

    private fun unregisterReceiver() {
        if (!receiverRegistered) return
        context.unregisterReceiver(scanReceiver)
        receiverRegistered = false
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        unregisterReceiver()
        eventSink = null
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private companion object {
        const val METHOD_CHANNEL = "pda_mobile/bld_scanner"
        const val EVENT_CHANNEL = "pda_mobile/bld_scanner/events"
        const val RESULT_ACTION = "scan.rcv.message"
        const val RESULT_KEY = "barcodeData"
        const val START_ACTION = "android.bld.scan.action.START_DECODE"
        const val STOP_ACTION = "android.bld.scan.action.STOP_DECODE_IMT"
    }
}
