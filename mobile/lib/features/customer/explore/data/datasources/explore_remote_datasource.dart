import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../models/customer_experience_model.dart';

/// DataSource remoto para la pantalla Explorar.
///
/// Se comunica con los endpoints públicos de Laravel:
/// - GET /api/client/explore/experiences
/// - GET /api/client/explore/experiences/categories
/// - GET /api/client/explore/experiences/{id}
///
/// Este datasource puede ser usado por usuarios autenticados
/// y también por visitantes.
class ExploreRemoteDataSource {
  /// Obtiene experiencias públicas disponibles para explorar.
  Future<List<CustomerExperienceModel>> getExperiences({
    String? search,
    String? category,
    String? province,
  }) async {
    final queryParams = <String, String>{};

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    if (category != null &&
        category.trim().isNotEmpty &&
        category.trim() != 'Todos') {
      queryParams['category'] = category.trim();
    }

    if (province != null && province.trim().isNotEmpty) {
      queryParams['province'] = province.trim();
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/explore/experiences',
    ).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar las experiencias.',
      );
    }

    final List data = body['data']?['data'] ?? [];

    return data
        .map(
          (item) => CustomerExperienceModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  /// Obtiene el detalle público de una experiencia.
  Future<CustomerExperienceModel> getExperienceDetail({
    required int experienceId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/explore/experiences/$experienceId',
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo cargar la experiencia.',
      );
    }

    return CustomerExperienceModel.fromJson(
      Map<String, dynamic>.from(body['data']),
    );
  }

  /// Obtiene las categorías públicas disponibles.
  Future<List<String>> getCategories() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/explore/experiences/categories',
    );

    final response = await http.get(
      uri,
      headers: _headers,
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar las categorías.',
      );
    }

    final List data = body['data'] ?? [];

    return data.map((item) => item.toString()).toList();
  }

  /// Headers estándar para endpoints públicos.
  Map<String, String> get _headers {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Decodifica la respuesta HTTP de forma segura.
  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}