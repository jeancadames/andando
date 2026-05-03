import 'package:flutter/foundation.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/secure_storage.dart';

/// Representa el estado actual de autenticación de la aplicación.
///
/// Este enum es importante porque la app necesita saber si:
///
/// - todavía está revisando si hay sesión guardada.
/// - el usuario ya tiene sesión activa.
/// - el usuario no tiene sesión.
///
/// Este estado será usado por el router para decidir si mostrar:
/// - WelcomeScreen
/// - ProviderVerificationPendingScreen
/// - ProviderDashboard
/// - ClientExplore
enum AuthStatus {
  /// Estado inicial mientras la app lee el token guardado.
  ///
  /// Ejemplo:
  /// La app abre y todavía no sabemos si el usuario tiene sesión.
  checking,

  /// El usuario tiene un token guardado.
  ///
  /// Esto no significa necesariamente que el token sea válido en backend,
  /// pero sí significa que localmente existe una sesión.
  authenticated,

  /// No hay token guardado.
  ///
  /// La app debe mandar al usuario al WelcomeScreen.
  unauthenticated,
}

/// Controlador global de autenticación.
///
/// Esta clase es una pieza central de la app.
/// Su responsabilidad es manejar:
///
/// - lectura del token guardado.
/// - guardado de sesión después de login o registro.
/// - cierre de sesión.
/// - datos mínimos del usuario autenticado.
/// - estado del proveedor.
///
/// Extiende ChangeNotifier porque go_router necesita escuchar cambios.
/// Cuando llamamos notifyListeners(), el router vuelve a evaluar
/// las redirecciones automáticamente.
class AuthController extends ChangeNotifier {
  AuthController({
    required SecureStorage secureStorage,
  }) : _secureStorage = secureStorage;

  /// Servicio encargado de leer/escribir datos sensibles.
  ///
  /// Aquí se guardan:
  /// - token
  /// - tipo de usuario
  /// - email
  /// - nombre
  /// - estado del proveedor
  final SecureStorage _secureStorage;

  /// Estado interno de autenticación.
  ///
  /// Arranca en checking porque al abrir la app todavía no sabemos
  /// si hay una sesión guardada.
  AuthStatus _status = AuthStatus.checking;

  /// Token de autenticación devuelto por Laravel/Sanctum.
  ///
  /// Este token se enviará luego en el header:
  /// Authorization: Bearer <token>
  String? _token;

  /// Tipo de usuario autenticado.
  ///
  /// Valores esperados:
  /// - customer
  /// - provider
  /// - admin
  String? _userType;

  /// Estado del proveedor.
  ///
  /// Esto solo aplica cuando userType == provider.
  ///
  /// Valores esperados:
  /// - pending
  /// - approved
  /// - rejected
  /// - suspended
  String? _providerStatus;

  /// Nombre del usuario autenticado.
  String? _userName;

  /// Email del usuario autenticado.
  String? _userEmail;

  /// Getter público del estado.
  ///
  /// Otras clases pueden leerlo, pero no modificarlo directamente.
  AuthStatus get status => _status;

  /// Getter del token actual.
  String? get token => _token;

  /// Getter del tipo de usuario.
  String? get userType => _userType;

  /// Getter del estado del proveedor.
  String? get providerStatus => _providerStatus;

  /// Getter del nombre del usuario.
  String? get userName => _userName;

  /// Getter del email del usuario.
  String? get userEmail => _userEmail;

  /// Atajo para saber si la app está verificando sesión.
  bool get isChecking => _status == AuthStatus.checking;

  /// Atajo para saber si el usuario está autenticado.
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Atajo para saber si el usuario NO está autenticado.
  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;

  /// Revisa si existe una sesión guardada cuando abre la app.
  ///
  /// Esta función normalmente se ejecuta una vez en main.dart.
  ///
  /// Flujo:
  /// 1. La app abre.
  /// 2. Lee el token desde secure storage.
  /// 3. Si no hay token, marca usuario como no autenticado.
  /// 4. Si hay token, carga datos mínimos de sesión.
  /// 5. Notifica al router para que redirija.
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.checking;
    notifyListeners();

    final savedToken = await _secureStorage.read(StorageKeys.authToken);

    if (savedToken == null || savedToken.trim().isEmpty) {
      _clearMemorySession();

      _status = AuthStatus.unauthenticated;
      notifyListeners();

      return;
    }

    _token = savedToken;
    _userType = await _secureStorage.read(StorageKeys.userType);
    _providerStatus = await _secureStorage.read(StorageKeys.providerStatus);
    _userName = await _secureStorage.read(StorageKeys.userName);
    _userEmail = await _secureStorage.read(StorageKeys.userEmail);

    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Guarda la sesión del usuario después de login o registro.
  ///
  /// Este método se usa cuando Laravel responde correctamente con:
  /// - token
  /// - user
  /// - provider, si aplica
  ///
  /// Después de guardar estos datos, se llama notifyListeners()
  /// para que go_router pueda redirigir automáticamente.
  Future<void> saveSession({
    required String token,
    required String userType,
    required String name,
    required String email,
    String? providerStatus,
  }) async {
    await _secureStorage.write(
      key: StorageKeys.authToken,
      value: token,
    );

    await _secureStorage.write(
      key: StorageKeys.userType,
      value: userType,
    );

    await _secureStorage.write(
      key: StorageKeys.userName,
      value: name,
    );

    await _secureStorage.write(
      key: StorageKeys.userEmail,
      value: email,
    );

    if (providerStatus != null) {
      await _secureStorage.write(
        key: StorageKeys.providerStatus,
        value: providerStatus,
      );
    } else {
      /// Si el usuario no es proveedor, eliminamos cualquier estado viejo.
      ///
      /// Esto evita que un login de cliente herede accidentalmente
      /// un providerStatus guardado de una sesión anterior.
      await _secureStorage.delete(StorageKeys.providerStatus);
    }

    _token = token;
    _userType = userType;
    _providerStatus = providerStatus;
    _userName = name;
    _userEmail = email;
    _status = AuthStatus.authenticated;

    notifyListeners();
  }

  /// Actualiza únicamente el estado del proveedor.
  ///
  /// Esto será útil más adelante cuando el backend diga:
  /// - proveedor aprobado
  /// - proveedor rechazado
  /// - proveedor suspendido
  Future<void> updateProviderStatus(String status) async {
    await _secureStorage.write(
      key: StorageKeys.providerStatus,
      value: status,
    );

    _providerStatus = status;

    notifyListeners();
  }

  /// Cierra la sesión local.
  ///
  /// Esto borra todo lo guardado en secure storage y limpia
  /// la sesión en memoria.
  ///
  /// Después de esto, el router debe mandar al usuario al WelcomeScreen.
  Future<void> logout() async {
    await _secureStorage.clear();

    _clearMemorySession();

    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  /// Limpia todas las variables de sesión que viven en memoria.
  ///
  /// Este método NO borra datos del dispositivo.
  /// Solo limpia las variables internas de esta clase.
  void _clearMemorySession() {
    _token = null;
    _userType = null;
    _providerStatus = null;
    _userName = null;
    _userEmail = null;
  }
}