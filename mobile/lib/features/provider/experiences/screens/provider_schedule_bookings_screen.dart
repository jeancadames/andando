import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../auth/application/auth_controller.dart';
import '../models/provider_schedule_bookings_response.dart';
import '../services/provider_experience_service.dart';

class ProviderScheduleBookingsScreen extends StatefulWidget {
  final AuthController authController;
  final int experienceId;
  final int scheduleId;

  const ProviderScheduleBookingsScreen({
    super.key,
    required this.authController,
    required this.experienceId,
    required this.scheduleId,
  });

  @override
  State<ProviderScheduleBookingsScreen> createState() =>
      _ProviderScheduleBookingsScreenState();
}

class _ProviderScheduleBookingsScreenState
    extends State<ProviderScheduleBookingsScreen> {
  final ProviderExperienceService _service = ProviderExperienceService();

  bool _isLoading = true;
  String? _error;
  ProviderScheduleBookingsResponse? _response;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getScheduleBookings(
        experienceId: widget.experienceId,
        scheduleId: widget.scheduleId,
        token: widget.authController.token,
      );

      if (!mounted) return;

      setState(() {
        _response = response;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = _BookingsColors.primary;

    return Scaffold(
      backgroundColor: _BookingsColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
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
                  color: primary,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Reservas de la fecha',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _loadBookings,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: _BookingsColors.primary,
        ),
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 56,
          ),
          const SizedBox(height: 16),
          Text(
            _error!.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _BookingsColors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _loadBookings,
            style: FilledButton.styleFrom(
              backgroundColor: _BookingsColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    final response = _response;

    if (response == null) {
      return const SizedBox.shrink();
    }

    final bookings = response.bookings;
    final startsAt = DateTime.tryParse(response.schedule.startsAt);

    if (bookings.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        children: [
          _ScheduleHero(
            title: response.schedule.experienceTitle,
            startsAt: startsAt,
            totalBookings: response.totalBookings,
            totalTravelers: response.totalTravelers,
          ),
          const SizedBox(height: 70),
          Container(
            width: 92,
            height: 92,
            margin: const EdgeInsets.symmetric(horizontal: 110),
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_2_outlined,
              size: 48,
              color: _BookingsColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No hay reservas para esta fecha',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _BookingsColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando un cliente reserve esta salida, aparecerá en este listado.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _BookingsColors.mutedText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
      children: [
        _ScheduleHero(
          title: response.schedule.experienceTitle,
          startsAt: startsAt,
          totalBookings: response.totalBookings,
          totalTravelers: response.totalTravelers,
        ),
        const SizedBox(height: 18),
        const _BookingsTableHeader(),
        const SizedBox(height: 10),
        ...bookings.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final booking = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BookingCard(
                index: index + 1,
                booking: booking,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        _TotalFooter(
          totalTravelers: response.totalTravelers,
          totalBookings: response.totalBookings,
        ),
      ],
    );
  }
}

class _ScheduleHero extends StatelessWidget {
  final String title;
  final DateTime? startsAt;
  final int totalBookings;
  final int totalTravelers;

  const _ScheduleHero({
    required this.title,
    required this.startsAt,
    required this.totalBookings,
    required this.totalTravelers,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = startsAt == null
        ? 'Fecha no disponible'
        : DateFormat('EEEE d MMMM yyyy').format(startsAt!);

    final timeText = startsAt == null
        ? '-'
        : DateFormat('hh:mm a').format(startsAt!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _BookingsColors.primary,
            Color(0xFF0756A5),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _BookingsColors.primary.withValues(alpha: 0.22),
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
                Icons.confirmation_number_outlined,
                color: Colors.white,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Listado de reservas',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            title.isEmpty ? 'Experiencia' : title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.access_time,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                timeText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: 'Reservas',
                  value: totalBookings.toString(),
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Personas',
                  value: totalTravelers.toString(),
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

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsTableHeader extends StatelessWidget {
  const _BookingsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _BookingsColors.border,
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(
                  Icons.badge_outlined,
                  size: 17,
                  color: _BookingsColors.mutedText,
                ),
                SizedBox(width: 7),
                Text(
                  'Reserva / Cliente',
                  style: TextStyle(
                    color: _BookingsColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Personas',
            style: TextStyle(
              color: _BookingsColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final int index;
  final ProviderScheduleBooking booking;

  const _BookingCard({
    required this.index,
    required this.booking,
  });

  @override
  Widget build(BuildContext context) {
    final code = booking.bookingCode.isEmpty
        ? 'Sin código'
        : booking.bookingCode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _BookingsColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              index.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: _BookingsColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _BookingsColors.text,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  booking.clientName.isEmpty
                      ? 'Cliente sin nombre'
                      : booking.clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _BookingsColors.mutedText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _BookingsColors.border),
            ),
            child: Text(
              booking.guestsCount.toString(),
              style: const TextStyle(
                color: _BookingsColors.primary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalFooter extends StatelessWidget {
  final int totalTravelers;
  final int totalBookings;

  const _TotalFooter({
    required this.totalTravelers,
    required this.totalBookings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.summarize_outlined,
            color: _BookingsColors.primary,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$totalBookings reservas registradas',
              style: const TextStyle(
                color: _BookingsColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '$totalTravelers personas',
            style: const TextStyle(
              color: _BookingsColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsColors {
  static const Color primary = Color(0xFF003A78);
  static const Color background = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}