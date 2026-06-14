import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class DeviceTokenApiService {
  const DeviceTokenApiService();

  static String get baseUrl => ApiConfig.baseUrl;

  Future<void> registerToken({
    required String apiToken,
    required String fcmToken,
    String platform = 'web',
    String deviceName = 'Flutter Web',
  }) async {
    final cleanApiToken = apiToken.trim();
    final cleanFcmToken = fcmToken.trim();

    if (cleanApiToken.isEmpty) {
      debugPrint('DEVICE TOKEN: no se registró porque apiToken está vacío.');
      return;
    }

    if (cleanFcmToken.isEmpty) {
      debugPrint('DEVICE TOKEN: no se registró porque fcmToken está vacío.');
      return;
    }

    final uri = Uri.parse('$baseUrl/device-tokens');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanApiToken',
      },
      body: jsonEncode({
        'token': cleanFcmToken,
        'platform': platform,
        'device_name': deviceName,
      }),
    );

    final isSuccessful = response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccessful) {
      debugPrint('DEVICE TOKEN REGISTER STATUS: ${response.statusCode}');
      debugPrint('DEVICE TOKEN REGISTER BODY: ${response.body}');

      throw Exception(
        _extractMessage(
          response.body,
          fallback: 'No se pudo registrar el token del dispositivo.',
        ),
      );
    }

    debugPrint('DEVICE TOKEN REGISTERED OK');
  }

  Future<void> deleteToken({
    required String apiToken,
    required String fcmToken,
  }) async {
    final cleanApiToken = apiToken.trim();
    final cleanFcmToken = fcmToken.trim();

    if (cleanApiToken.isEmpty || cleanFcmToken.isEmpty) {
      return;
    }

    final uri = Uri.parse('$baseUrl/device-tokens');

    final request = http.Request('DELETE', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $cleanApiToken',
      })
      ..body = jsonEncode({
        'token': cleanFcmToken,
      });

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    final isSuccessful = response.statusCode >= 200 && response.statusCode < 300;

    if (!isSuccessful) {
      debugPrint('DEVICE TOKEN DELETE STATUS: ${response.statusCode}');
      debugPrint('DEVICE TOKEN DELETE BODY: ${response.body}');

      throw Exception(
        _extractMessage(
          response.body,
          fallback: 'No se pudo eliminar el token del dispositivo.',
        ),
      );
    }

    debugPrint('DEVICE TOKEN DELETED OK');
  }

  String _extractMessage(
    String body, {
    required String fallback,
  }) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ?? fallback;
      }

      return fallback;
    } catch (_) {
      return body.trim().isNotEmpty ? body : fallback;
    }
  }
}