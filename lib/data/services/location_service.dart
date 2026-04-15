import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationService {
  /// Request permission and get current position + reverse-geocoded address.
  static Future<LocationResult?> getCurrentLocation() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final address = await _reverseGeocode(pos.latitude, pos.longitude);

    return LocationResult(
      latitude:  pos.latitude,
      longitude: pos.longitude,
      address:   address,
    );
  }

  /// Reverse geocode using OpenStreetMap Nominatim (free, no API key).
  static Future<String> _reverseGeocode(double lat, double lon) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=$lat&lon=$lon&format=json&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'WorkEye-Attendance-App/1.0'},
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body);
        final addr    = data['address'] as Map<String, dynamic>? ?? {};

        // Build a clean short address: road, suburb/area, city
        final parts = <String>[];
        if (addr['road'] != null)          parts.add(addr['road']);
        if (addr['suburb'] != null)        parts.add(addr['suburb']);
        else if (addr['neighbourhood'] != null) parts.add(addr['neighbourhood']);
        if (addr['city'] != null)          parts.add(addr['city']);
        else if (addr['town'] != null)     parts.add(addr['town']);

        if (parts.isNotEmpty) return parts.join(', ');
        return data['display_name'] ?? '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
      }
    } catch (_) {}

    return '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}';
  }
}