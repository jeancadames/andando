import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Esta clase es un wrapper, o sea, una capa encima de FlutterSecureStorage.
//
// ¿Para qué sirve?
// Para que el resto de la app no use directamente FlutterSecureStorage.
// Así, si mañana cambiamos la forma de guardar datos, solo modificamos este archivo.
class SecureStorage {
  SecureStorage();

  // Instancia del paquete que guarda datos de forma segura.
  //
  // Aquí se guardarán cosas sensibles como:
  // - token de autenticación
  // - tipo de usuario
  // - datos pequeños de sesión
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Lee un valor guardado usando una llave.
  //
  // Ejemplo:
  // final token = await secureStorage.read('auth_token');
  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  // Guarda un valor en almacenamiento seguro.
  //
  // Ejemplo:
  // await secureStorage.write(
  //   key: 'auth_token',
  //   value: 'abc123',
  // );
  Future<void> write({
    required String key,
    required String value,
  }) {
    return _storage.write(
      key: key,
      value: value,
    );
  }

  // Elimina una sola llave del almacenamiento seguro.
  //
  // Ejemplo:
  // await secureStorage.delete('auth_token');
  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  // Limpia todo lo que se haya guardado en secure storage.
  //
  // Esto lo usaremos para logout.
  Future<void> clear() {
    return _storage.deleteAll();
  }
}