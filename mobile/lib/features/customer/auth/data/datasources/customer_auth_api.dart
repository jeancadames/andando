import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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

    final headers = await _buildJsonHeaders();

    final response = await http.post(
      uri,
      headers: headers,
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

    final headers = await _buildJsonHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'id_token': idToken}),
    );

    return _handleAuthResponse(response);
  }

  Future<CustomerAuthResponse> loginWithApple({required String idToken}) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/auth/apple');

    final headers = await _buildJsonHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'id_token': idToken}),
    );

    return _handleAuthResponse(response);
  }

  /// Completa los requisitos legales de una cuenta creada mediante
  /// Google o Apple.
  Future<void> completeSocialLegalOnboarding({
    required String apiToken,
    required String birthDate,
    required int termsDocumentId,
    required String termsChecksum,
    required bool acceptTerms,
    required int privacyDocumentId,
    required String privacyChecksum,
    required bool privacyAcknowledged,
  }) async {
    final normalizedToken = apiToken.trim();

    if (normalizedToken.isEmpty) {
      throw Exception(
        'No existe una sesión válida para completar el registro.',
      );
    }

    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/auth/social/legal-onboarding',
    );

    final headers = await _buildJsonHeaders(apiToken: normalizedToken);

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'birth_date': birthDate,
        'terms_document_id': termsDocumentId,
        'terms_checksum': termsChecksum,
        'accept_terms': acceptTerms,
        'privacy_document_id': privacyDocumentId,
        'privacy_checksum': privacyChecksum,
        'privacy_acknowledged': privacyAcknowledged,
      }),
    );

    final body = _decodeResponseBody(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final requiresLegalOnboarding = body['requires_legal_onboarding'];

      if (requiresLegalOnboarding == true) {
        throw Exception(
          'El servidor no pudo confirmar que el proceso legal fue completado.',
        );
      }

      return;
    }

    throw Exception(
      _extractErrorMessage(
        body,
        fallback: 'No fue posible completar la información legal.',
      ),
    );
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

  Future<Map<String, String>> _buildJsonHeaders({String? apiToken}) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Platform': 'flutter',
      'X-Locale': 'es',
      'X-App-Version': '${packageInfo.version}+${packageInfo.buildNumber}',
    };

    final normalizedToken = apiToken?.trim();

    if (normalizedToken != null && normalizedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $normalizedToken';
    }

    return headers;
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
