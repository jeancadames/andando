/// Nombres centralizados de rutas.
///
/// Usar nombres evita escribir strings sueltos por toda la app.
class RouteNames {
  const RouteNames._();

  /// Ruta raíz.
  static const String splash = 'splash';

  /// Pantalla inicial / welcome.
  static const String welcome = 'welcome';

  /// Login general.
  static const String login = 'login';

  /// Reinicio de contraseñas.
  static const String forgotPassword = 'forgotPassword';
  static const String resetPassword = 'resetPassword';

  /// Registro cliente.
  static const String register = 'register';

  /// Onboarding legal obligatorio para cuentas creadas con Google o Apple.
  static const String socialLegalOnboarding = 'socialLegalOnboarding';

  /// Registro afiliado/proveedor.
  static const String affiliateRegister = 'affiliateRegister';

  /// Exploración pública del cliente.
  static const String clientExplore = 'clientExplore';

  /// Reservas del cliente.
  static const String clientBookings = 'clientBookings';

  /// Favoritos del cliente.
  static const String clientFavorites = 'clientFavorites';

  /// Perfil cliente.
  static const String customerProfile = 'customerProfile';

  /// Editar perfil cliente.
  static const String customerProfileEdit = 'customerProfileEdit';

  /// Configuración perfil cliente.
  static const String customerProfileSettings = 'customerProfileSettings';

  /// Dashboard cliente.
  static const String customerDashboard = 'customerDashboard';

  /// Crear reseña de una reserva completada.
  static const String createReview = 'createReview';

  /// Detalle público de experiencia.
  static const String experienceDetail = 'experienceDetail';

  /// Reviews públicas de una experiencia.
  static const String experienceReviews = 'experienceReviews';

  /// Chats del cliente
  static const String clientMessages = 'clientMessages';

  /// Chat individual del cliente
  static const String clientChatDetail = 'clientChatDetail';

  /// Login legacy proveedor.
  static const String providerLogin = 'providerLogin';

  /// Registro legacy proveedor.
  static const String providerRegister = 'providerRegister';

  /// Solicitud pendiente proveedor.
  static const String providerVerificationPending =
      'providerVerificationPending';

  /// Dashboard proveedor aprobado.
  static const String providerDashboard = 'providerDashboard';

  /// Catálogo proveedor.
  static const String providerCatalog = 'providerCatalog';

  /// Crear experiencia.
  static const String providerCreateExperience = 'providerCreateExperience';

  /// Editar experiencia.
  static const String providerEditExperience = 'providerEditExperience';

  /// Calendario de experiencia.
  static const String providerExperienceCalendar = 'providerExperienceCalendar';

  /// Agregar fecha al calendario.
  static const String providerAddSchedule = 'providerAddSchedule';

  /// Reseñas de una experiencia para el proveedor.
  static const String providerExperienceReviews = 'providerExperienceReviews';

  /// Reservas proveedor.
  static const String providerBookings = 'providerBookings';

  /// Analíticas proveedor.
  static const String providerAnalytics = 'providerAnalytics';

  /// Mensajes proveedor.
  static const String providerMessages = 'providerMessages';

  /// Chat de proveedor.
  static const String providerChatDetail = 'providerChatDetail';

  /// Perfil proveedor.
  static const String providerProfile = 'providerProfile';

  /// Configuración proveedor.
  static const String providerSettings = 'providerSettings';

  /// Centro Legal del proveedor.
  static const String providerLegalCenter = 'providerLegalCenter';
}
