import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../dashboard/models/provider_dashboard_model.dart';
import '../../dashboard/services/provider_dashboard_service.dart';
import '../../experiences/screens/provider_schedule_bookings_screen.dart';

class ProviderBookingsScreen extends StatefulWidget {
  final AuthController authController;

  const ProviderBookingsScreen({
    super.key,
    required this.authController,
  });

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen> {
  final ProviderDashboardService _service = ProviderDashboardService();

  late Future<ProviderUpcomingBookingsResponse> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getUpcomingBookings(
      token: widget.authController.token,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.getUpcomingBookings(
        token: widget.authController.token,
      );
    });

    await _future;
  }

  void _goBack() {
    context.goNamed(RouteNames.providerDashboard);
  }

  Future<void> _openDetails(UpcomingBookingModel booking) async {
    if (booking.providerExperienceId <= 0 ||
        booking.providerExperienceScheduleId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el detalle de esta reserva.'),
        ),
      );

      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderScheduleBookingsScreen(
          authController: widget.authController,
          experienceId: booking.providerExperienceId,
          scheduleId: booking.providerExperienceScheduleId,
        ),
      ),
    );

    if (!mounted) return;

    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _BookingsListColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: _goBack,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: _BookingsListColors.primary,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Próximas reservas',
          style: TextStyle(
            color: _BookingsListColors.primary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<ProviderUpcomingBookingsResponse>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: _BookingsListColors.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final response = snapshot.data;

          if (response == null) {
            return _ErrorState(
              message: 'No se pudieron cargar las próximas reservas.',
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            color: _BookingsListColors.primary,
            onRefresh: _refresh,
            child: response.bookings.isEmpty
                ? _EmptyBookingsList()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                    children: [
                      _SummaryHero(response: response),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Salidas próximas',
                              style: TextStyle(
                                color: _BookingsListColors.text,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '${response.totalGroups}',
                            style: const TextStyle(
                              color: _BookingsListColors.mutedText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...response.bookings.map(
                        (booking) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _UpcomingBookingCard(
                              booking: booking,
                              onDetails: () => _openDetails(booking),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _SummaryHero extends StatelessWidget {
  final ProviderUpcomingBookingsResponse response;

  const _SummaryHero({
    required this.response,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _BookingsListColors.primary,
            Color(0xFF0756A5),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _BookingsListColors.primary.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Resumen de próximas salidas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Reservas agrupadas por experiencia y fecha',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Salidas',
                  value: response.totalGroups.toString(),
                  icon: Icons.event_available_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Reservas',
                  value: response.totalBookings.toString(),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMetric(
                  label: 'Personas',
                  value: response.totalTravelers.toString(),
                  icon: Icons.groups_2_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  final UpcomingBookingModel booking;
  final VoidCallback onDetails;

  const _UpcomingBookingCard({
    required this.booking,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isConfirmed = booking.status == 'confirmed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _BookingsListColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.tour_outlined,
                  color: _BookingsListColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.tour,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _BookingsListColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 7,
                      children: [
                        _InfoPill(
                          icon: Icons.calendar_month_outlined,
                          label: booking.dateLabel,
                        ),
                        _InfoPill(
                          icon: Icons.receipt_long_outlined,
                          label: booking.bookingsCount == 1
                              ? '1 reserva'
                              : '${booking.bookingsCount} reservas',
                        ),
                        _InfoPill(
                          icon: Icons.groups_2_outlined,
                          label: booking.guests == 1
                              ? '1 persona'
                              : '${booking.guests} personas',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusBadge(
                label: booking.statusLabel,
                isConfirmed: isConfirmed,
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: onDetails,
              style: FilledButton.styleFrom(
                backgroundColor: _BookingsListColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text(
                'Ver detalles',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
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
          color: _BookingsListColors.mutedText,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: _BookingsListColors.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isConfirmed;

  const _StatusBadge({
    required this.label,
    required this.isConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isConfirmed
            ? const Color(0xFFE8F8EF)
            : const Color(0xFFFEF9C3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isConfirmed
              ? const Color(0xFF15803D)
              : const Color(0xFFA16207),
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyBookingsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        Container(
          width: 88,
          height: 88,
          margin: const EdgeInsets.symmetric(horizontal: 110),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.event_busy_outlined,
            size: 45,
            color: _BookingsListColors.primary,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'No tienes reservas próximas',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _BookingsListColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cuando tus experiencias reciban reservas futuras, aparecerán aquí agrupadas por fecha.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _BookingsListColors.mutedText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
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
              color: _BookingsListColors.primary,
              size: 54,
            ),
            const SizedBox(height: 14),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _BookingsListColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _BookingsListColors.primary,
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

class _BookingsListColors {
  static const Color primary = AppColors.primaryBlue;
  static const Color background = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}