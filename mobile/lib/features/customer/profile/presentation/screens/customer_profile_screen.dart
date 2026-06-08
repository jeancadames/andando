import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../auth/application/auth_controller.dart';
import 'package:intl/intl.dart';

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

    _controller.loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Cambia la foto de perfil.
  /// Solo se ejecuta al presionar el botón de cámara.
  Future<void> _handleChangeProfilePhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.bytes == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo leer la imagen seleccionada.'),
        ),
      );
      return;
    }

    final success = await _controller.updateProfilePhoto(
      bytes: file.bytes!,
      fileName: file.name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Foto de perfil actualizada correctamente.'
              : _controller.errorMessage ?? 'No se pudo actualizar la foto.',
        ),
      ),
    );
  }

  /// Muestra la imagen de perfil en grande.
  /// Solo se ejecuta al tocar la imagen/avatar.
  void _openProfilePhotoViewer() {
    final avatarUrl = _controller.user?.avatarUrl;

    if (avatarUrl == null || avatarUrl.trim().isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      barrierColor: const Color(0xFFEFF2F6).withOpacity(0.96),
      builder: (_) {
        return _ProfilePhotoViewer(
          imageUrl: avatarUrl,
        );
      },
    );
  }

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
          bottomNavigationBar: CustomerBottomNavigation(
            currentItem: CustomerBottomNavItem.profile,
            authController: widget.authController,
          ),
        );
      },
    );
  }

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
            isUploadingPhoto: _controller.isUploadingPhoto,
            onAvatarTap: _openProfilePhotoViewer,
            onCameraTap: _handleChangeProfilePhoto,
          ),
          const SizedBox(height: 22),
          _StatsSection(
            toursCount: stats.toursCount,
            reviewsCount: stats.reviewsCount,
            favoritesCount: stats.favoritesCount,
          ),
          const SizedBox(height: 22),
          _NextAdventureSection(
            bookingCode: nextBooking?.bookingCode,
            title: nextBooking?.experienceTitle,
            location: nextBooking?.experienceProvince ??
                nextBooking?.experienceLocation,
            date: nextBooking?.bookingDate,
            guestsCount: nextBooking?.guestsCount,
            totalAmount: nextBooking?.totalAmount,
            currency: nextBooking?.currency,
            onTap: () {
              context.go('/client/bookings');
            },
          ),
          const SizedBox(height: 22),
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
          _LogoutButton(
            isLoading: _controller.isLoggingOut,
            onPressed: _handleLogout,
          ),
        ],
      ),
    );
  }
}

/// Header superior con avatar, nombre, correo y botón para cambiar foto.
class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.isUploadingPhoto,
    required this.onAvatarTap,
    required this.onCameraTap,
  });

  final String name;
  final String email;
  final String? avatarUrl;
  final bool isUploadingPhoto;
  final VoidCallback onAvatarTap;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.trim().isNotEmpty;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: hasAvatar ? onAvatarTap : null,
              child: CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFFE0E7FF),
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
                child: !hasAvatar
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
            ),

            /// Botón de cámara.
            /// Solo este botón permite cambiar la foto.
            Positioned(
              right: -4,
              bottom: -4,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 5,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: isUploadingPhoto ? null : onCameraTap,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: isUploadingPhoto
                        ? const Padding(
                            padding: EdgeInsets.all(9),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            size: 19,
                            color: Color(0xFF003B73),
                          ),
                  ),
                ),
              ),
            ),
          ],
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

  static String _initials(String value) {
    final cleanValue = value.trim();

    if (cleanValue.isEmpty) return 'A';

    final parts = cleanValue.split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

/// Visor de foto de perfil en grande.
///
/// Se abre cuando el usuario toca la imagen.
/// Tiene fondo claro y botón X arriba a la derecha.
class _ProfilePhotoViewer extends StatelessWidget {
  const _ProfilePhotoViewer({
    required this.imageUrl,
  });

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFFEFF2F6),
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          width: 260,
                          height: 260,
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Color(0xFF6B7280),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close_rounded,
                  size: 30,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
/// Tarjeta de próxima aventura/reserva.
///
/// Se muestra con un estilo similar a las cards de reservas.
/// Al tocarla, navega hacia Mis Reservas.
class _NextAdventureSection extends StatelessWidget {
  const _NextAdventureSection({
    required this.bookingCode,
    required this.title,
    required this.location,
    required this.date,
    required this.guestsCount,
    required this.totalAmount,
    required this.currency,
    required this.onTap,
  });

  final String? bookingCode;
  final String? title;
  final String? location;
  final String? date;
  final int? guestsCount;
  final double? totalAmount;
  final String? currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasBooking = title != null && title!.trim().isNotEmpty;

    if (!hasBooking) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFF6B7280),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Aún no tienes reservas próximas',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Próxima aventura',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF003B73),
                ),
              ),
              const SizedBox(height: 10),
              if (bookingCode != null && bookingCode!.isNotEmpty) ...[
                Text(
                  'Código: $bookingCode',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 10),
              if (location != null && location!.isNotEmpty)
                _ProfileInfoRow(
                  icon: Icons.location_on_outlined,
                  text: location!,
                ),
              if (date != null && date!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ProfileInfoRow(
                  icon: Icons.calendar_month_outlined,
                  text: _formatProfileDate(date),
                ),
              ],
              if (guestsCount != null && guestsCount! > 0) ...[
                const SizedBox(height: 8),
                _ProfileInfoRow(
                  icon: Icons.people_alt_outlined,
                  text: guestsCount == 1
                      ? '1 persona'
                      : '$guestsCount personas',
                ),
              ],
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  if (totalAmount != null)
                    Expanded(
                      child: Text(
                        _formatProfileCurrency(
                          amount: totalAmount,
                          currency: currency,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF003B73),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const Text(
                    'Ver reserva',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF003B73),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF003B73),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fila reutilizable para datos pequeños dentro del perfil.
class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF6B7280),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Formatea fechas de perfil de forma homogénea con Reservas.
/// Ejemplo: sáb, 30 may 2026
String _formatProfileDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }

  final parsedDate = DateTime.tryParse(value);

  if (parsedDate == null) {
    return value;
  }

  const weekdays = [
    'lun',
    'mar',
    'mié',
    'jue',
    'vie',
    'sáb',
    'dom',
  ];

  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sept',
    'oct',
    'nov',
    'dic',
  ];

  final weekday = weekdays[parsedDate.weekday - 1];
  final month = months[parsedDate.month - 1];

  return '$weekday, ${parsedDate.day} $month ${parsedDate.year}';
}

/// Formatea montos de perfil de forma homogénea con Reservas.
/// Ejemplo: RD$10,000
String _formatProfileCurrency({
  required double? amount,
  required String? currency,
}) {
  if (amount == null) {
    return '';
  }

  final formatter = NumberFormat('#,###', 'en_US');
  final formattedAmount = formatter.format(amount);

  if ((currency ?? 'DOP').toUpperCase() == 'DOP') {
    return 'RD\$$formattedAmount';
  }

  return '${currency ?? ''} $formattedAmount';
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