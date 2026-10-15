package com.espadna.shah_dozd
// Same file in src/bazaar and src/direct (the two Iranian builds).

import android.app.Activity
import com.adivery.sdk.Adivery
import com.adivery.sdk.AdiveryListener
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

/**
 * Adivery rewarded ads for the Cafe Bazaar and direct-APK builds
 * (lib/shop/ads_io.dart, channel "shahdozd/adivery"). Ads show only when the
 * player asks for coins in the shop.
 */
object AdsBridge {
    private var configured = false
    private var activity = WeakReference<Activity>(null)
    private var pending: MethodChannel.Result? = null

    private val listener = object : AdiveryListener() {
        override fun onRewardedAdClosed(placementId: String, isRewarded: Boolean) {
            pending?.success(isRewarded)
            pending = null
            activity.get()?.let { Adivery.prepareRewardedAd(it, placementId) }
        }
    }

    fun register(activity: Activity, engine: FlutterEngine) {
        this.activity = WeakReference(activity)
        MethodChannel(engine.dartExecutor.binaryMessenger, "shahdozd/adivery").setMethodCallHandler { call, result ->
            val placement = call.argument<String>("placement") ?: ""
            when (call.method) {
                "init" -> {
                    val appId = call.argument<String>("appId") ?: ""
                    if (appId.isEmpty() || placement.isEmpty()) {
                        result.success(false)
                    } else {
                        if (!configured) {
                            Adivery.configure(activity.application, appId)
                            Adivery.addGlobalListener(listener)
                            configured = true
                        }
                        if (!Adivery.isLoaded(placement)) Adivery.prepareRewardedAd(activity, placement)
                        result.success(true)
                    }
                }
                "isLoaded" -> result.success(configured && Adivery.isLoaded(placement))
                "show" -> {
                    if (!configured || !Adivery.isLoaded(placement)) {
                        result.success(false)
                    } else {
                        pending?.success(false)
                        pending = result
                        Adivery.showAd(placement)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
