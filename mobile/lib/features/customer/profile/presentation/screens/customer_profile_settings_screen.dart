import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/application/auth_controller.dart';
import '../../../shared/widgets/customer_bottom_navigation.dart';

/// Pantalla de configuración del cliente.
///
/// Muestra opciones de:
/// - Cuenta
/// - Preferencias
/// - Soporte
/// - Cerrar sesión
class CustomerProfileSettingsScreen extends StatelessWidget {
  const CustomerProfileSettingsScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text('¿Seguro que quieres cerrar tu sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await authController.logout();

    if (!context.mounted) return;

    context.go('/login');
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title estará disponible próximamente.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F9),
        elevation: 0,
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _SettingsSection(
            title: 'Cuenta',
            children: [
              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notificaciones',
                subtitle: 'Gestiona tus preferencias',
                onTap: () => _showComingSoon(context, 'Notificaciones'),
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Privacidad y Seguridad',
                subtitle: 'Controla tu privacidad',
                onTap: () => _showComingSoon(context, 'Privacidad y Seguridad'),
              ),
              _SettingsTile(
                icon: Icons.credit_card_rounded,
                title: 'Métodos de Pago',
                subtitle: 'Tarjetas guardadas',
                onTap: () => context.push('/customer/profile/payment-methods'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsSection(
            title: 'Preferencias',
            children: [
              _SettingsTile(
                icon: Icons.language_rounded,
                title: 'Idioma',
                subtitle: 'Español',
                onTap: () => _showComingSoon(context, 'Idioma'),
              ),
              _SettingsTile(
                icon: Icons.location_on_outlined,
                title: 'Ubicación',
                subtitle: 'República Dominicana',
                onTap: () => _showComingSoon(context, 'Ubicación'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsSection(
            title: 'Soporte',
            children: [
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'Centro de Ayuda',
                subtitle: 'Preguntas frecuentes',
                onTap: () => context.push('/customer/profile/help-center'),
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                title: 'Términos y Condiciones',
                subtitle: 'Lee nuestras políticas',
                onTap: () => context.push('/customer/profile/terms'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _LogoutTile(
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 28),
          const Center(
            child: Text(
              'AndanDO v1.0.0',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavigation(
        currentItem: CustomerBottomNavItem.profile,
      ),
    );
  }
}

/// Sección agrupada de configuración.
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE5E7EB),
                ),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

/// Item normal de configuración.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFE5E7EB),
              ),
            ),
          ),
          child: Row(
            children: [
              _SettingsIcon(
                icon: icon,
                backgroundColor: Color(0xFFEFF6FF),
                iconColor: Color(0xFF003B73),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón de cerrar sesión dentro de configuración.
class _LogoutTile extends StatelessWidget {
  const _LogoutTile({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: const [
                _SettingsIcon(
                  icon: Icons.logout_rounded,
                  backgroundColor: Color(0xFFFFEEF2),
                  iconColor: Color(0xFFE11D48),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Salir de tu cuenta',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Icono circular de cada opción.
class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: 22,
      ),
    );
  }
}