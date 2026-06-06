import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_controller.dart';
import '../../chat/data/services/customer_chat_service.dart';

/// Tabs disponibles en la navegación inferior del cliente.
enum CustomerBottomNavItem {
  explore,
  bookings,
  messages,
  favorites,
  profile,
}

/// Bottom navigation reutilizable para todas las pantallas del cliente.
///
/// Rutas:
/// - Explorar  -> /client/explore
/// - Reservas  -> /client/bookings
/// - Mensajes  -> /client/messages
/// - Favoritos -> /client/favorites
/// - Perfil    -> /customer/profile
class CustomerBottomNavigation extends StatefulWidget {
  const CustomerBottomNavigation({
    super.key,
    required this.currentItem,
    this.authController,
    this.messagesUnreadCount,
  });

  final CustomerBottomNavItem currentItem;

  /// AuthController opcional.
  ///
  /// Si lo pasas, el navbar consulta automáticamente:
  /// GET /api/client/conversations/unread-count
  final AuthController? authController;

  /// Contador opcional manual.
  ///
  /// Úsalo cuando la pantalla ya tenga el contador calculado.
  /// Si es null, el navbar intentará buscarlo usando authController.
  final int? messagesUnreadCount;

  @override
  State<CustomerBottomNavigation> createState() =>
      _CustomerBottomNavigationState();
}

class _CustomerBottomNavigationState extends State<CustomerBottomNavigation> {
  final CustomerChatService _chatService = CustomerChatService();

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
        (userType == 'customer' || userType == 'client' || userType == 'user');
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
  void didUpdateWidget(covariant CustomerBottomNavigation oldWidget) {
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
    return NavigationBar(
      selectedIndex: widget.currentItem.index,
      onDestinationSelected: (index) {
        final selectedItem = CustomerBottomNavItem.values[index];

        if (selectedItem == widget.currentItem) {
          return;
        }

        switch (selectedItem) {
          case CustomerBottomNavItem.explore:
            context.go('/client/explore');
            break;

          case CustomerBottomNavItem.bookings:
            context.go('/client/bookings');
            break;

          case CustomerBottomNavItem.messages:
            context.go('/client/messages');
            break;

          case CustomerBottomNavItem.favorites:
            context.go('/client/favorites');
            break;

          case CustomerBottomNavItem.profile:
            context.go('/customer/profile');
            break;
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Explorar',
        ),
        const NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Reservas',
        ),
        NavigationDestination(
          icon: _CustomerNavBadgeIcon(
            icon: Icons.chat_bubble_outline_rounded,
            count: _effectiveUnreadCount,
          ),
          selectedIcon: _CustomerNavBadgeIcon(
            icon: Icons.chat_bubble_rounded,
            count: _effectiveUnreadCount,
          ),
          label: 'Mensajes',
        ),
        const NavigationDestination(
          icon: Icon(Icons.favorite_border_rounded),
          selectedIcon: Icon(Icons.favorite_rounded),
          label: 'Favoritos',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}

class _CustomerNavBadgeIcon extends StatelessWidget {
  const _CustomerNavBadgeIcon({
    required this.icon,
    required this.count,
  });

  final IconData icon;
  final int count;

  bool get _hasUnread => count > 0;

  String get _label {
    if (count > 99) {
      return '99+';
    }

    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasUnread) {
      return Icon(icon);
    }

    return SizedBox(
      width: 34,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: Icon(icon),
          ),
          Positioned(
            top: -2,
            right: 0,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 17,
                minHeight: 17,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
                _label,
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
    );
  }
}