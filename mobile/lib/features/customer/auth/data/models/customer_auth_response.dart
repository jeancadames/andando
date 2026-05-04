/// Modelo que representa la respuesta del backend
/// cuando un cliente se registra correctamente.
///
/// Este modelo convierte el JSON recibido desde Laravel
/// en un objeto Dart fácil de usar dentro de Flutter.
class CustomerAuthResponse {
  const CustomerAuthResponse({
    required this.token,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userType,
    this.userPhone,
  });

  /// Token Sanctum generado por Laravel.
  /// Se guarda en sesión para futuras peticiones autenticadas.
  final String token;

  /// ID del usuario creado en la tabla users.
  final int userId;

  /// Nombre del cliente.
  final String userName;

  /// Correo del cliente.
  final String userEmail;

  /// Tipo de usuario.
  /// Para este flujo debe ser: customer.
  final String userType;

  /// Teléfono opcional del cliente.
  final String? userPhone;

  /// Convierte la respuesta JSON del backend en CustomerAuthResponse.
  factory CustomerAuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;

    return CustomerAuthResponse(
      token: json['token'] as String,
      userId: user['id'] as int,
      userName: user['name'] as String,
      userEmail: user['email'] as String,
      userType: user['type'] as String,
      userPhone: user['phone']?.toString(),
    );
  }
}