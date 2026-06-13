import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';

class ProviderExperienceReviewsService {
  String get _baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    final cleanedEnvUrl = _cleanBaseUrl(envUrl);

    // Flutter Web / Chrome no puede usar 10.0.2.2.
    // En web usamos localhost/127.0.0.1.
    if (kIsWeb) {
      if (cleanedEnvUrl.isEmpty || cleanedEnvUrl.contains('10.0.2.2')) {
        return ApiConfig.baseUrl;
      }

      return cleanedEnvUrl;
    }

    if (cleanedEnvUrl.isNotEmpty) {
      return cleanedEnvUrl;
    }

    // Android Emulator.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }

    // iOS simulator / desktop.
    return ApiConfig.baseUrl;
  }

  String _cleanBaseUrl(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }

    return trimmed;
  }

  Uri _uri(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$cleanPath');

    debugPrint('REVIEWS API URL: $uri');

    return uri;
  }

  Map<String, String> _headers(String? token) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer ${token.trim()}',
    };
  }

  Future<ProviderExperienceReviewSummary> getSummary({
    required int experienceId,
    required String? token,
  }) async {
    final response = await http.get(
      _uri('/provider/experiences/$experienceId/reviews/summary'),
      headers: _headers(token),
    );

    debugPrint('REVIEWS SUMMARY STATUS: ${response.statusCode}');
    debugPrint('REVIEWS SUMMARY BODY: ${response.body}');

    return _handleSummaryResponse(response);
  }

  Future<ProviderExperienceReviewSummary> getReviews({
    required int experienceId,
    required String? token,
  }) async {
    final response = await http.get(
      _uri('/provider/experiences/$experienceId/reviews'),
      headers: _headers(token),
    );

    debugPrint('REVIEWS STATUS: ${response.statusCode}');
    debugPrint('REVIEWS BODY: ${response.body}');

    return _handleSummaryResponse(response);
  }

  /// Crea o edita la respuesta del afiliado.
  ///
  /// Backend:
  /// POST /api/provider/experiences/{experienceId}/reviews/{reviewId}/reply
  Future<void> replyToReview({
    required int experienceId,
    required int reviewId,
    required String responseText,
    required String? token,
  }) async {
    final response = await http.post(
      _uri('/provider/experiences/$experienceId/reviews/$reviewId/reply'),
      headers: _headers(token),
      body: jsonEncode({
        'response': responseText.trim(),
      }),
    );

    debugPrint('REPLY REVIEW STATUS: ${response.statusCode}');
    debugPrint('REPLY REVIEW BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response));
    }
  }

  /// Elimina la respuesta del afiliado.
  ///
  /// Backend:
  /// DELETE /api/provider/experiences/{experienceId}/reviews/{reviewId}/reply
  Future<void> deleteReply({
    required int experienceId,
    required int reviewId,
    required String? token,
  }) async {
    final response = await http.delete(
      _uri('/provider/experiences/$experienceId/reviews/$reviewId/reply'),
      headers: _headers(token),
    );

    debugPrint('DELETE REVIEW REPLY STATUS: ${response.statusCode}');
    debugPrint('DELETE REVIEW REPLY BODY: ${response.body}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response));
    }
  }

  ProviderExperienceReviewSummary _handleSummaryResponse(
    http.Response response,
  ) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractError(response));
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor.');
    }

    final data = decoded['data'];

    if (data is! Map) {
      throw Exception('La respuesta no contiene data válida.');
    }

    return ProviderExperienceReviewSummary.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  String _extractError(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['error']?.toString() ??
            'No pudimos procesar la solicitud.';
      }

      return 'No pudimos procesar la solicitud.';
    } catch (_) {
      return 'No pudimos procesar la solicitud.';
    }
  }
}

class ProviderExperienceReviewSummary {
  final int experienceId;
  final String experienceTitle;
  final double averageRating;
  final int totalReviews;
  final List<ProviderRatingDistribution> ratingDistribution;
  final List<ProviderExperienceReview> reviews;

  const ProviderExperienceReviewSummary({
    required this.experienceId,
    required this.experienceTitle,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.reviews,
  });

  factory ProviderExperienceReviewSummary.fromJson(Map<String, dynamic> json) {
    return ProviderExperienceReviewSummary(
      experienceId: int.tryParse(json['experience_id']?.toString() ?? '') ?? 0,
      experienceTitle: json['experience_title']?.toString() ?? 'Experiencia',
      averageRating:
          double.tryParse(json['average_rating']?.toString() ?? '') ?? 0.0,
      totalReviews: int.tryParse(json['total_reviews']?.toString() ?? '') ?? 0,
      ratingDistribution: _parseRatingDistribution(
        json['rating_distribution'],
      ),
      reviews: _parseReviews(
        json['reviews'],
      ),
    );
  }

  static List<ProviderRatingDistribution> _parseRatingDistribution(
    dynamic value,
  ) {
    if (value is! List) {
      return const [
        ProviderRatingDistribution(stars: 5, count: 0, percentage: 0),
        ProviderRatingDistribution(stars: 4, count: 0, percentage: 0),
        ProviderRatingDistribution(stars: 3, count: 0, percentage: 0),
        ProviderRatingDistribution(stars: 2, count: 0, percentage: 0),
        ProviderRatingDistribution(stars: 1, count: 0, percentage: 0),
      ];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => ProviderRatingDistribution.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  static List<ProviderExperienceReview> _parseReviews(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => ProviderExperienceReview.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}

class ProviderRatingDistribution {
  final int stars;
  final int count;
  final int percentage;

  const ProviderRatingDistribution({
    required this.stars,
    required this.count,
    required this.percentage,
  });

  factory ProviderRatingDistribution.fromJson(Map<String, dynamic> json) {
    return ProviderRatingDistribution(
      stars: int.tryParse(json['stars']?.toString() ?? '') ?? 0,
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
      percentage: int.tryParse(json['percentage']?.toString() ?? '') ?? 0,
    );
  }
}

class ProviderExperienceReview {
  final int id;
  final String clientName;
  final String clientInitials;
  final int rating;
  final String? comment;
  final String? date;
  final ProviderReviewResponse? response;

  const ProviderExperienceReview({
    required this.id,
    required this.clientName,
    required this.clientInitials,
    required this.rating,
    required this.comment,
    required this.date,
    required this.response,
  });

  factory ProviderExperienceReview.fromJson(Map<String, dynamic> json) {
    final response = json['response'];

    return ProviderExperienceReview(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      clientName: json['client_name']?.toString() ?? 'Cliente',
      clientInitials: json['client_initials']?.toString() ?? 'CL',
      rating: int.tryParse(json['rating']?.toString() ?? '') ?? 0,
      comment: json['comment']?.toString(),
      date: json['date']?.toString() ?? json['created_at']?.toString(),
      response: response is Map
          ? ProviderReviewResponse.fromJson(
              Map<String, dynamic>.from(response),
            )
          : _responseFromLegacyFields(json),
    );
  }

  static ProviderReviewResponse? _responseFromLegacyFields(
    Map<String, dynamic> json,
  ) {
    final text = json['provider_response']?.toString();

    if (text == null || text.trim().isEmpty) {
      return null;
    }

    return ProviderReviewResponse(
      text: text,
      date: json['provider_response_at']?.toString(),
    );
  }
}

class ProviderReviewResponse {
  final String text;
  final String? date;

  const ProviderReviewResponse({
    required this.text,
    required this.date,
  });

  factory ProviderReviewResponse.fromJson(Map<String, dynamic> json) {
    return ProviderReviewResponse(
      text: json['text']?.toString() ?? '',
      date: json['date']?.toString(),
    );
  }
}