/// Modelo principal del dashboard del afiliado.
///
/// Este modelo representa exactamente la respuesta que viene desde:
/// GET /api/provider/dashboard
class ProviderDashboardModel {
  final String affiliateName;
  final String? providerStatus;
  final ProviderDashboardStats stats;
  final List<UpcomingBookingModel> upcomingBookings;
  final QuickAnalysisModel quickAnalysis;

  ProviderDashboardModel({
    required this.affiliateName,
    required this.providerStatus,
    required this.stats,
    required this.upcomingBookings,
    required this.quickAnalysis,
  });

  factory ProviderDashboardModel.fromJson(Map<String, dynamic> json) {
    return ProviderDashboardModel(
      affiliateName: json['affiliate_name']?.toString() ?? 'Afiliado',
      providerStatus: json['provider_status']?.toString(),
      stats: ProviderDashboardStats.fromJson(
        Map<String, dynamic>.from(json['stats'] ?? {}),
      ),
      upcomingBookings: (json['upcoming_bookings'] as List? ?? [])
          .map(
            (item) => UpcomingBookingModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      quickAnalysis: QuickAnalysisModel.fromJson(
        Map<String, dynamic>.from(json['quick_analysis'] ?? {}),
      ),
    );
  }
}

/// Agrupa las cuatro tarjetas principales del dashboard.
class ProviderDashboardStats {
  final DashboardMetric monthlyEarnings;
  final DashboardMetric activeBookings;
  final DashboardMetric publishedExperiences;
  final DashboardMetric averageRating;

  ProviderDashboardStats({
    required this.monthlyEarnings,
    required this.activeBookings,
    required this.publishedExperiences,
    required this.averageRating,
  });

  factory ProviderDashboardStats.fromJson(Map<String, dynamic> json) {
    return ProviderDashboardStats(
      monthlyEarnings: DashboardMetric.fromJson(
        Map<String, dynamic>.from(json['monthly_earnings'] ?? {}),
      ),
      activeBookings: DashboardMetric.fromJson(
        Map<String, dynamic>.from(json['active_bookings'] ?? {}),
      ),
      publishedExperiences: DashboardMetric.fromJson(
        Map<String, dynamic>.from(json['published_experiences'] ?? {}),
      ),
      averageRating: DashboardMetric.fromJson(
        Map<String, dynamic>.from(json['average_rating'] ?? {}),
      ),
    );
  }
}

/// Modelo reutilizable para cada métrica.
///
/// Ejemplo:
/// - Ganancia del mes
/// - Reservas activas
/// - Experiencias publicadas
/// - Rating promedio
class DashboardMetric {
  final num value;
  final String formatted;
  final num change;
  final String changeLabel;

  DashboardMetric({
    required this.value,
    required this.formatted,
    required this.change,
    required this.changeLabel,
  });

  factory DashboardMetric.fromJson(Map<String, dynamic> json) {
    return DashboardMetric(
      value: json['value'] is num ? json['value'] as num : 0,
      formatted: json['formatted']?.toString() ?? '0',
      change: json['change'] is num ? json['change'] as num : 0,
      changeLabel: json['change_label']?.toString() ?? '0%',
    );
  }
}

/// Modelo para próximas reservas.
class UpcomingBookingModel {
  final int id;
  final String bookingCode;
  final String tour;
  final String? date;
  final String dateLabel;
  final int guests;
  final String status;
  final String statusLabel;

  UpcomingBookingModel({
    required this.id,
    required this.bookingCode,
    required this.tour,
    required this.date,
    required this.dateLabel,
    required this.guests,
    required this.status,
    required this.statusLabel,
  });

  factory UpcomingBookingModel.fromJson(Map<String, dynamic> json) {
    return UpcomingBookingModel(
      id: json['id'] is int ? json['id'] as int : 0,
      bookingCode: json['booking_code']?.toString() ?? '',
      tour: json['tour']?.toString() ?? 'Experiencia',
      date: json['date']?.toString(),
      dateLabel: json['date_label']?.toString() ?? 'Fecha no disponible',
      guests: json['guests'] is int ? json['guests'] as int : 0,
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString() ?? 'Pendiente',
    );
  }
}

/// Modelo para el bloque de análisis rápido.
class QuickAnalysisModel {
  final num confirmationRate;
  final int monthlyBookings;
  final int totalBookings;
  final int cancelledThisMonth;
  final num satisfaction;
  final List<MonthlyRevenuePointModel> monthlyRevenueSeries;

  QuickAnalysisModel({
    required this.confirmationRate,
    required this.monthlyBookings,
    required this.totalBookings,
    required this.cancelledThisMonth,
    required this.satisfaction,
    required this.monthlyRevenueSeries,
  });

  factory QuickAnalysisModel.fromJson(Map<String, dynamic> json) {
    return QuickAnalysisModel(
      confirmationRate:
          json['confirmation_rate'] is num ? json['confirmation_rate'] : 0,
      monthlyBookings:
          json['monthly_bookings'] is int ? json['monthly_bookings'] : 0,
      totalBookings: json['total_bookings'] is int ? json['total_bookings'] : 0,
      cancelledThisMonth: json['cancelled_this_month'] is int
          ? json['cancelled_this_month']
          : 0,
      satisfaction: json['satisfaction'] is num ? json['satisfaction'] : 0,
      monthlyRevenueSeries:
          (json['monthly_revenue_series'] as List? ?? [])
              .map(
                (item) => MonthlyRevenuePointModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(),
    );
  }
}

/// Punto mensual para el mini gráfico de ingresos.
class MonthlyRevenuePointModel {
  final String month;
  final String label;
  final num amount;
  final String formatted;

  MonthlyRevenuePointModel({
    required this.month,
    required this.label,
    required this.amount,
    required this.formatted,
  });

  factory MonthlyRevenuePointModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenuePointModel(
      month: json['month']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      amount: json['amount'] is num ? json['amount'] : 0,
      formatted: json['formatted']?.toString() ?? 'RD\$0.00',
    );
  }
}