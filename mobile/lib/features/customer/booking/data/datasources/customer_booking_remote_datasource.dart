import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:package_info_plus/package_info_plus.dart';
import '../../../../../core/config/api_config.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/storage/secure_storage.dart';
import '../models/customer_booking_model.dart';
import 'receipt_downloader.dart';

class CustomerBookingRemoteDataSource {
  CustomerBookingRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  }) : _secureStorage = secureStorage ?? SecureStorage(),
       _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  Future<List<CustomerBookingModel>> getBookings() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/bookings');

    final response = await _client.get(uri, headers: await _headers());

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'No se pudieron cargar tus reservas.');
    }

    final List data = body['data'] ?? [];

    return data
        .map(
          (item) =>
              CustomerBookingModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<Map<String, String>> _headers() async {
    final token = await _secureStorage.read(StorageKeys.authToken);
    final packageInfo = await PackageInfo.fromPlatform();

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Platform': 'flutter',
      'X-Locale': 'es',
      'X-App-Version': '${packageInfo.version}+${packageInfo.buildNumber}',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  Future<CustomerCancellationPreview> getCancellationPreview({
    required int bookingId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/bookings/$bookingId/cancellation-preview',
    );

    final response = await _client.get(uri, headers: await _headers());

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'No se pudo calcular la cancelación.');
    }

    final data = body['data'];

    if (data is! Map) {
      throw Exception('No se pudo calcular la cancelación.');
    }

    return CustomerCancellationPreview.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<void> cancelBooking({required int bookingId}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/bookings/$bookingId/cancel',
    );

    final response = await _client.patch(uri, headers: await _headers());

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'No se pudo cancelar la reserva.');
    }
  }

  Future<void> downloadReceipt({required int bookingId}) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/bookings/$bookingId/receipt',
    );

    final response = await _client.get(uri, headers: await _headers());

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
    required bool includesMinors,
    required int minorCount,
    required int paymentPolicyDocumentId,
    required String paymentPolicyChecksum,
    required bool paymentPolicyAccepted,
    required int waiverDocumentId,
    required String waiverChecksum,
    required bool waiverAccepted,
    int? minorsDocumentId,
    String? minorsChecksum,
    bool minorsAccepted = false,
    String? pickupPoint,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/bookings');

    final response = await _client.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'provider_experience_schedule_id': scheduleId,
        'guests_count': guestsCount,
        'includes_minors': includesMinors,
        'minor_count': includesMinors ? minorCount : 0,
        'payment_policy_document_id': paymentPolicyDocumentId,
        'payment_policy_checksum': paymentPolicyChecksum,
        'payment_policy_accepted': paymentPolicyAccepted,
        'waiver_document_id': waiverDocumentId,
        'waiver_checksum': waiverChecksum,
        'waiver_accepted': waiverAccepted,
        if (includesMinors) ...{
          'minors_document_id': minorsDocumentId,
          'minors_checksum': minorsChecksum,
          'minors_accepted': minorsAccepted,
        },
        if (pickupPoint != null && pickupPoint.trim().isNotEmpty)
          'pickup_point': pickupPoint,
      }),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw CustomerBookingException(
        message: body['message'] ?? 'No se pudo realizar la reserva.',
        code: body['code']?.toString(),
      );
    }

    final data = body['data'];

    if (data is Map) {
      return CustomerBookingModel.fromJson(Map<String, dynamic>.from(data));
    }

    return CustomerBookingModel.fromJson(body);
  }
}

class CustomerBookingException implements Exception {
  final String message;
  final String? code;

  CustomerBookingException({required this.message, this.code});

  @override
  String toString() => message;
}

class CustomerCancellationPreview {
  final bool canCancel;
  final String policyType;
  final double totalAmount;
  final double refundAmount;
  final double administrativeFeeAmount;
  final int refundPercentage;
  final String message;

  const CustomerCancellationPreview({
    required this.canCancel,
    required this.policyType,
    required this.totalAmount,
    required this.refundAmount,
    required this.administrativeFeeAmount,
    required this.refundPercentage,
    required this.message,
  });

  factory CustomerCancellationPreview.fromJson(Map<String, dynamic> json) {
    return CustomerCancellationPreview(
      canCancel: json['can_cancel'] == true,
      policyType: json['policy_type']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
      administrativeFeeAmount:
          (json['administrative_fee_amount'] as num?)?.toDouble() ?? 0,
      refundPercentage: (json['refund_percentage'] as num?)?.toInt() ?? 0,
      message: json['message']?.toString() ?? '',
    );
  }
}
