// Este archivo contiene una prueba básica de humo para la app AndanDO.
//
// Una prueba de humo no valida toda la lógica de la aplicación.
// Su objetivo principal es confirmar que Flutter puede construir un widget
// mínimo sin errores durante el análisis o ejecución de pruebas.
//
// Este archivo reemplaza el test generado por defecto de Flutter, que intentaba
// construir una clase llamada MyApp. En este proyecto esa clase no existe con
// ese nombre, por eso flutter analyze estaba mostrando:
//
// The name 'MyApp' isn't a class
//
// Para evitar romper el análisis mientras no tengamos tests reales de la app,
// usamos un MaterialApp mínimo con un texto simple.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test básico de AndanDO', (WidgetTester tester) async {
    // Construimos un widget mínimo válido de Flutter.
    //
    // No usamos la app real aquí porque este test solo busca comprobar que el
    // entorno de pruebas funciona y que flutter analyze no falla por una clase
    // inexistente.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('AndanDO'),
        ),
      ),
    );

    // Verificamos que el texto base se renderiza correctamente.
    expect(find.text('AndanDO'), findsOneWidget);
  });
}