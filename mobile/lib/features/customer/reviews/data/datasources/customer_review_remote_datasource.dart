import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';

class CustomerReviewRemoteDataSource {
  CustomerReviewRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  Future<void> createReview({
    required int bookingId,
    required int rating,
    required String? comment,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/reviews');

    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'booking_id': bookingId,
        'rating': rating,
        'comment': comment,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 201) {
      throw Exception(
        body['message'] ?? 'No se pudo publicar la reseña.',
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
    if (response.body.isEmpty) return {};

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  Future<void> updateReview({
    required int reviewId,
    required int rating,
    required String? comment,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/reviews/$reviewId');

    final response = await _client.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'rating': rating,
        'comment': comment,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo actualizar la reseña.',
      );
    }
  }
}