class ProviderExperience {
  final int id;
  final String title;
  final String? category;
  final String? description;
  final String? duration;
  final String? location;
  final String? province;
  final String? startLocation;
  final List<String> pickupPoints;
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
    required this.pickupPoints,
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
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      category: json['category'],
      description: json['description'],
      duration: json['duration'],
      location: json['location'],
      province: json['province'],
      startLocation: json['start_location'],
      pickupPoints: _stringList(json['pickup_points']),
      price: _toDouble(json['price']),
      currency: json['currency'] ?? 'DOP',
      capacity: _toInt(json['capacity']),
      itinerary: _mapList(json['itinerary']),
      amenities: _stringList(json['amenities']),
      included: _stringList(json['included']),
      notIncluded: _stringList(json['not_included']),
      requirements: _stringList(json['requirements']),
      cancellationPolicy: json['cancellation_policy'],
      status: json['status'] ?? 'draft',
      isActive: json['is_active'] ?? true,
      coverPhotoUrl: json['cover_photo_url'],
      bookingsCount: _toInt(json['bookings_count']),
      revenue: _toDouble(json['revenue']),
      views: _toInt(json['views']),
      rating: _toDouble(json['rating']),
      schedulesCount: _toInt(json['schedules_count']),
      nextAvailable: json['next_available'],
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
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
}