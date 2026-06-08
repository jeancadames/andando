import 'package:flutter/material.dart';

import '../../data/datasources/customer_payment_methods_remote_datasource.dart';
import '../../data/models/customer_payment_method_model.dart';
import '../../data/models/customer_payment_transaction_model.dart';

/// Controlador de estado para métodos de pago del cliente.
///
/// Maneja:
/// - cargar tarjetas tokenizadas
/// - solicitar tokenización/guardado de tarjeta
/// - establecer tarjeta principal
/// - eliminar tarjeta/token
class CustomerPaymentMethodsController extends ChangeNotifier {
  CustomerPaymentMethodsController({
    CustomerPaymentMethodsRemoteDataSource? dataSource,
  }) : _dataSource = dataSource ?? CustomerPaymentMethodsRemoteDataSource();

  final CustomerPaymentMethodsRemoteDataSource _dataSource;

  bool isLoading = false;
  bool isSaving = false;
  bool isDeleting = false;

  String? errorMessage;

  List<CustomerPaymentMethodModel> paymentMethods = [];

  List<CustomerPaymentTransactionModel> transactions = [];

  int selectedIndex = 0;

  CustomerPaymentMethodModel? get selectedPaymentMethod {
    if (paymentMethods.isEmpty) return null;

    if (selectedIndex < 0 || selectedIndex >= paymentMethods.length) {
      return paymentMethods.first;
    }

    return paymentMethods[selectedIndex];
  }

  /// Carga tarjetas guardadas desde backend.
  Future<void> loadPaymentMethods() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      paymentMethods = await _dataSource.getPaymentMethods();
      transactions = await _dataSource.getPaymentTransactions();

      if (selectedIndex >= paymentMethods.length) {
        selectedIndex = 0;
      }
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Cambia tarjeta seleccionada.
  void selectPaymentMethod(int index) {
    if (index < 0 || index >= paymentMethods.length) return;

    selectedIndex = index;
    notifyListeners();
  }

  /// Solicita tokenización y guardado de una tarjeta.
  ///
  /// IMPORTANTE:
  /// Flutter envía número y CVV temporalmente a Laravel.
  /// Laravel debe enviarlo a Azul y guardar solo token + datos seguros.
  Future<bool> createPaymentMethod({
    required String type,
    required String cardNumber,
    required String holderName,
    required String expiry,
    required String cvv,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      final expiryParts = expiry.split('/');

      if (expiryParts.length != 2) {
        throw Exception('Fecha de vencimiento inválida.');
      }

      final expiryMonth = int.tryParse(expiryParts[0]) ?? 0;
      final expiryYearShort = int.tryParse(expiryParts[1]) ?? 0;
      final expiryYear = 2000 + expiryYearShort;

      await _dataSource.createPaymentMethod(
        type: type,
        cardNumber: cardNumber,
        holderName: holderName.trim().toUpperCase(),
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
      );

      await loadPaymentMethods();

      selectedIndex = paymentMethods.isEmpty ? 0 : paymentMethods.length - 1;

      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Establece tarjeta seleccionada como principal.
  Future<bool> setDefaultSelectedPaymentMethod() async {
    final selected = selectedPaymentMethod;

    if (selected == null) return false;

    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.setDefaultPaymentMethod(
        paymentMethodId: selected.id,
      );

      await loadPaymentMethods();

      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Elimina tarjeta seleccionada.
  ///
  /// Backend:
  /// - elimina token en Azul si existe.
  /// - hace soft delete local.
  Future<bool> deleteSelectedPaymentMethod() async {
    final selected = selectedPaymentMethod;

    if (selected == null) return false;

    isDeleting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.deletePaymentMethod(
        paymentMethodId: selected.id,
      );

      await loadPaymentMethods();

      if (selectedIndex >= paymentMethods.length) {
        selectedIndex = 0;
      }

      return true;
    } catch (error) {
      errorMessage = error.toString();
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }
}