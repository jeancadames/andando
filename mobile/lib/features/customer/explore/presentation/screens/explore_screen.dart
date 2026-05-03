import 'package:flutter/material.dart';

// Pantalla temporal de exploración del cliente.
//
// Esta pantalla existe para que la navegación funcione desde WelcomeScreen.
// Luego aquí construiremos:
// - listado de tours
// - filtros
// - búsqueda
// - ofertas
// - categorías
// - detalles de experiencias
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Explorar experiencias'),
      ),
    );
  }
}