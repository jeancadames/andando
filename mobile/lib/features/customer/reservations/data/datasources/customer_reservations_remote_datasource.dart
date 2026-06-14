import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/core/config/api_config.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/secure_storage.dart';

class CustomerReservationsRemoteDataSource {
  CustomerReservationsRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  Future<Map<String, dynamic>> getReservations() async {
    final token = await _secureStorage.read(StorageKeys.authToken);

    if (token == null || token.trim().isEmpty) {
      throw const CustomerReservationException(
        'Debes iniciar sesión para ver tus reservas.',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/client/bookings');

    final response = await _client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(response.body));

    if (response.statusCode != 200) {
      throw CustomerReservationException(
        decoded['message']?.toString() ?? 'No se pudieron cargar tus reservas.',
      );
    }

    return decoded;
  }
}

class CustomerReservationException implements Exception {
  final String message;

  const CustomerReservationException(this.message);

  @override
  String toString() => message;
}