import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../auth/application/auth_controller.dart';
import '../models/provider_experience_schedule.dart';
import '../services/provider_experience_service.dart';
import 'add_schedule_screen.dart';
import 'provider_schedule_bookings_screen.dart';

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
  bool _isCancellingSchedule = false;
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

  Future<void> _openScheduleBookingsScreen(
    ProviderExperienceSchedule schedule,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderScheduleBookingsScreen(
          authController: widget.authController,
          experienceId: widget.experienceId,
          scheduleId: schedule.id,
        ),
      ),
    );

    if (!mounted) return;

    await _loadSchedules();
  }

  Future<void> _deleteSchedule(ProviderExperienceSchedule schedule) async {
    try {
      await _service.deleteSchedule(
        experienceId: widget.experienceId,
        scheduleId: schedule.id,
        token: widget.authController.token,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fecha eliminada correctamente.'),
        ),
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

  Future<void> _cancelSchedule(ProviderExperienceSchedule schedule) async {
    final request = await showDialog<_ScheduleCancellationRequest>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CancelScheduleDialog(),
    );

    if (request == null) {
      return;
    }

    setState(() {
      _isCancellingSchedule = true;
    });

    try {
      final result = await _service.cancelSchedule(
        experienceId: widget.experienceId,
        scheduleId: schedule.id,
        token: widget.authController.token,
        reasonType: request.reasonType,
        reasonDescription: request.reasonDescription,
      );

      if (!mounted) return;

      if (result.requiresSupportTicket) {
        await _showSupportTicketPlaceholder(result.message);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
        ),
      );

      await _loadSchedules();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isCancellingSchedule = false;
      });
    }
  }

  Future<void> _showSupportTicketPlaceholder(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contactar soporte'),
          content: Text(
            message.isNotEmpty
                ? '$message\n\nPróximamente podrás crear un ticket para solicitar una cancelación de emergencia.'
                : 'Próximamente podrás crear un ticket para solicitar una cancelación de emergencia.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
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

    if (!mounted) return;

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fecha programada correctamente.'),
        ),
      );

      await _loadSchedules();
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

    if (!mounted) return;

    if (updated == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fecha actualizada correctamente.'),
        ),
      );

      await _loadSchedules();
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
                  onPressed:
                      _isCancellingSchedule ? null : _openAddScheduleScreen,
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
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final canModify = schedule.booked == 0;

        return _ScheduleCard(
          schedule: schedule,
          onBookings: () => _openScheduleBookingsScreen(schedule),
          onEdit: canModify ? () => _openEditScheduleScreen(schedule) : null,
          onDelete: canModify ? () => _deleteSchedule(schedule) : null,
          onCancel: _isCancellingSchedule
              ? null
              : () => _cancelSchedule(schedule),
        );
      },
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final ProviderExperienceSchedule schedule;
  final VoidCallback onBookings;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onCancel;

  const _ScheduleCard({
    required this.schedule,
    required this.onBookings,
    required this.onEdit,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
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
                        onTap: onBookings,
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
          const SizedBox(height: 10),
          _ScheduleDangerButton(
            label: 'Cancelar fecha',
            icon: Icons.event_busy_outlined,
            onTap: onCancel ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hay una cancelación en proceso.'),
                    ),
                  );
                },
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

class _ScheduleDangerButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ScheduleDangerButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
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
              color: Colors.red,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: Colors.red,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.red,
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

class _ScheduleCancellationRequest {
  final String reasonType;
  final String reasonDescription;

  const _ScheduleCancellationRequest({
    required this.reasonType,
    required this.reasonDescription,
  });
}

class _CancellationReasonOption {
  final String value;
  final String label;

  const _CancellationReasonOption({
    required this.value,
    required this.label,
  });

  static const values = [
    _CancellationReasonOption(
      value: 'low_participants',
      label: 'No se alcanzó la cuota mínima',
    ),
    _CancellationReasonOption(
      value: 'weather_or_natural_event',
      label: 'Clima o fenómeno natural',
    ),
    _CancellationReasonOption(
      value: 'provider_emergency',
      label: 'Emergencia del afiliado',
    ),
    _CancellationReasonOption(
      value: 'operational_issue',
      label: 'Problema operativo',
    ),
    _CancellationReasonOption(
      value: 'other',
      label: 'Otro motivo',
    ),
  ];
}

class _CancelScheduleDialog extends StatefulWidget {
  const _CancelScheduleDialog();

  @override
  State<_CancelScheduleDialog> createState() => _CancelScheduleDialogState();
}

class _CancelScheduleDialogState extends State<_CancelScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _reasonType = _CancellationReasonOption.values.first.value;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      _ScheduleCancellationRequest(
        reasonType: _reasonType,
        reasonDescription: _descriptionController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cancelar fecha'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Indica el motivo de la cancelación. Esta información será revisada por el equipo de AndanDO para monitorear cancelaciones recurrentes.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _reasonType,
                decoration: const InputDecoration(
                  labelText: 'Motivo',
                  border: OutlineInputBorder(),
                ),
                items: _CancellationReasonOption.values
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _reasonType = value;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Explicación',
                  hintText:
                      'Ejemplo: Solo se inscribieron 3 personas y la cuota mínima era 10.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'La explicación es obligatoria.';
                  }

                  if (text.length < 10) {
                    return 'Agrega una explicación más detallada.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              const Text(
                'Al confirmar, esta fecha dejará de estar disponible para reservas. Las reservas pendientes o confirmadas serán marcadas como canceladas por el sistema.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Volver'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Cancelar fecha'),
        ),
      ],
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