/// Configuración central de API.
///
/// Usa --dart-define para cambiar la URL sin tocar código.
/// Ejemplo:
/// flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );
}