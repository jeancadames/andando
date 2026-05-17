import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile/core/config/api_config.dart';
import 'package:mobile/core/constants/storage_keys.dart';
import 'package:mobile/core/storage/secure_storage.dart';

class CustomerBookingRemoteDataSource {
  CustomerBookingRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  Future<CustomerBookingResponse> createBooking({
    required int scheduleId,
    required int guestsCount,
  }) async {
    final token = await _secureStorage.read(StorageKeys.authToken);

    if (token == null || token.trim().isEmpty) {
      throw CustomerBookingException(
        'Debes iniciar sesión para crear una reserva.',
      );
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/client/bookings');

    final response = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'provider_experience_schedule_id': scheduleId,
        'guests_count': guestsCount,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw CustomerBookingException(
        decoded is Map && decoded['message'] != null
            ? decoded['message'].toString()
            : 'No se pudo crear la reserva.',
      );
    }

    return CustomerBookingResponse.fromJson(
      decoded['data'] as Map<String, dynamic>,
    );
  }
}

class CustomerBookingResponse {
  final int id;
  final String bookingCode;
  final String status;
  final double totalAmount;

  const CustomerBookingResponse({
    required this.id,
    required this.bookingCode,
    required this.status,
    required this.totalAmount,
  });

  factory CustomerBookingResponse.fromJson(Map<String, dynamic> json) {
    return CustomerBookingResponse(
      id: int.tryParse(json['id'].toString()) ?? 0,
      bookingCode: json['booking_code']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0,
    );
  }
}

class CustomerBookingException implements Exception {
  final String message;

  const CustomerBookingException(this.message);

  @override
  String toString() => message;
}