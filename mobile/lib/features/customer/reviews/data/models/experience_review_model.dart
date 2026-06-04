import '../../../booking/data/models/customer_booking_model.dart';

class ExperienceReviewModel {
  final int id;
  final int rating;
  final String? comment;
  final String customerName;
  final DateTime? createdAt;
  final int? bookingId;
  final bool isOwner;
  final CustomerBookingModel? booking;
  final List<String> photoUrls;
  final int commentsCount;

  const ExperienceReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.customerName,
    required this.createdAt,
    required this.bookingId,
    required this.isOwner,
    required this.booking,
    required this.photoUrls,
    required this.commentsCount,
  });

  factory ExperienceReviewModel.fromJson(Map<String, dynamic> json) {
    return ExperienceReviewModel(
      id: _toInt(json['id']),
      rating: _toInt(json['rating']),
      comment: json['comment']?.toString(),
      customerName: json['customer_name']?.toString() ?? 'Viajero',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      bookingId: json['booking_id'] == null ? null : _toInt(json['booking_id']),
      isOwner: _toBool(json['is_owner']),
      booking: json['booking'] == null
          ? null
          : CustomerBookingModel.fromJson(
              Map<String, dynamic>.from(json['booking']),
            ),
      photoUrls: (json['photos'] as List? ?? [])
          .map((item) {
            final map = Map<String, dynamic>.from(item);
            return map['url']?.toString() ?? '';
          })
          .where((url) => url.trim().isNotEmpty)
          .toList(),
      commentsCount: _toInt(json['comments_count']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }
}
