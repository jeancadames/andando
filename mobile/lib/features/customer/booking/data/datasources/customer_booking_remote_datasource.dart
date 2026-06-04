import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:http/http.dart' as http;


import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../models/customer_booking_model.dart';

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

    final bytes = Uint8List.fromList(response.bodyBytes);

    final blob = html.Blob(
      [bytes],
      'application/pdf',
    );

    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..download = 'comprobante-reserva-$bookingId.pdf'
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);
}

}