import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../models/experience_review_model.dart';
import '../models/experience_reviews_response.dart';

class ExperienceReviewsRemoteDataSource {
  ExperienceReviewsRemoteDataSource({
    http.Client? client,
    SecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorage();

  final http.Client _client;
  final SecureStorage _secureStorage;

  Future<ExperienceReviewsResponse> getExperienceReviews({
    required int experienceId,
    int limit = 3,
  }) async {
    final token = await _secureStorage.read(StorageKeys.authToken);

    final endpoint = token != null && token.trim().isNotEmpty
        ? '${ApiConfig.baseUrl}/client/experiences/$experienceId/reviews'
        : '${ApiConfig.baseUrl}/client/explore/experiences/$experienceId/reviews';

    final uri = Uri.parse(endpoint);

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar las reseñas.',
      );
    }

    final data = Map<String, dynamic>.from(body['data'] ?? {});

    final reviews = List<Map<String, dynamic>>.from(
      data['reviews'] ?? [],
    );

    return ExperienceReviewsResponse(
      averageRating: _toDouble(data['average_rating']),
      totalReviews: _toInt(data['total_reviews']),
      reviews: reviews
          .take(limit)
          .map(ExperienceReviewModel.fromJson)
          .toList(),
    );
  }

  Future<void> deleteReview({
    required int reviewId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/reviews/$reviewId',
    );

    final response = await _client.delete(
      uri,
      headers: await _headers(),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo eliminar la reseña.',
      );
    }
  }

  Future<Map<String, String>> _headers() async {
    final token = await _secureStorage.read(
      StorageKeys.authToken,
    );

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}