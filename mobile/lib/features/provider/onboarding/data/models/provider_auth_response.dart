/// Modelo que representa la respuesta del backend después de:
///
/// - login de proveedor.
/// - registro de proveedor.
///
/// Este modelo nos permite convertir el JSON que viene de Laravel
/// en un objeto Dart fácil de usar.
class ProviderAuthResponse {
  const ProviderAuthResponse({
    required this.token,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.providerId,
    required this.providerStatus,
    required this.businessName,
  });

  /// Token de autenticación generado por Laravel Sanctum.
  final String token;

  /// ID del usuario en la tabla users.
  final int userId;

  /// Nombre del usuario.
  final String userName;

  /// Correo del usuario.
  final String userEmail;

  /// ID del proveedor en la tabla providers.
  final int providerId;

  /// Estado actual del proveedor.
  ///
  /// Valores esperados:
  /// - pending
  /// - approved
  /// - rejected
  /// - suspended
  final String providerStatus;

  /// Nombre comercial del proveedor.
  final String businessName;

  /// Convierte un Map JSON en ProviderAuthResponse.
  ///
  /// Laravel debería responder algo como:
  ///
  /// {
  ///   "token": "...",
  ///   "user": {
  ///     "id": 1,
  ///     "name": "Juan Pérez",
  ///     "email": "juan@email.com"
  ///   },
  ///   "provider": {
  ///     "id": 1,
  ///     "business_name": "Tours Paradise RD",
  ///     "status": "pending"
  ///   }
  /// }
  factory ProviderAuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    final provider = json['provider'] as Map<String, dynamic>;

    return ProviderAuthResponse(
      token: json['token'] as String,
      userId: user['id'] as int,
      userName: user['name'] as String,
      userEmail: user['email'] as String,
      providerId: provider['id'] as int,
      providerStatus: provider['status'] as String,
      businessName: provider['business_name'] as String,
    );
  }
}