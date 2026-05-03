import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/customer/explore/presentation/screens/explore_screen.dart';
import '../../features/provider/onboarding/presentation/screens/provider_register_screen.dart';
import '../../features/provider/onboarding/presentation/screens/provider_verification_pending_screen.dart';
import '../../features/provider/dashboard/screens/provider_dashboard_screen.dart';
import '../../features/provider/experiences/screens/provider_catalog_screen.dart';
import '../../features/provider/experiences/screens/create_experience_screen.dart';
import '../../features/provider/experiences/screens/experience_calendar_screen.dart';
import '../../features/provider/experiences/screens/add_schedule_screen.dart';

import 'route_names.dart';

/// Router principal de AndanDO.
///
/// Aquí controlamos:
/// - rutas públicas.
/// - rutas protegidas.
/// - redirecciones según autenticación.
/// - redirecciones según estado del proveedor.
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
        /// Pasamos AuthController al LoginScreen.
        ///
        /// Esto es necesario porque después de iniciar sesión
        /// necesitamos guardar:
        /// - token
        /// - tipo de usuario
        /// - email
        /// - estado del afiliado/proveedor
        return LoginScreen(
          authController: _authController,
        );
      },
    ),

      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) {
          return const _CustomerRegisterPlaceholder();
        },
      ),

      GoRoute(
        path: '/client/explore',
        name: RouteNames.clientExplore,
        builder: (context, state) {
          return const ExploreScreen();
        },
      ),

      /// Nueva ruta oficial para afiliados/proveedores.
      GoRoute(
        path: '/affiliate/register',
        name: RouteNames.affiliateRegister,
        builder: (context, state) {
          return ProviderRegisterScreen(
            authController: _authController,
          );
        },
      ),

      /// Ruta legacy.
      ///
      /// La dejamos para no romper navegación vieja.
      /// Internamente abre el mismo registro de afiliado/proveedor.
      GoRoute(
        path: '/provider/register',
        name: RouteNames.providerRegister,
        builder: (context, state) {
          return ProviderRegisterScreen(
            authController: _authController,
          );
        },
      ),

      /// Ruta legacy del login proveedor.
      ///
      /// Ahora el login general es /login.
      /// Si alguien entra a /provider/login, mostramos el login nuevo.
      GoRoute(
        path: '/provider/login',
        name: RouteNames.providerLogin,
        builder: (context, state) {
          /// Ruta legacy.
          ///
          /// Aunque el login oficial ahora sea /login,
          /// esta ruta también usa el mismo LoginScreen.
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
        path: '/customer/dashboard',
        name: RouteNames.customerDashboard,
        builder: (context, state) {
          return const _CustomerDashboardPlaceholder();
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
          return const _SimpleProviderPlaceholder(
            title: 'Reservas',
            message: 'Pantalla de reservas pendiente.',
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
          return const _SimpleProviderPlaceholder(
            title: 'Perfil',
            message: 'Pantalla de perfil pendiente.',
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

    ],
  );

  /// Redirección global de rutas.
  ///
  /// Esta función decide a dónde puede entrar el usuario.
  String? _redirect(BuildContext context, GoRouterState state) {
    final authStatus = _authController.status;
    final currentLocation = state.matchedLocation;

    final isChecking = authStatus == AuthStatus.checking;
    final isAuthenticated = authStatus == AuthStatus.authenticated;

    /// Rutas públicas.
    ///
    /// Se pueden abrir sin sesión.
    final publicRoutes = <String>{
      '/',
      '/welcome',
      '/login',
      '/register',
      '/client/explore',
      '/affiliate/register',
      '/provider/register',
      '/provider/login',
    };

    final isPublicRoute = publicRoutes.contains(currentLocation);

    /// Mientras el AuthController revisa sesión,
    /// dejamos que la app se quede en la pantalla raíz.
    if (isChecking) {
      return currentLocation == '/' ? null : '/';
    }

    /// Usuario no autenticado.
    ///
    /// Si intenta entrar a una ruta privada, lo mandamos al login.
    /// Ya no lo mandamos al welcome porque welcome ahora es solo splash.
    if (!isAuthenticated) {
      if (isPublicRoute) {
        return null;
      }

      return '/login';
    }

    /// Usuario autenticado.
    final userType = _authController.userType;

    /// Si el usuario autenticado es proveedor,
    /// respetamos el estado de verificación.
    if (userType == 'provider') {
      final providerStatus = _authController.providerStatus;

      final isAuthRoute = <String>{
        '/',
        '/welcome',
        '/login',
        '/register',
        '/affiliate/register',
        '/provider/register',
        '/provider/login',
      }.contains(currentLocation);

      if (isAuthRoute) {
        return _providerHomePath(providerStatus);
      }

      final isProviderPrivateRoute = currentLocation.startsWith('/provider/') &&
          currentLocation != '/provider/register' &&
          currentLocation != '/provider/login' &&
          currentLocation != '/provider/verification-pending';

      if (isProviderPrivateRoute && providerStatus != 'approved') {
        return '/provider/verification-pending';
      }

      if (currentLocation == '/provider/verification-pending' &&
          providerStatus == 'approved') {
        return '/provider/dashboard';
      }

      return null;
    }

    /// Usuario cliente autenticado.
    ///
    /// Si intenta abrir login/splash/register, lo mandamos a explorar.
    final isClientAuthRoute = <String>{
      '/',
      '/welcome',
      '/login',
      '/register',
      '/affiliate/register',
      '/provider/register',
      '/provider/login',
    }.contains(currentLocation);

    if (isClientAuthRoute) {
      return '/client/explore';
    }

    return null;
  }

  /// Decide la pantalla inicial de un proveedor autenticado.
  String _providerHomePath(String? providerStatus) {
    if (providerStatus == 'approved') {
      return '/provider/dashboard';
    }

    return '/provider/verification-pending';
  }
}

/// Placeholder temporal del registro de cliente.
///
/// Todavía no hemos creado el flujo real de cliente.
class _CustomerRegisterPlaceholder extends StatelessWidget {
  const _CustomerRegisterPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: const Center(
        child: Text('Registro de cliente pendiente'),
      ),
    );
  }
}

/// Placeholder temporal del dashboard proveedor.
class _ProviderDashboardPlaceholder extends StatelessWidget {
  const _ProviderDashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Provider Dashboard'),
      ),
    );
  }
}

/// Placeholder temporal del dashboard cliente.
class _CustomerDashboardPlaceholder extends StatelessWidget {
  const _CustomerDashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Customer Dashboard'),
      ),
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