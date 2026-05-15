import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/customer/auth/presentation/screens/customer_register_screen.dart';
import '../../features/customer/explore/presentation/screens/explore_screen.dart';
import '../../features/provider/dashboard/screens/provider_dashboard_screen.dart';
import '../../features/provider/experiences/screens/add_schedule_screen.dart';
import '../../features/provider/experiences/screens/create_experience_screen.dart';
import '../../features/provider/experiences/screens/experience_calendar_screen.dart';
import '../../features/provider/experiences/screens/provider_catalog_screen.dart';
import '../../features/provider/onboarding/presentation/screens/provider_register_screen.dart';
import '../../features/provider/onboarding/presentation/screens/provider_verification_pending_screen.dart';
import 'route_names.dart';

/// Router principal de AndanDO.
///
/// Este archivo centraliza toda la navegación de la app.
///
/// Aquí controlamos:
/// - rutas públicas.
/// - rutas privadas.
/// - redirecciones según autenticación.
/// - redirecciones según tipo de usuario.
/// - redirecciones según estado del afiliado/proveedor.
///
/// Tipos esperados:
/// - customer
/// - provider
///
/// Estados esperados del provider:
/// - pending
/// - approved
/// - rejected
/// - suspended
class AppRouter {
  AppRouter({
    required AuthController authController,
  }) : _authController = authController;

  /// Controlador global de autenticación.
  ///
  /// GoRouter escucha este controlador porque AuthController extiende
  /// ChangeNotifier. Cuando el usuario inicia sesión o cierra sesión,
  /// notifyListeners() hace que el router vuelva a evaluar redirecciones.
  final AuthController _authController;

  /// Instancia principal de GoRouter.
  late final GoRouter router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authController,
    redirect: _redirect,
    routes: [
      /*
      |--------------------------------------------------------------------------
      | Splash / Welcome
      |--------------------------------------------------------------------------
      */

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

      /*
      |--------------------------------------------------------------------------
      | Login general
      |--------------------------------------------------------------------------
      |
      | Este login debe permitir entrar a:
      | - clientes.
      | - afiliados/proveedores.
      |
      | El LoginScreen recibe AuthController para guardar sesión después
      | de que Laravel responda correctamente.
      */

      GoRoute(
        path: '/login',
        name: RouteNames.login,
        builder: (context, state) {
          return LoginScreen(
            authController: _authController,
          );
        },
      ),

      /*
      |--------------------------------------------------------------------------
      | Registro de cliente
      |--------------------------------------------------------------------------
      */

      GoRoute(
        path: '/register',
        name: RouteNames.register,
        builder: (context, state) {
          return CustomerRegisterScreen(
            authController: _authController,
          );
        },
      ),

      /*
      |--------------------------------------------------------------------------
      | Cliente / Exploración
      |--------------------------------------------------------------------------
      |
      | Esta ruta queda pública porque existe "Continuar como invitado".
      */

      GoRoute(
        path: '/client/explore',
        name: RouteNames.clientExplore,
        builder: (context, state) {
          return const ExploreScreen();
        },
      ),

      /// Alias de dashboard cliente.
      ///
      /// Por ahora el home real del cliente será ExploreScreen.
      GoRoute(
        path: '/customer/dashboard',
        name: RouteNames.customerDashboard,
        builder: (context, state) {
          return const ExploreScreen();
        },
      ),

      /*
      |--------------------------------------------------------------------------
      | Registro de afiliado/proveedor
      |--------------------------------------------------------------------------
      */

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
      /// La mantenemos para no romper navegación vieja.
      GoRoute(
        path: '/provider/register',
        name: RouteNames.providerRegister,
        builder: (context, state) {
          return ProviderRegisterScreen(
            authController: _authController,
          );
        },
      ),

      /// Ruta legacy del login de proveedor.
      ///
      /// Ahora usamos el login general.
      GoRoute(
        path: '/provider/login',
        name: RouteNames.providerLogin,
        builder: (context, state) {
          return LoginScreen(
            authController: _authController,
          );
        },
      ),

      /*
      |--------------------------------------------------------------------------
      | Estado de verificación del afiliado/proveedor
      |--------------------------------------------------------------------------
      */

      GoRoute(
        path: '/provider/verification-pending',
        name: RouteNames.providerVerificationPending,
        builder: (context, state) {
          return ProviderVerificationPendingScreen(
            authController: _authController,
          );
        },
      ),

      /*
      |--------------------------------------------------------------------------
      | Dashboard proveedor
      |--------------------------------------------------------------------------
      */

      GoRoute(
        path: '/provider/dashboard',
        name: RouteNames.providerDashboard,
        builder: (context, state) {
          return ProviderDashboardScreen(
            authController: _authController,
          );
        },
      ),

      /*
      |--------------------------------------------------------------------------
      | Catálogo / Experiencias proveedor
      |--------------------------------------------------------------------------
      */

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

      /*
      |--------------------------------------------------------------------------
      | Calendario de experiencia
      |--------------------------------------------------------------------------
      |
      | Nota:
      | Ponemos la ruta add-schedule antes de la ruta general del calendario
      | para evitar cualquier conflicto de matching con rutas dinámicas.
      */

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

      /*
      |--------------------------------------------------------------------------
      | Placeholders proveedor
      |--------------------------------------------------------------------------
      */

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
    ],
  );

  /// Redirección global de rutas.
  ///
  /// Esta función decide a dónde puede entrar el usuario según:
  /// - si está autenticado.
  /// - si es cliente.
  /// - si es afiliado/proveedor.
  /// - si el proveedor está aprobado o pendiente.
  String? _redirect(BuildContext context, GoRouterState state) {
    final authStatus = _authController.status;
    final currentLocation = state.matchedLocation;

    final isChecking = authStatus == AuthStatus.checking;
    final isAuthenticated = authStatus == AuthStatus.authenticated;

    /// Rutas públicas.
    ///
    /// Estas rutas pueden abrirse sin token.
    ///
    /// Importante:
    /// /client/explore es pública porque existe "Continuar como invitado".
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

    /// Rutas de autenticación y registro.
    ///
    /// Si un usuario autenticado entra aquí, lo redirigimos a su home.
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

    /// Mientras se revisa la sesión, mantenemos al usuario en la raíz.
    ///
    /// Esto evita que el router mande al login antes de saber
    /// si existe una sesión guardada.
    if (isChecking) {
      return currentLocation == '/' ? null : '/';
    }

    /// Usuario no autenticado.
    ///
    /// Puede entrar solamente a rutas públicas.
    /// Si intenta abrir una ruta privada, lo mandamos al login.
    if (!isAuthenticated) {
      if (isPublicRoute) {
        return null;
      }

      return '/login';
    }

    /// Usuario autenticado.
    ///
    /// Normalizamos userType porque el backend podría devolver:
    /// - customer
    /// - client
    /// - user
    /// - provider
    /// - affiliate
    /// - afiliado
    final normalizedUserType = _normalizeUserTypeForRouter(
      _authController.userType,
    );

    final isProvider = normalizedUserType == 'provider';
    final isCustomer = normalizedUserType == 'customer';

    /// Rutas privadas del proveedor.
    ///
    /// Incluye:
    /// - dashboard
    /// - catálogo
    /// - crear experiencia
    /// - editar experiencia
    /// - calendario
    /// - reservas
    /// - analíticas
    /// - mensajes
    /// - perfil
    ///
    /// Excluimos:
    /// - register
    /// - login
    /// - verification-pending
    final isProviderPrivateRoute = currentLocation.startsWith('/provider/') &&
        currentLocation != '/provider/register' &&
        currentLocation != '/provider/login' &&
        currentLocation != '/provider/verification-pending';

    /*
    |--------------------------------------------------------------------------
    | Usuario afiliado/proveedor autenticado
    |--------------------------------------------------------------------------
    */

    if (isProvider) {
      final providerStatus = _normalizeProviderStatus(
        _authController.providerStatus,
      );

      /// Si el proveedor intenta abrir login/register/splash,
      /// lo mandamos a su pantalla correcta.
      if (isAuthRoute) {
        return _providerHomePath(providerStatus);
      }

      /// Si el proveedor no está aprobado, no puede entrar a rutas privadas
      /// como dashboard, catálogo, crear experiencia o calendario.
      if (isProviderPrivateRoute && providerStatus != 'approved') {
        return '/provider/verification-pending';
      }

      /// Si el proveedor ya fue aprobado y entra a pending,
      /// lo mandamos automáticamente al dashboard.
      if (currentLocation == '/provider/verification-pending' &&
          providerStatus == 'approved') {
        return '/provider/dashboard';
      }

      return null;
    }

    /*
    |--------------------------------------------------------------------------
    | Usuario cliente autenticado
    |--------------------------------------------------------------------------
    */

    if (isCustomer) {
      /// Si el cliente abre login/register/splash,
      /// lo mandamos a explorar.
      if (isAuthRoute) {
        return '/client/explore';
      }

      /// Un cliente no debe entrar a rutas privadas del proveedor.
      if (isProviderPrivateRoute ||
          currentLocation == '/provider/verification-pending') {
        return '/client/explore';
      }

      return null;
    }

    /*
    |--------------------------------------------------------------------------
    | Fallback seguro
    |--------------------------------------------------------------------------
    |
    | Si llega un userType desconocido, tratamos al usuario como cliente.
    */

    if (isAuthRoute) {
      return '/client/explore';
    }

    if (isProviderPrivateRoute ||
        currentLocation == '/provider/verification-pending') {
      return '/client/explore';
    }

    return null;
  }

  /// Normaliza el tipo de usuario para el router.
  ///
  /// El backend puede devolver distintos nombres dependiendo del flujo:
  /// - customer
  /// - client
  /// - user
  /// - provider
  /// - affiliate
  /// - afiliado
  ///
  /// Internamente el router solo trabaja con:
  /// - customer
  /// - provider
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

  /// Normaliza el estado del proveedor.
  ///
  /// Si viene null o vacío, lo tratamos como pending para evitar que
  /// un proveedor sin status pueda entrar al dashboard.
  String _normalizeProviderStatus(String? providerStatus) {
    final status = providerStatus?.trim().toLowerCase() ?? '';

    if (status.isEmpty) {
      return 'pending';
    }

    return status;
  }

  /// Decide la pantalla inicial de un proveedor autenticado.
  ///
  /// Reglas:
  /// - approved -> dashboard.
  /// - cualquier otro estado -> verification-pending.
  String _providerHomePath(String? providerStatus) {
    final status = _normalizeProviderStatus(providerStatus);

    if (status == 'approved') {
      return '/provider/dashboard';
    }

    return '/provider/verification-pending';
  }
}

/// Pantalla simple para mostrar errores de rutas dinámicas.
///
/// Ejemplo:
/// Si alguien entra a:
/// /provider/edit-experience/abc
///
/// Como "abc" no es un ID válido, mostramos esta pantalla.
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

/// Placeholder simple para pantallas futuras del proveedor.
///
/// Se usa mientras construimos:
/// - reservas.
/// - analíticas.
/// - mensajes.
/// - perfil.
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