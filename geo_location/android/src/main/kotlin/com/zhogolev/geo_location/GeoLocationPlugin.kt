package com.zhogolev.geo_location

import android.app.Activity
import androidx.annotation.NonNull
import com.google.android.gms.location.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class GeoLocationPlugin : FlutterPlugin, MethodCallHandler, ActivityAware, LocationCallback() {
    private lateinit var channel: MethodChannel
    private var fusedLocationClient: FusedLocationProviderClient? = null
    private val request = LocationRequest.create().setInterval(500).setFastestInterval(100).setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY)

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "zhogolev.geo_location")
        channel.setMethodCallHandler(this)
    }

    private fun getCurrentLocation(result: Result) {
        fusedLocationClient?.lastLocation
                ?.addOnSuccessListener { location ->
                    if (location == null) {
                        return@addOnSuccessListener result.error("404", "location is null", "")
                    }
                    return@addOnSuccessListener result.success(mapOf("lng" to location.longitude, "lat" to location.latitude))
                }
                ?.addOnFailureListener { exception ->
                    return@addOnFailureListener result.error("200", exception.message, "${exception.stackTrace.first()}")
                }
    }


    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (call.method == "getCurrentLocation") {
            getCurrentLocation(result)
        } else {
            result.notImplemented()
        }
    }

    private fun attachLocationService(activity: Activity?) {
        if (activity == null) {
            return
        }

        if (fusedLocationClient == null) {
            fusedLocationClient = LocationServices.getFusedLocationProviderClient(activity)
            fusedLocationClient!!.requestLocationUpdates(request, this, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        attachLocationService(binding.activity)
    }

    override fun onDetachedFromActivity() {
        fusedLocationClient = null
    }

    override fun onDetachedFromActivityForConfigChanges() {
        fusedLocationClient = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        attachLocationService(binding.activity)
    }

    override fun onLocationResult(result: LocationResult?) {
        for (location in result!!.locations) {
            channel.invokeMethod("locationChanged", mapOf("lat" to location.latitude, "lng" to location.longitude))
        }
    }

}

