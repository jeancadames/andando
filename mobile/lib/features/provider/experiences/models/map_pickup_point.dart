/// Punto de recogida geolocalizado para una experiencia.
class MapPickupPoint {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;
  final String? instructions;

  const MapPickupPoint({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.instructions,
  });

  factory MapPickupPoint.fromJson(Map<String, dynamic> json) {
    return MapPickupPoint(
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      placeId: json['place_id']?.toString(),
      instructions: json['instructions']?.toString(),
    );
  }

  Map<String, String> toMultipartFields() {
    return {
      'name': name,
      'address': address,
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      if (placeId != null && placeId!.trim().isNotEmpty) 'place_id': placeId!,
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
