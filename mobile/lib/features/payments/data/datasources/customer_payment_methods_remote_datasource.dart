import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/api_config.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/secure_storage.dart';
import '../models/customer_payment_method_model.dart';
import '../models/customer_payment_transaction_model.dart';

/// Datasource remoto para métodos de pago del cliente.
///
/// Consume:
/// - GET    /api/client/payment-methods
/// - POST   /api/payments/azul/payment-page/session
/// - PATCH  /api/client/payment-methods/{id}/default
/// - DELETE /api/client/payment-methods/{id}
///
/// IMPORTANTE:
/// Flutter NO captura ni envía:
/// - número de tarjeta
/// - CVV
/// - fecha de vencimiento digitada
/// - titular
///
/// El cliente registra la tarjeta directamente en Azul Payment Page.
/// AndanDO guarda solo DataVaultToken y datos visuales seguros.
class CustomerPaymentMethodsRemoteDataSource {
  CustomerPaymentMethodsRemoteDataSource({
    SecureStorage? secureStorage,
    http.Client? client,
  })  : _secureStorage = secureStorage ?? SecureStorage(),
        _client = client ?? http.Client();

  final SecureStorage _secureStorage;
  final http.Client _client;

  /// Lista las tarjetas guardadas del cliente.
  Future<List<CustomerPaymentMethodModel>> getPaymentMethods() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/payment-methods');

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar los métodos de pago.',
      );
    }

    final data = Map<String, dynamic>.from(body['data'] ?? {});
    final list = List<Map<String, dynamic>>.from(
      data['payment_methods'] ?? [],
    );

    return list.map(CustomerPaymentMethodModel.fromJson).toList();
  }

  /// Lista las transacciones recientes del cliente.
  ///
  /// Consume:
  /// GET /api/client/payment-transactions
  Future<List<CustomerPaymentTransactionModel>> getPaymentTransactions() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/client/payment-transactions');

    final response = await _client.get(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudieron cargar las transacciones.',
      );
    }

    final data = Map<String, dynamic>.from(body['data'] ?? {});
    final list = List<Map<String, dynamic>>.from(
      data['transactions'] ?? [],
    );

    return list.map(CustomerPaymentTransactionModel.fromJson).toList();
  }

  /// Crea una sesión segura de tokenización en backend.
  ///
  /// Backend responde una redirect_url pública.
  /// Flutter abre esa URL en WebView o navegador.
  Future<Map<String, dynamic>> getAzulTokenizationWebViewRequest() async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/payments/azul/payment-page/session',
    );

    final response = await _client.post(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo iniciar la tokenización.',
      );
    }

    final data = Map<String, dynamic>.from(body['data'] ?? {});

    final redirectUrl = data['redirect_url']?.toString();

    if (redirectUrl == null || redirectUrl.trim().isEmpty) {
      throw Exception('El backend no devolvió la URL de tokenización.');
    }

    return {
      'url': redirectUrl,
      'headers': <String, String>{
        'Accept': 'text/html',
      },
    };
  }

  /// Establece una tarjeta como principal.
  Future<CustomerPaymentMethodModel> setDefaultPaymentMethod({
    required int paymentMethodId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/payment-methods/$paymentMethodId/default',
    );

    final response = await _client.patch(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo establecer la tarjeta principal.',
      );
    }

    final data = Map<String, dynamic>.from(body['data'] ?? {});

    return CustomerPaymentMethodModel.fromJson(
      Map<String, dynamic>.from(data['payment_method'] ?? {}),
    );
  }

  /// Elimina una tarjeta guardada.
  ///
  /// Laravel intentará eliminar/desactivar el token en Azul
  /// y luego hará soft delete local.
  Future<void> deletePaymentMethod({
    required int paymentMethodId,
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/client/payment-methods/$paymentMethodId',
    );

    final response = await _client.delete(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response);

    if (response.statusCode != 200) {
      throw Exception(
        body['message'] ?? 'No se pudo eliminar la tarjeta.',
      );
    }
  }

  /// Headers autenticados.
  Future<Map<String, String>> _headers() async {
    final token = await _secureStorage.read(StorageKeys.authToken);

    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  /// Decodifica JSON de forma segura.
  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    return Map<String, dynamic>.from(
      jsonDecode(response.body),
    );
  }
}