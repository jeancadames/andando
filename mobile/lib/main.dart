import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/application/auth_controller.dart';
import 'firebase_options.dart';

import 'core/notifications/firebase_push_service.dart';

/// main() es el punto de entrada principal de la aplicación.
///
/// Aquí:
/// - inicializamos Flutter
/// - inicializamos Firebase
/// - inicializamos locales de fechas
/// - restauramos sesión
/// - configuramos router
/// - montamos la app
Future<void> main() async {
  /// Necesario antes de usar plugins nativos.
  WidgetsFlutterBinding.ensureInitialized();

  /// Inicializa Firebase usando la configuración generada por FlutterFire.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// Inicializa soporte de fechas en español.
  ///
  /// Esto es requerido para:
  /// DateFormat('d MMM y', 'es')
  ///
  /// Ejemplo:
  /// 29 may 2026
  await initializeDateFormatting('es');

  /// Servicio de almacenamiento seguro.
  final secureStorage = SecureStorage();

  /// Controlador global de autenticación.
  final authController = AuthController(
    secureStorage: secureStorage,
  );

  /// Revisamos si existe sesión guardada.
  await authController.checkAuthStatus();

  /// Router principal de la app.
  final appRouter = AppRouter(
    authController: authController,
  );

  /// Monta la aplicación.
  runApp(
    AndandoApp(
      appRouter: appRouter,
    ),
  );
}