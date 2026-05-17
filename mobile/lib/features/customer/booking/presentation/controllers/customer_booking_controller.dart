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
    return bookings.where((booking) => booking.isUpcoming).toList();
  }

  List<CustomerBookingModel> get completedBookings {
    return bookings.where((booking) => booking.isCompleted).toList();
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
}