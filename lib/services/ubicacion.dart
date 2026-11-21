import 'package:geolocator/geolocator.dart';

class Ubicacion {
  /// Obtiene la posición por GPS (funciona sin internet). Devuelve null si
  /// no hay permiso o el GPS está apagado y no hay última posición conocida.
  static Future<Position?> actual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return Geolocator.getLastKnownPosition();
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      return Geolocator.getLastKnownPosition();
    }
  }
}
