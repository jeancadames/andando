import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/customer_review_remote_datasource.dart';

/// Controlador para crear y editar reseñas de experiencias.
///
/// Maneja:
/// - validación de estrellas
/// - envío de comentario
/// - envío opcional de fotos
/// - actualización o creación según exista reviewId
/// - estados de carga y error
class CreateReviewController extends ChangeNotifier {
  CreateReviewController({
    CustomerReviewRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? CustomerReviewRemoteDataSource();

  final CustomerReviewRemoteDataSource _dataSource;

  bool isSubmitting = false;
  String? errorMessage;

  /// Crea o actualiza una reseña.
  ///
  /// Si [reviewId] viene nulo, se crea una reseña nueva.
  /// Si [reviewId] tiene valor, se actualiza la reseña existente.
  ///
  /// [photos] representa las nuevas imágenes seleccionadas por el usuario.
  /// [removeExistingPhotos] indica si se deben borrar las fotos anteriores
  /// antes de guardar las nuevas.
  Future<bool> submitReview({
    required int bookingId,
    required int rating,
    required String? comment,
    int? reviewId,
    List<XFile> photos = const [],
    bool removeExistingPhotos = false,
  }) async {
    if (rating < 1) {
      errorMessage = 'Debes seleccionar al menos una estrella.';
      notifyListeners();
      return false;
    }

    if (photos.length > 6) {
      errorMessage = 'Solo puedes subir hasta 6 fotos.';
      notifyListeners();
      return false;
    }

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (reviewId != null) {
        await _dataSource.updateReview(
          reviewId: reviewId,
          rating: rating,
          comment: comment,
          photos: photos,
          removeExistingPhotos: removeExistingPhotos,
        );
      } else {
        await _dataSource.createReview(
          bookingId: bookingId,
          rating: rating,
          comment: comment,
          photos: photos,
        );
      }

      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> deleteReviewPhoto({
    required int reviewId,
    required int photoId,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.deleteReviewPhoto(
        reviewId: reviewId,
        photoId: photoId,
      );

      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

}