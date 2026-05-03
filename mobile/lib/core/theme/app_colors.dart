import 'package:flutter/material.dart';

/// Clase central para guardar todos los colores de la app.
///
/// ¿Por qué hacer esto?
/// Porque así no ponemos colores "quemados" (hardcoded)
/// en todas las pantallas.
///
/// Si mañana cambias el azul o el rojo,
/// solo cambias este archivo y toda la app se actualiza.
class AppColors {
  /// Constructor privado para evitar instancias.
  const AppColors._();

  /// Color principal de la app:
  /// Azul ultramar de la bandera dominicana.
  static const Color primaryBlue = Color(0xFF002D62);

  /// Color secundario de la app:
  /// Rojo bermellón de la bandera dominicana.
  static const Color primaryRed = Color(0xFFCE1126);

  /// Blanco principal.
  static const Color white = Color(0xFFFFFFFF);

  /// Negro suave para texto oscuro en fondos claros.
  static const Color textDark = Color(0xFF1A1A1A);

  /// Gris claro útil para fondos neutros.
  static const Color muted = Color(0xFFF5F5F5);

  /// Gris medio para texto secundario en fondos claros.
  static const Color mutedForeground = Color(0xFF666666);

  /// Color del degradado en la parte media.
  ///
  /// Este no vino explícito en el theme de Figma,
  /// pero lo usamos para que la transición entre azul y rojo
  /// se vea más suave y más parecida a la referencia visual.
  static const Color gradientMiddle = Color(0xFF243C7A);

  /// Gradiente principal del WelcomeScreen.
  static const LinearGradient welcomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primaryBlue,
      Color(0xFF2E5C96),
      white,
    ],
    stops: [
      0.0,
      0.45,
      1.0,
    ],
  );
}