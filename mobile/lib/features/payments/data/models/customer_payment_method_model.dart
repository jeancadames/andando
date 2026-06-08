/// Modelo de método de pago del cliente.
///
/// Representa una tarjeta tokenizada por Azul Datavault.
///
/// IMPORTANTE:
/// No contiene número completo ni CVV.
class CustomerPaymentMethodModel {
  final int id;
  final String gateway;
  final String type;
  final String brand;
  final String last4;
  final String? maskedCardNumber;
  final String holderName;
  final int expiryMonth;
  final int expiryYear;
  final String expiryLabel;
  final bool isDefault;
  final bool hasToken;

  const CustomerPaymentMethodModel({
    required this.id,
    required this.gateway,
    required this.type,
    required this.brand,
    required this.last4,
    required this.maskedCardNumber,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.expiryLabel,
    required this.isDefault,
    required this.hasToken,
  });

  factory CustomerPaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentMethodModel(
      id: _toInt(json['id']),
      gateway: json['gateway']?.toString() ?? 'azul',
      type: json['type']?.toString() ?? 'credit',
      brand: json['brand']?.toString() ?? 'unknown',
      last4: json['last4']?.toString() ?? '',
      maskedCardNumber: json['masked_card_number']?.toString(),
      holderName: json['holder_name']?.toString() ?? '',
      expiryMonth: _toInt(json['expiry_month']),
      expiryYear: _toInt(json['expiry_year']),
      expiryLabel: json['expiry_label']?.toString() ?? '',
      isDefault: json['is_default'] == true ||
          json['is_default']?.toString() == '1',
      hasToken: json['has_token'] == true ||
          json['has_token']?.toString() == '1',
    );
  }

  String get typeLabel {
    if (type == 'debit') return 'Tarjeta de Débito';
    return 'Tarjeta de Crédito';
  }

  String get brandLabel {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'VISA';
      case 'mastercard':
        return 'Mastercard';
      case 'amex':
        return 'AMEX';
      case 'discover':
        return 'Discover';
      default:
        return 'Tarjeta';
    }
  }

  String get safeMaskedNumber {
    if (maskedCardNumber != null && maskedCardNumber!.trim().isNotEmpty) {
      return maskedCardNumber!;
    }

    if (last4.isNotEmpty) {
      return '•••• •••• •••• $last4';
    }

    return '•••• •••• •••• ••••';
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}