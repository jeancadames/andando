import 'package:flutter/material.dart';

import '../../data/datasources/customer_review_remote_datasource.dart';

class CreateReviewController extends ChangeNotifier {
  CreateReviewController({
    CustomerReviewRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? CustomerReviewRemoteDataSource();

  final CustomerReviewRemoteDataSource _dataSource;

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> submitReview({
    required int bookingId,
    required int rating,
    required String? comment,
    int? reviewId,
  }) async {
    if (rating < 1) {
      errorMessage = 'Debes seleccionar al menos una estrella.';
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
        );
      } else {
        await _dataSource.createReview(
          bookingId: bookingId,
          rating: rating,
          comment: comment,
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
}