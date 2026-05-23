import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/application/auth_controller.dart';

import '../../../shared/widgets/customer_bottom_navigation.dart';
import '../controllers/customer_profile_controller.dart';

/// Pantalla principal del perfil del cliente.
///
/// Responsabilidades:
/// - Cargar el perfil del cliente autenticado.
/// - Mostrar datos básicos, estadísticas y próxima aventura.
/// - Permitir acceso a edición de perfil.
/// - Navegar hacia reservas, favoritos y configuración.
/// - Cerrar sesión.
/// - Mantener activo el ícono de Perfil en el bottom navigation.
class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  late final CustomerProfileController _controller;

  @override
  void initState() {
    super.initState();

    _controller = CustomerProfileController(
      authController: widget.authController,
    );

    /// Carga inicial del perfil al entrar a la pantalla.
    _controller.loadProfile();
  }

  @override
  void dispose() {
    /// Liberamos el controlador para evitar fugas de memoria.
    _controller.dispose();
    super.dispose();
  }

  /// Muestra confirmación y luego cierra sesión.
  Future<void> _handleLogout() async {
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

    final success = await _controller.logout();

    if (!mounted) return;

    if (success) {
      context.go('/login');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _controller.errorMessage ?? 'No se pudo cerrar sesión.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F7F9),
          body: SafeArea(
            child: _buildBody(),
          ),

          /// Navbar compartido de cliente.
          bottomNavigationBar: const CustomerBottomNavigation(
            currentItem: CustomerBottomNavItem.profile,
          ),
        );
      },
    );
  }

  /// Construye el contenido según el estado actual:
  /// - loading
  /// - error
  /// - datos cargados
  Widget _buildBody() {
    if (_controller.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_controller.errorMessage != null && _controller.profile == null) {
      return _ErrorState(
        message: _controller.errorMessage!,
        onRetry: _controller.loadProfile,
      );
    }

    final user = _controller.user;
    final stats = _controller.stats;
    final nextBooking = _controller.nextBooking;

    if (user == null || stats == null) {
      return _ErrorState(
        message: 'No se pudo cargar la información del perfil.',
        onRetry: _controller.loadProfile,
      );
    }

    return RefreshIndicator(
      onRefresh: _controller.loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _HeaderSection(
            name: user.name,
            email: user.email,
            avatarUrl: user.avatarUrl,
            onEdit: () {
              context.push('/customer/profile/edit');
            },
          ),
          const SizedBox(height: 22),

          /// Estadísticas principales.
          _StatsSection(
            toursCount: stats.toursCount,
            reviewsCount: stats.reviewsCount,
            favoritesCount: stats.favoritesCount,
          ),
          const SizedBox(height: 22),

          /// Próxima reserva futura.
          _NextAdventureSection(
            title: nextBooking?.experienceTitle,
            location: nextBooking?.experienceProvince ??
                nextBooking?.experienceLocation,
            date: nextBooking?.bookingDate,
          ),
          const SizedBox(height: 22),

          /// Opciones del perfil.
          _MenuSection(
            onPersonalInfo: () {
              context.push('/customer/profile/edit');
            },
            onBookings: () {
              context.go('/client/bookings');
            },
            onFavorites: () {
              context.go('/client/favorites');
            },
            onSettings: () {
              context.push('/customer/profile/settings');
            },
          ),
          const SizedBox(height: 22),

          /// Cierre de sesión.
          _LogoutButton(
            isLoading: _controller.isLoggingOut,
            onPressed: _handleLogout,
          ),
        ],
      ),
    );
  }
}

/// Header superior con avatar, nombre, correo y botón de edición.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.onEdit,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            color: Color(0xFF1E293B),
          ),
        ),
        CircleAvatar(
          radius: 46,
          backgroundColor: const Color(0xFFE0E7FF),
          backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
              ? NetworkImage(avatarUrl!)
              : null,
          child: avatarUrl == null || avatarUrl!.isEmpty
              ? Text(
                  _initials(name),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E3A8A),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          name.isEmpty ? 'Cliente AndanDO' : name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  /// Devuelve iniciales para usuarios sin foto.
  static String _initials(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return 'A';
    }

    final parts = cleanValue.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

/// Sección de estadísticas del cliente.
class _StatsSection extends StatelessWidget {
  const _StatsSection({
    required this.toursCount,
    required this.reviewsCount,
    required this.favoritesCount,
  });

  final int toursCount;
  final int reviewsCount;
  final int favoritesCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: toursCount.toString(),
            label: 'Tours',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: reviewsCount.toString(),
            label: 'Reseñas',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: favoritesCount.toString(),
            label: 'Favoritos',
          ),
        ),
      ],
    );
  }
}

/// Tarjeta individual de estadística.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de próxima aventura/reserva.
class _NextAdventureSection extends StatelessWidget {
  const _NextAdventureSection({
    required this.title,
    required this.location,
    required this.date,
  });

  final String? title;
  final String? location;
  final String? date;

  @override
  Widget build(BuildContext context) {
    final hasBooking = title != null && title!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.hiking_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Próxima aventura',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasBooking ? title! : 'Aún no tienes reservas próximas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (hasBooking) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (location != null && location!.isNotEmpty) location,
                      if (date != null && date!.isNotEmpty) date,
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de accesos rápidos del perfil.
class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.onPersonalInfo,
    required this.onBookings,
    required this.onFavorites,
    required this.onSettings,
  });

  final VoidCallback onPersonalInfo;
  final VoidCallback onBookings;
  final VoidCallback onFavorites;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileMenuTile(
          icon: Icons.person_outline,
          title: 'Información personal',
          subtitle: 'Nombre, teléfono y datos básicos',
          onTap: onPersonalInfo,
        ),
        _ProfileMenuTile(
          icon: Icons.calendar_month_outlined,
          title: 'Mis reservas',
          subtitle: 'Consulta tus próximas experiencias',
          onTap: onBookings,
        ),
        _ProfileMenuTile(
          icon: Icons.favorite_border_rounded,
          title: 'Favoritos',
          subtitle: 'Experiencias guardadas',
          onTap: onFavorites,
        ),
        _ProfileMenuTile(
          icon: Icons.settings_outlined,
          title: 'Configuración',
          subtitle: 'Preferencias de cuenta',
          onTap: onSettings,
        ),
      ],
    );
  }
}

/// Item individual del menú del perfil.
class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2563EB),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9CA3AF),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Botón de cerrar sesión.
class _LogoutButton extends StatelessWidget {
  const _LogoutButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.logout_rounded),
      label: Text(isLoading ? 'Cerrando...' : 'Cerrar sesión'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFDC2626),
        side: const BorderSide(color: Color(0xFFFCA5A5)),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// Estado visual para errores de carga.
class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}