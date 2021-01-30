import 'dart:async';

import 'package:flutter/services.dart';

class GeoLocationLatLng {
  final double lat;
  final double long;

  GeoLocationLatLng({this.lat = 0, this.long = 0});

  factory GeoLocationLatLng.fromJson(Map<dynamic, dynamic> json) =>
      GeoLocationLatLng(
        lat: json['lat'] ?? 0 as double,
        long: json['lng'] ?? 0 as double,
      );
}

typedef LocationCallback = void Function(GeoLocationLatLng location);

class GeoLocation {
  static List<LocationCallback> _listeners = [];

  static const MethodChannel _channel =
      const MethodChannel('zhogolev.geo_location');

  static void addListener(LocationCallback callback) =>
      _listeners.add(callback);

  static void removeListener(LocationCallback callback) =>
      _listeners.remove(callback);

  static void init() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'locationChanged':
          for (final listener in _listeners) {
            return listener(GeoLocationLatLng.fromJson(call.arguments));
          }
      }
    });
  }

  static Future<GeoLocationLatLng> getCurrentLocation() async {
    final result = await _channel.invokeMethod('getCurrentLocation');
    return GeoLocationLatLng.fromJson(result);
  }
}
