import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Navbar inferior reutilizable para el flujo del afiliado/proveedor.
///
/// Este widget nace del mismo navbar que ya tienes en:
/// - ProviderDashboardScreen
/// - ProviderProfileScreen
///
/// La idea es NO crear un navbar distinto para cada pantalla.
/// En vez de duplicar código, usamos este componente compartido.
///
/// Sirve para navegar entre las secciones principales del afiliado:
/// - Dashboard
/// - Catálogo
/// - Mensajes
/// - Perfil
///
/// Importante:
/// Este widget NO decide rutas.
/// Solo dibuja el navbar y ejecuta las funciones que recibe.
///
/// Eso permite que cada pantalla decida cómo navegar usando GoRouter,
/// por ejemplo:
///
/// context.goNamed(RouteNames.providerDashboard);
class ProviderBottomNav extends StatelessWidget {
  const ProviderBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDashboard,
    required this.onCatalog,
    required this.onMessages,
    required this.onProfile,
  });

  /// Índice activo del navbar.
  ///
  /// Valores:
  /// 0 = Dashboard
  /// 1 = Catálogo
  /// 2 = Mensajes
  /// 3 = Perfil
  ///
  /// Si una pantalla no pertenece directamente a una pestaña,
  /// como Analytics, puede enviar -1 para no marcar ninguna activa.
  final int currentIndex;

  /// Acción al tocar Dashboard.
  final VoidCallback onDashboard;

  /// Acción al tocar Catálogo.
  final VoidCallback onCatalog;

  /// Acción al tocar Mensajes.
  final VoidCallback onMessages;

  /// Acción al tocar Perfil.
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _ProviderBottomNavColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _ProviderBottomNavItem(
                label: 'Dashboard',
                icon: Icons.trending_up,
                isActive: currentIndex == 0,
                onTap: onDashboard,
              ),
              _ProviderBottomNavItem(
                label: 'Catálogo',
                icon: Icons.calendar_month_outlined,
                isActive: currentIndex == 1,
                onTap: onCatalog,
              ),
              _ProviderBottomNavItem(
                label: 'Mensajes',
                icon: Icons.chat_bubble_outline,
                isActive: currentIndex == 2,
                showDot: true,
                onTap: onMessages,
              ),
              _ProviderBottomNavItem(
                label: 'Perfil',
                icon: Icons.person_outline,
                isActive: currentIndex == 3,
                onTap: onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item individual del navbar del afiliado.
///
/// Este widget dibuja:
/// - ícono
/// - texto
/// - color activo/inactivo
/// - punto de notificación opcional
///
/// No maneja rutas.
/// No consulta backend.
/// No modifica estado global.
class _ProviderBottomNavItem extends StatelessWidget {
  const _ProviderBottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.showDot = false,
  });

  /// Texto visible debajo del ícono.
  final String label;

  /// Ícono del item.
  final IconData icon;

  /// Acción al tocar el item.
  final VoidCallback onTap;

  /// Define si este item se pinta como activo.
  final bool isActive;

  /// Muestra un punto visual de notificación.
  ///
  /// Ahora mismo lo usamos en Mensajes, igual que en tus pantallas actuales.
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? _ProviderBottomNavColors.primary
        : _ProviderBottomNavColors.mutedText;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (showDot)
              Positioned(
                top: 13,
                right: 28,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _ProviderBottomNavColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Colores del navbar del afiliado.
///
/// Usamos AppColors.primaryBlue para respetar el color principal
/// que ya vienes usando en AndanDO.
class _ProviderBottomNavColors {
  static const Color primary = AppColors.primaryBlue;
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}