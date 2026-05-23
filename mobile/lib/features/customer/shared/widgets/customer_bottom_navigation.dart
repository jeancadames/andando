import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Tabs disponibles en la navegación inferior del cliente.
enum CustomerBottomNavItem {
  explore,
  bookings,
  favorites,
  profile,
}

/// Bottom navigation reutilizable para todas las pantallas del cliente.
///
/// Rutas:
/// - Explorar  -> /client/explore
/// - Reservas  -> /client/bookings
/// - Favoritos -> /client/favorites
/// - Perfil    -> /customer/profile
class CustomerBottomNavigation extends StatelessWidget {
  const CustomerBottomNavigation({
    super.key,
    required this.currentItem,
  });

  final CustomerBottomNavItem currentItem;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentItem.index,
      onDestinationSelected: (index) {
        final selectedItem = CustomerBottomNavItem.values[index];

        if (selectedItem == currentItem) {
          return;
        }

        switch (selectedItem) {
          case CustomerBottomNavItem.explore:
            context.go('/client/explore');
            break;

          case CustomerBottomNavItem.bookings:
            context.go('/client/bookings');
            break;

          case CustomerBottomNavItem.favorites:
            context.go('/client/favorites');
            break;

          case CustomerBottomNavItem.profile:
            context.go('/customer/profile');
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.explore_outlined),
          selectedIcon: Icon(Icons.explore),
          label: 'Explorar',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Reservas',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_border_rounded),
          selectedIcon: Icon(Icons.favorite_rounded),
          label: 'Favoritos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}