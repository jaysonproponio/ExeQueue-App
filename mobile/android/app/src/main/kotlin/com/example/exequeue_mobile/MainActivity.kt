package com.example.exequeue_mobile

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), EventChannel.StreamHandler {
    private companion object {
        const val METHOD_CHANNEL = "exequeue_mobile/app_links/methods"
        const val EVENT_CHANNEL = "exequeue_mobile/app_links/events"
    }

    private var eventSink: EventChannel.EventSink? = null
    private var pendingLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        cacheLink(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> result.success(consumePendingLink())
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        dispatchLink(intent.dataString)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val pending = consumePendingLink()
        if (pending != null && events != null) {
            events.success(pending)
        }
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    private fun cacheLink(intent: Intent?) {
        val link = intent?.dataString?.trim().orEmpty()
        if (link.isNotEmpty()) {
            pendingLink = link
        }
    }

    private fun dispatchLink(link: String?) {
        val normalized = link?.trim().orEmpty()
        if (normalized.isEmpty()) {
            return
        }

        if (eventSink != null) {
            eventSink?.success(normalized)
            return
        }

        pendingLink = normalized
    }

    private fun consumePendingLink(): String? {
        val link = pendingLink
        pendingLink = null
        return link
    }
}
