import 'package:flutter/material.dart';

import 'app.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/application/auth_controller.dart';

// main() es el punto de entrada de toda app Flutter.
//
// Cuando la app abre, Flutter ejecuta esta función primero.
Future<void> main() async {
  // Esto asegura que Flutter esté inicializado antes de usar plugins.
  //
  // Es importante porque flutter_secure_storage es un plugin nativo.
  WidgetsFlutterBinding.ensureInitialized();

  // Creamos el servicio de almacenamiento seguro.
  final secureStorage = SecureStorage();

  // Creamos el controlador global de autenticación.
  final authController = AuthController(
    secureStorage: secureStorage,
  );

  // Antes de mostrar la app, revisamos si existe sesión guardada.
  //
  // Si hay token:
  // AuthController quedará como authenticated.
  //
  // Si no hay token:
  // AuthController quedará como unauthenticated.
  await authController.checkAuthStatus();

  // Creamos el router y le pasamos el AuthController.
  //
  // Así el router puede decidir si manda al usuario a Welcome,
  // Explore, Dashboard, etc.
  final appRouter = AppRouter(
    authController: authController,
  );

  // runApp monta la aplicación en pantalla.
  runApp(
    AndandoApp(
      appRouter: appRouter,
    ),
  );
}