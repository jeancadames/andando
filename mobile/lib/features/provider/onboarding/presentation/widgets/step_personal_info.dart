import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'provider_text_field.dart';

/// Paso 1 del registro de proveedor.
///
/// Esta pantalla recoge la información personal básica:
/// - Nombre completo
/// - Correo electrónico
/// - Teléfono
/// - Contraseña
/// - Confirmación de contraseña
///
/// Este widget NO guarda datos por sí solo.
/// Los datos viven en los TextEditingController que vienen desde
/// ProviderRegisterScreen.
///
/// ¿Por qué los controllers vienen desde el screen padre?
/// Porque el screen padre necesita conservar la información
/// aunque el usuario avance al paso 2, 3 o 4.
class StepPersonalInfo extends StatelessWidget {
  const StepPersonalInfo({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onChanged,
  });

  /// Controlador del campo nombre completo.
  final TextEditingController fullNameController;

  /// Controlador del campo correo electrónico.
  final TextEditingController emailController;

  /// Controlador del campo teléfono.
  final TextEditingController phoneController;

  /// Controlador del campo contraseña.
  final TextEditingController passwordController;

  /// Controlador del campo confirmar contraseña.
  final TextEditingController confirmPasswordController;

  /// Define si la contraseña se muestra o se oculta.
  final bool showPassword;

  /// Define si la confirmación de contraseña se muestra o se oculta.
  final bool showConfirmPassword;

  /// Acción que se ejecuta al tocar el icono del ojo
  /// en el campo contraseña.
  final VoidCallback onTogglePassword;

  /// Acción que se ejecuta al tocar el icono del ojo
  /// en el campo confirmar contraseña.
  final VoidCallback onToggleConfirmPassword;

  /// Callback que notifica al screen padre que algún campo cambió.
  ///
  /// Esto permite recalcular si el botón "Continuar" debe estar activo.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    /// Verificamos si el usuario ya escribió algo en confirmar contraseña.
    final hasConfirmPassword = confirmPasswordController.text.isNotEmpty;

    /// Verificamos si las contraseñas coinciden.
    final passwordsMatch =
        passwordController.text == confirmPasswordController.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Título del paso.
        const Text(
          'Información Personal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        /// Subtítulo explicativo.
        const Text(
          'Comencemos con tus datos básicos',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
        ),

        const SizedBox(height: 28),

        ProviderTextField(
          label: 'Nombre completo',
          controller: fullNameController,
          hintText: 'Juan Pérez',
          prefixIcon: Icons.person_outline,
          keyboardType: TextInputType.name,
          onChanged: onChanged,
        ),

        const SizedBox(height: 20),

        ProviderTextField(
          label: 'Correo electrónico',
          controller: emailController,
          hintText: 'tu@correo.com',
          prefixIcon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
        ),

        const SizedBox(height: 20),

        ProviderTextField(
          label: 'Teléfono',
          controller: phoneController,
          hintText: '+1 (809) 000-0000',
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          onChanged: onChanged,
        ),

        const SizedBox(height: 20),

        ProviderTextField(
          label: 'Contraseña',
          controller: passwordController,
          hintText: 'Mínimo 8 caracteres',
          prefixIcon: Icons.lock_outline,

          /// Si showPassword es false, ocultamos el texto.
          obscureText: !showPassword,

          /// Botón de mostrar/ocultar contraseña.
          suffixIcon: IconButton(
            onPressed: onTogglePassword,
            icon: Icon(
              showPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.mutedForeground,
            ),
          ),
          onChanged: onChanged,
        ),

        const SizedBox(height: 20),

        ProviderTextField(
          label: 'Confirmar contraseña',
          controller: confirmPasswordController,
          hintText: 'Confirma tu contraseña',
          prefixIcon: Icons.lock_outline,
          obscureText: !showConfirmPassword,
          suffixIcon: IconButton(
            onPressed: onToggleConfirmPassword,
            icon: Icon(
              showConfirmPassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: AppColors.mutedForeground,
            ),
          ),
          onChanged: onChanged,
        ),

        /// Mensaje de error visual si las contraseñas no coinciden.
        ///
        /// Esto no reemplaza la validación final,
        /// solo ayuda al usuario mientras escribe.
        if (hasConfirmPassword && !passwordsMatch) ...[
          const SizedBox(height: 8),
          const Text(
            'Las contraseñas no coinciden',
            style: TextStyle(
              color: AppColors.primaryRed,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}