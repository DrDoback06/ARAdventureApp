import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';

class LocationService extends ChangeNotifier {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();
  LocationService._();

  UserLocation? _currentLocation;
  bool _isTracking = false;
  StreamSubscription<Position>? _locationSubscription;

  // Getters
  UserLocation? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;

  // Get current location
  Future<UserLocation?> getCurrentLocation() async {
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever');
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentLocation = UserLocation(
        userId: 'player',
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      notifyListeners();
      return _currentLocation;
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Start location tracking
  void startLocationUpdates(Function(UserLocation) onLocationUpdate) {
    if (_isTracking) return;

    _isTracking = true;
    notifyListeners();

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      final location = UserLocation(
        userId: 'player',
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      _currentLocation = location;
      onLocationUpdate(location);
      notifyListeners();
    });
  }

  // Stop location tracking
  void stopLocationUpdates() {
    _isTracking = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    notifyListeners();
  }

  // Calculate distance between two points
  static double calculateDistance(UserLocation start, UserLocation end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }

  // Get address from coordinates (simplified for now)
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    // For now, return coordinates as address
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }
} 