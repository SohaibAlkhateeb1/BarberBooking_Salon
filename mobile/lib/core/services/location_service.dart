import 'package:geolocator/geolocator.dart';
import '../storage/token_storage.dart';

class LocationService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      await _tokenStorage.saveLocation(position.latitude, position.longitude);

      return position;
    } catch (e) {
      return null;
    }
  }

  Future<double?> calculateDistance(
    double lat1, double lon1, double lat2, double lon2,
  ) async {
    try {
      final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
      return distance / 1000.0;
    } catch (e) {
      return null;
    }
  }
}
