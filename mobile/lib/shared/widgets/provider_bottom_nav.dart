import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/provider/chat/data/services/provider_chat_service.dart';

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
class ProviderBottomNav extends StatefulWidget {
  const ProviderBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDashboard,
    required this.onCatalog,
    required this.onMessages,
    required this.onProfile,
    this.authController,
    this.messagesUnreadCount,
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

  final VoidCallback onDashboard;
  final VoidCallback onCatalog;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  /// AuthController opcional.
  ///
  /// Si lo pasas, el navbar consulta automáticamente:
  /// GET /api/provider/conversations/unread-count
  final AuthController? authController;

  /// Contador opcional manual.
  ///
  /// Úsalo cuando la pantalla ya tenga el contador calculado.
  /// Si es null, el navbar intentará buscarlo usando authController.
  final int? messagesUnreadCount;

  @override
  State<ProviderBottomNav> createState() => _ProviderBottomNavState();
}

class _ProviderBottomNavState extends State<ProviderBottomNav> {
  final ProviderChatService _chatService = ProviderChatService();

  Timer? _timer;
  int _fetchedUnreadCount = 0;
  String? _lastToken;

  bool get _canFetchUnreadCount {
    final authController = widget.authController;
    final token = authController?.token?.trim() ?? '';
    final userType = authController?.userType?.trim().toLowerCase() ?? '';

    return authController != null &&
        authController.isAuthenticated &&
        token.isNotEmpty &&
        (userType == 'provider' ||
            userType == 'affiliate' ||
            userType == 'afiliado');
  }

  int get _effectiveUnreadCount {
    return widget.messagesUnreadCount ?? _fetchedUnreadCount;
  }

  @override
  void initState() {
    super.initState();

    _lastToken = widget.authController?.token;

    _refreshUnreadCount();

    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _refreshUnreadCount(),
    );
  }

  @override
  void didUpdateWidget(covariant ProviderBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentToken = widget.authController?.token;

    if (_lastToken != currentToken) {
      _lastToken = currentToken;
      _refreshUnreadCount();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnreadCount() async {
    if (!_canFetchUnreadCount) {
      if (!mounted) return;

      if (_fetchedUnreadCount != 0) {
        setState(() {
          _fetchedUnreadCount = 0;
        });
      }

      return;
    }

    try {
      final count = await _chatService.getUnreadCount(
        token: widget.authController?.token,
      );

      if (!mounted) return;

      if (_fetchedUnreadCount != count) {
        setState(() {
          _fetchedUnreadCount = count;
        });
      }
    } catch (_) {
      // Silencioso: el navbar no debe romper la pantalla por un contador.
    }
  }

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
                isActive: widget.currentIndex == 0,
                onTap: widget.onDashboard,
              ),
              _ProviderBottomNavItem(
                label: 'Catálogo',
                icon: Icons.calendar_month_outlined,
                isActive: widget.currentIndex == 1,
                onTap: widget.onCatalog,
              ),
              _ProviderBottomNavItem(
                label: 'Mensajes',
                icon: Icons.chat_bubble_outline,
                isActive: widget.currentIndex == 2,
                badgeCount: _effectiveUnreadCount,
                onTap: widget.onMessages,
              ),
              _ProviderBottomNavItem(
                label: 'Perfil',
                icon: Icons.person_outline,
                isActive: widget.currentIndex == 3,
                onTap: widget.onProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item individual del navbar del afiliado.
class _ProviderBottomNavItem extends StatelessWidget {
  const _ProviderBottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.badgeCount = 0,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final int badgeCount;

  bool get _hasBadge => badgeCount > 0;

  String get _badgeLabel {
    if (badgeCount > 99) {
      return '99+';
    }

    return badgeCount.toString();
  }

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
            if (_hasBadge)
              Positioned(
                top: 9,
                right: 22,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _badgeLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      height: 1,
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

class _ProviderBottomNavColors {
  static const Color primary = AppColors.primaryBlue;
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}