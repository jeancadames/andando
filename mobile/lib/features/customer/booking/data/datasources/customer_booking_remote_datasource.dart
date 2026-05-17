import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../models/customer_booking_model.dart';

class CustomerBookingRemoteDataSource {
  CustomerBookingRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  Future<List<CustomerBookingModel>> getBookings() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/bookings');

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar tus reservas.',
      );
    }

    final List data = body['data'] ?? [];

    return data
        .map(
          (item) => CustomerBookingModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
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