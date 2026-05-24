/// Modelo principal del módulo de análisis estadístico del afiliado.
///
/// Este modelo representa la respuesta real de:
/// GET /api/provider/analytics
///
/// No contiene data quemada.
/// Todo se alimenta del backend Laravel.
class ProviderAnalyticsModel {
  final String message;
  final AnalyticsFilters filters;
  final AnalyticsProvider provider;
  final AnalyticsSummary summary;
  final AnalyticsAudience audience;
  final AnalyticsConversion conversion;
  final AnalyticsSchedules schedules;
  final AnalyticsDemand demand;
  final AnalyticsExperiences experiences;
  final AnalyticsLoyalty loyalty;
  final List<AnalyticsAvailableExperience> availableExperiences;
  final AnalyticsWarnings warnings;
  final List<AnalyticsInsight> insights;

  ProviderAnalyticsModel({
    required this.message,
    required this.filters,
    required this.provider,
    required this.summary,
    required this.audience,
    required this.conversion,
    required this.schedules,
    required this.demand,
    required this.experiences,
    required this.loyalty,
    required this.availableExperiences,
    required this.warnings,
    required this.insights,
  });

  factory ProviderAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return ProviderAnalyticsModel(
      message: json['message']?.toString() ?? '',
      filters: AnalyticsFilters.fromJson(_asMap(json['filters'])),
      provider: AnalyticsProvider.fromJson(_asMap(json['provider'])),
      summary: AnalyticsSummary.fromJson(_asMap(json['summary'])),
      audience: AnalyticsAudience.fromJson(_asMap(json['audience'])),
      conversion: AnalyticsConversion.fromJson(_asMap(json['conversion'])),
      schedules: AnalyticsSchedules.fromJson(_asMap(json['schedules'])),
      demand: AnalyticsDemand.fromJson(_asMap(json['demand'])),
      experiences: AnalyticsExperiences.fromJson(_asMap(json['experiences'])),
      loyalty: AnalyticsLoyalty.fromJson(_asMap(json['loyalty'])),
      availableExperiences: _asList(json['available_experiences'])
          .map(
            (item) => AnalyticsAvailableExperience.fromJson(_asMap(item)),
          )
          .toList(),
      warnings: AnalyticsWarnings.fromJson(_asMap(json['warnings'])),
      insights: _asList(json['insights'])
          .map(
            (item) => AnalyticsInsight.fromJson(_asMap(item)),
          )
          .toList(),
    );
  }
}

/// Filtros aplicados al endpoint.
class AnalyticsFilters {
  final String period;
  final String startDate;
  final String endDate;
  final int? experienceId;

  AnalyticsFilters({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.experienceId,
  });

  factory AnalyticsFilters.fromJson(Map<String, dynamic> json) {
    return AnalyticsFilters(
      period: json['period']?.toString() ?? '30d',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      experienceId: _toNullableInt(json['experience_id']),
    );
  }
}

/// Datos básicos del proveedor autenticado.
class AnalyticsProvider {
  final int id;
  final String businessName;
  final String status;

  AnalyticsProvider({
    required this.id,
    required this.businessName,
    required this.status,
  });

  factory AnalyticsProvider.fromJson(Map<String, dynamic> json) {
    return AnalyticsProvider(
      id: _toInt(json['id']),
      businessName: json['business_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Resumen principal de KPIs.
class AnalyticsSummary {
  final AnalyticsMetric revenue;
  final AnalyticsMetric confirmedBookings;
  final AnalyticsMetric confirmedGuests;
  final AnalyticsMetric occupancyRate;
  final AnalyticsMetric publishedExperiences;
  final AnalyticsMetric favorites;
  final AnalyticsMetric cancelledBookings;
  final AnalyticsMetric cancellationRate;

  AnalyticsSummary({
    required this.revenue,
    required this.confirmedBookings,
    required this.confirmedGuests,
    required this.occupancyRate,
    required this.publishedExperiences,
    required this.favorites,
    required this.cancelledBookings,
    required this.cancellationRate,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      revenue: AnalyticsMetric.fromJson(_asMap(json['revenue'])),
      confirmedBookings:
          AnalyticsMetric.fromJson(_asMap(json['confirmed_bookings'])),
      confirmedGuests:
          AnalyticsMetric.fromJson(_asMap(json['confirmed_guests'])),
      occupancyRate:
          AnalyticsMetric.fromJson(_asMap(json['occupancy_rate'])),
      publishedExperiences:
          AnalyticsMetric.fromJson(_asMap(json['published_experiences'])),
      favorites: AnalyticsMetric.fromJson(_asMap(json['favorites'])),
      cancelledBookings:
          AnalyticsMetric.fromJson(_asMap(json['cancelled_bookings'])),
      cancellationRate:
          AnalyticsMetric.fromJson(_asMap(json['cancellation_rate'])),
    );
  }
}

/// Métrica reutilizable.
///
/// Ejemplo:
/// {
///   "value": 0,
///   "formatted": "RD$0.00"
/// }
class AnalyticsMetric {
  final num value;
  final String formatted;

  AnalyticsMetric({
    required this.value,
    required this.formatted,
  });

  factory AnalyticsMetric.fromJson(Map<String, dynamic> json) {
    return AnalyticsMetric(
      value: _toNum(json['value']),
      formatted: json['formatted']?.toString() ?? '',
    );
  }
}

/// Perfil del público.
class AnalyticsAudience {
  final List<AnalyticsRankingItem> ageRanges;
  final List<AnalyticsRankingItem> topCities;
  final List<AnalyticsRankingItem> topCountries;
  final List<AnalyticsRankingItem> topNationalities;
  final List<AnalyticsRankingItem> topLanguages;

  AnalyticsAudience({
    required this.ageRanges,
    required this.topCities,
    required this.topCountries,
    required this.topNationalities,
    required this.topLanguages,
  });

  factory AnalyticsAudience.fromJson(Map<String, dynamic> json) {
    return AnalyticsAudience(
      ageRanges: _rankingList(json['age_ranges']),
      topCities: _rankingList(json['top_cities']),
      topCountries: _rankingList(json['top_countries']),
      topNationalities: _rankingList(json['top_nationalities']),
      topLanguages: _rankingList(json['top_languages']),
    );
  }
}

/// Item de ranking/porcentaje.
///
/// Sirve para:
/// - edad
/// - ciudades
/// - países
/// - idiomas
/// - anticipación de reserva
class AnalyticsRankingItem {
  final String label;
  final int count;
  final num percentage;

  AnalyticsRankingItem({
    required this.label,
    required this.count,
    required this.percentage,
  });

  factory AnalyticsRankingItem.fromJson(Map<String, dynamic> json) {
    return AnalyticsRankingItem(
      label: json['label']?.toString() ?? '',
      count: _toInt(json['count']),
      percentage: _toNum(json['percentage']),
    );
  }
}

/// Conversión de favoritos a reservas.
class AnalyticsConversion {
  final int favoritesCount;
  final int convertedFavoritesCount;
  final num favoritesToBookingsRate;
  final int? viewsCount;
  final num? viewsToBookingsRate;
  final int confirmedBookingsCount;

  AnalyticsConversion({
    required this.favoritesCount,
    required this.convertedFavoritesCount,
    required this.favoritesToBookingsRate,
    required this.viewsCount,
    required this.viewsToBookingsRate,
    required this.confirmedBookingsCount,
  });

  factory AnalyticsConversion.fromJson(Map<String, dynamic> json) {
    return AnalyticsConversion(
      favoritesCount: _toInt(json['favorites_count']),
      convertedFavoritesCount: _toInt(json['converted_favorites_count']),
      favoritesToBookingsRate: _toNum(json['favorites_to_bookings_rate']),
      viewsCount: _toNullableInt(json['views_count']),
      viewsToBookingsRate: _toNullableNum(json['views_to_bookings_rate']),
      confirmedBookingsCount: _toInt(json['confirmed_bookings_count']),
    );
  }
}

/// Bloque de fechas, ocupación por día y heatmap.
class AnalyticsSchedules {
  final List<AnalyticsUpcomingSchedule> upcoming;
  final List<AnalyticsWeekdayOccupancy> occupancyByWeekday;
  final List<AnalyticsHeatmapCell> bookingHeatmap;

  AnalyticsSchedules({
    required this.upcoming,
    required this.occupancyByWeekday,
    required this.bookingHeatmap,
  });

  factory AnalyticsSchedules.fromJson(Map<String, dynamic> json) {
    return AnalyticsSchedules(
      upcoming: _asList(json['upcoming'])
          .map(
            (item) => AnalyticsUpcomingSchedule.fromJson(_asMap(item)),
          )
          .toList(),
      occupancyByWeekday: _asList(json['occupancy_by_weekday'])
          .map(
            (item) => AnalyticsWeekdayOccupancy.fromJson(_asMap(item)),
          )
          .toList(),
      bookingHeatmap: _asList(json['booking_heatmap'])
          .map(
            (item) => AnalyticsHeatmapCell.fromJson(_asMap(item)),
          )
          .toList(),
    );
  }
}

/// Próximas fechas/salidas.
class AnalyticsUpcomingSchedule {
  final int id;
  final int providerExperienceId;
  final String experienceTitle;
  final String startsAt;
  final int capacity;
  final int booked;
  final int available;
  final num occupancyRate;
  final num price;
  final String currency;
  final String status;
  final bool needsPromotion;

  AnalyticsUpcomingSchedule({
    required this.id,
    required this.providerExperienceId,
    required this.experienceTitle,
    required this.startsAt,
    required this.capacity,
    required this.booked,
    required this.available,
    required this.occupancyRate,
    required this.price,
    required this.currency,
    required this.status,
    required this.needsPromotion,
  });

  factory AnalyticsUpcomingSchedule.fromJson(Map<String, dynamic> json) {
    return AnalyticsUpcomingSchedule(
      id: _toInt(json['id']),
      providerExperienceId: _toInt(json['provider_experience_id']),
      experienceTitle: json['experience_title']?.toString() ?? '',
      startsAt: json['starts_at']?.toString() ?? '',
      capacity: _toInt(json['capacity']),
      booked: _toInt(json['booked']),
      available: _toInt(json['available']),
      occupancyRate: _toNum(json['occupancy_rate']),
      price: _toNum(json['price']),
      currency: json['currency']?.toString() ?? 'DOP',
      status: json['status']?.toString() ?? '',
      needsPromotion: json['needs_promotion'] == true,
    );
  }
}

/// Ocupación agrupada por día de la semana.
class AnalyticsWeekdayOccupancy {
  final String day;
  final String label;
  final int capacity;
  final int booked;
  final num occupancyRate;

  AnalyticsWeekdayOccupancy({
    required this.day,
    required this.label,
    required this.capacity,
    required this.booked,
    required this.occupancyRate,
  });

  factory AnalyticsWeekdayOccupancy.fromJson(Map<String, dynamic> json) {
    return AnalyticsWeekdayOccupancy(
      day: json['day']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      capacity: _toInt(json['capacity']),
      booked: _toInt(json['booked']),
      occupancyRate: _toNum(json['occupancy_rate']),
    );
  }
}

/// Celda del heatmap de reservas.
class AnalyticsHeatmapCell {
  final String day;
  final String dayLabel;
  final String block;
  final String blockLabel;
  final int count;
  final int intensity;

  AnalyticsHeatmapCell({
    required this.day,
    required this.dayLabel,
    required this.block,
    required this.blockLabel,
    required this.count,
    required this.intensity,
  });

  factory AnalyticsHeatmapCell.fromJson(Map<String, dynamic> json) {
    return AnalyticsHeatmapCell(
      day: json['day']?.toString() ?? '',
      dayLabel: json['day_label']?.toString() ?? '',
      block: json['block']?.toString() ?? '',
      blockLabel: json['block_label']?.toString() ?? '',
      count: _toInt(json['count']),
      intensity: _toInt(json['intensity']),
    );
  }
}

/// Demanda y anticipación de reserva.
class AnalyticsDemand {
  final AnalyticsBookingLeadTime bookingLeadTime;

  AnalyticsDemand({
    required this.bookingLeadTime,
  });

  factory AnalyticsDemand.fromJson(Map<String, dynamic> json) {
    return AnalyticsDemand(
      bookingLeadTime:
          AnalyticsBookingLeadTime.fromJson(_asMap(json['booking_lead_time'])),
    );
  }
}

/// Anticipación promedio y rangos.
class AnalyticsBookingLeadTime {
  final num averageDays;
  final List<AnalyticsRankingItem> ranges;

  AnalyticsBookingLeadTime({
    required this.averageDays,
    required this.ranges,
  });

  factory AnalyticsBookingLeadTime.fromJson(Map<String, dynamic> json) {
    return AnalyticsBookingLeadTime(
      averageDays: _toNum(json['average_days']),
      ranges: _rankingList(json['ranges']),
    );
  }
}

/// Desempeño de experiencias.
class AnalyticsExperiences {
  final List<AnalyticsExperiencePerformance> topByRevenue;
  final List<AnalyticsExperiencePerformance> topByBookings;
  final List<AnalyticsExperiencePerformance> topByOccupancy;
  final List<AnalyticsExperiencePerformance> lowConversion;

  AnalyticsExperiences({
    required this.topByRevenue,
    required this.topByBookings,
    required this.topByOccupancy,
    required this.lowConversion,
  });

  factory AnalyticsExperiences.fromJson(Map<String, dynamic> json) {
    return AnalyticsExperiences(
      topByRevenue: _experiencePerformanceList(json['top_by_revenue']),
      topByBookings: _experiencePerformanceList(json['top_by_bookings']),
      topByOccupancy: _experiencePerformanceList(json['top_by_occupancy']),
      lowConversion: _experiencePerformanceList(json['low_conversion']),
    );
  }
}

/// Desempeño individual de una experiencia.
class AnalyticsExperiencePerformance {
  final int id;
  final String title;
  final String category;
  final String status;
  final int capacity;
  final int bookingsCount;
  final int guestsCount;
  final num revenue;
  final String revenueFormatted;
  final int periodCapacity;
  final num occupancyRate;
  final int favoritesCount;
  final num favoritesToBookingsRate;

  AnalyticsExperiencePerformance({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.capacity,
    required this.bookingsCount,
    required this.guestsCount,
    required this.revenue,
    required this.revenueFormatted,
    required this.periodCapacity,
    required this.occupancyRate,
    required this.favoritesCount,
    required this.favoritesToBookingsRate,
  });

  factory AnalyticsExperiencePerformance.fromJson(Map<String, dynamic> json) {
    return AnalyticsExperiencePerformance(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      capacity: _toInt(json['capacity']),
      bookingsCount: _toInt(json['bookings_count']),
      guestsCount: _toInt(json['guests_count']),
      revenue: _toNum(json['revenue']),
      revenueFormatted: json['revenue_formatted']?.toString() ?? 'RD\$0.00',
      periodCapacity: _toInt(json['period_capacity']),
      occupancyRate: _toNum(json['occupancy_rate']),
      favoritesCount: _toInt(json['favorites_count']),
      favoritesToBookingsRate: _toNum(json['favorites_to_bookings_rate']),
    );
  }
}

/// Lealtad y recurrencia.
class AnalyticsLoyalty {
  final int uniqueCustomers;
  final int newCustomers;
  final int recurrentCustomers;
  final num newCustomersRate;
  final num recurrentCustomersRate;
  final int vipCustomersCount;

  AnalyticsLoyalty({
    required this.uniqueCustomers,
    required this.newCustomers,
    required this.recurrentCustomers,
    required this.newCustomersRate,
    required this.recurrentCustomersRate,
    required this.vipCustomersCount,
  });

  factory AnalyticsLoyalty.fromJson(Map<String, dynamic> json) {
    return AnalyticsLoyalty(
      uniqueCustomers: _toInt(json['unique_customers']),
      newCustomers: _toInt(json['new_customers']),
      recurrentCustomers: _toInt(json['recurrent_customers']),
      newCustomersRate: _toNum(json['new_customers_rate']),
      recurrentCustomersRate: _toNum(json['recurrent_customers_rate']),
      vipCustomersCount: _toInt(json['vip_customers_count']),
    );
  }
}

/// Experiencias disponibles para el filtro.
class AnalyticsAvailableExperience {
  final int id;
  final String title;
  final String status;

  AnalyticsAvailableExperience({
    required this.id,
    required this.title,
    required this.status,
  });

  factory AnalyticsAvailableExperience.fromJson(Map<String, dynamic> json) {
    return AnalyticsAvailableExperience(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

/// Advertencias del backend.
class AnalyticsWarnings {
  final bool lowData;
  final String? message;

  AnalyticsWarnings({
    required this.lowData,
    required this.message,
  });

  factory AnalyticsWarnings.fromJson(Map<String, dynamic> json) {
    return AnalyticsWarnings(
      lowData: json['low_data'] == true,
      message: json['message']?.toString(),
    );
  }
}

/// Recomendación generada por reglas estadísticas.
class AnalyticsInsight {
  final String id;
  final String type;
  final String priority;
  final num confidence;
  final String title;
  final String description;
  final String recommendation;
  final bool dataWarning;
  final Map<String, dynamic> evidence;

  AnalyticsInsight({
    required this.id,
    required this.type,
    required this.priority,
    required this.confidence,
    required this.title,
    required this.description,
    required this.recommendation,
    required this.dataWarning,
    required this.evidence,
  });

  factory AnalyticsInsight.fromJson(Map<String, dynamic> json) {
    return AnalyticsInsight(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'low',
      confidence: _toNum(json['confidence']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      recommendation: json['recommendation']?.toString() ?? '',
      dataWarning: json['data_warning'] == true,
      evidence: _asMap(json['evidence']),
    );
  }
}

/// Helpers internos de parseo seguro.

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }

  return <dynamic>[];
}

List<AnalyticsRankingItem> _rankingList(dynamic value) {
  return _asList(value)
      .map(
        (item) => AnalyticsRankingItem.fromJson(_asMap(item)),
      )
      .toList();
}

List<AnalyticsExperiencePerformance> _experiencePerformanceList(dynamic value) {
  return _asList(value)
      .map(
        (item) => AnalyticsExperiencePerformance.fromJson(_asMap(item)),
      )
      .toList();
}

int _toInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value.toString());
}

num _toNum(dynamic value) {
  if (value is num) {
    return value;
  }

  return num.tryParse(value?.toString() ?? '') ?? 0;
}

num? _toNullableNum(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value;
  }

  return num.tryParse(value.toString());
}