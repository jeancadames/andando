import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../../core/config/environment.dart';
import '../../../../customer/auth/data/models/legal_document.dart';
import '../models/provider_auth_response.dart';
import '../models/provider_register_form_data.dart';

/// Servicio de autenticación y onboarding de afiliados.
class ProviderAuthApi {
  const ProviderAuthApi();

  /// Obtiene un documento legal vigente para proveedores.
  Future<LegalDocument> getLegalDocument({required String type}) async {
    final normalizedType = type.trim();

    if (normalizedType.isEmpty) {
      throw Exception('El tipo de documento legal es obligatorio.');
    }

    final uri = Uri.parse(
      '${Environment.apiBaseUrl}/legal/documents/$normalizedType',
    ).replace(queryParameters: {'audience': 'provider'});

    final response = await http.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    final body = _decodeJson(response);

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

  /// Inicia sesión como afiliado.
  Future<ProviderAuthResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/login');

    final headers = await _buildHeaders();

    final response = await http.post(
      uri,
      headers: headers,
      body: {'email': email, 'password': password},
    );

    return _handleAuthResponse(response);
  }

  /// Envía el registro multipart del afiliado.
  Future<ProviderAuthResponse> register({
    required ProviderRegisterFormData data,
  }) async {
    final termsDocumentId = data.termsDocumentId;
    final termsChecksum = data.termsDocumentChecksum;

    final standardsDocumentId = data.standardsDocumentId;
    final standardsChecksum = data.standardsDocumentChecksum;

    final privacyDocumentId = data.privacyDocumentId;
    final privacyChecksum = data.privacyDocumentChecksum;

    if (!data.hasLegalDocuments) {
      throw Exception('Los documentos legales todavía no están disponibles.');
    }

    if (!data.hasAcceptedLegalDocuments) {
      throw Exception('Debes completar todas las confirmaciones legales.');
    }

    if (termsDocumentId == null ||
        termsChecksum == null ||
        standardsDocumentId == null ||
        standardsChecksum == null ||
        privacyDocumentId == null ||
        privacyChecksum == null) {
      throw Exception(
        'No se pudo identificar la versión de los documentos legales.',
      );
    }

    if (data.identityCard == null || data.rncCertificate == null) {
      throw Exception('La cédula y el certificado RNC son obligatorios.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/register');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(await _buildHeaders());

    request.fields.addAll({
      'full_name': data.fullName,
      'email': data.email,
      'phone': data.phone,
      'password': data.password,
      'password_confirmation': data.confirmPassword,
      'business_name': data.businessName,
      'business_type_slug': data.businessTypeSlug,
      'rnc': data.rnc,
      'address': data.address,
      'city': data.city,
      'province': data.province,

      /*
       * Confirmaciones legales.
       */
      'accept_terms': data.acceptTerms ? '1' : '0',
      'accept_standards': data.acceptStandards ? '1' : '0',
      'accept_privacy': data.acceptPrivacy ? '1' : '0',

      /*
       * Términos para afiliados.
       */
      'terms_document_id': termsDocumentId.toString(),
      'terms_document_checksum': termsChecksum,

      /*
       * Estándares de publicación y seguridad.
       */
      'standards_document_id': standardsDocumentId.toString(),
      'standards_document_checksum': standardsChecksum,

      /*
       * Política de privacidad.
       */
      'privacy_document_id': privacyDocumentId.toString(),
      'privacy_document_checksum': privacyChecksum,
    });

    request.files.add(
      _fileToMultipart(fieldName: 'identity_card', file: data.identityCard!),
    );

    request.files.add(
      _fileToMultipart(
        fieldName: 'rnc_certificate',
        file: data.rncCertificate!,
      ),
    );

    if (data.businessLicense != null) {
      request.files.add(
        _fileToMultipart(
          fieldName: 'business_license',
          file: data.businessLicense!,
        ),
      );
    }

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    return _handleAuthResponse(response);
  }

  /// Consulta el estado actual del afiliado.
  Future<String> getCurrentProviderStatus({required String token}) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/me');

    final headers = await _buildHeaders(token: token);

    final response = await http.get(uri, headers: headers);

    final body = _decodeJson(response);

    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccessful) {
      throw Exception(
        _extractErrorMessage(body, fallback: 'No se pudo consultar el estado.'),
      );
    }

    final provider = body['provider'];

    if (provider is! Map<String, dynamic>) {
      throw Exception('Este usuario no tiene perfil de afiliado.');
    }

    final status = provider['status']?.toString().trim();

    if (status == null || status.isEmpty) {
      throw Exception('El backend no devolvió el estado del afiliado.');
    }

    return status;
  }

  /// Cierra la sesión remota.
  Future<void> logout({required String token}) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/logout');

    final headers = await _buildHeaders(token: token);

    final response = await http.post(uri, headers: headers);

    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccessful) {
      final body = _decodeJson(response);

      throw Exception(
        _extractErrorMessage(
          body,
          fallback: 'No se pudo cerrar sesión en el servidor.',
        ),
      );
    }
  }

  Future<Map<String, String>> _buildHeaders({String? token}) async {
    final packageInfo = await PackageInfo.fromPlatform();

    final headers = <String, String>{
      'Accept': 'application/json',
      'X-Platform': 'flutter',
      'X-Locale': 'es',
      'X-App-Version': '${packageInfo.version}+${packageInfo.buildNumber}',
    };

    final normalizedToken = token?.trim();

    if (normalizedToken != null && normalizedToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $normalizedToken';
    }

    return headers;
  }

  http.MultipartFile _fileToMultipart({
    required String fieldName,
    required PlatformFile file,
  }) {
    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception(
        'No se pudo leer el archivo ${file.name}. '
        'Intenta seleccionarlo nuevamente.',
      );
    }

    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: file.name,
      contentType: _guessContentType(file.name),
    );
  }

  MediaType _guessContentType(String fileName) {
    final lower = fileName.toLowerCase();

    if (lower.endsWith('.pdf')) {
      return MediaType('application', 'pdf');
    }

    if (lower.endsWith('.png')) {
      return MediaType('image', 'png');
    }

    if (lower.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }

    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }

    return MediaType('application', 'octet-stream');
  }

  ProviderAuthResponse _handleAuthResponse(http.Response response) {
    final body = _decodeJson(response);

    final isSuccessful =
        response.statusCode >= 200 && response.statusCode < 300;

    if (isSuccessful) {
      return ProviderAuthResponse.fromJson(body);
    }

    throw Exception(
      _extractErrorMessage(body, fallback: 'Ocurrió un error inesperado.'),
    );
  }

  Map<String, dynamic> _decodeJson(http.Response response) {
    if (response.body.trim().isEmpty) {
      throw Exception('El servidor respondió sin contenido.');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      final preview = response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body;

      throw Exception(
        'El servidor respondió con un formato inválido. '
        'Status: ${response.statusCode}. '
        'Body: $preview',
      );
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

    final message = body['message']?.toString().trim();

    if (message != null && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }
}
