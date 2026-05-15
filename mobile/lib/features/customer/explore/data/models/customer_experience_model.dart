/// Modelo usado por el cliente para explorar experiencias.
///
/// Este modelo representa una experiencia creada por un proveedor
/// desde el backend Laravel usando ProviderExperience.
class CustomerExperienceModel {
  final int id;
  final String title;
  final String? category;
  final String? description;
  final String? duration;
  final String? location;
  final String? province;
  final double price;
  final String currency;
  final int capacity;
  final String? cancellationPolicy;
  final bool instantConfirmation;
  final String? coverPhotoUrl;
  final double rating;
  final int reviewsCount;

  const CustomerExperienceModel({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.duration,
    required this.location,
    required this.province,
    required this.price,
    required this.currency,
    required this.capacity,
    required this.cancellationPolicy,
    required this.instantConfirmation,
    required this.coverPhotoUrl,
    required this.rating,
    required this.reviewsCount,
  });

  /// Construye el modelo desde el JSON retornado por Laravel.
  factory CustomerExperienceModel.fromJson(Map<String, dynamic> json) {
    return CustomerExperienceModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      duration: json['duration']?.toString(),
      location: json['location']?.toString(),
      province: json['province']?.toString(),
      price: _toDouble(json['price']),
      currency: json['currency']?.toString() ?? 'DOP',
      capacity: _toInt(json['capacity']),
      cancellationPolicy: json['cancellation_policy']?.toString(),
      instantConfirmation: _toBool(json['instant_confirmation']),
      coverPhotoUrl: json['cover_photo_url']?.toString(),
      rating: _toDouble(json['rating']),
      reviewsCount: _toInt(json['reviews_count']),
    );
  }

  /// Convierte el modelo a JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'description': description,
      'duration': duration,
      'location': location,
      'province': province,
      'price': price,
      'currency': currency,
      'capacity': capacity,
      'cancellation_policy': cancellationPolicy,
      'instant_confirmation': instantConfirmation,
      'cover_photo_url': coverPhotoUrl,
      'rating': rating,
      'reviews_count': reviewsCount,
    };
  }

  /// Precio formateado para mostrar en UI.
  String get formattedPrice {
    if (currency == 'DOP') {
      return 'RD\$${price.toStringAsFixed(0)}';
    }

    return '$currency ${price.toStringAsFixed(0)}';
  }

  /// Ubicación segura para evitar textos nulos en pantalla.
  String get displayLocation {
    if (location != null && location!.trim().isNotEmpty) {
      return location!;
    }

    if (province != null && province!.trim().isNotEmpty) {
      return province!;
    }

    return 'Ubicación no especificada';
  }

  /// Duración segura para mostrar en pantalla.
  String get displayDuration {
    if (duration != null && duration!.trim().isNotEmpty) {
      return duration!;
    }

    return 'Duración no especificada';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }

    return false;
  }
}