import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../../core/config/environment.dart';
import '../models/provider_settings_model.dart';

class ProviderSettingsService {
  const ProviderSettingsService();

  Future<ProviderSettingsModel> getSettings({required String? token}) async {
    final cleanToken = _requireToken(token);

    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/provider/settings'),
      headers: _jsonHeaders(cleanToken),
    );

    final body = _decode(response);
    _ensureSuccess(response, body);

    return ProviderSettingsModel.fromJson(body);
  }

  Future<ProviderSettingsModel> updateSettings({
    required String? token,
    required String phone,
    required String city,
    required String province,
  }) async {
    final cleanToken = _requireToken(token);

    final response = await http.put(
      Uri.parse('${Environment.apiBaseUrl}/provider/settings'),
      headers: _jsonHeaders(cleanToken),
      body: jsonEncode({
        'phone': phone.trim(),
        'city': city.trim(),
        'province': province.trim(),
      }),
    );

    final body = _decode(response);
    _ensureSuccess(response, body);

    return ProviderSettingsModel.fromJson(body);
  }

  Future<ProviderSettingsModel> uploadOptionalDocuments({
    required String? token,
    PlatformFile? businessLicense,
    PlatformFile? insurancePolicy,
  }) async {
    if (businessLicense == null && insurancePolicy == null) {
      throw Exception('Selecciona al menos un documento.');
    }

    final cleanToken = _requireToken(token);
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Environment.apiBaseUrl}/provider/settings/documents'),
    );

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $cleanToken',
    });

    if (businessLicense != null) {
      request.files.add(_multipartFile('business_license', businessLicense));
    }

    if (insurancePolicy != null) {
      request.files.add(_multipartFile('insurance_policy', insurancePolicy));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final body = _decode(response);

    _ensureSuccess(response, body);

    return ProviderSettingsModel.fromJson(body);
  }

  Map<String, String> _jsonHeaders(String token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  String _requireToken(String? token) {
    final cleanToken = token?.trim() ?? '';

    if (cleanToken.isEmpty) {
      throw Exception('Tu sesión de afiliado ha expirado.');
    }

    return cleanToken;
  }

  http.MultipartFile _multipartFile(String fieldName, PlatformFile file) {
    final bytes = file.bytes;

    if (bytes == null) {
      throw Exception(
        'No se pudo leer el archivo ${file.name}. '
        'Selecciónalo nuevamente.',
      );
    }

    return http.MultipartFile.fromBytes(
      fieldName,
      bytes,
      filename: file.name,
      contentType: _contentType(file.name),
    );
  }

  MediaType _contentType(String fileName) {
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

    return MediaType('image', 'jpeg');
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'El servidor respondió con un formato inválido. '
        'Status: ${response.statusCode}.',
      );
    }
  }

  void _ensureSuccess(http.Response response, Map<String, dynamic> body) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final errors = body['errors'];

    if (errors is Map && errors.isNotEmpty) {
      final firstValue = errors.values.first;

      if (firstValue is List && firstValue.isNotEmpty) {
        throw Exception(firstValue.first.toString());
      }
    }

    throw Exception(
      body['message']?.toString() ?? 'No se pudo completar la operación.',
    );
  }
}
