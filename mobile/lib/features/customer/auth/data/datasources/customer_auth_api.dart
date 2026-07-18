import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/environment.dart';
import '../models/customer_auth_response.dart';
import '../models/legal_document.dart';

class CustomerAuthApi {
  const CustomerAuthApi();

  Future<LegalDocument> getLegalDocument({required String type}) async {
    final normalizedType = type.trim();

    if (normalizedType.isEmpty) {
      throw Exception('El tipo de documento legal es obligatorio.');
    }

    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/legal/documents/$normalizedType',
    ).replace(queryParameters: {'audience': 'customer'});

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = body['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'El servidor respondió con un documento legal inválido.',
        );
      }

      try {
        return LegalDocument.fromJson(data);
      } on FormatException catch (error) {
        throw Exception(error.message);
      }
    }

    throw Exception(
      _extractErrorMessage(
        body,
        fallback: 'No fue posible cargar el documento legal.',
      ),
    );
  }

  Future<CustomerAuthResponse> register({
    required String fullName,
    required String email,
    required String phone,
    required String birthDate,
    required String password,
    required String passwordConfirmation,
    required int termsDocumentId,
    required String termsChecksum,
    required bool acceptTerms,
    required int privacyDocumentId,
    required String privacyChecksum,
    required bool privacyAcknowledged,
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/customer/register');

    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Platform': 'flutter',
        'X-Locale': 'es',
      },
      body: jsonEncode({
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'birth_date': birthDate,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'terms_document_id': termsDocumentId,
        'terms_checksum': termsChecksum,
        'accept_terms': acceptTerms,
        'privacy_document_id': privacyDocumentId,
        'privacy_checksum': privacyChecksum,
        'privacy_acknowledged': privacyAcknowledged,
      }),
    );

    return _handleAuthResponse(response);
  }

  Future<CustomerAuthResponse> loginWithGoogle({
    required String idToken,
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/auth/google');

    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id_token': idToken}),
    );

    return _handleAuthResponse(response);
  }

  Future<CustomerAuthResponse> loginWithApple({required String idToken}) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/auth/apple');

    final response = await http.post(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id_token': idToken}),
    );

    return _handleAuthResponse(response);
  }

  CustomerAuthResponse _handleAuthResponse(http.Response response) {
    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return CustomerAuthResponse.fromJson(body);
    }

    throw Exception(
      _extractErrorMessage(
        body,
        fallback: 'No fue posible completar la solicitud.',
      ),
    );
  }

  Map<String, dynamic> _decodeResponseBody(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw Exception('El servidor respondió sin contenido.');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('El servidor respondió con un formato inválido.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('El servidor respondió con un formato inválido.');
    }

    return decoded;
  }

  String _extractErrorMessage(
    Map<String, dynamic> body, {
    required String fallback,
  }) {
    final errors = body['errors'];

    if (errors is Map<String, dynamic>) {
      for (final value in errors.values) {
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }

        if (value != null) {
          return value.toString();
        }
      }
    }

    final message = body['message'];

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    return fallback;
  }
}
