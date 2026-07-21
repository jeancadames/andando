import 'map_pickup_point.dart';

enum ExperienceDifficulty {
  easy(apiValue: 'easy', label: 'Fácil'),
  moderate(apiValue: 'moderate', label: 'Moderada'),
  hard(apiValue: 'hard', label: 'Difícil');

  const ExperienceDifficulty({required this.apiValue, required this.label});

  final String apiValue;
  final String label;

  static ExperienceDifficulty? fromApiValue(dynamic value) {
    final normalized = value?.toString().trim().toLowerCase();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    for (final difficulty in values) {
      if (difficulty.apiValue == normalized) {
        return difficulty;
      }
    }

    return null;
  }
}

class ProviderExperiencePhoto {
  final int id;
  final String url;
  final bool isCover;
  final int sortOrder;

  const ProviderExperiencePhoto({
    required this.id,
    required this.url,
    required this.isCover,
    required this.sortOrder,
  });

  factory ProviderExperiencePhoto.fromJson(Map<String, dynamic> json) {
    final rawIsCover = json['is_cover'];

    return ProviderExperiencePhoto(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      url: json['url']?.toString() ?? '',
      isCover:
          rawIsCover == true ||
          rawIsCover == 1 ||
          rawIsCover?.toString().toLowerCase() == 'true' ||
          rawIsCover?.toString() == '1',
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '') ?? 0,
    );
  }
}

class ProviderExperience {
  final int id;
  final String title;
  final String? category;
  final String? description;
  final String? duration;
  final String? location;
  final String? province;

  final String? experienceAddress;
  final String? experiencePlaceId;
  final double? experienceLatitude;
  final double? experienceLongitude;
  final bool includesTransport;
  final bool allowsMinors;
  final ExperienceDifficulty? difficultyLevel;

  final List<String> pickupPoints;
  final List<MapPickupPoint> mapPickupPoints;

  final double price;
  final bool allowsDiscount;
  final double? discountPercentage;
  final double discountAmount;
  final double finalPrice;
  final String currency;
  final int capacity;
  final List<Map<String, dynamic>> itinerary;
  final List<String> amenities;
  final List<String> included;
  final List<String> notIncluded;
  final List<String> requirements;
  final String? cancellationPolicy;
  final String status;
  final bool isActive;
  final String? coverPhotoUrl;
  final List<ProviderExperiencePhoto> photos;
  final int bookingsCount;
  final double revenue;
  final int views;
  final double rating;
  final int schedulesCount;
  final String? nextAvailable;

  ProviderExperience({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.duration,
    required this.location,
    required this.province,
    required this.experienceAddress,
    required this.experiencePlaceId,
    required this.experienceLatitude,
    required this.experienceLongitude,
    required this.includesTransport,
    required this.allowsMinors,
    required this.pickupPoints,
    required this.mapPickupPoints,
    required this.price,
    this.allowsDiscount = false,
    this.discountPercentage,
    this.discountAmount = 0,
    double? finalPrice,
    required this.currency,
    required this.capacity,
    required this.itinerary,
    required this.amenities,
    required this.included,
    required this.notIncluded,
    required this.requirements,
    required this.cancellationPolicy,
    required this.status,
    required this.isActive,
    required this.coverPhotoUrl,
    this.photos = const [],
    required this.bookingsCount,
    required this.revenue,
    required this.views,
    required this.rating,
    required this.schedulesCount,
    required this.nextAvailable,
    this.difficultyLevel,
  }) : finalPrice = finalPrice ?? price;

  factory ProviderExperience.fromJson(Map<String, dynamic> json) {
    return ProviderExperience(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      duration: json['duration']?.toString(),
      location: json['location']?.toString(),
      province: json['province']?.toString(),

      experienceAddress: json['experience_address']?.toString(),
      experiencePlaceId: json['experience_place_id']?.toString(),
      experienceLatitude: _toNullableDouble(json['experience_latitude']),
      experienceLongitude: _toNullableDouble(json['experience_longitude']),
      includesTransport:
          json['includes_transport'] == true ||
          json['includes_transport'] == 1 ||
          json['includes_transport']?.toString() == '1',
      allowsMinors:
          json['allows_minors'] == true ||
          json['allows_minors'] == 1 ||
          json['allows_minors']?.toString().toLowerCase() == 'true' ||
          json['allows_minors']?.toString() == '1',
      difficultyLevel: ExperienceDifficulty.fromApiValue(
        json['difficulty_level'],
      ),

      pickupPoints: _stringList(json['pickup_points']),
      mapPickupPoints: _mapPickupPointList(json['map_pickup_points']),

      price: _toDouble(json['price']),
      allowsDiscount:
          json['allows_discount'] == true ||
          json['allows_discount'] == 1 ||
          json['allows_discount']?.toString().toLowerCase() == 'true' ||
          json['allows_discount']?.toString() == '1',
      discountPercentage: _toNullableDouble(json['discount_percentage']),
      discountAmount: _toDouble(json['discount_amount']),
      finalPrice: _toNullableDouble(json['final_price']),
      currency: json['currency']?.toString() ?? 'DOP',
      capacity: _toInt(json['capacity']),
      itinerary: _mapList(json['itinerary']),
      amenities: _stringList(json['amenities']),
      included: _stringList(json['included']),
      notIncluded: _stringList(json['not_included']),
      requirements: _stringList(json['requirements']),
      cancellationPolicy: json['cancellation_policy']?.toString(),
      status: json['status']?.toString() ?? 'draft',
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
      coverPhotoUrl: json['cover_photo_url']?.toString(),
      photos: _photoList(json['photos']),
      bookingsCount: _toInt(json['bookings_count']),
      revenue: _toDouble(json['revenue']),
      views: _toInt(json['views']),
      rating: _toDouble(json['rating']),
      schedulesCount: _toInt(json['schedules_count']),
      nextAvailable: json['next_available']?.toString(),
    );
  }

  static List<ProviderExperiencePhoto> _photoList(dynamic value) {
    if (value is! List) {
      return [];
    }

    final photos = value
        .whereType<Map>()
        .map(
          (item) =>
              ProviderExperiencePhoto.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((photo) => photo.url.trim().isNotEmpty)
        .toList();

    photos.sort((left, right) => left.sortOrder.compareTo(right.sortOrder));

    return photos;
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  static List<MapPickupPoint> _mapPickupPointList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map(
            (item) => MapPickupPoint.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }

    return [];
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
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

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
