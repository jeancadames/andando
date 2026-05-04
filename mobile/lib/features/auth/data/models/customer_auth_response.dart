/**
 * Modelo que representa la respuesta del backend
 *
 * RESPONSABILIDAD:
 * - Convertir JSON → objeto Dart
 * - Tipar correctamente la data
 */
class CustomerAuthResponse {
  const CustomerAuthResponse({
    required this.token,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userType,
    this.userPhone,
  });

  final String token;
  final int userId;
  final String userName;
  final String userEmail;
  final String userType;
  final String? userPhone;

  /**
   * Factory para transformar JSON a objeto
   */
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