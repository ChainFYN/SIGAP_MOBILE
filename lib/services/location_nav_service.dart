import 'dart:math';

class LocationNavService {
  // Koordinat simulasi GPS user / mandor saat ini
  static double currentLat = -8.1762;
  static double currentLng = 113.6930;

  /// Menghitung jarak garis lurus antara dua titik koordinat bumi (Haversine Formula)
  /// Mengembalikan jarak dalam satuan meter
  static double calculateDistanceMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const double earthRadiusKm = 6371.0;

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distanceKm = earthRadiusKm * c;

    return distanceKm * 1000.0; // ke meter
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Mengecek apakah mandor berada dalam radius geofence yang sah (maks 500m)
  static bool isWithinValidRadius({
    required double targetLat,
    required double targetLng,
    double maxRadiusMeters = 500.0,
  }) {
    final distance = calculateDistanceMeters(
      lat1: currentLat,
      lon1: currentLng,
      lat2: targetLat,
      lon2: targetLng,
    );
    return distance <= maxRadiusMeters;
  }

  /// Format teks jarak yang mudah dibaca (misal: "120m" atau "1.2 km")
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  /// URL scheme turn-by-turn navigasi Google Maps
  static String getNavigationUri(double lat, double lng) {
    return 'google.navigation:q=$lat,$lng&mode=d';
  }

  /// Fallback web url Google Maps
  static String getWebMapsUrl(double lat, double lng) {
    return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
  }
}
