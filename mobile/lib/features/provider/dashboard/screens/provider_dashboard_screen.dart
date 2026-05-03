import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../models/provider_dashboard_model.dart';
import '../services/provider_dashboard_service.dart';
import '../../../../core/router/route_names.dart';

/// Pantalla principal del dashboard del afiliado.
///
/// No usa data quemada.
/// Toda la información viene desde GET /api/provider/dashboard.
class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({
    super.key,
    required this.authController,
  });

  /// Controlador global de autenticación.
  ///
  /// De aquí tomamos el token que ya fue guardado en SecureStorage
  /// por AuthController.saveSession().
  final AuthController authController;

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final ProviderDashboardService _service = ProviderDashboardService();

  late Future<ProviderDashboardModel> _dashboardFuture;

  @override
  void initState() {
    super.initState();

    // Carga inicial del dashboard usando el token real de AuthController.
    _dashboardFuture = _service.getDashboard(
      token: widget.authController.token,
    );
  }

  /// Recarga la información desde la base de datos.
  Future<void> _refreshDashboard() async {
    setState(() {
      _dashboardFuture = _service.getDashboard(
        token: widget.authController.token,
      );
    });

    await _dashboardFuture;
  }

  /// Navegación centralizada usando go_router.
  ///
  /// No usamos Navigator.pushNamed porque esta app está montada con
  /// MaterialApp.router + GoRouter.
  void _goTo(String path) {
    context.go(path);
  }

  void _goToNamed(String name) {
    context.goNamed(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _DashboardColors.background,
      body: SafeArea(
        child: FutureBuilder<ProviderDashboardModel>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _DashboardLoading();
            }

            if (snapshot.hasError) {
              return _DashboardError(
                message: snapshot.error.toString(),
                onRetry: _refreshDashboard,
              );
            }

            final dashboard = snapshot.data;

            if (dashboard == null) {
              return _DashboardError(
                message: 'No se pudo cargar la información del dashboard.',
                onRetry: _refreshDashboard,
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _HeaderSection(
                    dashboard: dashboard,
                    onProfileTap: () => _goToNamed(RouteNames.providerProfile),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_shouldShowStatusWarning(dashboard.providerStatus))
                          _ProviderStatusWarning(
                            status: dashboard.providerStatus ?? 'pending',
                          ),

                        const SizedBox(height: 16),

                        _ActionButtons(
                          onCreateExperience: () =>
                              _goToNamed(RouteNames.providerCreateExperience),
                          onCatalog: () => _goToNamed(RouteNames.providerCatalog),
                        ),

                        const SizedBox(height: 28),

                        _UpcomingBookingsSection(
                          bookings: dashboard.upcomingBookings,
                          onViewAll: () => _goToNamed(RouteNames.providerBookings),
                        ),

                        const SizedBox(height: 28),

                        _QuickAnalysisSection(
                          analysis: dashboard.quickAnalysis,
                          onViewMore: () => _goToNamed(RouteNames.providerAnalytics),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _ProviderBottomNav(
        onDashboard: () {},
        onCatalog: () => _goToNamed(RouteNames.providerCatalog),
        onMessages: () => _goToNamed(RouteNames.providerMessages),
        onProfile: () => _goToNamed(RouteNames.providerProfile),
      ),
    );
  }

  /// Muestra una alerta si el afiliado todavía no está aprobado/activo.
  bool _shouldShowStatusWarning(String? status) {
    if (status == null) return false;

    return status != 'approved' && status != 'active';
  }
}

/// Header superior con saludo y tarjetas de métricas.
class _HeaderSection extends StatelessWidget {
  final ProviderDashboardModel dashboard;
  final VoidCallback onProfileTap;

  const _HeaderSection({
    required this.dashboard,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // En caso de que tengas logo asset, puedes reemplazar este texto
              // por Image.asset('assets/images/andando_logo.png').
              Image.asset(
                'assets/images/logos/andando_logo.png',
                width: 140,
                fit: BoxFit.contain,

                /// Si por alguna razón el asset falla,
                /// mostramos un fallback de texto para no romper la UI.
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'AndanDO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _DashboardColors.primary,
                    ),
                  );
                },
              ),
              const Spacer(),

              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _DashboardColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: _DashboardColors.primary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Text(
            'Bienvenido de vuelta, ${dashboard.affiliateName}',
            style: const TextStyle(
              color: _DashboardColors.mutedText,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 22),

          _StatsGrid(stats: dashboard.stats),
        ],
      ),
    );
  }
}

/// Grid de las cuatro métricas principales.
class _StatsGrid extends StatelessWidget {
  final ProviderDashboardStats stats;

  const _StatsGrid({
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.32,
      children: [
        _StatCard(
          title: 'Ganancia del mes',
          value: stats.monthlyEarnings.formatted,
          changeLabel: stats.monthlyEarnings.changeLabel,
          icon: Icons.attach_money,
          iconBackground: const Color(0xFFE8F8EF),
          iconColor: const Color(0xFF15803D),
        ),
        _StatCard(
          title: 'Reservas activas',
          value: stats.activeBookings.formatted,
          changeLabel: stats.activeBookings.changeLabel,
          icon: Icons.calendar_month_outlined,
          iconBackground: const Color(0xFFEFF6FF),
          iconColor: const Color(0xFF1D4ED8),
        ),
        _StatCard(
          title: 'Experiencias publicadas',
          value: stats.publishedExperiences.formatted,
          changeLabel: stats.publishedExperiences.changeLabel,
          icon: Icons.explore_outlined,
          iconBackground: const Color(0xFFF5F3FF),
          iconColor: const Color(0xFF7C3AED),
        ),
        _StatCard(
          title: 'Rating promedio',
          value: stats.averageRating.formatted,
          changeLabel: stats.averageRating.changeLabel,
          icon: Icons.star_outline,
          iconBackground: const Color(0xFFFEF9C3),
          iconColor: const Color(0xFFA16207),
        ),
      ],
    );
  }
}

/// Tarjeta visual de una métrica.
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String changeLabel;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.changeLabel,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _DashboardColors.primary.withValues(alpha: 0.05),
            _DashboardColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _DashboardColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const Spacer(),
              Text(
                changeLabel,
                style: const TextStyle(
                  color: Color(0xFF15803D),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const Spacer(),

          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _DashboardColors.text,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: _DashboardColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botones principales de acción.
class _ActionButtons extends StatelessWidget {
  final VoidCallback onCreateExperience;
  final VoidCallback onCatalog;

  const _ActionButtons({
    required this.onCreateExperience,
    required this.onCatalog,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DashboardActionButton(
            label: 'Nueva Experiencia',
            icon: Icons.add,
            background: _DashboardColors.primary,
            foreground: Colors.white,
            onTap: onCreateExperience,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DashboardActionButton(
            label: 'Mi Catálogo',
            icon: Icons.calendar_month_outlined,
            background: Colors.white,
            foreground: _DashboardColors.primary,
            borderColor: _DashboardColors.primary,
            onTap: onCatalog,
          ),
        ),
      ],
    );
  }
}

/// Botón grande reusable.
class _DashboardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onTap;

  const _DashboardActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: borderColor == null
                ? null
                : Border.all(
                    color: borderColor!,
                    width: 1.5,
                  ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: foreground,
                size: 30,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sección de próximas reservas.
class _UpcomingBookingsSection extends StatelessWidget {
  final List<UpcomingBookingModel> bookings;
  final VoidCallback onViewAll;

  const _UpcomingBookingsSection({
    required this.bookings,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          title: 'Próximas Reservas',
          actionLabel: 'Ver todas',
          onAction: onViewAll,
        ),

        const SizedBox(height: 12),

        if (bookings.isEmpty)
          const _EmptyStateCard(
            icon: Icons.event_busy_outlined,
            title: 'No tienes reservas próximas',
            message:
                'Cuando un cliente reserve una experiencia, aparecerá aquí.',
          )
        else
          Column(
            children: bookings
                .map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _BookingCard(booking: booking),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

/// Tarjeta individual de reserva.
class _BookingCard extends StatelessWidget {
  final UpcomingBookingModel booking;

  const _BookingCard({
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final bool isConfirmed = booking.status == 'confirmed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _DashboardColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.tour,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _DashboardColors.text,
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _SmallInfo(
                      icon: Icons.calendar_month_outlined,
                      label: booking.dateLabel,
                    ),
                    _SmallInfo(
                      icon: Icons.group_outlined,
                      label: '${booking.guests} personas',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isConfirmed
                  ? const Color(0xFFE8F8EF)
                  : const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              booking.statusLabel,
              style: TextStyle(
                color: isConfirmed
                    ? const Color(0xFF15803D)
                    : const Color(0xFFA16207),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Texto pequeño con icono.
class _SmallInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallInfo({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: _DashboardColors.mutedText,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: _DashboardColors.mutedText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Bloque de análisis rápido.
class _QuickAnalysisSection extends StatelessWidget {
  final QuickAnalysisModel analysis;
  final VoidCallback onViewMore;

  const _QuickAnalysisSection({
    required this.analysis,
    required this.onViewMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _DashboardColors.border),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          _SectionHeader(
            title: 'Análisis Rápido',
            actionLabel: 'Ver más',
            onAction: onViewMore,
          ),

          const SizedBox(height: 18),

          _MiniRevenueChart(points: analysis.monthlyRevenueSeries),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _AnalysisItem(
                  value: '${analysis.confirmationRate}%',
                  label: 'Tasa confirmación',
                ),
              ),
              Expanded(
                child: _AnalysisItem(
                  value: analysis.totalBookings.toString(),
                  label: 'Total reservas',
                ),
              ),
              Expanded(
                child: _AnalysisItem(
                  value: analysis.satisfaction.toString(),
                  label: 'Satisfacción',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mini gráfico de ingresos usando barras.
/// No usa datos falsos; si no hay ingresos, muestra estado vacío.
class _MiniRevenueChart extends StatelessWidget {
  final List<MonthlyRevenuePointModel> points;

  const _MiniRevenueChart({
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = points.any((point) => point.amount > 0);

    if (points.isEmpty || !hasData) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: _DashboardColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 52,
                color: _DashboardColors.primarySoft,
              ),
              SizedBox(height: 8),
              Text(
                'Sin ingresos registrados todavía',
                style: TextStyle(
                  color: _DashboardColors.mutedText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxAmount = points
        .map((point) => point.amount)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      decoration: BoxDecoration(
        color: _DashboardColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final barHeight = maxAmount == 0
              ? 0.0
              : ((point.amount.toDouble() / maxAmount) * 92).clamp(8.0, 92.0);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 18,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: _DashboardColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  point.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _DashboardColors.mutedText,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Item numérico del análisis rápido.
class _AnalysisItem extends StatelessWidget {
  final String value;
  final String label;

  const _AnalysisItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _DashboardColors.primary,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _DashboardColors.mutedText,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// Header reusable de secciones.
class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _DashboardColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

/// Estado vacío reusable.
class _EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _DashboardColors.border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 42,
            color: _DashboardColors.primarySoft,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _DashboardColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _DashboardColors.mutedText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

/// Alerta para afiliado pendiente/no aprobado.
class _ProviderStatusWarning extends StatelessWidget {
  final String status;

  const _ProviderStatusWarning({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFFA16207),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu cuenta de afiliado está en estado "$status". Algunas funciones pueden estar limitadas hasta ser aprobada.',
              style: const TextStyle(
                color: Color(0xFF854D0E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom nav del flujo de afiliado.
class _ProviderBottomNav extends StatelessWidget {
  final VoidCallback onDashboard;
  final VoidCallback onCatalog;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  const _ProviderBottomNav({
    required this.onDashboard,
    required this.onCatalog,
    required this.onMessages,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _DashboardColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _BottomNavItem(
                label: 'Dashboard',
                icon: Icons.trending_up,
                isActive: true,
                onTap: onDashboard,
              ),
              _BottomNavItem(
                label: 'Catálogo',
                icon: Icons.calendar_month_outlined,
                onTap: onCatalog,
              ),
              _BottomNavItem(
                label: 'Mensajes',
                icon: Icons.chat_bubble_outline,
                showDot: true,
                onTap: onMessages,
              ),
              _BottomNavItem(
                label: 'Perfil',
                icon: Icons.person_outline,
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item individual del bottom nav.
class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? _DashboardColors.primary : _DashboardColors.mutedText;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (showDot)
              Positioned(
                top: 0,
                right: 28,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _DashboardColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Loading inicial.
class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _DashboardColors.primary,
      ),
    );
  }
}

/// Error con botón de reintento.
class _DashboardError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: _DashboardColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _DashboardColors.text,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _DashboardColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colores locales de la pantalla del dashboard.
///
/// Aquí usamos el azul principal de la app para que:
/// - navbar
/// - botones
/// - KPIs
/// - gráfico
/// mantengan consistencia visual con el resto del proyecto.
class _DashboardColors {
  static const Color primary = AppColors.primaryBlue;

  /// Versión suave/transparente del azul principal.
  static const Color primarySoft = Color(0x661D4ED8);

  /// Podemos mantener secondary igual o ajustarlo después
  /// si quieres más contraste en otras secciones.
  static const Color secondary = AppColors.primaryBlue;

  static const Color background = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}