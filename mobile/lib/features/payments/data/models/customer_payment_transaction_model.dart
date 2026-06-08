class CustomerPaymentTransactionModel {
  final int id;
  final int bookingId;
  final String title;
  final String? date;
  final String? dateLabel;
  final double amount;
  final String currency;
  final String? paymentMethodLabel;
  final String status;
  final String statusLabel;
  final String type;

  const CustomerPaymentTransactionModel({
    required this.id,
    required this.bookingId,
    required this.title,
    required this.date,
    required this.dateLabel,
    required this.amount,
    required this.currency,
    required this.paymentMethodLabel,
    required this.status,
    required this.statusLabel,
    required this.type,
  });

  factory CustomerPaymentTransactionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return CustomerPaymentTransactionModel(
      id: _toInt(json['id']),
      bookingId: _toInt(json['booking_id']),
      title: json['title']?.toString() ?? 'Reserva',
      date: json['date']?.toString(),
      dateLabel: json['date_label']?.toString(),
      amount: _toDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'DOP',
      paymentMethodLabel: json['payment_method_label']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      statusLabel: json['status_label']?.toString() ?? 'Pendiente',
      type: json['type']?.toString() ?? 'charge',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}