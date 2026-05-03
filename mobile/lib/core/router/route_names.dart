/// Nombres centralizados de rutas.
///
/// Usar nombres evita escribir strings sueltos por toda la app.
/// En vez de navegar así:
///
/// context.go('/login');
///
/// navegamos así:
///
/// context.goNamed(RouteNames.login);
///
/// Esto hace que el proyecto sea más mantenible.
class RouteNames {
  const RouteNames._();

  /// Ruta raíz.
  ///
  /// La app entra aquí primero.
  /// Desde aquí mostramos la pantalla de carga.
  static const String splash = 'splash';

  /// Pantalla de carga inicial con el logo.
  ///
  /// Aunque se llame WelcomeScreen, ahora funciona como splash/loading.
  static const String welcome = 'welcome';

  /// Login general de la app.
  ///
  /// Desde aquí el usuario puede:
  /// - iniciar sesión
  /// - crear cuenta cliente
  /// - continuar como invitado
  /// - registrarse como afiliado/proveedor
  static const String login = 'login';

  /// Registro futuro de cliente.
  ///
  /// Todavía no lo hemos construido completo.
  static const String register = 'register';

  /// Registro de afiliado/proveedor.
  ///
  /// Este path apunta al mismo flujo de ProviderRegisterScreen.
  static const String affiliateRegister = 'affiliateRegister';

  /// Exploración pública del cliente.
  ///
  /// Se deja pública porque existe "Continuar como invitado".
  static const String clientExplore = 'clientExplore';

  /// Ruta legacy del login proveedor.
  ///
  /// La dejamos por compatibilidad, pero el nuevo flujo usa /login.
  static const String providerLogin = 'providerLogin';

  /// Ruta legacy del registro proveedor.
  ///
  /// La dejamos por compatibilidad, pero el nuevo flujo usa /affiliate/register.
  static const String providerRegister = 'providerRegister';

  /// Pantalla de solicitud pendiente del proveedor.
  static const String providerVerificationPending =
      'providerVerificationPending';

  /// Dashboard del proveedor aprobado.
  static const String providerDashboard = 'providerDashboard';

  /// Dashboard futuro del cliente autenticado.
  static const String customerDashboard = 'customerDashboard';

    // Nuevas rutas del flujo de experiencias.
  static const String providerCatalog = 'providerCatalog';
  static const String providerCreateExperience = 'providerCreateExperience';
  static const String providerEditExperience = 'providerEditExperience';
  static const String providerExperienceCalendar = 'providerExperienceCalendar';
  static const String providerAddSchedule = 'providerAddSchedule';

  // Placeholders futuros.
  static const String providerBookings = 'providerBookings';
  static const String providerAnalytics = 'providerAnalytics';
  static const String providerMessages = 'providerMessages';
  static const String providerProfile = 'providerProfile';
}