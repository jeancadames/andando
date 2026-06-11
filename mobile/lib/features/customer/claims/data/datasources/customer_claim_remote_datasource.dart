import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/customer_claim_model.dart';

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';

class CustomerClaimRemoteDataSource {
  CustomerClaimRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  Future<void> createClaim({
    required int bookingId,
    required String reason,
    required String description,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/claims');

    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'provider_booking_id': bookingId,
        'reason': reason,
        'description': description,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw Exception(
        body['message'] ?? 'No se pudo enviar el reclamo.',
      );
    }
  }

  Future<CustomerClaimModel> getClaim({
    required int claimId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/claims/$claimId');

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo cargar el reclamo.',
      );
    }

    return CustomerClaimModel.fromJson(
      Map<String, dynamic>.from(body['data']),
    );
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