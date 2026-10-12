import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LatLng2 {
  const LatLng2(this.lat, this.lng);
  final double lat, lng;
}

/// المسافة بالكيلومتر بين نقطتين (هافرساين)
double kmBetween(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.sqrt(a.toDouble()));
}

/// الرياض كموقع افتراضي إن رُفض إذن الموقع
const kFallbackLocation = LatLng2(24.7136, 46.6753);

final currentLocationProvider = FutureProvider<LatLng2>((ref) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return kFallbackLocation;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever) return kFallbackLocation;
    final pos = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
    return LatLng2(pos.latitude, pos.longitude);
  } catch (_) {
    return kFallbackLocation;
  }
});
