import 'package:shared_preferences/shared_preferences.dart';

/// Maneja el token de autenticación de la app.
///
/// Esta debe ser la única fuente oficial para guardar,
/// leer y borrar el token que Laravel Sanctum devuelve.
class AuthTokenStore {
  static const String tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(tokenKey);
  }
}