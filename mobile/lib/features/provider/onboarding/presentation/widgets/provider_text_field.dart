import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Campo de texto reutilizable para formularios del flujo de afiliado.
///
/// Aunque el archivo todavía se llama `provider_text_field.dart`,
/// visualmente este componente se usa para el registro de afiliados.
///
/// Nota técnica:
/// Internamente mantenemos nombres como "provider" porque el backend,
/// las rutas, las tablas y los modelos ya están funcionando con ese nombre.
/// Cambiarlo todo ahora sería una refactorización grande y puede romper
/// el flujo que ya validamos.
///
/// Este widget centraliza el estilo de los inputs:
/// - label arriba.
/// - icono a la izquierda.
/// - fondo gris claro.
/// - bordes redondeados.
/// - texto oscuro.
/// - cursor azul.
/// - borde azul al enfocarse.
class ProviderTextField extends StatelessWidget {
  const ProviderTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  /// Texto que aparece encima del campo.
  final String label;

  /// Controlador que permite leer y modificar el valor del input.
  final TextEditingController controller;

  /// Texto placeholder que se muestra cuando el input está vacío.
  final String hintText;

  /// Icono izquierdo del input.
  final IconData prefixIcon;

  /// Tipo de teclado.
  ///
  /// Ejemplos:
  /// - TextInputType.emailAddress
  /// - TextInputType.phone
  /// - TextInputType.text
  final TextInputType? keyboardType;

  /// Si es true, oculta el texto.
  ///
  /// Se usa para campos de contraseña.
  final bool obscureText;

  /// Widget opcional al lado derecho.
  ///
  /// Se usa para el botón de mostrar/ocultar contraseña.
  final Widget? suffixIcon;

  /// Validador opcional si el campo está dentro de un Form.
  final String? Function(String?)? validator;

  /// Callback que se ejecuta cuando cambia el texto.
  ///
  /// En el registro se usa para recalcular si el botón
  /// "Continuar" debe estar activo.
  final VoidCallback? onChanged;

  /// Cantidad máxima de líneas.
  ///
  /// Para campos como dirección usamos 3 líneas.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Label del campo.
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLines: maxLines,

          /// IMPORTANTE:
          /// Este `style` arregla el problema del texto blanco.
          ///
          /// Como el ThemeData global puede tener bodyText blanco,
          /// el TextFormField puede heredar ese color.
          /// Aquí lo forzamos a negro/gris oscuro para que siempre
          /// sea legible sobre fondo claro.
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),

          /// Color del cursor cuando el usuario escribe.
          cursorColor: AppColors.primaryBlue,

          onChanged: (_) {
            onChanged?.call();
          },

          decoration: InputDecoration(
            hintText: hintText,

            /// Color del placeholder.
            hintStyle: const TextStyle(
              color: Color(0xFF8A94A6),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),

            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.mutedForeground,
            ),

            suffixIcon: suffixIcon,

            filled: true,
            fillColor: const Color(0xFFF8F9FA),

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
        ),
      ],
    );
  }
}