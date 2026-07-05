import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/config/api_config.dart';

class CustomerNotificationPreferences {
  const CustomerNotificationPreferences({
    required this.pushEnabled,
    required this.bookingNotificationsEnabled,
    required this.messageNotificationsEnabled,
    required this.paymentNotificationsEnabled,
    required this.claimNotificationsEnabled,
    required this.payoutNotificationsEnabled,
    required this.reminderNotificationsEnabled,
  });

  final bool pushEnabled;
  final bool bookingNotificationsEnabled;
  final bool messageNotificationsEnabled;
  final bool paymentNotificationsEnabled;
  final bool claimNotificationsEnabled;
  final bool payoutNotificationsEnabled;
  final bool reminderNotificationsEnabled;

  factory CustomerNotificationPreferences.fromJson(Map<String, dynamic> json) {
    return CustomerNotificationPreferences(
      pushEnabled: json['push_enabled'] as bool? ?? true,
      bookingNotificationsEnabled:
          json['booking_notifications_enabled'] as bool? ?? true,
      messageNotificationsEnabled:
          json['message_notifications_enabled'] as bool? ?? true,
      paymentNotificationsEnabled:
          json['payment_notifications_enabled'] as bool? ?? true,
      claimNotificationsEnabled:
          json['claim_notifications_enabled'] as bool? ?? true,
      payoutNotificationsEnabled:
          json['payout_notifications_enabled'] as bool? ?? true,
      reminderNotificationsEnabled:
          json['reminder_notifications_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'booking_notifications_enabled': bookingNotificationsEnabled,
      'message_notifications_enabled': messageNotificationsEnabled,
      'payment_notifications_enabled': paymentNotificationsEnabled,
      'claim_notifications_enabled': claimNotificationsEnabled,
      'payout_notifications_enabled': payoutNotificationsEnabled,
      'reminder_notifications_enabled': reminderNotificationsEnabled,
    };
  }
}

class CustomerSettingsPreferencesService {
  static const _pushEnabledKey = 'customer_notifications_push_enabled';
  static const _bookingNotificationsKey =
      'customer_notifications_bookings_enabled';
  static const _messageNotificationsKey =
      'customer_notifications_messages_enabled';
  static const _paymentNotificationsKey =
      'customer_notifications_payments_enabled';
  static const _claimNotificationsKey =
      'customer_notifications_claims_enabled';
  static const _payoutNotificationsKey =
      'customer_notifications_payouts_enabled';
  static const _reminderNotificationsKey =
      'customer_notifications_reminders_enabled';
  static const _analyticsEnabledKey = 'customer_privacy_analytics_enabled';

  Future<CustomerNotificationPreferences> fetchNotificationPreferences({
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notification-preferences'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron cargar las preferencias de notificaciones.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final preferences = CustomerNotificationPreferences.fromJson(data);

    await saveNotificationPreferences(
      pushEnabled: preferences.pushEnabled,
      bookingNotificationsEnabled: preferences.bookingNotificationsEnabled,
      messageNotificationsEnabled: preferences.messageNotificationsEnabled,
      paymentNotificationsEnabled: preferences.paymentNotificationsEnabled,
      claimNotificationsEnabled: preferences.claimNotificationsEnabled,
      payoutNotificationsEnabled: preferences.payoutNotificationsEnabled,
      reminderNotificationsEnabled: preferences.reminderNotificationsEnabled,
    );

    return preferences;
  }

  Future<CustomerNotificationPreferences> updateNotificationPreferences({
    required String token,
    required CustomerNotificationPreferences preferences,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/notification-preferences'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.trim()}',
      },
      body: jsonEncode(preferences.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudieron actualizar las preferencias de notificaciones.',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as Map<String, dynamic>;
    final updatedPreferences = CustomerNotificationPreferences.fromJson(data);

    await saveNotificationPreferences(
      pushEnabled: updatedPreferences.pushEnabled,
      bookingNotificationsEnabled:
          updatedPreferences.bookingNotificationsEnabled,
      messageNotificationsEnabled:
          updatedPreferences.messageNotificationsEnabled,
      paymentNotificationsEnabled:
          updatedPreferences.paymentNotificationsEnabled,
      claimNotificationsEnabled: updatedPreferences.claimNotificationsEnabled,
      payoutNotificationsEnabled: updatedPreferences.payoutNotificationsEnabled,
      reminderNotificationsEnabled:
          updatedPreferences.reminderNotificationsEnabled,
    );

    return updatedPreferences;
  }

  Future<CustomerNotificationPreferences> getCachedNotificationPreferences() async {
    return CustomerNotificationPreferences(
      pushEnabled: await getPushEnabled(),
      bookingNotificationsEnabled: await getBookingNotificationsEnabled(),
      messageNotificationsEnabled: await getMessageNotificationsEnabled(),
      paymentNotificationsEnabled: await getPaymentNotificationsEnabled(),
      claimNotificationsEnabled: await getClaimNotificationsEnabled(),
      payoutNotificationsEnabled: await getPayoutNotificationsEnabled(),
      reminderNotificationsEnabled: await getReminderNotificationsEnabled(),
    );
  }

  Future<bool> getPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushEnabledKey) ?? true;
  }

  Future<bool> getBookingNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bookingNotificationsKey) ?? true;
  }

  Future<bool> getMessageNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_messageNotificationsKey) ?? true;
  }

  Future<bool> getPaymentNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_paymentNotificationsKey) ?? true;
  }

  Future<bool> getClaimNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_claimNotificationsKey) ?? true;
  }

  Future<bool> getPayoutNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_payoutNotificationsKey) ?? true;
  }

  Future<bool> getReminderNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderNotificationsKey) ?? true;
  }

  Future<bool> getAnalyticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_analyticsEnabledKey) ?? true;
  }

  Future<void> saveNotificationPreferences({
    required bool pushEnabled,
    required bool bookingNotificationsEnabled,
    required bool messageNotificationsEnabled,
    required bool paymentNotificationsEnabled,
    required bool claimNotificationsEnabled,
    required bool payoutNotificationsEnabled,
    required bool reminderNotificationsEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_pushEnabledKey, pushEnabled);
    await prefs.setBool(
      _bookingNotificationsKey,
      bookingNotificationsEnabled,
    );
    await prefs.setBool(
      _messageNotificationsKey,
      messageNotificationsEnabled,
    );
    await prefs.setBool(
      _paymentNotificationsKey,
      paymentNotificationsEnabled,
    );
    await prefs.setBool(
      _claimNotificationsKey,
      claimNotificationsEnabled,
    );
    await prefs.setBool(
      _payoutNotificationsKey,
      payoutNotificationsEnabled,
    );
    await prefs.setBool(
      _reminderNotificationsKey,
      reminderNotificationsEnabled,
    );
  }

  Future<void> savePrivacyPreferences({
    required bool analyticsEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_analyticsEnabledKey, analyticsEnabled);
  }
}