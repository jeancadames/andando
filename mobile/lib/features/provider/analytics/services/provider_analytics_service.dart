import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/provider_analytics_model.dart';

/// Servicio encargado de consumir el endpoint de análisis del proveedor.
///
/// Endpoint:
/// GET /api/provider/analytics
///
/// No modifica datos.
/// Solo consulta estadísticas reales del backend.
class ProviderAnalyticsService {
  ProviderAnalyticsService({
    this.baseUrl = 'http://127.0.0.1:8000/api',
  });

  final String baseUrl;

  /// Obtiene el analytics del afiliado.
  ///
  /// Parámetros soportados:
  /// - period: 7d, 30d, 90d, year, custom
  /// - experienceId: id de experiencia específica
  /// - startDate/endDate: requeridos cuando period == custom
  Future<ProviderAnalyticsModel> getAnalytics({
    required String? token,
    String period = '30d',
    int? experienceId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (token == null || token.trim().isEmpty) {
      throw Exception('No hay token de autenticación.');
    }

    final uri = Uri.parse('$baseUrl/provider/analytics').replace(
      queryParameters: _buildQueryParameters(
        period: period,
        experienceId: experienceId,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final decoded = _decodeBody(response.body);

    if (response.statusCode != 200) {
      final message = decoded['message']?.toString() ??
          'No se pudo cargar el análisis estadístico.';

      throw Exception(message);
    }

    return ProviderAnalyticsModel.fromJson(decoded);
  }

  /// Construye los query params sin enviar nulls.
  Map<String, String> _buildQueryParameters({
    required String period,
    required int? experienceId,
    required DateTime? startDate,
    required DateTime? endDate,
  }) {
    final params = <String, String>{
      'period': period,
    };

    if (experienceId != null) {
      params['experience_id'] = experienceId.toString();
    }

    if (period == 'custom') {
      if (startDate == null || endDate == null) {
        throw Exception(
          'Para usar período personalizado debes enviar fecha inicial y fecha final.',
        );
      }

      params['start_date'] = _formatDate(startDate);
      params['end_date'] = _formatDate(endDate);
    }

    return params;
  }

  /// Decodifica el body de Laravel de forma segura.
  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Formato requerido por Laravel:
  /// YYYY-MM-DD
  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}