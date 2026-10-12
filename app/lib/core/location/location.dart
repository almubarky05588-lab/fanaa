import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class LatLng2 {
  const LatLng2(this.lat, this.lng);
  final double lat, lng;
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
