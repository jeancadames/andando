import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/auth/firebase_google_auth_service.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/notifications/device_token_api_service.dart';
import '../../../core/notifications/firebase_push_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../customer/auth/data/datasources/customer_auth_api.dart';

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
  checking,

  /// El usuario tiene un token guardado.
  authenticated,

  /// No hay token guardado.
  unauthenticated,
}

/// Controlador global de autenticación.
///
/// Esta clase maneja:
/// - lectura del token guardado.
/// - guardado de sesión después de login o registro.
/// - cierre de sesión.
/// - datos mínimos del usuario autenticado.
/// - estado del proveedor.
/// - registro del FCM token en backend.
/// - login de cliente con Google.
class AuthController extends ChangeNotifier {
  AuthController({
    required SecureStorage secureStorage,
    FirebasePushService? firebasePushService,
    DeviceTokenApiService? deviceTokenApiService,
    FirebaseGoogleAuthService? firebaseGoogleAuthService,
    CustomerAuthApi? customerAuthApi,
  })  : _secureStorage = secureStorage,
        _firebasePushService = firebasePushService ?? FirebasePushService(),
        _deviceTokenApiService =
            deviceTokenApiService ?? const DeviceTokenApiService(),
        _firebaseGoogleAuthService =
            firebaseGoogleAuthService ?? FirebaseGoogleAuthService(),
        _customerAuthApi = customerAuthApi ?? const CustomerAuthApi();

  /// Servicio encargado de leer/escribir datos sensibles.
  final SecureStorage _secureStorage;

  /// Servicio encargado de pedir permisos y obtener el FCM token.
  final FirebasePushService _firebasePushService;

  /// Servicio encargado de guardar/borrar el FCM token en Laravel.
  final DeviceTokenApiService _deviceTokenApiService;

  /// Servicio encargado de autenticar con Google usando Firebase Auth.
  final FirebaseGoogleAuthService _firebaseGoogleAuthService;

  /// Servicio encargado de comunicarse con endpoints de cliente.
  final CustomerAuthApi _customerAuthApi;

  /// Estado interno de autenticación.
  AuthStatus _status = AuthStatus.checking;

  /// Token de autenticación devuelto por Laravel/Sanctum.
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

  AuthStatus get status => _status;

  String? get token => _token;

  String? get userType => _userType;

  String? get providerStatus => _providerStatus;

  String? get userName => _userName;

  String? get userEmail => _userEmail;

  bool get isChecking => _status == AuthStatus.checking;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  bool get isUnauthenticated => _status == AuthStatus.unauthenticated;

  /// Revisa si existe una sesión guardada cuando abre la app.
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

    unawaited(_registerDeviceTokenForSession(savedToken));
  }

  /// Login/registro de cliente usando Google.
  ///
  /// Flujo:
  /// 1. Firebase Auth abre Google.
  /// 2. Firebase devuelve un ID token.
  /// 3. Laravel valida ese ID token.
  /// 4. Laravel devuelve token Sanctum.
  /// 5. Guardamos sesión igual que login/register normal.
  Future<void> loginWithGoogle() async {
    try {
      final googleResult = await _firebaseGoogleAuthService.signInWithGoogle();

      final response = await _customerAuthApi.loginWithGoogle(
        idToken: googleResult.idToken,
      );

      await saveSession(
        token: response.token,
        userType: response.userType,
        name: response.userName,
        email: response.userEmail,
      );
    } catch (_) {
      await _firebaseGoogleAuthService.signOutFromFirebase();
      rethrow;
    }
  }

  /// Guarda la sesión del usuario después de login o registro.
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
      await _secureStorage.delete(StorageKeys.providerStatus);
    }

    _token = token;
    _userType = userType;
    _providerStatus = providerStatus;
    _userName = name;
    _userEmail = email;
    _status = AuthStatus.authenticated;

    notifyListeners();

    unawaited(_registerDeviceTokenForSession(token));
  }

  /// Actualiza únicamente el estado del proveedor.
  Future<void> updateProviderStatus(String status) async {
    await _secureStorage.write(
      key: StorageKeys.providerStatus,
      value: status,
    );

    _providerStatus = status;

    notifyListeners();
  }

  /// Cierra la sesión local y borra el device token en backend.
  Future<void> logout() async {
    final currentApiToken = _token;

    if (currentApiToken != null && currentApiToken.trim().isNotEmpty) {
      await _deleteDeviceTokenForSession(currentApiToken);
    }

    await _firebaseGoogleAuthService.signOutFromFirebase();

    await _secureStorage.clear();

    _clearMemorySession();

    _status = AuthStatus.unauthenticated;

    notifyListeners();
  }

  Future<void> _registerDeviceTokenForSession(String apiToken) async {
    try {
      final fcmToken = await _firebasePushService.initialize();

      if (fcmToken == null || fcmToken.trim().isEmpty) {
        debugPrint('DEVICE TOKEN: no se registró porque FCM token está vacío.');
        return;
      }

      final platform = kIsWeb
          ? 'web'
          : defaultTargetPlatform.toString().split('.').last;

      final deviceName = kIsWeb ? 'Flutter Web' : 'Flutter $platform';

      await _deviceTokenApiService.registerToken(
        apiToken: apiToken,
        fcmToken: fcmToken,
        platform: platform,
        deviceName: deviceName,
      );
    } catch (error, stackTrace) {
      debugPrint('DEVICE TOKEN REGISTER ERROR: $error');
      debugPrint('$stackTrace');
    }
  }

  Future<void> _deleteDeviceTokenForSession(String apiToken) async {
    try {
      final fcmToken = await _firebasePushService.getCurrentToken();

      if (fcmToken == null || fcmToken.trim().isEmpty) {
        return;
      }

      await _deviceTokenApiService.deleteToken(
        apiToken: apiToken,
        fcmToken: fcmToken,
      );
    } catch (error, stackTrace) {
      debugPrint('DEVICE TOKEN DELETE ERROR: $error');
      debugPrint('$stackTrace');
    }
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