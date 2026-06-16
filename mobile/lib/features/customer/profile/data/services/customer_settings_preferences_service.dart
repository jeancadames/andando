import 'package:shared_preferences/shared_preferences.dart';

class CustomerSettingsPreferencesService {
  static const _pushEnabledKey = 'customer_notifications_push_enabled';
  static const _bookingNotificationsKey =
      'customer_notifications_bookings_enabled';
  static const _messageNotificationsKey =
      'customer_notifications_messages_enabled';
  static const _paymentNotificationsKey =
      'customer_notifications_payments_enabled';
  static const _reviewNotificationsKey =
      'customer_notifications_reviews_enabled';
  static const _analyticsEnabledKey = 'customer_privacy_analytics_enabled';

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

  Future<bool> getReviewNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reviewNotificationsKey) ?? true;
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
    required bool reviewNotificationsEnabled,
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
      _reviewNotificationsKey,
      reviewNotificationsEnabled,
    );
  }

  Future<void> savePrivacyPreferences({
    required bool analyticsEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_analyticsEnabledKey, analyticsEnabled);
  }
}