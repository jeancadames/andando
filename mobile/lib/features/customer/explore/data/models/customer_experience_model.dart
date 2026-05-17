import 'package:intl/intl.dart';

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
  final bool isFavorite;
  final List<DateTime> availableDates;
  final List<CustomerExperienceScheduleModel> availableSchedules;

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
    required this.isFavorite,
    required this.availableDates,
    required this.availableSchedules,
  });

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
      isFavorite: _toBool(json['is_favorite']),
      availableDates: _parseAvailableDates(json['available_dates']),
      availableSchedules: _parseAvailableSchedules(json['available_schedules']),
    );
  }

  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'en_US');
    final formattedNumber = formatter.format(price);

    if (currency == 'DOP') {
      return 'RD\$$formattedNumber';
    }

    return '$currency $formattedNumber';
  }

  String get displayLocation {
    if (location != null && location!.trim().isNotEmpty) {
      return location!;
    }

    if (province != null && province!.trim().isNotEmpty) {
      return province!;
    }

    return 'Ubicación no especificada';
  }

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

  static List<DateTime> _parseAvailableDates(dynamic value) {
    if (value == null || value is! List) return [];

    return value
        .map((item) => item is String ? DateTime.tryParse(item) : null)
        .whereType<DateTime>()
        .toList();
  }

  static List<CustomerExperienceScheduleModel> _parseAvailableSchedules(
    dynamic value,
  ) {
    if (value == null || value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => CustomerExperienceScheduleModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .where((schedule) => schedule.availableSpots > 0)
        .toList();
  }
}

class CustomerExperienceScheduleModel {
  final int id;
  final DateTime startsAt;
  final int capacity;
  final int availableSpots;
  final double price;
  final String currency;

  const CustomerExperienceScheduleModel({
    required this.id,
    required this.startsAt,
    required this.capacity,
    required this.availableSpots,
    required this.price,
    required this.currency,
  });

  factory CustomerExperienceScheduleModel.fromJson(Map<String, dynamic> json) {
    return CustomerExperienceScheduleModel(
      id: CustomerExperienceModel._toInt(json['id']),
      startsAt: DateTime.tryParse(json['starts_at']?.toString() ?? '') ??
          DateTime.now(),
      capacity: CustomerExperienceModel._toInt(json['capacity']),
      availableSpots: CustomerExperienceModel._toInt(json['available_spots']),
      price: CustomerExperienceModel._toDouble(json['price']),
      currency: json['currency']?.toString() ?? 'DOP',
    );
  }

  String get formattedDate {
    final day = startsAt.day.toString().padLeft(2, '0');
    final month = startsAt.month.toString().padLeft(2, '0');
    final year = startsAt.year.toString();

    return '$day/$month/$year';
  }
}