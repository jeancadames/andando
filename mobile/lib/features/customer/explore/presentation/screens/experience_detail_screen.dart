import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/customer_experience_model.dart';
import '../../../reservations/data/datasources/customer_booking_remote_datasource.dart';

class ExperienceDetailScreen extends StatefulWidget {
  final CustomerExperienceModel experience;
  final bool initialIsFavorite;
  final ValueChanged<bool> onFavoriteChanged;

  const ExperienceDetailScreen({
    super.key,
    required this.experience,
    required this.initialIsFavorite,
    required this.onFavoriteChanged,
  });

  @override
  State<ExperienceDetailScreen> createState() => _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState extends State<ExperienceDetailScreen> {
  late bool isFavorite;

  int travelers = 1;
  bool isReserving = false;

  CustomerExperienceScheduleModel? selectedSchedule;
  late List<CustomerExperienceScheduleModel> _availableSchedules;

  late final TextEditingController _travelersController;
  late final CustomerBookingRemoteDataSource _bookingDataSource;

  List<CustomerExperienceScheduleModel> get availableSchedules {
    return _availableSchedules;
  }

  int get maxTravelers {
    if (selectedSchedule != null) {
      return selectedSchedule!.availableSpots;
    }

    if (widget.experience.capacity > 0) {
      return widget.experience.capacity;
    }

    return 20;
  }

  bool get canReserve {
    return selectedSchedule != null &&
        travelers >= 1 &&
        travelers <= maxTravelers &&
        !isReserving;
  }

  double get unitPrice {
    return selectedSchedule?.price ?? widget.experience.price;
  }

  String get unitCurrency {
    return selectedSchedule?.currency ?? widget.experience.currency;
  }

  double get totalPrice => unitPrice * travelers;

  String get formattedUnitPrice {
    final formatter = NumberFormat('#,###', 'en_US');
    final formatted = formatter.format(unitPrice);

    if (unitCurrency == 'DOP') {
      return 'RD\$$formatted';
    }

    return '$unitCurrency $formatted';
  }

  String get formattedTotal {
    final formatter = NumberFormat('#,###', 'en_US');
    final formatted = formatter.format(totalPrice);

    if (unitCurrency == 'DOP') {
      return 'RD\$$formatted';
    }

    return '$unitCurrency $formatted';
  }

  String get shareLink {
    final currentHost = Uri.base.origin;

    if (currentHost.contains('andando.app')) {
      return 'https://andando.app/experiences/${widget.experience.id}';
    }

    return '$currentHost/#/experiences/${widget.experience.id}';
  }

  String get shareMessage {
    return 'Mira esta experiencia en AndanDO: ${widget.experience.title}\n$shareLink';
  }

  @override
  void initState() {
    super.initState();

    isFavorite = widget.initialIsFavorite;
    selectedSchedule = null;

    _availableSchedules = List<CustomerExperienceScheduleModel>.from(
      widget.experience.availableSchedules,
    );

    _travelersController = TextEditingController(text: travelers.toString());
    _bookingDataSource = CustomerBookingRemoteDataSource();
  }

  @override
  void dispose() {
    _travelersController.dispose();
    super.dispose();
  }

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    widget.onFavoriteChanged(isFavorite);
  }

  void _updateTravelers(int value) {
    final safeValue = value.clamp(1, maxTravelers);

    setState(() {
      travelers = safeValue;
      _travelersController.text = safeValue.toString();
      _travelersController.selection = TextSelection.fromPosition(
        TextPosition(offset: _travelersController.text.length),
      );
    });
  }

  void _onScheduleChanged(CustomerExperienceScheduleModel? schedule) {
    setState(() {
      selectedSchedule = schedule;

      if (schedule != null && travelers > schedule.availableSpots) {
        travelers = schedule.availableSpots;
        _travelersController.text = travelers.toString();
        _travelersController.selection = TextSelection.fromPosition(
          TextPosition(offset: _travelersController.text.length),
        );
      }
    });
  }

  void _decreaseAvailableSpotsAfterBooking() {
  final schedule = selectedSchedule;

  if (schedule == null) return;

  final newAvailableSpots = schedule.availableSpots - travelers;

  final updatedSchedule = CustomerExperienceScheduleModel(
    id: schedule.id,
    startsAt: schedule.startsAt,
    capacity: schedule.capacity,
    availableSpots: newAvailableSpots,
    price: schedule.price,
    currency: schedule.currency,
  );

  setState(() {
    if (newAvailableSpots <= 0) {
      _availableSchedules = _availableSchedules
          .where((item) => item.id != schedule.id)
          .toList();

      selectedSchedule = null;
      travelers = 1;
    } else {
      _availableSchedules = _availableSchedules.map((item) {
        if (item.id == schedule.id) {
          return updatedSchedule;
        }

        return item;
      }).toList();

      selectedSchedule = updatedSchedule;

      if (travelers > updatedSchedule.availableSpots) {
        travelers = updatedSchedule.availableSpots;
      }
    }

    _travelersController.text = travelers.toString();
    _travelersController.selection = TextSelection.fromPosition(
      TextPosition(offset: _travelersController.text.length),
    );
  });
}

Future<void> _reserveExperience() async {
  if (!canReserve || selectedSchedule == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecciona una fecha y cantidad válida de viajeros.'),
      ),
    );
    return;
  }

  final shouldConfirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return _BookingReviewDialog(
        experienceTitle: widget.experience.title,
        date: selectedSchedule!.formattedDate,
        travelers: travelers,
        duration: widget.experience.displayDuration,
        unitPrice: formattedUnitPrice,
        totalPrice: formattedTotal,
        includedItems: widget.experience.displayAmenities,
      );
    },
  );

  if (shouldConfirm != true) {
    return;
  }

  setState(() {
    isReserving = true;
  });

  try {
    final reservedTotal = formattedTotal;

    final booking = await _bookingDataSource.createBooking(
      scheduleId: selectedSchedule!.id,
      guestsCount: travelers,
    );

    _decreaseAvailableSpotsAfterBooking();

    if (!mounted) return;

    final goToBooking = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _BookingSuccessDialog(
          bookingCode: booking.bookingCode,
          totalPrice: reservedTotal,
        );
      },
    );

    if (goToBooking == true && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        context.go('/client/bookings?bookingCode=${booking.bookingCode}');
      });
    }
  } on CustomerBookingException catch (error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  } catch (_) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo crear la reserva. Inténtalo nuevamente.'),
      ),
    );
  } finally {
    if (!mounted) return;

    setState(() {
      isReserving = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final experience = widget.experience;
    final hasImage = experience.coverPhotoUrl != null &&
        experience.coverPhotoUrl!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      bottomNavigationBar: _BottomBookingBar(
        unitPrice: formattedUnitPrice,
        totalPrice: formattedTotal,
        canReserve: canReserve,
        isLoading: isReserving,
        onReserve: _reserveExperience,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 300,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: hasImage
                        ? Image.network(
                            experience.coverPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _DetailImagePlaceholder(),
                          )
                        : const _DetailImagePlaceholder(),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 14,
                    left: 18,
                    child: _CircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 14,
                    right: 76,
                    child: _CircleButton(
                      icon: isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: isFavorite
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF111827),
                      onTap: _toggleFavorite,
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 14,
                    right: 18,
                    child: _CircleButton(
                      icon: Icons.share_rounded,
                      onTap: _openShareModal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
              child: _MainInfoCard(experience: experience),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 130),
              child: _BookingCard(
                availableSchedules: availableSchedules,
                selectedSchedule: selectedSchedule,
                travelersController: _travelersController,
                travelers: travelers,
                maxTravelers: maxTravelers,
                onScheduleChanged: _onScheduleChanged,
                onMinus: () => _updateTravelers(travelers - 1),
                onPlus: () => _updateTravelers(travelers + 1),
                onTravelersTyped: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed == null) return;
                  _updateTravelers(parsed);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openShareModal() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Compartir experiencia',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ShareOption(
                  icon: Icons.email_outlined,
                  title: 'Compartir por mail',
                  onTap: () async {
                    Navigator.pop(context);
                    await _launchShareUri(
                      Uri(
                        scheme: 'mailto',
                        queryParameters: {
                          'subject': 'Experiencia en AndanDO',
                          'body': shareMessage,
                        },
                      ),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.chat_outlined,
                  title: 'Compartir por WhatsApp',
                  onTap: () async {
                    Navigator.pop(context);
                    final encoded = Uri.encodeComponent(shareMessage);
                    await _launchShareUri(
                      Uri.parse('https://wa.me/?text=$encoded'),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.sms_outlined,
                  title: 'Compartir por Apple Message',
                  onTap: () async {
                    Navigator.pop(context);
                    await _launchShareUri(
                      Uri(
                        scheme: 'sms',
                        queryParameters: {'body': shareMessage},
                      ),
                    );
                  },
                ),
                _ShareOption(
                  icon: Icons.link_rounded,
                  title: 'Copiar link',
                  onTap: () async {
                    Navigator.pop(context);
                    await Clipboard.setData(ClipboardData(text: shareLink));

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link copiado al portapapeles.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchShareUri(Uri uri) async {
    final canOpen = await canLaunchUrl(uri);

    if (!canOpen) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir esta opción para compartir.'),
        ),
      );

      return;
    }

    await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  }
}

class _MainInfoCard extends StatelessWidget {
  final CustomerExperienceModel experience;

  const _MainInfoCard({
    required this.experience,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = experience.displayAmenities;
    final itinerary = experience.displayItinerary;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  experience.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (experience.instantConfirmation)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Instantánea',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  experience.displayLocation,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 22,
                    color: Color(0xFFFACC15),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${experience.rating.toStringAsFixed(1)} (${experience.reviewsCount} reseñas)',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 18,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    experience.displayDuration,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              experience.description?.trim().isNotEmpty == true
                  ? experience.description!
                  : 'Vive una experiencia única diseñada para descubrir lo mejor del destino.',
              style: const TextStyle(
                fontSize: 16,
                height: 1.45,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 18),
          const Text(
            'Incluye:',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 18,
            runSpacing: 12,
            children: amenities
                .map(
                  (item) => _IncludeItem(text: item),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 18),
          const Text(
            'Itinerario:',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 18),
          ...itinerary.map(
            (item) => _ItineraryItem(
              time: item.time,
              text: item.activity,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final List<CustomerExperienceScheduleModel> availableSchedules;
  final CustomerExperienceScheduleModel? selectedSchedule;
  final TextEditingController travelersController;
  final int travelers;
  final int maxTravelers;
  final ValueChanged<CustomerExperienceScheduleModel?> onScheduleChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onTravelersTyped;

  const _BookingCard({
    required this.availableSchedules,
    required this.selectedSchedule,
    required this.travelersController,
    required this.travelers,
    required this.maxTravelers,
    required this.onScheduleChanged,
    required this.onMinus,
    required this.onPlus,
    required this.onTravelersTyped,
  });

  @override
  Widget build(BuildContext context) {
    final hasSchedules = availableSchedules.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reserva tu experiencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fecha disponible',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          if (hasSchedules)
            _ScheduleSelector(
              availableSchedules: availableSchedules,
              selectedSchedule: selectedSchedule,
              onChanged: onScheduleChanged,
            )
          else
            const _NoSchedulesBox(),
          const SizedBox(height: 22),
          const Text(
            'Viajeros',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          _TravelersSelector(
            controller: travelersController,
            travelers: travelers,
            maxTravelers: maxTravelers,
            enabled: hasSchedules && selectedSchedule != null,
            onMinus: onMinus,
            onPlus: onPlus,
            onChanged: onTravelersTyped,
          ),
          const SizedBox(height: 8),
          Text(
            selectedSchedule == null
                ? 'Selecciona una fecha para ver los cupos disponibles.'
                : 'Mínimo 1 persona. Máximo $maxTravelers cupos.',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleSelector extends StatefulWidget {
  final List<CustomerExperienceScheduleModel> availableSchedules;
  final CustomerExperienceScheduleModel? selectedSchedule;
  final ValueChanged<CustomerExperienceScheduleModel?> onChanged;

  const _ScheduleSelector({
    required this.availableSchedules,
    required this.selectedSchedule,
    required this.onChanged,
  });

  @override
  State<_ScheduleSelector> createState() => _ScheduleSelectorState();
}

class _ScheduleSelectorState extends State<_ScheduleSelector> {
  final GlobalKey _fieldKey = GlobalKey();

  Future<void> _openMenu() async {
    final renderBox =
        _fieldKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) return;

    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final fieldOffset = renderBox.localToGlobal(
      Offset.zero,
      ancestor: overlay,
    );

    final fieldSize = renderBox.size;

    final selected = await showMenu<CustomerExperienceScheduleModel>(
      context: context,
      color: Colors.white,
      elevation: 10,
      constraints: BoxConstraints(
        minWidth: fieldSize.width,
        maxWidth: fieldSize.width,
        maxHeight: 280,
      ),
      position: RelativeRect.fromLTRB(
        fieldOffset.dx,
        fieldOffset.dy + fieldSize.height + 6,
        overlay.size.width - fieldOffset.dx - fieldSize.width,
        0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      items: widget.availableSchedules.map((schedule) {
        return PopupMenuItem<CustomerExperienceScheduleModel>(
          value: schedule,
          height: 58,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  schedule.formattedDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              Text(
                schedule.availableSpots == 1
                ? '1 cupo disponible'
                : '${schedule.availableSpots} cupos disponibles',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      widget.onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedSchedule = widget.selectedSchedule != null;

    return InkWell(
      key: _fieldKey,
      onTap: _openMenu,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                hasSelectedSchedule
                    ? '${widget.selectedSchedule!.formattedDate} · ${widget.selectedSchedule!.availableSpots} cupos'
                    : 'Selecciona una fecha',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight:
                      hasSelectedSchedule ? FontWeight.w700 : FontWeight.w500,
                  color: hasSelectedSchedule
                      ? const Color(0xFF111827)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSchedulesBox extends StatelessWidget {
  const _NoSchedulesBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: const Text(
        'Esta experiencia todavía no tiene fechas disponibles para reservar.',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF9A3412),
        ),
      ),
    );
  }
}

class _TravelersSelector extends StatelessWidget {
  final TextEditingController controller;
  final int travelers;
  final int maxTravelers;
  final bool enabled;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onChanged;

  const _TravelersSelector({
    required this.controller,
    required this.travelers,
    required this.maxTravelers,
    required this.enabled,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          _CounterButton(
            icon: Icons.remove_rounded,
            enabled: enabled && travelers > 1,
            onTap: onMinus,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '1',
              ),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
          ),
          _CounterButton(
            icon: Icons.add_rounded,
            enabled: enabled && travelers < maxTravelers,
            onTap: onPlus,
          ),
        ],
      ),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF111827) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }
}

class _BottomBookingBar extends StatelessWidget {
  final String unitPrice;
  final String totalPrice;
  final bool canReserve;
  final bool isLoading;
  final VoidCallback onReserve;

  const _BottomBookingBar({
    required this.unitPrice,
    required this.totalPrice,
    required this.canReserve,
    required this.isLoading,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = canReserve
        ? const Color(0xFF003B73)
        : const Color(0xFFCBD5E1);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.black.withOpacity(0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$unitPrice por persona',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalPrice,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF003B73),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 180,
              height: 56,
              child: ElevatedButton(
                onPressed: canReserve ? onReserve : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Reservar ahora',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF111827),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF9CA3AF),
      ),
      onTap: onTap,
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF111827),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _IncludeItem extends StatelessWidget {
  final String text;

  const _IncludeItem({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 15,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItineraryItem extends StatelessWidget {
  final String time;
  final String text;

  const _ItineraryItem({
    required this.time,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF003B73),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE9D2D8),
      child: const Center(
        child: Icon(
          Icons.location_on_outlined,
          size: 92,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

class _BookingReviewDialog extends StatefulWidget {
  final String experienceTitle;
  final String date;
  final int travelers;
  final String duration;
  final String unitPrice;
  final String totalPrice;
  final List<String> includedItems;

  const _BookingReviewDialog({
    required this.experienceTitle,
    required this.date,
    required this.travelers,
    required this.duration,
    required this.unitPrice,
    required this.totalPrice,
    required this.includedItems,
  });

  @override
  State<_BookingReviewDialog> createState() => _BookingReviewDialogState();
}

class _BookingReviewDialogState extends State<_BookingReviewDialog> {
  bool acceptedLiability = false;

  void _openInfoModal({
    required String title,
    required String content,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(
                height: 1.45,
                color: Color(0xFF475569),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Revisar reserva',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(false),
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
              const SizedBox(height: 24),
              const Text(
                'Resumen de tu reserva',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Experiencia', value: widget.experienceTitle),
                    _SummaryRow(label: 'Fecha', value: widget.date),
                    _SummaryRow(
                      label: 'Viajeros',
                      value: widget.travelers == 1
                          ? '1 persona'
                          : '${widget.travelers} personas',
                    ),
                    _SummaryRow(label: 'Duración', value: widget.duration),
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
              const SizedBox(height: 14),
              _PriceRow(
                label: '${widget.unitPrice} x ${widget.travelers} viajero(s)',
                value: widget.totalPrice,
              ),
              const Divider(height: 28),
              _PriceRow(
                label: 'Total',
                value: widget.totalPrice,
                isTotal: true,
              ),
              const SizedBox(height: 26),
              const Text(
                'Políticas importantes',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              const _PolicyItem(
                icon: Icons.shield_outlined,
                iconColor: Color(0xFF16A34A),
                title: 'Cancelación gratuita',
                text: 'Cancela hasta 24 horas antes del inicio.',
              ),
              const _PolicyItem(
                icon: Icons.credit_card_rounded,
                iconColor: Color(0xFF003B73),
                title: 'Condiciones de cobro',
                text: 'El cobro se realizará al confirmar la reserva.',
              ),
              _PolicyItem(
                icon: Icons.check_rounded,
                iconColor: const Color(0xFF003B73),
                title: 'Qué incluye',
                text: widget.includedItems.join(', '),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'Al confirmar esta reserva, aceptas nuestros ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    ),
                    InkWell(
                      onTap: () => _openInfoModal(
                        title: 'Términos y Condiciones',
                        content:
                            'Al reservar en AndanDO, aceptas cumplir con las normas de la experiencia, llegar a tiempo al punto de encuentro, proveer información real y respetar las políticas del proveedor. Las reservas están sujetas a disponibilidad, condiciones climáticas y reglas operativas del afiliado.',
                      ),
                      child: const Text(
                        'Términos y Condiciones',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF003B73),
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      ' y ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    ),
                    InkWell(
                      onTap: () => _openInfoModal(
                        title: 'Política de Privacidad',
                        content:
                            'AndanDO utiliza tus datos personales únicamente para gestionar tu reserva, contactar al proveedor, enviar confirmaciones y mejorar tu experiencia. No compartimos información sensible con terceros fuera de lo necesario para operar la reserva.',
                      ),
                      child: const Text(
                        'Política de Privacidad',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF003B73),
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const Text(
                      '.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              CheckboxListTile(
                value: acceptedLiability,
                onChanged: (value) {
                  setState(() {
                    acceptedLiability = value ?? false;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Acepto el documento de descargo de responsabilidad en caso de accidente.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                subtitle: InkWell(
                  onTap: () => _openInfoModal(
                    title: 'Descargo de responsabilidad',
                    content:
                        'Reconozco que algunas experiencias pueden incluir riesgos propios de actividades turísticas, transporte, caminatas, actividades acuáticas o al aire libre. Acepto seguir las instrucciones del guía o proveedor, informar cualquier condición médica relevante y liberar a AndanDO de responsabilidad por incidentes derivados del incumplimiento de normas, negligencia personal o eventos fuera del control de la plataforma.',
                  ),
                  child: const Text(
                    'Leer documento de descargo',
                    style: TextStyle(
                      color: Color(0xFF003B73),
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: acceptedLiability
                      ? () => Navigator.of(context).pop(true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003B73),
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Confirmar y Pagar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Revisar Reserva',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingSuccessDialog extends StatelessWidget {
  final String bookingCode;
  final String totalPrice;

  const _BookingSuccessDialog({
    required this.bookingCode,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFD1FAE5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 42,
                color: Color(0xFF059669),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Reserva creada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tu reserva fue creada correctamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Código de reserva',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    bookingCode,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF003B73),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Total pagado',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      Text(
                        totalPrice,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF003B73),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.calendar_month_rounded),
                label: const Text('Ver mi reserva'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B73),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Seguir explorando',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ],
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Color(0xFF003B73),
              ),
              SizedBox(width: 8),
              Text(
                'Código de reserva',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            bookingCode,
            style: const TextStyle(
              fontSize: 22,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF003B73),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Guarda este código para futuras consultas.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
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
                fontWeight: FontWeight.w800,
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
            color: isTotal
                ? const Color(0xFF003B73)
                : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }
}

class _PolicyItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String text;

  const _PolicyItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Color(0xFF64748B),
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