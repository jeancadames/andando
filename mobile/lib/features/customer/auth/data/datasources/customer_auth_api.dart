import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../../core/config/environment.dart';
import '../models/customer_auth_response.dart';

/**
 * CustomerAuthApi
 *
 * RESPONSABILIDAD:
 * - Comunicarse con Laravel
 * - NO manejar UI
 * - NO navegar
 * - SOLO HTTP + parseo
 */
class CustomerAuthApi {
  const CustomerAuthApi();

  /**
   * Registrar cliente
   */
  Future<CustomerAuthResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/customer/register');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    return _handleResponse(response);
  }

  /**
   * Manejo de respuesta del backend
   */
  CustomerAuthResponse _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return CustomerAuthResponse.fromJson(body);
    }

    // Manejo de errores Laravel
    if (body['errors'] != null) {
      final errors = body['errors'] as Map<String, dynamic>;
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        throw Exception(firstError.first);
      }
    }

    throw Exception(body['message'] ?? 'Error desconocido');
  }
}