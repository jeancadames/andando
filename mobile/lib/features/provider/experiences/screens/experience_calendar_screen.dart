import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../auth/application/auth_controller.dart';
import '../models/provider_experience_schedule.dart';
import '../services/provider_experience_service.dart';
import 'add_schedule_screen.dart';

class ExperienceCalendarScreen extends StatefulWidget {
  final int experienceId;
  final String experienceTitle;
  final AuthController authController;

  const ExperienceCalendarScreen({
    super.key,
    required this.experienceId,
    required this.experienceTitle,
    required this.authController,
  });

  @override
  State<ExperienceCalendarScreen> createState() =>
      _ExperienceCalendarScreenState();
}

class _ExperienceCalendarScreenState extends State<ExperienceCalendarScreen> {
  final ProviderExperienceService _service = ProviderExperienceService();

  bool _isLoading = true;
  String? _error;
  List<ProviderExperienceSchedule> _schedules = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final schedules = await _service.listSchedules(
        widget.experienceId,
        token: widget.authController.token,
      );

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
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

  Future<void> _deleteSchedule(ProviderExperienceSchedule schedule) async {
    try {
      await _service.deleteSchedule(
        experienceId: widget.experienceId,
        scheduleId: schedule.id,
        token: widget.authController.token,
      );

      await _loadSchedules();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _openAddScheduleScreen() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddScheduleScreen(
          authController: widget.authController,
          experienceId: widget.experienceId,
          experienceTitle: widget.experienceTitle,
        ),
      ),
    );

    if (created == true) {
      _loadSchedules();
    }
  }

  Future<void> _openEditScheduleScreen(
    ProviderExperienceSchedule schedule,
  ) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddScheduleScreen(
          authController: widget.authController,
          experienceId: widget.experienceId,
          experienceTitle: widget.experienceTitle,
          scheduleToEdit: schedule,
        ),
      ),
    );

    if (updated == true) {
      _loadSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Calendario de fechas',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Experiencia',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.experienceTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Fechas programadas',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openAddScheduleScreen,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadSchedules,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.error_outline, color: Colors.red, size: 54),
          const SizedBox(height: 14),
          Text(
            _error!.replaceFirst('Exception: ', ''),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadSchedules,
            child: const Text('Reintentar'),
          ),
        ],
      );
    }

    if (_schedules.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.calendar_month, color: Colors.grey, size: 64),
          const SizedBox(height: 16),
          const Text(
            'No hay fechas programadas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega una fecha para que los clientes puedan reservar esta experiencia.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _openAddScheduleScreen,
            child: const Text('Agregar fecha'),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final canModify = schedule.booked == 0;

        return _ScheduleCard(
          schedule: schedule,
          onEdit: canModify ? () => _openEditScheduleScreen(schedule) : null,
          onDelete: canModify ? () => _deleteSchedule(schedule) : null,
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ProviderExperienceSchedule schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // No usamos toLocal() aquí por ahora, porque el backend devuelve la hora
    // con Z, pero representa la hora de salida configurada.
    final startsAt = DateTime.tryParse(schedule.startsAt);

    final safeCapacity = schedule.capacity <= 0 ? 1 : schedule.capacity;
    final safeBooked = schedule.booked < 0 ? 0 : schedule.booked;
    final safeAvailable = schedule.available < 0 ? 0 : schedule.available;

    final percentage = safeBooked / safeCapacity;
    final progressValue =
        percentage <= 0 ? 0.03 : percentage.clamp(0.0, 1.0).toDouble();

    final isFull = safeBooked >= safeCapacity;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  startsAt == null
                      ? 'Fecha no disponible'
                      : DateFormat('EEEE d MMMM yyyy').format(startsAt),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusChip(
                label: isFull
                    ? 'Completo'
                    : safeBooked == 0
                        ? 'Disponible'
                        : '$safeAvailable cupos',
                isFull: isFull,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Colors.grey),
              const SizedBox(width: 5),
              Text(
                startsAt == null ? '-' : DateFormat('hh:mm a').format(startsAt),
              ),
              const SizedBox(width: 18),
              const Icon(Icons.attach_money, size: 18, color: Colors.grey),
              const SizedBox(width: 5),
              Text('RD\$${schedule.price.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Ocupación',
                style: TextStyle(color: Colors.grey),
              ),
              const Spacer(),
              Text(
                '$safeBooked/${schedule.capacity} personas',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(
              _occupancyColor(percentage),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: safeBooked > 0
                    ? _ScheduleActionButton(
                        label: 'Ver reservas ($safeBooked)',
                        icon: Icons.people,
                        filled: true,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'La pantalla de reservas se conectará cuando creemos el flujo de clientes.',
                              ),
                            ),
                          );
                        },
                      )
                    : _ScheduleActionButton(
                        label: 'Editar fecha',
                        icon: Icons.edit_calendar_outlined,
                        filled: false,
                        onTap: onEdit ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No puedes editar una fecha que ya tiene reservas.',
                                  ),
                                ),
                              );
                            },
                      ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 10),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onDelete,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.red,
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (safeBooked > 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            Row(
              children: [
                const Text(
                  'Ingresos estimados',
                  style: TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  'RD\$${schedule.estimatedRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _occupancyColor(double percentage) {
    if (percentage >= 0.9) {
      return const Color(0xFFDC2626);
    }

    if (percentage >= 0.6) {
      return const Color(0xFFF59E0B);
    }

    return const Color(0xFF003A78);
  }
}

class _ScheduleActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ScheduleActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: filled ? primary : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: primary,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.white : primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.white : primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isFull;

  const _StatusChip({
    required this.label,
    required this.isFull,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: isFull
          ? Colors.red.withValues(alpha: 0.1)
          : Colors.blue.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isFull ? Colors.red : Colors.blue,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}