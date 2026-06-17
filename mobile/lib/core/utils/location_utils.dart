class LocationUtils {
  static Map<String, double> parseCoordinates(String coordinates) {
    final parts = coordinates.split(',');
    if (parts.length != 2) {
      return {'lat': 0.0, 'lng': 0.0};
    }
    return {
      'lat': double.tryParse(parts[0].trim()) ?? 0.0,
      'lng': double.tryParse(parts[1].trim()) ?? 0.0,
    };
  }
}
