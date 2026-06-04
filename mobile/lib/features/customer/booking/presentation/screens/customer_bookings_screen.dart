import 'package:flutter/material.dart';

import '../../../../../core/router/route_names.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/customer_bottom_navigation.dart';
import '../../data/models/customer_booking_model.dart';
import '../controllers/customer_booking_controller.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() => _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  final CustomerBookingController _controller = CustomerBookingController();

  String? _lastOpenedBookingCode;
  bool _isOpeningBookingFromQuery = false;

  int selectedTab = 0;

  @override
  void initState() {
    super.initState();

    _controller.initialize().then((_) {
      _openBookingFromQueryIfNeeded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _openBookingFromQueryIfNeeded();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<CustomerBookingModel> get _visibleBookings {
    return selectedTab == 0
        ? _controller.upcomingBookings
        : _controller.completedBookings;
  }

  void _openBookingDetails(CustomerBookingModel booking) {
    showDialog<void>(
      context: context,
      builder: (_) => _BookingDetailsDialog(
        booking: booking,
        onCancelBooking: () async {
          Navigator.of(context).pop();
          await _confirmCancelBooking(booking);
        },
      ),
    );
  }

  Future<void> _openReviewScreen(CustomerBookingModel booking) async {
    await _controller.loadBookings();

    if (!mounted) return;

    final freshBooking = _controller.bookings.firstWhere(
      (item) => item.id == booking.id,
      orElse: () => booking,
    );

    final edited = await context.push<bool>(
      '/client/bookings/${freshBooking.id}/review',
      extra: freshBooking,
    );

    if (!mounted) return;

    if (edited == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            freshBooking.hasReview
                ? 'Reseña actualizada correctamente.'
                : 'Reseña publicada correctamente.',
          ),
        ),
      );

      await _controller.loadBookings();
    }
  }

  Future<void> _confirmCancelBooking(CustomerBookingModel booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancelar reserva'),
          content: Text(
            '¿Seguro que quieres cancelar la reserva ${booking.bookingCode}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final success = await _controller.cancelBooking(booking.id);

    if (!mounted) return;

    if (success) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: const Text('Reserva cancelada'),
            content: Text(
              'La reserva ${booking.bookingCode} fue cancelada correctamente.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
            ],
          );
        },
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ?? 'No se pudo cancelar la reserva.',
        ),
      ),
    );
  }

  Future<void> _openBookingFromQueryIfNeeded() async {
    if (!mounted || _isOpeningBookingFromQuery) return;

    final bookingCode =
        GoRouterState.of(context).uri.queryParameters['bookingCode'];

    if (bookingCode == null || bookingCode.trim().isEmpty) {
      return;
    }

    if (_lastOpenedBookingCode == bookingCode) {
      return;
    }

    _isOpeningBookingFromQuery = true;

    await _controller.loadBookings();

    if (!mounted) return;

    final allBookings = [
      ..._controller.upcomingBookings,
      ..._controller.completedBookings,
    ];

    final matches = allBookings.where(
      (booking) => booking.bookingCode == bookingCode,
    );

    if (matches.isEmpty) {
      _isOpeningBookingFromQuery = false;
      return;
    }

    final booking = matches.first;

    setState(() {
      selectedTab = booking.isCompleted ? 1 : 0;
      _lastOpenedBookingCode = bookingCode;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _isOpeningBookingFromQuery = false;
      _openBookingDetails(booking);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _controller.loadBookings,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverToBoxAdapter(child: _BookingsHeader()),
                  SliverToBoxAdapter(
                    child: _BookingTabs(
                      selectedTab: selectedTab,
                      upcomingCount: _controller.upcomingBookings.length,
                      completedCount: _controller.completedBookings.length,
                      onChanged: (value) {
                        setState(() => selectedTab = value);
                      },
                    ),
                  ),
                  if (_controller.isLoading)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_controller.errorMessage != null)
                    SliverFillRemaining(
                      child: _BookingErrorState(
                        message: _controller.errorMessage!,
                        onRetry: _controller.loadBookings,
                      ),
                    )
                  else if (_visibleBookings.isEmpty)
                    SliverFillRemaining(
                      child: _BookingEmptyState(
                        isUpcomingTab: selectedTab == 0,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      sliver: SliverList.separated(
                        itemCount: _visibleBookings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final booking = _visibleBookings[index];

                          return _BookingCard(
                            booking: booking,
                            isCompletedTab: selectedTab == 1,
                            onDetailsTap: () => _openBookingDetails(booking),
                            onReviewTap: () => _openReviewScreen(booking),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: const CustomerBottomNavigation(
            currentItem: CustomerBottomNavItem.bookings,
          ),
        );
      },
    );
  }
}

class _BookingsHeader extends StatelessWidget {
  const _BookingsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mis Reservas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gestiona tus próximas aventuras',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingTabs extends StatelessWidget {
  final int selectedTab;
  final int upcomingCount;
  final int completedCount;
  final ValueChanged<int> onChanged;

  const _BookingTabs({
    required this.selectedTab,
    required this.upcomingCount,
    required this.completedCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TabButton(
                title: 'Próximas',
                count: upcomingCount,
                isSelected: selectedTab == 0,
                onTap: () => onChanged(0),
              ),
            ),
            Expanded(
              child: _TabButton(
                title: 'Completadas',
                count: completedCount,
                isSelected: selectedTab == 1,
                onTap: () => onChanged(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isSelected ? Colors.white : const Color(0xFF374151);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF003B73) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.18)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final CustomerBookingModel booking;
  final bool isCompletedTab;
  final VoidCallback onDetailsTap;
  final VoidCallback onReviewTap;

  const _BookingCard({
    required this.booking,
    required this.isCompletedTab,
    required this.onDetailsTap,
    required this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        booking.coverPhotoUrl != null && booking.coverPhotoUrl!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 168,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: hasImage
                      ? Image.network(
                          booking.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _BookingImagePlaceholder(),
                        )
                      : const _BookingImagePlaceholder(),
                ),
                if (isCompletedTab)
                  Positioned(
                    top: 14,
                    right: 14,
                    child: _StatusBadge(status: booking.status),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código: ${booking.bookingCode}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  booking.experienceTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: booking.displayLocation,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfo(
                        icon: Icons.calendar_month_outlined,
                        label: 'Fecha',
                        value: booking.formattedDate,
                      ),
                    ),
                    Expanded(
                      child: _MiniInfo(
                        icon: Icons.access_time_rounded,
                        label: 'Hora',
                        value: booking.formattedTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MiniInfo(
                        icon: Icons.people_alt_outlined,
                        label: 'Viajeros',
                        value: booking.guestsCount == 1
                            ? '1 persona'
                            : '${booking.guestsCount} personas',
                      ),
                    ),
                    Expanded(
                      child: _MiniInfo(
                        icon: Icons.place_outlined,
                        label: 'Recogida',
                        value: booking.pickupPoint?.trim().isNotEmpty == true
                            ? booking.pickupPoint!
                            : 'No especificada',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total pagado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            booking.formattedTotalAmount,
                            style: const TextStyle(
                              fontSize: 19,
                              color: Color(0xFF003B73),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onDetailsTap,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        size: 21,
                      ),
                      label: const Text(
                        'Ver detalles',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF003B73),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isCompletedTab
                          ? onReviewTap
                          : () {},
                        icon: Icon(
                          isCompletedTab
                              ? booking.hasReview
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.star_border_rounded
                              : Icons.download_rounded,
                          size: 18,
                        ),
                        label: Text(
                          isCompletedTab
                              ? booking.hasReview
                                  ? 'Editar reseña'
                                  : 'Calificar experiencia'
                              : 'Descargar',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompletedTab && booking.hasReview
                              ? const Color(0xFFE5E7EB)
                              : const Color(0xFF003B73),
                          foregroundColor: isCompletedTab && booking.hasReview
                              ? const Color(0xFF374151)
                              : Colors.white,
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          if (isCompletedTab) {
                            context.push('/experiences/${booking.experienceId}');
                          }
                        },
                        icon: Icon(
                          isCompletedTab
                              ? Icons.refresh_rounded
                              : Icons.chat_bubble_outline_rounded,
                          size: 17,
                        ),
                        label: Text(
                          isCompletedTab ? 'Reservar otra vez' : 'Contactar',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF111827),
                          side: BorderSide.none,
                          backgroundColor: const Color(0xFFF3F4F6),
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingDetailsDialog extends StatelessWidget {
  final CustomerBookingModel booking;
  final Future<void> Function() onCancelBooking;

  const _BookingDetailsDialog({
    required this.booking,
    required this.onCancelBooking,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage =
        booking.coverPhotoUrl != null && booking.coverPhotoUrl!.trim().isNotEmpty;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 14, 14),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Detalles de la Reserva',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BookingCodeBox(bookingCode: booking.bookingCode),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 190,
                          width: double.infinity,
                          child: hasImage
                              ? Image.network(
                                  booking.coverPhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const _BookingImagePlaceholder(),
                                )
                              : const _BookingImagePlaceholder(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        booking.experienceTitle,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        text: booking.displayLocation,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(label: 'Fecha', value: booking.formattedDate),
                            _DetailRow(label: 'Hora de inicio', value: booking.formattedTime),
                            _DetailRow(
                              label: 'Duración',
                              value: booking.displayDuration,
                            ),
                            _DetailRow(
                              label: 'Viajeros',
                              value: booking.guestsCount == 1
                                  ? '1 persona'
                                  : '${booking.guestsCount} personas',
                            ),
                            _DetailRow(
                              label: 'Punto de recogida',
                              value: booking.pickupPoint?.trim().isNotEmpty == true
                                  ? booking.pickupPoint!
                                  : 'No especificado',
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'Desglose de precios',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PriceRow(
                        label: 'Subtotal',
                        value: booking.formattedTotalAmount,
                      ),
                      const Divider(height: 28),
                      _PriceRow(
                        label: 'Total',
                        value: booking.formattedTotalAmount,
                        isTotal: true,
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFF2563EB),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Presenta este código de reserva el día de tu actividad. Asegúrate de llegar al punto de encuentro 15 minutos antes.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Descargar Comprobante'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003B73),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      if (!booking.isCompleted && booking.status.toLowerCase() != 'cancelled') ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () async {
                              await onCancelBooking();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFDE2E6),
                              foregroundColor: const Color(0xFFDC2626),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            child: const Text('Cancelar Reserva'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingCodeBox extends StatelessWidget {
  final String bookingCode;

  const _BookingCodeBox({
    required this.bookingCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Código de reserva',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            bookingCode,
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF003B73),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
              color: const Color(0xFF334155),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 21 : 15,
            fontWeight: FontWeight.w900,
            color: isTotal ? const Color(0xFF003B73) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF6B7280)),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6B7280),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();

    final label = switch (normalized) {
      'confirmed' => 'Confirmada',
      'completed' => 'Completada',
      'cancelled' => 'Cancelada',
      'pending' => 'Pendiente',
      _ => status,
    };

    final backgroundColor = switch (normalized) {
      'confirmed' => const Color(0xFFDCFCE7),
      'completed' => const Color(0xFFE0F2FE),
      'cancelled' => const Color(0xFFFEE2E2),
      'pending' => const Color(0xFFFEF3C7),
      _ => const Color(0xFFF3F4F6),
    };

    final textColor = switch (normalized) {
      'confirmed' => const Color(0xFF166534),
      'completed' => const Color(0xFF075985),
      'cancelled' => const Color(0xFF991B1B),
      'pending' => const Color(0xFF92400E),
      _ => const Color(0xFF374151),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingImagePlaceholder extends StatelessWidget {
  const _BookingImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(
          Icons.calendar_month_outlined,
          size: 54,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _BookingEmptyState extends StatelessWidget {
  final bool isUpcomingTab;

  const _BookingEmptyState({
    required this.isUpcomingTab,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUpcomingTab
                  ? Icons.calendar_month_outlined
                  : Icons.check_circle_outline_rounded,
              size: 58,
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 14),
            Text(
              isUpcomingTab
                  ? 'No tienes reservas próximas'
                  : 'No tienes reservas completadas',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isUpcomingTab
                  ? 'Cuando reserves una experiencia, aparecerá aquí.'
                  : 'Cuando completes experiencias, aparecerán aquí.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _BookingErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 58,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 14),
            const Text(
              'No pudimos cargar tus reservas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

