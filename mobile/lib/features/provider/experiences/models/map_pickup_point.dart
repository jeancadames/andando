/// Punto de recogida geolocalizado para una experiencia.
///
/// Se usa para enviar al backend:
/// map_pickup_points[]
///
/// AndanDO guarda:
/// - nombre
/// - dirección visible
/// - latitud
/// - longitud
/// - instrucciones opcionales
class MapPickupPoint {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? instructions;

  const MapPickupPoint({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.instructions,
  });

  factory MapPickupPoint.fromJson(Map<String, dynamic> json) {
    return MapPickupPoint(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      instructions: json['instructions']?.toString(),
    );
  }

  Map<String, String> toMultipartFields() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (instructions != null && instructions!.trim().isNotEmpty)
        'instructions': instructions!,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}