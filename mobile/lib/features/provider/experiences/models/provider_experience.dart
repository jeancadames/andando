import 'map_pickup_point.dart';

class ProviderExperience {
  final int id;
  final String title;
  final String? category;
  final String? description;
  final String? duration;
  final String? location;
  final String? province;
  final String? startLocation;

  final String? experienceAddress;
  final double? experienceLatitude;
  final double? experienceLongitude;

  final List<String> pickupPoints;
  final List<MapPickupPoint> mapPickupPoints;

  final double price;
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
    required this.startLocation,
    required this.experienceAddress,
    required this.experienceLatitude,
    required this.experienceLongitude,
    required this.pickupPoints,
    required this.mapPickupPoints,
    required this.price,
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
    required this.bookingsCount,
    required this.revenue,
    required this.views,
    required this.rating,
    required this.schedulesCount,
    required this.nextAvailable,
  });

  factory ProviderExperience.fromJson(Map<String, dynamic> json) {
    return ProviderExperience(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString(),
      description: json['description']?.toString(),
      duration: json['duration']?.toString(),
      location: json['location']?.toString(),
      province: json['province']?.toString(),
      startLocation: json['start_location']?.toString(),

      experienceAddress: json['experience_address']?.toString(),
      experienceLatitude: _toNullableDouble(json['experience_latitude']),
      experienceLongitude: _toNullableDouble(json['experience_longitude']),

      pickupPoints: _stringList(json['pickup_points']),
      mapPickupPoints: _mapPickupPointList(json['map_pickup_points']),

      price: _toDouble(json['price']),
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
      bookingsCount: _toInt(json['bookings_count']),
      revenue: _toDouble(json['revenue']),
      views: _toInt(json['views']),
      rating: _toDouble(json['rating']),
      schedulesCount: _toInt(json['schedules_count']),
      nextAvailable: json['next_available']?.toString(),
    );
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
            (item) => MapPickupPoint.fromJson(
              Map<String, dynamic>.from(item),
            ),
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