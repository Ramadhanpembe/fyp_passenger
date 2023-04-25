import 'dart:developer';

import 'package:fyp_passenger/data/resource.dart';
import 'package:geolocator/geolocator.dart';

class LocationManager {
  LocationManager() {
    _init();
  }
  void _init() async {
    isPermissionGranted = await _requestLocationPermission();
  }

  Future<bool> _requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location service is disabled');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permission is denied');
      }
      log('----------------Permission granted: $permission}');
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permission is permanently denied, we cannot request permission');
    }
    return true;
  }

  Future<Position?> getCurrentLocation() async {
    if (!isPermissionGranted) return null;
    return await Geolocator.getCurrentPosition();
  }
}
