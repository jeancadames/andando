import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/customer/booking/presentation/screens/customer_bookings_screen.dart';
import '../../features/customer/favorites/presentation/screens/customer_favorites_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/customer/auth/presentation/screens/customer_register_screen.dart';
import '../../features/customer/explore/data/models/customer_experience_model.dart';
import '../../features/customer/explore/presentation/controllers/explore_controller.dart';
import '../../features/customer/explore/presentation/screens/experience_detail_screen.dart';
import '../../features/customer/explore/presentation/screens/explore_screen.dart';
import '../../features/provider/dashboard/screens/provider_dashboard_screen.dart';
import '../../features/provider/experiences/screens/add_schedule_screen.dart';
import '../../features/provider/experiences/screens/create_experience_screen.dart';
import '../../features/provider/experiences/screens/experience_calendar_screen.dart';
import '../../features/provider/experiences/screens/provider_catalog_screen.dart';
import '../../features/provider/onboarding/presentation/screens/provider_register_screen.dart';
import '../../features/provider/onboarding/presentation/screens/provider_verification_pending_screen.dart';
import '../../features/provider/profile/screens/provider_profile_screen.dart';
import '../../features/provider/bookings/screens/provider_bookings_screen.dart';
import 'route_names.dart';

class AppRouter {
  AppRouter({
    required AuthController authController,
  }) : _authController = authController;

  final AuthController _authController;

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authController,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: '/',
        name: RouteNames.splash,
        builder: (context, state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (context, state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) {
          return LoginScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) {
          return CustomerRegisterScreen(
            authController: _authController,
          );
        },
      ),

      GoRoute(
        path: '/client/explore',
        name: RouteNames.clientExplore,
        builder: (context, state) {
          return const ExploreScreen();
        },
      ),
      
      GoRoute(
        path: '/client/bookings',
        name: 'clientBookings',
        builder: (context, state) {
          return const CustomerBookingsScreen();
        },
      ),

      GoRoute(
        path: '/client/favorites',
        name: 'clientFavorites',
        builder: (context, state) {
          return const CustomerFavoritesScreen();
        },
      ),

      GoRoute(
        path: '/customer/dashboard',
        name: RouteNames.customerDashboard,
        builder: (context, state) {
          return const ExploreScreen();
        },
      ),

      GoRoute(
        path: '/experiences/:id',
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          return _PublicExperienceDetailLoader(
            experienceId: experienceId,
          );
        },
      ),

      GoRoute(
        path: '/affiliate/register',
        name: RouteNames.affiliateRegister,
        builder: (context, state) {
          return ProviderRegisterScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/register',
        name: RouteNames.providerRegister,
        builder: (context, state) {
          return ProviderRegisterScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/login',
        name: RouteNames.providerLogin,
        builder: (context, state) {
          return LoginScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/verification-pending',
        name: RouteNames.providerVerificationPending,
        builder: (context, state) {
          return ProviderVerificationPendingScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/dashboard',
        name: RouteNames.providerDashboard,
        builder: (context, state) {
          return ProviderDashboardScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/catalog',
        name: RouteNames.providerCatalog,
        builder: (context, state) {
          return ProviderCatalogScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/create-experience',
        name: RouteNames.providerCreateExperience,
        builder: (context, state) {
          return CreateExperienceScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/edit-experience/:id',
        name: RouteNames.providerEditExperience,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          return CreateExperienceScreen(
            authController: _authController,
            experienceId: experienceId,
          );
        },
      ),
      GoRoute(
        path: '/provider/experience-calendar/:id/add-schedule',
        name: RouteNames.providerAddSchedule,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          final title = state.uri.queryParameters['title'] ?? 'Experiencia';

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          return AddScheduleScreen(
            authController: _authController,
            experienceId: experienceId,
            experienceTitle: title,
          );
        },
      ),
      GoRoute(
        path: '/provider/experience-calendar/:id',
        name: RouteNames.providerExperienceCalendar,
        builder: (context, state) {
          final experienceId = int.tryParse(
            state.pathParameters['id'] ?? '',
          );

          final title = state.uri.queryParameters['title'] ?? 'Experiencia';

          if (experienceId == null) {
            return const _RouteErrorPlaceholder(
              message: 'ID de experiencia inválido.',
            );
          }

          return ExperienceCalendarScreen(
            authController: _authController,
            experienceId: experienceId,
            experienceTitle: title,
          );
        },
      ),
      GoRoute(
        path: '/provider/bookings',
        name: RouteNames.providerBookings,
        builder: (context, state) {
          return ProviderBookingsScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/analytics',
        name: RouteNames.providerAnalytics,
        builder: (context, state) {
          return const _SimpleProviderPlaceholder(
            title: 'Analíticas',
            message: 'Pantalla de analíticas pendiente.',
          );
        },
      ),
      GoRoute(
        path: '/provider/messages',
        name: RouteNames.providerMessages,
        builder: (context, state) {
          return const _SimpleProviderPlaceholder(
            title: 'Mensajes',
            message: 'Pantalla de mensajes pendiente.',
          );
        },
      ),
      GoRoute(
        path: '/provider/profile',
        name: RouteNames.providerProfile,
        builder: (context, state) {
          return ProviderProfileScreen(
            authController: _authController,
          );
        },
      ),
      GoRoute(
        path: '/provider/settings',
        name: RouteNames.providerSettings,
        builder: (context, state) {
          return const _SimpleProviderPlaceholder(
            title: 'Configuración',
            message: 'Pantalla de configuración pendiente.',
          );
        },
      ),
    ],
  );

  String? _redirect(BuildContext context, GoRouterState state) {
    final authStatus = _authController.status;
    final currentLocation = state.matchedLocation;

    final isChecking = authStatus == AuthStatus.checking;
    final isAuthenticated = authStatus == AuthStatus.authenticated;

    final isPublicExperienceRoute =
        currentLocation.startsWith('/experiences/');

    final publicRoutes = <String>{
      '/',
      '/welcome',
      '/login',
      '/register',
      '/client/explore',
      '/client/bookings',
      '/client/favorites',
      '/customer/dashboard',
      '/affiliate/register',
      '/provider/register',
      '/provider/login',
    };

    final isPublicRoute =
        publicRoutes.contains(currentLocation) || isPublicExperienceRoute;

    final authRoutes = <String>{
      '/',
      '/welcome',
      '/login',
      '/register',
      '/affiliate/register',
      '/provider/register',
      '/provider/login',
    };

    final isAuthRoute = authRoutes.contains(currentLocation);

    if (isChecking) {
      return currentLocation == '/' ? null : '/';
    }

    if (!isAuthenticated) {
      if (isPublicRoute) {
        return null;
      }

      return '/login';
    }

    final normalizedUserType = _normalizeUserTypeForRouter(
      _authController.userType,
    );

    final isProvider = normalizedUserType == 'provider';
    final isCustomer = normalizedUserType == 'customer';

    final isProviderPrivateRoute = currentLocation.startsWith('/provider/') &&
        currentLocation != '/provider/register' &&
        currentLocation != '/provider/login' &&
        currentLocation != '/provider/verification-pending';

    if (isProvider) {
      final providerStatus = _normalizeProviderStatus(
        _authController.providerStatus,
      );

      if (isAuthRoute) {
        return _providerHomePath(providerStatus);
      }

      if (isProviderPrivateRoute && providerStatus != 'approved') {
        return '/provider/verification-pending';
      }

      if (currentLocation == '/provider/verification-pending' &&
          providerStatus == 'approved') {
        return '/provider/dashboard';
      }

      return null;
    }

    if (isCustomer) {
      if (isAuthRoute) {
        return '/client/explore';
      }

      if (isProviderPrivateRoute ||
          currentLocation == '/provider/verification-pending') {
        return '/client/explore';
      }

      return null;
    }

    if (isAuthRoute) {
      return '/client/explore';
    }

    if (isProviderPrivateRoute ||
        currentLocation == '/provider/verification-pending') {
      return '/client/explore';
    }

    return null;
  }

  String _normalizeUserTypeForRouter(String? userType) {
    final type = userType?.trim().toLowerCase() ?? '';

    if (type == 'provider' || type == 'affiliate' || type == 'afiliado') {
      return 'provider';
    }

    if (type == 'customer' || type == 'client' || type == 'user') {
      return 'customer';
    }

    return type.isEmpty ? 'customer' : type;
  }

  String _normalizeProviderStatus(String? providerStatus) {
    final status = providerStatus?.trim().toLowerCase() ?? '';

    if (status.isEmpty) {
      return 'pending';
    }

    return status;
  }

  String _providerHomePath(String? providerStatus) {
    final status = _normalizeProviderStatus(providerStatus);

    if (status == 'approved') {
      return '/provider/dashboard';
    }

    return '/provider/verification-pending';
  }
}

class _PublicExperienceDetailLoader extends StatefulWidget {
  final int experienceId;

  const _PublicExperienceDetailLoader({
    required this.experienceId,
  });

  @override
  State<_PublicExperienceDetailLoader> createState() =>
      _PublicExperienceDetailLoaderState();
}

class _PublicExperienceDetailLoaderState
    extends State<_PublicExperienceDetailLoader> {
  final ExploreController _controller = ExploreController();

  bool _isLoading = true;
  String? _errorMessage;
  CustomerExperienceModel? _experience;

  @override
  void initState() {
    super.initState();
    _loadExperience();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadExperience() async {
    try {
      await _controller.initialize();

      final matches = _controller.experiences.where(
        (experience) => experience.id == widget.experienceId,
      );

      if (!mounted) return;

      setState(() {
        _experience = matches.isNotEmpty ? matches.first : null;
        _isLoading = false;
        _errorMessage = _experience == null
            ? 'No encontramos esta experiencia.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'No pudimos cargar esta experiencia.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F8F8),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null || _experience == null) {
      return _RouteErrorPlaceholder(
        message: _errorMessage ?? 'Experiencia no encontrada.',
      );
    }

    final experience = _experience!;

    return ExperienceDetailScreen(
      experience: experience,
      initialIsFavorite: _controller.isFavorite(experience.id),
      onFavoriteChanged: (isFavorite) {
        if (_controller.isFavorite(experience.id) != isFavorite) {
          _controller.toggleFavorite(experience.id);
        }
      },
    );
  }
}

class _RouteErrorPlaceholder extends StatelessWidget {
  const _RouteErrorPlaceholder({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta inválida'),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}

class _SimpleProviderPlaceholder extends StatelessWidget {
  const _SimpleProviderPlaceholder({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text(message),
      ),
    );
  }
}