import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../models/customer_profile_model.dart';

/// Datasource remoto para el perfil del cliente.
///
/// Consume:
/// - GET  /api/client/profile
/// - PUT  /api/client/profile
/// - POST /api/client/logout
///
/// Este datasource lee el token desde SecureStorage,
/// siguiendo el mismo patrón usado en reservas.
class CustomerProfileRemoteDataSource {
  CustomerProfileRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  /// Obtiene el perfil completo del cliente autenticado.
  Future<CustomerProfileModel> getProfile() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/profile');

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo cargar el perfil.',
      );
    }

    return CustomerProfileModel.fromJson(body);
  }

  /// Actualiza los datos personales del cliente.
  Future<CustomerProfileUser> updateProfile({
    required String name,
    String? phone,
    String? birthDate,
    String? gender,
    String? nationality,
    String? residenceCity,
    String? preferredCurrency,
    String? language,
    String? country,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/profile');

    final response = await _client.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'birth_date': birthDate,
        'gender': gender,
        'nationality': nationality,
        'residence_city': residenceCity,
        'preferred_currency': preferredCurrency ?? 'DOP',
        'language': language ?? 'es',
        'country': country,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo actualizar el perfil.',
      );
    }

    final data = Map<String, dynamic>.from(body['data'] ?? {});

    return CustomerProfileUser.fromJson(
      Map<String, dynamic>.from(data['user'] ?? {}),
    );
  }

  /// Cierra sesión en backend.
  Future<void> logout() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/logout');

    final response = await _client.post(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo cerrar sesión.',
      );
    }

    await _secureStorage.delete(StorageKeys.authToken);
  }

  /// Headers estándar para requests autenticadas.
  Future<Map<String, String>> _headers() async {
    final token = await _secureStorage.read(StorageKeys.authToken);

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  /// Decodifica respuestas JSON de forma segura.
  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}