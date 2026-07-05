import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/application/auth_controller.dart';

import '../../data/services/customer_settings_preferences_service.dart';

class CustomerNotificationSettingsScreen extends StatefulWidget {
  const CustomerNotificationSettingsScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<CustomerNotificationSettingsScreen> createState() =>
      _CustomerNotificationSettingsScreenState();
}

class _CustomerNotificationSettingsScreenState
    extends State<CustomerNotificationSettingsScreen> {
  final CustomerSettingsPreferencesService _preferencesService =
      CustomerSettingsPreferencesService();

  bool _isLoading = true;
  bool _isSaving = false;

  bool _pushEnabled = true;
  bool _bookingsEnabled = true;
  bool _messagesEnabled = true;
  bool _paymentsEnabled = true;
  bool _claimsEnabled = true;
  bool _payoutsEnabled = true;
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final token = widget.authController.token;

      final preferences = token == null || token.trim().isEmpty
          ? await _preferencesService.getCachedNotificationPreferences()
          : await _preferencesService.fetchNotificationPreferences(
              token: token,
            );

      if (!mounted) return;

      setState(() {
        _pushEnabled = preferences.pushEnabled;
        _bookingsEnabled = preferences.bookingNotificationsEnabled;
        _messagesEnabled = preferences.messageNotificationsEnabled;
        _paymentsEnabled = preferences.paymentNotificationsEnabled;
        _claimsEnabled = preferences.claimNotificationsEnabled;
        _payoutsEnabled = preferences.payoutNotificationsEnabled;
        _remindersEnabled = preferences.reminderNotificationsEnabled;
        _isLoading = false;
      });
    } catch (_) {
      final cachedPreferences =
          await _preferencesService.getCachedNotificationPreferences();

      if (!mounted) return;

      setState(() {
        _pushEnabled = cachedPreferences.pushEnabled;
        _bookingsEnabled = cachedPreferences.bookingNotificationsEnabled;
        _messagesEnabled = cachedPreferences.messageNotificationsEnabled;
        _paymentsEnabled = cachedPreferences.paymentNotificationsEnabled;
        _claimsEnabled = cachedPreferences.claimNotificationsEnabled;
        _payoutsEnabled = cachedPreferences.payoutNotificationsEnabled;
        _remindersEnabled = cachedPreferences.reminderNotificationsEnabled;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron sincronizar las preferencias. Mostrando datos guardados localmente.',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
    });

    final preferences = CustomerNotificationPreferences(
      pushEnabled: _pushEnabled,
      bookingNotificationsEnabled: _bookingsEnabled,
      messageNotificationsEnabled: _messagesEnabled,
      paymentNotificationsEnabled: _paymentsEnabled,
      claimNotificationsEnabled: _claimsEnabled,
      payoutNotificationsEnabled: _payoutsEnabled,
      reminderNotificationsEnabled: _remindersEnabled,
    );

    final token = widget.authController.token;

    if (token == null || token.trim().isEmpty) {
      await _preferencesService.saveNotificationPreferences(
        pushEnabled: preferences.pushEnabled,
        bookingNotificationsEnabled: preferences.bookingNotificationsEnabled,
        messageNotificationsEnabled: preferences.messageNotificationsEnabled,
        paymentNotificationsEnabled: preferences.paymentNotificationsEnabled,
        claimNotificationsEnabled: preferences.claimNotificationsEnabled,
        payoutNotificationsEnabled: preferences.payoutNotificationsEnabled,
        reminderNotificationsEnabled: preferences.reminderNotificationsEnabled,
      );
    } else {
      await _preferencesService.updateNotificationPreferences(
        token: token,
        preferences: preferences,
      );
    }

    if (!mounted) return;

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preferencias de notificación guardadas.'),
      ),
    );

    context.pop();
  }

  void _toggleMasterPush(bool value) {
    setState(() {
      _pushEnabled = value;

      if (!value) {
        _bookingsEnabled = false;
        _messagesEnabled = false;
        _paymentsEnabled = false;
        _claimsEnabled = false;
        _payoutsEnabled = false;
        _remindersEnabled = false;
      } else {
        _bookingsEnabled = true;
        _messagesEnabled = true;
        _paymentsEnabled = true;
        _claimsEnabled = true;
        _payoutsEnabled = true;
        _remindersEnabled = true;
      }
    });
  }

  void _toggleCategory({
    required bool value,
    required void Function(bool value) update,
  }) {
    if (!_pushEnabled && value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero activa las notificaciones push.'),
        ),
      );
      return;
    }

    setState(() {
      update(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notificaciones',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Controla qué te avisamos y cómo',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                _MasterPushCard(
                  value: _pushEnabled,
                  onChanged: _toggleMasterPush,
                ),
                const SizedBox(height: 22),
                const _SectionTitle('Por categoría'),
                _SettingsCard(
                  children: [
                    _NotificationRow(
                      icon: Icons.calendar_month_outlined,
                      title: 'Reservas',
                      subtitle: 'Confirmaciones, recordatorios y cambios',
                      value: _bookingsEnabled,
                      onChanged: (value) {
                        _toggleCategory(
                          value: value,
                          update: (v) => _bookingsEnabled = v,
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _NotificationRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Mensajes',
                      subtitle: 'Mensajes de proveedores y soporte',
                      value: _messagesEnabled,
                      onChanged: (value) {
                        _toggleCategory(
                          value: value,
                          update: (v) => _messagesEnabled = v,
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _NotificationRow(
                      icon: Icons.credit_card_rounded,
                      title: 'Pagos y Transacciones',
                      subtitle: 'Pagos, reembolsos y errores de cobro',
                      value: _paymentsEnabled,
                      onChanged: (value) {
                        _toggleCategory(
                          value: value,
                          update: (v) => _paymentsEnabled = v,
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _NotificationRow(
                      icon: Icons.report_problem_outlined,
                      title: 'Reclamos',
                      subtitle: 'Actualizaciones de solicitudes y decisiones',
                      value: _claimsEnabled,
                      onChanged: (value) {
                        _toggleCategory(
                          value: value,
                          update: (v) => _claimsEnabled = v,
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _NotificationRow(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Pagos de viaje',
                      subtitle: 'Liberación de payouts y pagos asociados',
                      value: _payoutsEnabled,
                      onChanged: (value) {
                        _toggleCategory(
                          value: value,
                          update: (v) => _payoutsEnabled = v,
                        );
                      },
                    ),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    _NotificationRow(
                      icon: Icons.alarm_outlined,
                      title: 'Recordatorios',
                      subtitle: 'Avisos antes de una salida programada',
                      value: _remindersEnabled,
                      onChanged: (value) {
                        _toggleCategory(
                          value: value,
                          update: (v) => _remindersEnabled = v,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003B73),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _isSaving ? 'Guardando...' : 'Guardar Preferencias',
                      style: const TextStyle(
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

class _MasterPushCard extends StatelessWidget {
  const _MasterPushCard({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF002D62),
            Color(0xFF1A4A8A),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0x22FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notificaciones Push',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Activar o desactivar todas',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF3B82F6),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0x55FFFFFF),
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: Colors.white,
      activeTrackColor: const Color(0xFF003B73),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: const Color(0xFFE5E7EB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF003B73),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF111827),
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF8A94A6),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}