import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema global de AndanDO.
///
/// IMPORTANTE:
/// El theme global NO debe usar texto blanco por defecto.
///
/// ¿Por qué?
/// Porque la mayoría de pantallas de la app tienen fondo blanco:
/// - login
/// - formularios
/// - registro de afiliado
/// - dashboard
/// - configuración
///
/// Si ponemos textos blancos globales, los inputs y labels pueden
/// heredar blanco y no verse.
///
/// Para pantallas oscuras o con gradiente, como el WelcomeScreen,
/// se define el texto blanco directamente en esa pantalla.
class AppTheme {
  const AppTheme._();

  /// Tema claro principal de la aplicación.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      /// Color base de pantallas.
      scaffoldBackgroundColor: AppColors.white,

      /// Color principal usado por componentes Material.
      primaryColor: AppColors.primaryBlue,

      /// Color del cursor y selección de texto.
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryBlue,
        selectionColor: Color(0x332D62FF),
        selectionHandleColor: AppColors.primaryBlue,
      ),

      /// Esquema de colores general.
      ///
      /// onSurface es muy importante porque muchos textos e inputs
      /// toman su color desde ahí.
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.primaryRed,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.textDark,
        error: AppColors.primaryRed,
      ),

      /// Textos globales de la app.
      ///
      /// Todos deben ser oscuros por defecto.
      /// Nunca pongas blanco aquí como color global.
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textDark),
        displayMedium: TextStyle(color: AppColors.textDark),
        displaySmall: TextStyle(color: AppColors.textDark),

        headlineLarge: TextStyle(color: AppColors.textDark),
        headlineMedium: TextStyle(color: AppColors.textDark),
        headlineSmall: TextStyle(color: AppColors.textDark),

        titleLarge: TextStyle(color: AppColors.textDark),
        titleMedium: TextStyle(color: AppColors.textDark),
        titleSmall: TextStyle(color: AppColors.textDark),

        bodyLarge: TextStyle(color: AppColors.textDark),
        bodyMedium: TextStyle(color: AppColors.textDark),
        bodySmall: TextStyle(color: AppColors.mutedForeground),

        labelLarge: TextStyle(color: AppColors.textDark),
        labelMedium: TextStyle(color: AppColors.textDark),
        labelSmall: TextStyle(color: AppColors.mutedForeground),
      ),

      /// Tema global de inputs.
      ///
      /// Esto controla bordes, colores de fondo, errores, etc.
      /// El color del texto escrito se controla mejor directamente
      /// en cada TextFormField con `style`, pero esto ayuda a que
      /// todos los formularios tengan una base consistente.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        hintStyle: const TextStyle(
          color: Color(0xFF8A94A6),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textDark,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        errorStyle: const TextStyle(
          color: AppColors.primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIconColor: AppColors.mutedForeground,
        suffixIconColor: AppColors.mutedForeground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryBlue,
            width: 1.4,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryRed,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primaryRed,
            width: 1.4,
          ),
        ),
      ),

      /// Tema global para botones elevados.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 56),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      /// Tema global para botones con borde.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          minimumSize: const Size(double.infinity, 56),
          side: const BorderSide(
            color: AppColors.primaryBlue,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      /// Tema global para TextButton.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlue,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      /// Tema global para checkboxes.
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }

          return AppColors.white;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(
          color: Color(0xFFD1D5DB),
        ),
      ),
    );
  }
}