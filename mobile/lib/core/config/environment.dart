/// Configuración de ambiente.
///
/// Aquí ponemos URLs y valores que cambian entre local,
/// staging y producción.
class Environment {
  const Environment._();

  /// URL base del backend Laravel.
  ///
  /// Para Chrome web con Laravel corriendo local:
  /// http://127.0.0.1:8000/api
  ///
  /// Para Android emulator normalmente sería:
  /// http://10.0.2.2:8000/api
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api';
}