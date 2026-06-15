import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../models/customer_booking_model.dart';
import 'receipt_downloader.dart';

class CustomerBookingRemoteDataSource {
  CustomerBookingRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  Future<List<CustomerBookingModel>> getBookings() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/bookings');

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar tus reservas.',
      );
    }

    final List data = body['data'] ?? [];

    return data
        .map(
          (item) => CustomerBookingModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
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

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }

  Future<void> cancelBooking({
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/bookings/$bookingId/cancel',
    );

    final response = await _client.patch(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo cancelar la reserva.',
      );
    }
  }

  Future<void> downloadReceipt({
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/bookings/$bookingId/receipt',
    );

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo descargar el comprobante.');
    }

    await saveReceiptPdf(
      bytes: Uint8List.fromList(response.bodyBytes),
      fileName: 'comprobante-reserva-$bookingId.pdf',
    );
  }

  Future<CustomerBookingModel> createBooking({
    required int scheduleId,
    required int guestsCount,
    String? pickupPoint,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/bookings');

    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'provider_experience_schedule_id': scheduleId,
        'guests_count': guestsCount,
        if (pickupPoint != null && pickupPoint.trim().isNotEmpty)
          'pickup_point': pickupPoint,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo realizar la reserva.',
      );
    }

    final data = body['data'];

    if (data is Map) {
      return CustomerBookingModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    return CustomerBookingModel.fromJson(body);
  }

}