import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';

class PasswordResetService {
  Future<String> sendResetLink({
    required String email,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/forgot-password',
    );

    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
      }),
    );

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          body,
          fallback: 'No se pudo enviar el enlace de recuperación.',
        ),
      );
    }

    return body['message']?.toString() ??
        'Si el correo existe, enviaremos un enlace de recuperación.';
  }

  Future<String> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/reset-password',
    );

    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body));

    if (response.statusCode != 200) {
      throw Exception(
        _extractErrorMessage(
          body,
          fallback: 'No se pudo actualizar la contraseña.',
        ),
      );
    }

    return body['message']?.toString() ??
        'Contraseña actualizada correctamente.';
  }

  String _extractErrorMessage(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final errors = body['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final firstError = errors.values.first;

      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }

    return body['message']?.toString() ?? fallback;
  }
}