class ProviderScheduleBookingsResponse {
  final ProviderScheduleInfo schedule;
  final List<ProviderScheduleBooking> bookings;
  final int totalBookings;
  final int totalTravelers;

  ProviderScheduleBookingsResponse({
    required this.schedule,
    required this.bookings,
    required this.totalBookings,
    required this.totalTravelers,
  });

  factory ProviderScheduleBookingsResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] as List? ?? [];

    return ProviderScheduleBookingsResponse(
      schedule: ProviderScheduleInfo.fromJson(
        Map<String, dynamic>.from(json['schedule'] ?? {}),
      ),
      bookings: data
          .whereType<Map>()
          .map(
            (item) => ProviderScheduleBooking.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      totalBookings: _toInt(json['total_bookings']),
      totalTravelers: _toInt(json['total_travelers']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class ProviderScheduleInfo {
  final int id;
  final int providerExperienceId;
  final String experienceTitle;
  final String startsAt;
  final String timezone;
  final int capacity;
  final int booked;
  final int available;
  final double price;
  final String currency;
  final String status;

  ProviderScheduleInfo({
    required this.id,
    required this.providerExperienceId,
    required this.experienceTitle,
    required this.startsAt,
    required this.timezone,
    required this.capacity,
    required this.booked,
    required this.available,
    required this.price,
    required this.currency,
    required this.status,
  });

  factory ProviderScheduleInfo.fromJson(Map<String, dynamic> json) {
    return ProviderScheduleInfo(
      id: _toInt(json['id']),
      providerExperienceId: _toInt(json['provider_experience_id']),
      experienceTitle: json['experience_title']?.toString() ?? '',
      startsAt: json['starts_at']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'America/Santo_Domingo',
      capacity: _toInt(json['capacity']),
      booked: _toInt(json['booked']),
      available: _toInt(json['available']),
      price: _toDouble(json['price']),
      currency: json['currency']?.toString() ?? 'DOP',
      status: json['status']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class ProviderScheduleBooking {
  final int id;
  final String bookingCode;
  final String clientName;
  final String? customerPhone;
  final String? customerEmail;
  final int guestsCount;
  final double unitPrice;
  final double totalAmount;
  final double providerEarning;
  final String status;
  final String? bookingDate;

  ProviderScheduleBooking({
    required this.id,
    required this.bookingCode,
    required this.clientName,
    required this.customerPhone,
    required this.customerEmail,
    required this.guestsCount,
    required this.unitPrice,
    required this.totalAmount,
    required this.providerEarning,
    required this.status,
    required this.bookingDate,
  });

  factory ProviderScheduleBooking.fromJson(Map<String, dynamic> json) {
    return ProviderScheduleBooking(
      id: _toInt(json['id']),
      bookingCode: json['booking_code']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? 'Cliente sin nombre',
      customerPhone: json['customer_phone']?.toString(),
      customerEmail: json['customer_email']?.toString(),
      guestsCount: _toInt(json['guests_count']),
      unitPrice: _toDouble(json['unit_price']),
      totalAmount: _toDouble(json['total_amount']),
      providerEarning: _toDouble(json['provider_earning']),
      status: json['status']?.toString() ?? '',
      bookingDate: json['booking_date']?.toString(),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}