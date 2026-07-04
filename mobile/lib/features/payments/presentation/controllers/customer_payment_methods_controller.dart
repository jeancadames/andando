import 'package:flutter/material.dart';

import '../../data/datasources/customer_payment_methods_remote_datasource.dart';
import '../../data/models/customer_payment_method_model.dart';
import '../../data/models/customer_payment_transaction_model.dart';

/// Controlador de estado para métodos de pago del cliente.
///
/// Maneja:
/// - cargar tarjetas tokenizadas
/// - iniciar tokenización segura con Azul Payment Page
/// - establecer tarjeta principal
/// - eliminar tarjeta/token
///
/// IMPORTANTE:
/// Flutter NO captura número de tarjeta, CVV ni vencimiento.
/// La tarjeta se registra directamente en Azul.
/// AndanDO solo guarda el token y datos visuales seguros.
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

  Future<bool> createPaymentMethod({
    required String type,
    required String cardNumber,
    required String holderName,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _dataSource.createPaymentMethod(
        type: type,
        cardNumber: cardNumber,
        holderName: holderName,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvv: cvv,
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
  /// - elimina/desactiva el token en Azul si aplica.
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