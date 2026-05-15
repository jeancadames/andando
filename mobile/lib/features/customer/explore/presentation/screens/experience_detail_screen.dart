import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/models/customer_experience_model.dart';

class ExperienceDetailScreen extends StatefulWidget {
  final CustomerExperienceModel experience;

  const ExperienceDetailScreen({
    super.key,
    required this.experience,
  });

  @override
  State<ExperienceDetailScreen> createState() => _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState extends State<ExperienceDetailScreen> {
  bool isFavorite = false;
  int travelers = 1;
  DateTime? selectedDate;

  late final TextEditingController _travelersController;

  int get maxTravelers {
    if (widget.experience.capacity > 0) {
      return widget.experience.capacity;
    }

    return 20;
  }

  List<DateTime> get availableDates {
    if (widget.experience.availableDates.isNotEmpty) {
      return widget.experience.availableDates;
    }

    final now = DateTime.now();

    return List.generate(
      8,
      (index) => DateTime(
        now.year,
        now.month,
        now.day + index + 1,
      ),
    );
  }

  int get availableSpotsForSelectedDate {
    if (selectedDate == null) return maxTravelers;

    return maxTravelers;
  }

  double get totalPrice => widget.experience.price * travelers;

  String get formattedTotal {
    final formatter = NumberFormat('#,###', 'en_US');

    final formatted = formatter.format(totalPrice);

    if (widget.experience.currency == 'DOP') {
      return 'RD\$$formatted';
    }

    return '${widget.experience.currency} $formatted';
  }

  @override
  void initState() {
    super.initState();
    _travelersController = TextEditingController(text: travelers.toString());

    final dates = availableDates;
    if (dates.isNotEmpty) {
      selectedDate = dates.first;
    }
  }

  @override
  void dispose() {
    _travelersController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final experience = widget.experience;
    final hasImage = experience.coverPhotoUrl != null &&
        experience.coverPhotoUrl!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      bottomNavigationBar: _BottomBookingBar(
        unitPrice: experience.formattedPrice,
        totalPrice: formattedTotal,
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
                      onTap: () {
                        setState(() {
                          isFavorite = !isFavorite;
                        });
                      },
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 14,
                    right: 18,
                    child: _CircleButton(
                      icon: Icons.share_rounded,
                      onTap: _shareExperience,
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
                availableDates: availableDates,
                selectedDate: selectedDate,
                travelersController: _travelersController,
                travelers: travelers,
                maxTravelers: maxTravelers,
                availableSpots: availableSpotsForSelectedDate,
                onDateChanged: (value) {
                  setState(() {
                    selectedDate = value;
                  });
                },
                onMinus: () {
                  _updateTravelers(travelers - 1);
                },
                onPlus: () {
                  _updateTravelers(travelers + 1);
                },
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

  void _shareExperience() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compartir: ${widget.experience.title}'),
      ),
    );
  }

  void _reserveExperience() {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha para continuar.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reserva iniciada para $travelers viajero(s). Total: $formattedTotal',
        ),
      ),
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
          const Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [
              _IncludeItem(text: 'Transporte incluido'),
              _IncludeItem(text: 'Almuerzo'),
              _IncludeItem(text: 'Guía certificado'),
              _IncludeItem(text: 'Seguro'),
            ],
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
          const _ItineraryItem(time: '07:00', text: 'Recogida en hotel'),
          const _ItineraryItem(time: '09:30', text: 'Llegada al destino'),
          const _ItineraryItem(time: '10:00', text: 'Inicio de la experiencia'),
          const _ItineraryItem(time: '13:00', text: 'Almuerzo típico'),
          const _ItineraryItem(time: '15:00', text: 'Tiempo libre'),
          const _ItineraryItem(time: '17:00', text: 'Regreso'),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final List<DateTime> availableDates;
  final DateTime? selectedDate;
  final TextEditingController travelersController;
  final int travelers;
  final int maxTravelers;
  final int availableSpots;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onTravelersTyped;

  const _BookingCard({
    required this.availableDates,
    required this.selectedDate,
    required this.travelersController,
    required this.travelers,
    required this.maxTravelers,
    required this.availableSpots,
    required this.onDateChanged,
    required this.onMinus,
    required this.onPlus,
    required this.onTravelersTyped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
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
          _DateSelector(
            availableDates: availableDates,
            selectedDate: selectedDate,
            onChanged: onDateChanged,
          ),
          if (selectedDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_seat_outlined,
                    size: 18,
                    color: Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cupos disponibles para esta fecha: $availableSpots',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
            onMinus: onMinus,
            onPlus: onPlus,
            onChanged: onTravelersTyped,
          ),
          const SizedBox(height: 8),
          Text(
            'Mínimo 1 persona. Máximo $maxTravelers cupos.',
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

class _DateSelector extends StatelessWidget {
  final List<DateTime> availableDates;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onChanged;

  const _DateSelector({
    required this.availableDates,
    required this.selectedDate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DateTime>(
      value: selectedDate,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        hintText: 'Selecciona una fecha',
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      items: availableDates.map((date) {
        return DropdownMenuItem<DateTime>(
          value: date,
          child: Text(_formatDate(date)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }
}

class _TravelersSelector extends StatelessWidget {
  final TextEditingController controller;
  final int travelers;
  final int maxTravelers;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onChanged;

  const _TravelersSelector({
    required this.controller,
    required this.travelers,
    required this.maxTravelers,
    required this.onMinus,
    required this.onPlus,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          _CounterButton(
            icon: Icons.remove_rounded,
            enabled: travelers > 1,
            onTap: onMinus,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
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
            enabled: travelers < maxTravelers,
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
  final VoidCallback onReserve;

  const _BottomBookingBar({
    required this.unitPrice,
    required this.totalPrice,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.08),
            ),
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
                onPressed: onReserve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8EA5BF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
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