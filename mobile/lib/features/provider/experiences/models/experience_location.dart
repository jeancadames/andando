/// Ubicacion principal donde ocurre la experiencia.
///
/// Se usa para:
/// - guardar la ubicacion real de la experiencia
/// - calcular "Experiencias cerca de ti"
/// - ordenar experiencias por distancia en Explore
class ExperienceLocation {
  final String address;
  final double latitude;
  final double longitude;
  final String? placeId;

  const ExperienceLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  factory ExperienceLocation.fromJson(Map<String, dynamic> json) {
    return ExperienceLocation(
      address: json['address']?.toString() ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      placeId: json['place_id']?.toString(),
    );
  }

  Map<String, String> toMultipartFields() {
    return {
      'experience_address': address,
      'experience_latitude': latitude.toString(),
      'experience_longitude': longitude.toString(),
      if (placeId != null && placeId!.trim().isNotEmpty)
        'experience_place_id': placeId!,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
