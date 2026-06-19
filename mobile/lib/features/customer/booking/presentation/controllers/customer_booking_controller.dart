import 'package:flutter/material.dart';

import '../../data/datasources/customer_booking_remote_datasource.dart';
import '../../data/models/customer_booking_model.dart';

class CustomerBookingController extends ChangeNotifier {
  CustomerBookingController({
    CustomerBookingRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? CustomerBookingRemoteDataSource();

  final CustomerBookingRemoteDataSource _dataSource;

  bool isLoading = false;
  String? errorMessage;

  List<CustomerBookingModel> bookings = [];

  List<CustomerBookingModel> get upcomingBookings {
    return bookings.where((booking) {
      return !booking.isCompleted && !booking.isCancelled;
    }).toList();
  }

  List<CustomerBookingModel> get completedBookings {
    return bookings.where((booking) => booking.isCompleted).toList();
  }

  List<CustomerBookingModel> get cancelledBookings {
    return bookings.where((booking) => booking.isCancelled).toList();
  }

  Future<void> initialize() async {
    await loadBookings();
  }

  Future<void> loadBookings() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      bookings = await _dataSource.getBookings();
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<CustomerCancellationPreview?> getCancellationPreview(int bookingId) async {
    errorMessage = null;
    notifyListeners();

    try {
      return await _dataSource.getCancellationPreview(
        bookingId: bookingId,
      );
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  Future<bool> cancelBooking(int bookingId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.cancelBooking(
        bookingId: bookingId,
      );

      await loadBookings();

      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> downloadReceipt(int bookingId) async {
    try {
      await _dataSource.downloadReceipt(
        bookingId: bookingId,
      );

      return true;
    } catch (_) {
      return false;
    }
  }

}