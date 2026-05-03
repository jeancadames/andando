import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// Este archivo contiene el widget raíz de la aplicación.
//
// En Flutter, casi todo es un widget.
// AndandoApp es el widget principal que monta MaterialApp.router.
class AndandoApp extends StatelessWidget {
  const AndandoApp({
    super.key,
    required this.appRouter,
  });

  // Recibimos el router ya creado desde main.dart.
  //
  // Esto es mejor que crearlo dentro del build,
  // porque así evitamos recrear rutas innecesariamente.
  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Quita la etiqueta roja de "DEBUG" en la esquina superior derecha.
      debugShowCheckedModeBanner: false,

      // Nombre de la app.
      title: 'AndanDO',

      // Aquí conectamos go_router con Flutter.
      routerConfig: appRouter.router,

      // Tema base de la app.
      theme: AppTheme.lightTheme,
    );
  }
}