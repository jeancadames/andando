/// Modelo principal del perfil del cliente.
///
/// Representa la respuesta completa de:
/// GET /api/client/profile
class CustomerProfileModel {
  final CustomerProfileUser user;
  final CustomerProfileStats stats;
  final CustomerNextBooking? nextBooking;

  const CustomerProfileModel({
    required this.user,
    required this.stats,
    required this.nextBooking,
  });

  factory CustomerProfileModel.fromJson(Map<String, dynamic> json) {
    final data = Map<String, dynamic>.from(json['data'] ?? {});

    return CustomerProfileModel(
      user: CustomerProfileUser.fromJson(
        Map<String, dynamic>.from(data['user'] ?? {}),
      ),
      stats: CustomerProfileStats.fromJson(
        Map<String, dynamic>.from(data['stats'] ?? {}),
      ),
      nextBooking: data['next_booking'] != null
          ? CustomerNextBooking.fromJson(
              Map<String, dynamic>.from(data['next_booking']),
            )
          : null,
    );
  }
}

/// Información básica del usuario.
class CustomerProfileUser {
  final int id;

  final String name;
  final String email;

  final String? phone;

  final String? avatarUrl;

  final String? birthDate;
  final String? gender;
  final String? nationality;
  final String? residenceCity;
  final String? preferredCurrency;
  final String? language;
  final String? country;

  const CustomerProfileUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarUrl,
    required this.birthDate,
    required this.gender,
    required this.nationality,
    required this.residenceCity,
    required this.preferredCurrency,
    required this.language,
    required this.country,
  });

  factory CustomerProfileUser.fromJson(Map<String, dynamic> json) {
    return CustomerProfileUser(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),

      avatarUrl: json['avatar_url']?.toString(),

      birthDate: json['birth_date']?.toString(),
      gender: json['gender']?.toString(),
      nationality: json['nationality']?.toString(),
      residenceCity: json['residence_city']?.toString(),
      preferredCurrency: json['preferred_currency']?.toString(),
      language: json['language']?.toString(),
      country: json['country']?.toString(),
    );
  }
}

/// Estadísticas mostradas en el header del perfil.
class CustomerProfileStats {
  final int toursCount;
  final int reviewsCount;
  final int favoritesCount;
  final int pendingBookingsCount;

  const CustomerProfileStats({
    required this.toursCount,
    required this.reviewsCount,
    required this.favoritesCount,
    required this.pendingBookingsCount,
  });

  factory CustomerProfileStats.fromJson(Map<String, dynamic> json) {
    return CustomerProfileStats(
      toursCount: json['tours_count'] ?? 0,
      reviewsCount: json['reviews_count'] ?? 0,
      favoritesCount: json['favorites_count'] ?? 0,
      pendingBookingsCount: json['pending_bookings_count'] ?? 0,
    );
  }
}

/// Próxima aventura/reserva futura.
class CustomerNextBooking {
  final int id;

  final String bookingCode;
  final String status;

  final String? experienceTitle;
  final String? experienceLocation;
  final String? experienceProvince;

  final String? bookingDate;
  final String? startsAt;

  final int guestsCount;

  final double totalAmount;
  final String? currency;

  const CustomerNextBooking({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.experienceTitle,
    required this.experienceLocation,
    required this.experienceProvince,
    required this.bookingDate,
    required this.startsAt,
    required this.guestsCount,
    required this.totalAmount,
    required this.currency,
  });

  factory CustomerNextBooking.fromJson(Map<String, dynamic> json) {
    return CustomerNextBooking(
      id: json['id'] ?? 0,
      bookingCode: json['booking_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',

      experienceTitle: json['experience_title']?.toString(),
      experienceLocation: json['experience_location']?.toString(),
      experienceProvince: json['experience_province']?.toString(),

      bookingDate: json['booking_date']?.toString(),
      startsAt: json['starts_at']?.toString(),

      guestsCount: json['guests_count'] ?? 0,

      totalAmount: (json['total_amount'] ?? 0).toDouble(),

      currency: json['currency']?.toString(),
    );
  }
}