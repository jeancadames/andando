// Este archivo centraliza los nombres de las llaves que vamos a usar
// para guardar datos en el almacenamiento seguro del dispositivo.
//
// ¿Por qué hacerlo aquí?
// Porque si escribimos strings como 'auth_token' en muchos archivos,
// es fácil equivocarse escribiendo una letra mal.
// Aquí lo dejamos centralizado y reutilizable.

class StorageKeys {
  // Constructor privado.
  // Esto evita que alguien haga: StorageKeys()
  // porque esta clase no necesita crear objetos.
  const StorageKeys._();

  // Llave donde guardaremos el token que venga del backend Laravel.
  // Ejemplo futuro: token de Sanctum, JWT o cualquier token de sesión.
  static const String authToken = 'auth_token';

  // Llave donde guardaremos el tipo de usuario.
  // Ejemplo: 'customer' o 'provider'.
  static const String userType = 'user_type';

  /// Estado del proveedor:
  /// pending, approved, rejected, suspended.
  static const String providerStatus = 'provider_status';

  static const String userName = 'user_name';
  static const String userEmail = 'user_email';

}