import 'package:intl/intl.dart';

class CustomerBookingModel {
  final int id;
  final String bookingCode;
  final String status;

  final String experienceTitle;

  final String? location;
  final String? province;

  final String? coverPhotoUrl;

  final DateTime? bookingDate;
  final DateTime? startsAt;

  final int guestsCount;

  final double unitPrice;
  final double totalAmount;

  final String currency;

  final String? pickupPoint;
  final String? duration;

  const CustomerBookingModel({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.experienceTitle,
    required this.location,
    required this.province,
    required this.coverPhotoUrl,
    required this.bookingDate,
    required this.startsAt,
    required this.guestsCount,
    required this.unitPrice,
    required this.totalAmount,
    required this.currency,
    required this.pickupPoint,
    required this.duration,
  });

  factory CustomerBookingModel.fromJson(Map<String, dynamic> json) {
    return CustomerBookingModel(
      id: _toInt(json['id']),
      bookingCode: json['booking_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      experienceTitle: json['experience_title']?.toString() ?? '',
      location: json['location']?.toString(),
      province: json['province']?.toString(),
      coverPhotoUrl: json['cover_photo_url']?.toString(),
      bookingDate: _parseDate(json['booking_date']),
      startsAt: _parseDate(json['starts_at']),
      guestsCount: _toInt(json['guests_count']),
      unitPrice: _toDouble(json['unit_price']),
      totalAmount: _toDouble(json['total_amount']),
      currency: json['currency']?.toString() ?? 'DOP',
      pickupPoint: json['pickup_point']?.toString(),
      duration: json['duration']?.toString(),
    );
  }

  bool get isCompleted {
    return status.toLowerCase() == 'completed';
  }

  bool get isUpcoming {
    return !isCompleted;
  }

  String get formattedTotalAmount {
    final formatter = NumberFormat('#,###', 'en_US');

    final formatted = formatter.format(totalAmount);

    if (currency == 'DOP') {
      return 'RD\$$formatted';
    }

    return '$currency $formatted';
  }

  String get formattedDate {
    final date = startsAt ?? bookingDate;

    if (date == null) {
      return 'Fecha no disponible';
    }

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String get formattedTime {
    final date = startsAt ?? bookingDate;

    if (date == null) {
      return '--:--';
    }

    return DateFormat('HH:mm').format(date);
  }

  String get displayLocation {
    if (location != null && location!.trim().isNotEmpty) {
      return location!;
    }

    if (province != null && province!.trim().isNotEmpty) {
      return province!;
    }

    return 'Ubicación no disponible';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;

    if (value is int) {
      return value.toDouble();
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }
}