import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../../core/config/environment.dart';
import '../models/provider_legal_settings_model.dart';

class ProviderLegalSettingsService {
  const ProviderLegalSettingsService();

  Future<ProviderLegalSettingsModel> getLegalSettings({
    required String token,
  }) async {
    final normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      throw Exception('No existe una sesión válida del afiliado.');
    }

    final uri = Uri.parse('${Environment.apiBaseUrl}/provider/legal-settings');

    final packageInfo = await PackageInfo.fromPlatform();

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $normalizedToken',
        'X-Platform': 'flutter',
        'X-Locale': 'es',
        'X-App-Version': '${packageInfo.version}+${packageInfo.buildNumber}',
      },
    );

    final body = _decodeResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return ProviderLegalSettingsModel.fromJson(body);
      } on FormatException catch (error) {
        throw Exception(error.message);
      }
    }

    throw Exception(
      _extractErrorMessage(
        body,
        fallback: 'No fue posible cargar el Centro Legal del afiliado.',
      ),
    );
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
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

    final message = body['message']?.toString().trim();

    if (message != null && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }
}
