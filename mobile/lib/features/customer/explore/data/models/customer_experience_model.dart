import 'dart:convert';

import 'package:intl/intl.dart';

/// Modelo usado por el cliente para mostrar experiencias en:
/// - Explorar
/// - Favoritos
/// - Detalle de experiencia
/// - Flujo de reserva
///
/// Este modelo representa la información que Laravel devuelve desde:
/// GET /client/explore/experiences
/// GET /client/explore/experiences/{id}
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

  /// URL principal que se muestra en cards y detalle.
  ///
  /// Normalmente viene como `cover_photo_url`.
  /// Si backend no manda portada, intentamos obtener la primera foto del array
  /// `photos`.
  final String? coverPhotoUrl;

  final double rating;
  final int reviewsCount;
  final bool isFavorite;

  /// Fechas simples disponibles.
  ///
  /// Se mantiene por compatibilidad, aunque actualmente el flujo de reserva
  /// usa preferiblemente [availableSchedules].
  final List<DateTime> availableDates;

  /// Horarios reales disponibles para reservar.
  ///
  /// Incluye:
  /// - id del schedule
  /// - fecha/hora de inicio
  /// - cupos disponibles
  /// - precio
  /// - moneda
  final List<CustomerExperienceScheduleModel> availableSchedules;

  /// Próxima fecha disponible para reservar.
  final DateTime? nextAvailableDate;

  /// Elementos incluidos en la experiencia.
  ///
  /// Viene desde la columna `amenities` de Laravel.
  final List<String> amenities;

  /// Itinerario detallado de la experiencia.
  ///
  /// Viene desde la columna `itinerary` de Laravel.
  final List<CustomerExperienceItineraryItem> itinerary;

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
    required this.nextAvailableDate,
    required this.amenities,
    required this.itinerary,
  });

  /// Construye una experiencia desde el JSON devuelto por Laravel.
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
      coverPhotoUrl: _resolveCoverPhotoUrl(json),
      rating: _toDouble(json['rating']),
      reviewsCount: _toInt(json['reviews_count']),
      isFavorite: _toBool(json['is_favorite']),
      availableDates: _parseAvailableDates(json['available_dates']),
      availableSchedules: _parseAvailableSchedules(
        json['available_schedules'],
      ),
      amenities: _parseStringList(json['amenities']),
      itinerary: _parseItinerary(json['itinerary']),

      nextAvailableDate: json['next_available_datetime'] != null
        ? DateTime.tryParse(
            json['next_available_datetime'].toString(),
          )
        : null,
    );
  }

  /// Precio formateado con separador de miles.
  ///
  /// Ejemplo:
  /// RD$5,700
  String get formattedPrice {
    final formatter = NumberFormat('#,###', 'en_US');
    final formattedNumber = formatter.format(price);

    if (currency == 'DOP') {
      return 'RD\$$formattedNumber';
    }

    return '$currency $formattedNumber';
  }

  /// Ubicación segura para UI.
  ///
  /// Prioriza `location`; si no existe, usa `province`.
  String get displayLocation {
    if (location != null && location!.trim().isNotEmpty) {
      return location!;
    }

    if (province != null && province!.trim().isNotEmpty) {
      return province!;
    }

    return 'Ubicación no especificada';
  }

  /// Duración segura para UI.
  ///
  /// Si backend devuelve solo un número, por ejemplo:
  /// "13"
  ///
  /// Se muestra como:
  /// "13 horas"
  String get displayDuration {
    final raw = duration?.trim();

    if (raw == null || raw.isEmpty) {
      return 'Duración no especificada';
    }

    final lower = raw.toLowerCase();

    if (lower.contains('hora') ||
        lower.contains('minuto') ||
        lower.contains('día') ||
        lower.contains('dia')) {
      return raw;
    }

    final numericDuration = int.tryParse(raw);

    if (numericDuration != null) {
      return numericDuration == 1 ? '1 hora' : '$numericDuration horas';
    }

    return raw;
  }

  /// Fecha más próxima disponible para reservar.
  ///
  /// Ejemplo:
  /// 15 may 2026
  String get formattedNextAvailableDate {
    if (nextAvailableDate == null) {
      return 'Sin salidas próximas';
    }

    return 'Próxima salida: ${DateFormat(
      'dd MMM yyyy',
      'es',
    ).format(nextAvailableDate!)}';
  }

  /// Lista de elementos incluidos.
  ///
  /// Si backend todavía no manda amenities, se muestran valores fallback para
  /// evitar una sección vacía.
  List<String> get displayAmenities {
    if (amenities.isNotEmpty) {
      return amenities;
    }

    return const [
      'Transporte incluido',
      'Almuerzo',
      'Guía certificado',
      'Seguro',
    ];
  }

  /// Lista de pasos del itinerario.
  ///
  /// Si backend todavía no manda itinerary, se muestran valores fallback.
  List<CustomerExperienceItineraryItem> get displayItinerary {
    if (itinerary.isNotEmpty) {
      return itinerary;
    }

    return const [
      CustomerExperienceItineraryItem(
        time: '07:00',
        activity: 'Recogida en hotel',
      ),
      CustomerExperienceItineraryItem(
        time: '09:30',
        activity: 'Llegada al destino',
      ),
      CustomerExperienceItineraryItem(
        time: '10:00',
        activity: 'Inicio de la experiencia',
      ),
      CustomerExperienceItineraryItem(
        time: '13:00',
        activity: 'Almuerzo típico',
      ),
      CustomerExperienceItineraryItem(
        time: '15:00',
        activity: 'Tiempo libre',
      ),
      CustomerExperienceItineraryItem(
        time: '17:00',
        activity: 'Regreso',
      ),
    ];
  }

  /// Resuelve qué imagen mostrar como portada.
  ///
  /// Orden de prioridad:
  /// 1. `cover_photo_url`
  /// 2. Primera foto marcada como `is_cover` dentro de `photos`
  /// 3. Primera foto disponible dentro de `photos`
  static String? _resolveCoverPhotoUrl(Map<String, dynamic> json) {
    final directCover = json['cover_photo_url']?.toString().trim();

    if (directCover != null &&
        directCover.isNotEmpty &&
        directCover.toLowerCase() != 'null') {
      return directCover;
    }

    final photos = _decodeIfJsonString(json['photos']);

    if (photos is! List || photos.isEmpty) {
      return null;
    }

    Map<String, dynamic>? firstPhoto;
    Map<String, dynamic>? coverPhoto;

    for (final item in photos) {
      if (item is! Map) continue;

      final photo = Map<String, dynamic>.from(item);
      firstPhoto ??= photo;

      if (_toBool(photo['is_cover'])) {
        coverPhoto = photo;
        break;
      }
    }

    final selectedPhoto = coverPhoto ?? firstPhoto;

    if (selectedPhoto == null) {
      return null;
    }

    final url = selectedPhoto['url']?.toString().trim();

    if (url != null && url.isNotEmpty && url.toLowerCase() != 'null') {
      return url;
    }

    final path = selectedPhoto['path']?.toString().trim();

    if (path != null && path.isNotEmpty && path.toLowerCase() != 'null') {
      return path;
    }

    return null;
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

  static bool _toBool(dynamic value) {
    if (value is bool) return value;

    if (value is int) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.toLowerCase();

      return normalized == 'true' || normalized == '1';
    }

    return false;
  }

  /// Decodifica valores que podrían venir como JSON string.
  ///
  /// Laravel normalmente devuelve arrays reales si el modelo tiene casts,
  /// pero esta función evita que Flutter falle si alguna respuesta llega como:
  /// "[{\"time\":\"08:00\"}]"
  static dynamic _decodeIfJsonString(dynamic value) {
    if (value is! String) return value;

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return value;
    }

    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return value;
    }
  }

  static List<String> _parseStringList(dynamic value) {
    final decoded = _decodeIfJsonString(value);

    if (decoded == null || decoded is! List) {
      return [];
    }

    return decoded
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<DateTime> _parseAvailableDates(dynamic value) {
    final decoded = _decodeIfJsonString(value);

    if (decoded == null || decoded is! List) {
      return [];
    }

    return decoded
        .map((item) => item is String ? DateTime.tryParse(item) : null)
        .whereType<DateTime>()
        .toList();
  }

  static List<CustomerExperienceScheduleModel> _parseAvailableSchedules(
    dynamic value,
  ) {
    final decoded = _decodeIfJsonString(value);

    if (decoded == null || decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => CustomerExperienceScheduleModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((schedule) => schedule.availableSpots > 0)
        .toList();
  }

  static List<CustomerExperienceItineraryItem> _parseItinerary(dynamic value) {
    final decoded = _decodeIfJsonString(value);

    if (decoded == null || decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => CustomerExperienceItineraryItem.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((item) => item.time.isNotEmpty || item.activity.isNotEmpty)
        .toList();
  }
}

/// Modelo de una fecha/horario disponible para reservar.
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

  /// Fecha del schedule para mostrar en dropdowns.
  ///
  /// Ejemplo:
  /// 29/05/2026
  String get formattedDate {
    const weekdays = [
      'lun',
      'mar',
      'mié',
      'jue',
      'vie',
      'sáb',
      'dom',
    ];

    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sept',
      'oct',
      'nov',
      'dic',
    ];

    final weekday = weekdays[startsAt.weekday - 1];
    final month = months[startsAt.month - 1];

    return '$weekday, ${startsAt.day} $month ${startsAt.year}';
  }

  /// Hora del schedule con AM/PM.
  ///
  /// Ejemplo:
  /// 08:00 AM
  String get formattedTime {
    return DateFormat('hh:mm a', 'en_US').format(startsAt);
  }

  /// Fecha + hora compacta.
  ///
  /// Ejemplo:
  /// 29/05/2026 · 08:00 AM
  String get formattedDateTime {
    return '$formattedDate · $formattedTime';
  }
}

/// Item individual del itinerario de una experiencia.
class CustomerExperienceItineraryItem {
  final String time;
  final String activity;

  const CustomerExperienceItineraryItem({
    required this.time,
    required this.activity,
  });

  factory CustomerExperienceItineraryItem.fromJson(Map<String, dynamic> json) {
    return CustomerExperienceItineraryItem(
      time: json['time']?.toString().trim() ?? '',
      activity: (json['activity'] ?? json['description'] ?? json['title'])
              ?.toString()
              .trim() ??
          '',
    );
  }
}