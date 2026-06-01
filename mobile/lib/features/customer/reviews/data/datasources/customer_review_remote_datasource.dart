import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';

/// DataSource encargado de crear y actualizar reseñas del cliente.
///
/// Este servicio usa `multipart/form-data` porque las reseñas pueden incluir
/// imágenes además de campos de texto como rating y comentario.
class CustomerReviewRemoteDataSource {
  CustomerReviewRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  /// Crea una reseña nueva para una reserva completada.
  ///
  /// Envía:
  /// - booking_id
  /// - rating
  /// - comment
  /// - photos[] opcional, máximo 6 imágenes.
  Future<void> createReview({
    required int bookingId,
    required int rating,
    required String? comment,
    List<XFile> photos = const [],
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/reviews');

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(await _multipartHeaders());

    request.fields['booking_id'] = bookingId.toString();
    request.fields['rating'] = rating.toString();

    if (comment != null && comment.trim().isNotEmpty) {
      request.fields['comment'] = comment.trim();
    }

    await _attachPhotos(
      request: request,
      photos: photos,
    );

    final response = await _sendMultipart(request);
    final body = _decodeMultipartResponse(response);

    if (response.statusCode != 201) {
      throw Exception(
        body['message'] ?? 'No se pudo publicar la reseña.',
      );
    }
  }

  /// Actualiza una reseña existente.
  ///
  /// Si `removeExistingPhotos` es true, el backend elimina las fotos anteriores
  /// antes de guardar las nuevas. Esto permite reemplazar el set de imágenes
  /// completo al editar.
  Future<void> updateReview({
    required int reviewId,
    required int rating,
    required String? comment,
    List<XFile> photos = const [],
    bool removeExistingPhotos = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/reviews/$reviewId');

    // Laravel recibe mejor uploads multipart usando POST + _method=PUT.
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll(await _multipartHeaders());

    request.fields['_method'] = 'PUT';
    request.fields['rating'] = rating.toString();
    request.fields['remove_existing_photos'] =
        removeExistingPhotos ? '1' : '0';

    if (comment != null && comment.trim().isNotEmpty) {
      request.fields['comment'] = comment.trim();
    }

    await _attachPhotos(
      request: request,
      photos: photos,
    );

    final response = await _sendMultipart(request);
    final body = _decodeMultipartResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo actualizar la reseña.',
      );
    }
  }

  /// Agrega al request multipart hasta 6 fotos.
  ///
  /// El nombre `photos[]` coincide con la validación Laravel:
  /// `photos` y `photos.*`.
  Future<void> _attachPhotos({
    required http.MultipartRequest request,
    required List<XFile> photos,
  }) async {
    final limitedPhotos = photos.take(6).toList();

    for (final photo in limitedPhotos) {
      final bytes = await photo.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'photos[]',
          bytes,
          filename: photo.name,
        ),
      );
    }
  }

  Future<void> deleteReviewPhoto({
    required int reviewId,
    required int photoId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/reviews/$reviewId/photos/$photoId',
    );

    final response = await _client.delete(
      uri,
      headers: await _multipartHeaders(),
    );

    final body = _decodeMultipartResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo eliminar la foto.',
      );
    }
  }

  /// Headers para requests multipart.
  ///
  /// No se coloca manualmente Content-Type porque `MultipartRequest`
  /// genera el boundary automáticamente.
  Future<Map<String, String>> _multipartHeaders() async {
    final token = await _secureStorage.read(StorageKeys.authToken);

    return {
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  /// Envía un request multipart y devuelve una respuesta normal.
  Future<http.Response> _sendMultipart(
    http.MultipartRequest request,
  ) async {
    final streamedResponse = await _client.send(request);

    return http.Response.fromStream(streamedResponse);
  }

  /// Decodifica la respuesta del backend.
  Map<String, dynamic> _decodeMultipartResponse(http.Response response) {
    if (response.body.isEmpty) return {};

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}