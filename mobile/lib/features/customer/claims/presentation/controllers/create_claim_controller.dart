import 'package:flutter/foundation.dart';

import '../../data/datasources/customer_claim_remote_datasource.dart';

class CreateClaimController extends ChangeNotifier {
  CreateClaimController({
    CustomerClaimRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? CustomerClaimRemoteDataSource();

  final CustomerClaimRemoteDataSource _dataSource;

  bool isSubmitting = false;
  String? errorMessage;

  Future<bool> createClaim({
    required int bookingId,
    required String reason,
    required String description,
  }) async {
    if (isSubmitting) return false;

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.createClaim(
        bookingId: bookingId,
        reason: reason,
        description: description,
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