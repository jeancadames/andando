import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../models/customer_experience_model.dart';

class ExploreRemoteDataSource {
  final SecureStorage _secureStorage = SecureStorage();

  Future<List<CustomerExperienceModel>> getExperiences({
    String? search,
    String? category,
    String? province,
    DateTime? selectedDate,
    double? latitude,
    double? longitude,
    int? radiusKm,

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

    if (selectedDate != null) {
      queryParams['date'] = selectedDate.toIso8601String().split('T').first;
    }

    if (province != null && province.trim().isNotEmpty) {
      queryParams['province'] = province.trim();
    }

    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }

    if (radiusKm != null) {
      queryParams['radius_km'] = radiusKm.toString();
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/explore/experiences',
    ).replace(
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
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

  Future<CustomerExperienceModel> getExperienceDetail({
    required int experienceId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/explore/experiences/$experienceId',
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
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

  Future<List<String>> getCategories() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/explore/experiences/categories',
    );

    final response = await http.get(
      uri,
      headers: await _headers(),
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

  Future<void> addFavorite({
    required int experienceId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/experiences/$experienceId/favorite',
    );

    final response = await http.post(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo agregar a favoritos.',
      );
    }
  }

  Future<void> removeFavorite({
    required int experienceId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/experiences/$experienceId/favorite',
    );

    final response = await http.delete(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo quitar de favoritos.',
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _secureStorage.read(StorageKeys.authToken);

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}