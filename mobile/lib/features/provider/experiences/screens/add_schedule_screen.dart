import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../auth/application/auth_controller.dart';
import '../models/provider_experience_schedule.dart';
import '../services/provider_experience_service.dart';

class AddScheduleScreen extends StatefulWidget {
  final int experienceId;
  final String experienceTitle;
  final AuthController authController;

  /// Si viene una fecha, esta pantalla funciona en modo edición.
  /// En modo edición solo permitimos modificar una fecha específica,
  /// no una programación múltiple completa.
  final ProviderExperienceSchedule? scheduleToEdit;

  const AddScheduleScreen({
    super.key,
    required this.experienceId,
    required this.experienceTitle,
    required this.authController,
    this.scheduleToEdit,
  });

  bool get isEditing => scheduleToEdit != null;

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final ProviderExperienceService _service = ProviderExperienceService();

  String _scheduleType = 'single';
  String _frequency = 'daily';

  DateTime? _singleDate;
  DateTime? _startDate;
  DateTime? _endDate;

  TimeOfDay _departureTime = const TimeOfDay(hour: 8, minute: 0);

  bool _isSaving = false;

  final List<String> _selectedDays = [];

  final List<_WeekDayOption> _daysOfWeek = const [
    _WeekDayOption(value: 'monday', label: 'L'),
    _WeekDayOption(value: 'tuesday', label: 'M'),
    _WeekDayOption(value: 'wednesday', label: 'X'),
    _WeekDayOption(value: 'thursday', label: 'J'),
    _WeekDayOption(value: 'friday', label: 'V'),
    _WeekDayOption(value: 'saturday', label: 'S'),
    _WeekDayOption(value: 'sunday', label: 'D'),
  ];

  @override
  void initState() {
    super.initState();

    if (widget.isEditing) {
      _loadScheduleForEdit();
    }
  }

  void _loadScheduleForEdit() {
    final startsAtRaw = widget.scheduleToEdit?.startsAt;

    if (startsAtRaw == null || startsAtRaw.isEmpty) {
      return;
    }

    // No usamos toLocal() aquí porque el backend actualmente devuelve la hora
    // con formato UTC/Z, pero representa la hora de salida configurada.
    final startsAt = DateTime.tryParse(startsAtRaw);

    if (startsAt == null) {
      return;
    }

    _scheduleType = 'single';

    _singleDate = DateTime(
      startsAt.year,
      startsAt.month,
      startsAt.day,
    );

    _departureTime = TimeOfDay(
      hour: startsAt.hour,
      minute: startsAt.minute,
    );
  }

  bool get _canSave {
    if (widget.isEditing) {
      return _singleDate != null;
    }

    if (_scheduleType == 'single') {
      return _singleDate != null;
    }

    if (_startDate == null || _endDate == null) {
      return false;
    }

    if (_frequency == 'custom' && _selectedDays.isEmpty) {
      return false;
    }

    return true;
  }

  Future<void> _pickSingleDate() async {
    final date = await _pickDate(
      initialDate: _singleDate ?? DateTime.now(),
    );

    if (date == null) return;

    setState(() {
      _singleDate = date;
    });
  }

  Future<void> _pickStartDate() async {
    final date = await _pickDate(
      initialDate: _startDate ?? DateTime.now(),
    );

    if (date == null) return;

    setState(() {
      _startDate = date;

      if (_endDate != null && _endDate!.isBefore(date)) {
        _endDate = date;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final firstDate = _startDate ?? DateTime.now();

    final today = _dateOnly(DateTime.now());
    final safeFirstDate = firstDate.isBefore(today) ? today : firstDate;

    final date = await showDatePicker(
      context: context,
      firstDate: safeFirstDate,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: _endDate ?? safeFirstDate,
    );

    if (date == null) return;

    setState(() {
      _endDate = date;
    });
  }

  Future<DateTime?> _pickDate({
    required DateTime initialDate,
  }) {
    final today = _dateOnly(DateTime.now());
    final safeInitialDate = initialDate.isBefore(today) ? today : initialDate;

    return showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: safeInitialDate,
    );
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _departureTime,
    );

    if (time == null) return;

    setState(() {
      _departureTime = time;
    });
  }

  void _toggleDay(String value) {
    setState(() {
      if (_selectedDays.contains(value)) {
        _selectedDays.remove(value);
      } else {
        _selectedDays.add(value);
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;

    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.isEditing) {
        await _service.updateSchedule(
          experienceId: widget.experienceId,
          scheduleId: widget.scheduleToEdit!.id,
          token: widget.authController.token,
          date: _formatDateForApi(_singleDate!),
          time: _formatTimeForApi(_departureTime),
        );
      } else if (_scheduleType == 'single') {
        await _service.createSingleSchedule(
          experienceId: widget.experienceId,
          token: widget.authController.token,
          date: _formatDateForApi(_singleDate!),
          time: _formatTimeForApi(_departureTime),
        );
      } else {
        await _service.createMultipleSchedules(
          experienceId: widget.experienceId,
          token: widget.authController.token,
          startDate: _formatDateForApi(_startDate!),
          endDate: _formatDateForApi(_endDate!),
          time: _formatTimeForApi(_departureTime),
          frequency: _frequency,
          daysOfWeek: _selectedDays,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Fecha actualizada correctamente.'
                : _scheduleType == 'single'
                    ? 'Fecha programada correctamente.'
                    : 'Fechas programadas correctamente.',
          ),
        ),
      );

      Navigator.pop(context, true);
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
        _isSaving = false;
      });
    }
  }

  String _formatDateForApi(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDateLabel(DateTime? date) {
    if (date == null) {
      return 'Seleccionar';
    }

    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatTimeForApi(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _frequencyLabel() {
    if (_frequency == 'daily') {
      return 'Se crearán fechas todos los días dentro del rango seleccionado.';
    }

    if (_frequency == 'weekly') {
      return 'Se creará una fecha cada 7 días desde la fecha inicial.';
    }

    if (_selectedDays.isEmpty) {
      return 'Selecciona los días específicos de la semana.';
    }

    return 'Se crearán fechas en los ${_selectedDays.length} días seleccionados cada semana.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AddScheduleColors.background,
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
                  color: _AddScheduleColors.primary,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          widget.isEditing ? 'Editar Fecha' : 'Programar Fechas',
          style: const TextStyle(
            color: _AddScheduleColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          _ExperienceBanner(
            title: widget.experienceTitle,
          ),
          const SizedBox(height: 22),
          if (!widget.isEditing) ...[
            _ScheduleTypeSelector(
              selectedType: _scheduleType,
              onChanged: (value) {
                setState(() {
                  _scheduleType = value;
                });
              },
            ),
            const SizedBox(height: 24),
          ],
          if (widget.isEditing || _scheduleType == 'single')
            _SingleDateForm(
              selectedDate: _singleDate,
              departureTime: _departureTime,
              onPickDate: _pickSingleDate,
              onPickTime: _pickTime,
              formatDateLabel: _formatDateLabel,
            )
          else
            _MultipleDatesForm(
              startDate: _startDate,
              endDate: _endDate,
              departureTime: _departureTime,
              frequency: _frequency,
              selectedDays: _selectedDays,
              daysOfWeek: _daysOfWeek,
              onPickStartDate: _pickStartDate,
              onPickEndDate: _pickEndDate,
              onPickTime: _pickTime,
              onFrequencyChanged: (value) {
                setState(() {
                  _frequency = value;
                  if (_frequency != 'custom') {
                    _selectedDays.clear();
                  }
                });
              },
              onToggleDay: _toggleDay,
              formatDateLabel: _formatDateLabel,
              summary: _frequencyLabel(),
            ),
          const SizedBox(height: 24),
          _TipsCard(
            isEditing: widget.isEditing,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: _AddScheduleColors.border),
            ),
          ),
          child: SizedBox(
            height: 52,
            child: _PrimaryActionButton(
              label: widget.isEditing
                  ? 'Guardar Cambios'
                  : _scheduleType == 'single'
                      ? 'Guardar Fecha'
                      : 'Crear Fechas',
              enabled: _canSave && !_isSaving,
              onTap: _save,
              isLoading: _isSaving,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExperienceBanner extends StatelessWidget {
  final String title;

  const _ExperienceBanner({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _AddScheduleColors.primary.withValues(alpha: 0.06),
            _AddScheduleColors.primary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AddScheduleColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Experiencia',
            style: TextStyle(
              color: _AddScheduleColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: _AddScheduleColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onChanged;

  const _ScheduleTypeSelector({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _AddScheduleColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ScheduleTypeButton(
              label: 'Fecha única',
              selected: selectedType == 'single',
              onTap: () => onChanged('single'),
            ),
            _ScheduleTypeButton(
              label: 'Fechas múltiples',
              selected: selectedType == 'multiple',
              onTap: () => onChanged('multiple'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleTypeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ScheduleTypeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _AddScheduleColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : _AddScheduleColors.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SingleDateForm extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay departureTime;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final String Function(DateTime?) formatDateLabel;

  const _SingleDateForm({
    required this.selectedDate,
    required this.departureTime,
    required this.onPickDate,
    required this.onPickTime,
    required this.formatDateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PickerField(
          label: 'Fecha *',
          icon: Icons.calendar_month_outlined,
          value: formatDateLabel(selectedDate),
          onTap: onPickDate,
        ),
        const SizedBox(height: 16),
        _PickerField(
          label: 'Hora de salida *',
          icon: Icons.access_time,
          value: departureTime.format(context),
          onTap: onPickTime,
        ),
      ],
    );
  }
}

class _MultipleDatesForm extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final TimeOfDay departureTime;
  final String frequency;
  final List<String> selectedDays;
  final List<_WeekDayOption> daysOfWeek;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final VoidCallback onPickTime;
  final ValueChanged<String> onFrequencyChanged;
  final ValueChanged<String> onToggleDay;
  final String Function(DateTime?) formatDateLabel;
  final String summary;

  const _MultipleDatesForm({
    required this.startDate,
    required this.endDate,
    required this.departureTime,
    required this.frequency,
    required this.selectedDays,
    required this.daysOfWeek,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onPickTime,
    required this.onFrequencyChanged,
    required this.onToggleDay,
    required this.formatDateLabel,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PickerField(
                label: 'Desde *',
                icon: Icons.calendar_month_outlined,
                value: formatDateLabel(startDate),
                onTap: onPickStartDate,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PickerField(
                label: 'Hasta *',
                icon: Icons.event_outlined,
                value: formatDateLabel(endDate),
                onTap: onPickEndDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _FrequencyDropdown(
          value: frequency,
          onChanged: onFrequencyChanged,
        ),
        if (frequency == 'custom') ...[
          const SizedBox(height: 18),
          _WeekDaysSelector(
            days: daysOfWeek,
            selectedDays: selectedDays,
            onToggle: onToggleDay,
          ),
        ],
        const SizedBox(height: 16),
        _PickerField(
          label: 'Hora de salida *',
          icon: Icons.access_time,
          value: departureTime.format(context),
          onTap: onPickTime,
        ),
        const SizedBox(height: 18),
        _SummaryBox(message: summary),
      ],
    );
  }
}

class _FrequencyDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _FrequencyDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Frecuencia',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _AddScheduleColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _AddScheduleColors.border),
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'daily',
          child: Text('Diario'),
        ),
        DropdownMenuItem(
          value: 'weekly',
          child: Text('Semanal'),
        ),
        DropdownMenuItem(
          value: 'custom',
          child: Text('Días específicos'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        onChanged(value);
      },
    );
  }
}

class _WeekDaysSelector extends StatelessWidget {
  final List<_WeekDayOption> days;
  final List<String> selectedDays;
  final ValueChanged<String> onToggle;

  const _WeekDaysSelector({
    required this.days,
    required this.selectedDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Días de la semana',
            style: TextStyle(
              color: _AddScheduleColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: days.map((day) {
            final selected = selectedDays.contains(day.value);

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  onTap: () => onToggle(day.value),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? _AddScheduleColors.primary
                          : const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      day.label,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : _AddScheduleColors.mutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == 'Seleccionar';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(
            icon,
            color: _AddScheduleColors.mutedText,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _AddScheduleColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: _AddScheduleColors.border),
          ),
        ),
        child: Text(
          value,
          style: TextStyle(
            color: isPlaceholder
                ? _AddScheduleColors.mutedText
                : _AddScheduleColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String message;

  const _SummaryBox({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF1E3A8A),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final bool isEditing;

  const _TipsCard({
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final text = isEditing
        ? '• Solo puedes editar fechas sin reservas\n'
            '• Si ya hay clientes inscritos, debes cancelar o coordinar manualmente\n'
            '• Cambia la fecha u hora con cuidado para evitar conflictos'
        : '• Programa con al menos 1 semana de anticipación\n'
            '• Considera días festivos y temporada alta\n'
            '• Agrega varias fechas para mejorar la disponibilidad';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _AddScheduleColors.primary.withValues(alpha: 0.08),
            _AddScheduleColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '💡 Consejos',
            style: TextStyle(
              color: _AddScheduleColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: const TextStyle(
              color: _AddScheduleColors.mutedText,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.enabled,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? _AddScheduleColors.primary
          : _AddScheduleColors.primary.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
      ),
    );
  }
}

class _WeekDayOption {
  final String value;
  final String label;

  const _WeekDayOption({
    required this.value,
    required this.label,
  });
}

class _AddScheduleColors {
  static const Color primary = Color(0xFF003A78);
  static const Color background = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}