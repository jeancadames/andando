import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../dashboard/models/provider_dashboard_model.dart';
import '../../dashboard/services/provider_dashboard_service.dart';

class ProviderProfileScreen extends StatefulWidget {
  final AuthController authController;

  const ProviderProfileScreen({
    super.key,
    required this.authController,
  });

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final ProviderDashboardService _service = ProviderDashboardService();

  late Future<ProviderDashboardModel> _profileFuture;

  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();

    _profileFuture = _service.getDashboard(
      token: widget.authController.token,
    );
  }

  Future<void> _refreshProfile() async {
    setState(() {
      _profileFuture = _service.getDashboard(
        token: widget.authController.token,
      );
    });

    await _profileFuture;
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cerrar sesión'),
          content: const Text(
            '¿Seguro que deseas cerrar tu sesión de afiliado?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await _logout();
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await widget.authController.logout();

      if (!mounted) return;

      context.goNamed(RouteNames.welcome);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  void _goToDashboard() {
    context.goNamed(RouteNames.providerDashboard);
  }

  void _goToCatalog() {
    context.goNamed(RouteNames.providerCatalog);
  }

  void _goToAnalytics() {
    context.goNamed(RouteNames.providerAnalytics);
  }

  void _goToSettings() {
    context.goNamed(RouteNames.providerSettings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ProfileColors.background,
      body: SafeArea(
        child: FutureBuilder<ProviderDashboardModel>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: _ProfileColors.primary,
                ),
              );
            }

            if (snapshot.hasError) {
              return _ProfileError(
                message: snapshot.error.toString(),
                onRetry: _refreshProfile,
              );
            }

            final dashboard = snapshot.data;

            if (dashboard == null) {
              return _ProfileError(
                message: 'No se pudo cargar el perfil del afiliado.',
                onRetry: _refreshProfile,
              );
            }

            return RefreshIndicator(
              color: _ProfileColors.primary,
              onRefresh: _refreshProfile,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _ProfileHero(
                    dashboard: dashboard,
                    onBack: _goToDashboard,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    child: Column(
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -34),
                          child: Column(
                            children: [
                              _ProfileStatsGrid(
                                stats: dashboard.stats,
                              ),
                              const SizedBox(height: 18),
                              _ProfileMenu(
                                onCatalog: _goToCatalog,
                                onAnalytics: _goToAnalytics,
                                onSettings: _goToSettings,
                              ),
                              const SizedBox(height: 18),
                              _LogoutButton(
                                isLoading: _isLoggingOut,
                                onTap: _confirmLogout,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _ProviderBottomNav(
        currentIndex: 3,
        onDashboard: () => context.goNamed(RouteNames.providerDashboard),
        onCatalog: () => context.goNamed(RouteNames.providerCatalog),
        onMessages: () => context.goNamed(RouteNames.providerMessages),
        onProfile: () {},
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final ProviderDashboardModel dashboard;
  final VoidCallback onBack;

  const _ProfileHero({
    required this.dashboard,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final name = dashboard.affiliateName.trim().isEmpty
        ? 'Afiliado'
        : dashboard.affiliateName.trim();

    final initials = _initialsFromName(name);
    final isVerified = _isVerified(dashboard.providerStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 72),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: _ProfileColors.border),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: _ProfileColors.primary,
                    size: 21,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Perfil',
                style: TextStyle(
                  color: _ProfileColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              const SizedBox(width: 42),
            ],
          ),
          const SizedBox(height: 28),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 124,
                height: 124,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _ProfileColors.primary,
                      Color(0xFF0756A5),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: _ProfileColors.primary.withValues(alpha: 0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Positioned(
                right: -5,
                bottom: -5,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _ProfileColors.background,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: _ProfileColors.primary,
                    size: 21,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ProfileColors.primary,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _VerificationPill(
            isVerified: isVerified,
            status: dashboard.providerStatus,
          ),
        ],
      ),
    );
  }

  static bool _isVerified(String? status) {
    final value = status?.trim().toLowerCase() ?? '';

    return value == 'approved' || value == 'active';
  }

  static String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'AF';

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}

class _VerificationPill extends StatelessWidget {
  final bool isVerified;
  final String? status;

  const _VerificationPill({
    required this.isVerified,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final label = isVerified ? 'Afiliado verificado' : _statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: isVerified
            ? const Color(0xFFE8F8EF)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isVerified
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified
                ? Icons.verified_user_outlined
                : Icons.info_outline,
            color: isVerified
                ? const Color(0xFF15803D)
                : const Color(0xFFA16207),
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: isVerified
                  ? const Color(0xFF15803D)
                  : const Color(0xFFA16207),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String? value) {
    final status = value?.trim().toLowerCase() ?? '';

    switch (status) {
      case 'pending':
        return 'Afiliado en revisión';
      case 'rejected':
        return 'Afiliado rechazado';
      case 'suspended':
        return 'Afiliado suspendido';
      default:
        return 'Afiliado pendiente';
    }
  }
}

class _ProfileStatsGrid extends StatelessWidget {
  final ProviderDashboardStats stats;

  const _ProfileStatsGrid({
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.22,
      children: [
        _ProfileStatCard(
          label: 'Experiencias',
          value: stats.publishedExperiences.formatted,
          trend: stats.publishedExperiences.changeLabel,
          icon: Icons.calendar_month_outlined,
        ),
        _ProfileStatCard(
          label: 'Reservas activas',
          value: stats.activeBookings.formatted,
          trend: stats.activeBookings.changeLabel,
          icon: Icons.groups_2_outlined,
        ),
        _ProfileStatCard(
          label: 'Ganancia del mes',
          value: stats.monthlyEarnings.formatted,
          trend: stats.monthlyEarnings.changeLabel,
          icon: Icons.attach_money,
        ),
        _ProfileStatCard(
          label: 'Rating promedio',
          value: stats.averageRating.formatted,
          trend: stats.averageRating.changeLabel,
          icon: Icons.star_outline,
        ),
      ],
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final IconData icon;

  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _ProfileColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              icon,
              color: _ProfileColors.primary,
              size: 23,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ProfileColors.text,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ProfileColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                size: 13,
                color: Color(0xFF15803D),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileMenu extends StatelessWidget {
  final VoidCallback onCatalog;
  final VoidCallback onAnalytics;
  final VoidCallback onSettings;

  const _ProfileMenu({
    required this.onCatalog,
    required this.onAnalytics,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _ProfileColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _ProfileMenuItem(
            icon: Icons.calendar_month_outlined,
            title: 'Mis experiencias',
            subtitle: 'Administra tu catálogo publicado',
            onTap: onCatalog,
          ),
          const Divider(height: 1, color: _ProfileColors.border),
          _ProfileMenuItem(
            icon: Icons.trending_up,
            title: 'Análisis detallado',
            subtitle: 'Métricas, reportes e ingresos',
            onTap: onAnalytics,
          ),
          const Divider(height: 1, color: _ProfileColors.border),
          _ProfileMenuItem(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            subtitle: 'Preferencias de cuenta',
            onTap: onSettings,
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: _ProfileColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _ProfileColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _ProfileColors.mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: _ProfileColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _LogoutButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                )
              else
                const Icon(
                  Icons.logout,
                  color: Colors.red,
                  size: 20,
                ),
              const SizedBox(width: 9),
              Text(
                isLoading ? 'Cerrando sesión...' : 'Cerrar sesión',
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderBottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onDashboard;
  final VoidCallback onCatalog;
  final VoidCallback onMessages;
  final VoidCallback onProfile;

  const _ProviderBottomNav({
    required this.currentIndex,
    required this.onDashboard,
    required this.onCatalog,
    required this.onMessages,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: _ProfileColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: [
              _BottomNavItem(
                label: 'Dashboard',
                icon: Icons.trending_up,
                isActive: currentIndex == 0,
                onTap: onDashboard,
              ),
              _BottomNavItem(
                label: 'Catálogo',
                icon: Icons.calendar_month_outlined,
                isActive: currentIndex == 1,
                onTap: onCatalog,
              ),
              _BottomNavItem(
                label: 'Mensajes',
                icon: Icons.chat_bubble_outline,
                isActive: currentIndex == 2,
                showDot: true,
                onTap: onMessages,
              ),
              _BottomNavItem(
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

class _BottomNavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool showDot;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? _ProfileColors.primary : _ProfileColors.mutedText;

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
                    color: _ProfileColors.primary,
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

class _ProfileError extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ProfileError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: _ProfileColors.primary,
              size: 52,
            ),
            const SizedBox(height: 14),
            Text(
              message.replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ProfileColors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _ProfileColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileColors {
  static const Color primary = AppColors.primaryBlue;
  static const Color background = Color(0xFFF8FAFC);
  static const Color text = Color(0xFF111827);
  static const Color mutedText = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
}