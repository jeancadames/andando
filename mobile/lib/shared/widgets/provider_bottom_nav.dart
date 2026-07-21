import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/provider/chat/data/services/provider_chat_service.dart';

/// Navbar inferior unica para el flujo del afiliado.
///
/// La ruta actual determina automaticamente la opcion activa.
/// Este widget tambien centraliza la navegacion principal.
class ProviderBottomNav extends StatefulWidget {
  const ProviderBottomNav({
    super.key,
    this.authController,
    this.messagesUnreadCount,
  });

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

  int _currentIndexForPath(String path) {
    if (path == '/provider/catalog' ||
        path.startsWith('/provider/create-experience') ||
        path.startsWith('/provider/edit-experience/') ||
        path.startsWith('/provider/experience-calendar/') ||
        path.startsWith('/provider/experiences/')) {
      return 1;
    }

    if (path.startsWith('/provider/messages')) {
      return 2;
    }

    if (path == '/provider/profile' || path.startsWith('/provider/settings')) {
      return 3;
    }

    if (path == '/provider/dashboard' ||
        path == '/provider/analytics' ||
        path == '/provider/bookings') {
      return 0;
    }

    return -1;
  }

  void _goTo(BuildContext context, String destination) {
    final currentPath = GoRouterState.of(context).uri.path;

    if (currentPath == destination) {
      return;
    }

    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final currentIndex = _currentIndexForPath(currentPath);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _ProviderBottomNavColors.border)),
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
                onTap: () => _goTo(context, '/provider/dashboard'),
              ),
              _ProviderBottomNavItem(
                label: 'Catálogo',
                icon: Icons.calendar_month_outlined,
                isActive: currentIndex == 1,
                onTap: () => _goTo(context, '/provider/catalog'),
              ),
              _ProviderBottomNavItem(
                label: 'Mensajes',
                icon: Icons.chat_bubble_outline,
                isActive: currentIndex == 2,
                badgeCount: _effectiveUnreadCount,
                onTap: () => _goTo(context, '/provider/messages'),
              ),
              _ProviderBottomNavItem(
                label: 'Perfil',
                icon: Icons.person_outline,
                isActive: currentIndex == 3,
                onTap: () => _goTo(context, '/provider/profile'),
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
                  Icon(icon, color: color, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
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
                    border: Border.all(color: Colors.white, width: 1.5),
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
