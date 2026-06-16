import 'package:shared_preferences/shared_preferences.dart';

class CustomerLocationPreferencesService {
  static const _gpsEnabledKey = 'customer_location_gps_enabled';
  static const _autoDetectEnabledKey = 'customer_location_auto_detect_enabled';
  static const _searchRadiusKmKey = 'customer_location_search_radius_km';

  Future<bool> getGpsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_gpsEnabledKey) ?? true;
  }

  Future<bool> getAutoDetectEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoDetectEnabledKey) ?? false;
  }

  Future<int> getSearchRadiusKm() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_searchRadiusKmKey) ?? 50;
  }

  Future<void> save({
    required bool gpsEnabled,
    required bool autoDetectEnabled,
    required int searchRadiusKm,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_gpsEnabledKey, gpsEnabled);
    await prefs.setBool(_autoDetectEnabledKey, autoDetectEnabled);
    await prefs.setInt(_searchRadiusKmKey, searchRadiusKm);
  }
}