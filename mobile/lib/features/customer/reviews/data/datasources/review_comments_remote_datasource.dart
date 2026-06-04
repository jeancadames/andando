import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../models/review_comment_model.dart';

class ReviewCommentsRemoteDataSource {
  ReviewCommentsRemoteDataSource({
    http.Client? client,
    SecureStorage? secureStorage,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorage();

  final http.Client _client;
  final SecureStorage _secureStorage;

  Future<List<ReviewCommentModel>> getComments({
    required int reviewId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/reviews/$reviewId/comments',
    );

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar los comentarios.',
      );
    }

    final data = List<Map<String, dynamic>>.from(body['data'] ?? []);

    return data.map(ReviewCommentModel.fromJson).toList();
  }

  Future<ReviewCommentModel> createComment({
    required int reviewId,
    required String comment,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/reviews/$reviewId/comments',
    );

    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'comment': comment,
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 201) {
      throw Exception(
        body['message'] ?? 'No se pudo publicar el comentario.',
      );
    }

    return ReviewCommentModel.fromJson(
      Map<String, dynamic>.from(body['data'] ?? {}),
    );
  }

  Future<ReviewCommentModel> updateComment({
    required int commentId,
    required String comment,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/review-comments/$commentId',
    );

    final response = await _client.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'comment': comment,
      }),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo actualizar el comentario.',
      );
    }

    return ReviewCommentModel.fromJson(
      Map<String, dynamic>.from(body['data'] ?? {}),
    );
  }

  Future<void> deleteComment({
    required int commentId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/review-comments/$commentId',
    );

    final response = await _client.delete(
      uri,
      headers: await _headers(),
    );

    final body = _decode(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo eliminar el comentario.',
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

  Map<String, dynamic> _decode(http.Response response) {
    if (response.body.isEmpty) return {};

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}