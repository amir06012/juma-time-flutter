import 'dart:math';

class QiblaService {
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  /// Initial great-circle bearing (degrees, 0-360, 0 = true North) from the
  /// given point toward the Kaaba in Mecca.
  double calculateQiblaBearing(double latitude, double longitude) {
    final lat1 = _toRadians(latitude);
    final lon1 = _toRadians(longitude);
    final lat2 = _toRadians(kaabaLat);
    final lon2 = _toRadians(kaabaLng);

    final dLon = lon2 - lon1;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    final bearing = atan2(y, x);

    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
  double _toDegrees(double radians) => radians * 180 / pi;
}
