class ProviderExperienceSchedule {
  final int id;
  final int providerExperienceId;
  final int? seriesId;
  final String startsAt;
  final String? endsAt;
  final String timezone;
  final int capacity;
  final int booked;
  final int available;
  final double price;
  final String currency;
  final String status;
  final String? notes;
  final double estimatedRevenue;

  ProviderExperienceSchedule({
    required this.id,
    required this.providerExperienceId,
    required this.seriesId,
    required this.startsAt,
    required this.endsAt,
    required this.timezone,
    required this.capacity,
    required this.booked,
    required this.available,
    required this.price,
    required this.currency,
    required this.status,
    required this.notes,
    required this.estimatedRevenue,
  });

  factory ProviderExperienceSchedule.fromJson(Map<String, dynamic> json) {
    return ProviderExperienceSchedule(
      id: _toInt(json['id']),
      providerExperienceId: _toInt(json['provider_experience_id']),
      seriesId: json['series_id'] == null ? null : _toInt(json['series_id']),
      startsAt: json['starts_at']?.toString() ?? '',
      endsAt: json['ends_at']?.toString(),
      timezone: json['timezone']?.toString() ?? 'America/Santo_Domingo',
      capacity: _toInt(json['capacity']),
      booked: _toInt(json['booked']),
      available: _toInt(json['available']),
      price: _toDouble(json['price']),
      currency: json['currency']?.toString() ?? 'DOP',
      status: json['status']?.toString() ?? 'active',
      notes: json['notes']?.toString(),
      estimatedRevenue: _toDouble(json['estimated_revenue']),
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