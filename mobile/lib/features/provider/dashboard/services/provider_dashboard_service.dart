import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../models/provider_dashboard_model.dart';

/// Servicio encargado de pedir la data real del dashboard al backend.
class ProviderDashboardService {
  /// Obtiene el dashboard del afiliado autenticado.
  ///
  /// El token viene desde AuthController, que ya lo carga desde SecureStorage.
  Future<ProviderDashboardModel> getDashboard({
    required String? token,
  }) async {
    if (token == null || token.trim().isEmpty) {
      throw Exception('No hay sesión activa. Inicia sesión nuevamente.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/provider/dashboard');

    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final Map<String, dynamic> body = response.body.isNotEmpty
        ? Map<String, dynamic>.from(jsonDecode(response.body))
        : {};

    if (response.statusCode == 200) {
      return ProviderDashboardModel.fromJson(
        Map<String, dynamic>.from(body['data'] ?? {}),
      );
    }

    if (response.statusCode == 401) {
      throw Exception('Tu sesión expiró. Inicia sesión nuevamente.');
    }

    if (response.statusCode == 404) {
      throw Exception(
        body['message']?.toString() ??
            'No se encontró el perfil de afiliado.',
      );
    }

    throw Exception(
      body['message']?.toString() ??
          'No se pudo cargar el dashboard del afiliado.',
    );
  }
}