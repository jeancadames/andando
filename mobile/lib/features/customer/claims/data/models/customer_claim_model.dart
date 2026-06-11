class CustomerClaimModel {
  final int id;
  final int providerBookingId;
  final String? bookingCode;
  final String? bookingStatus;
  final String experienceTitle;
  final String reason;
  final String description;
  final String status;
  final String? providerResponse;
  final DateTime? createdAt;

  const CustomerClaimModel({
    required this.id,
    required this.providerBookingId,
    required this.bookingCode,
    required this.bookingStatus,
    required this.experienceTitle,
    required this.reason,
    required this.description,
    required this.status,
    required this.providerResponse,
    required this.createdAt,
  });

  factory CustomerClaimModel.fromJson(Map<String, dynamic> json) {
    return CustomerClaimModel(
      id: _toInt(json['id']),
      providerBookingId: _toInt(json['provider_booking_id']),
      bookingCode: json['booking_code']?.toString(),
      bookingStatus: json['booking_status']?.toString(),
      experienceTitle: json['experience_title']?.toString() ?? 'Experiencia',
      reason: json['reason']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      providerResponse: json['provider_response']?.toString(),
      createdAt: _parseDate(json['created_at']),
    );
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'provider_replied':
        return 'Respondido';
      case 'resolved':
        return 'Resuelto';
      case 'rejected':
        return 'Rechazado';
      default:
        return status;
    }
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}