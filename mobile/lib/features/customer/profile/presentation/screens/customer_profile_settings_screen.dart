import 'package:flutter/material.dart';

/// Pantalla temporal de configuración.
///
/// Luego aquí iremos agregando:
/// - idioma
/// - moneda
/// - notificaciones
/// - privacidad
/// - seguridad
class CustomerProfileSettingsScreen extends StatelessWidget {
  const CustomerProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: const Center(
        child: Text(
          'Pantalla de configuración en construcción.',
        ),
      ),
    );
  }
}