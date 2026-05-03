import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/auth_controller.dart';
import '../../../provider/onboarding/data/datasources/provider_auth_api.dart';

/// Login general de AndanDO.
///
/// Por ahora este login está conectado al endpoint de afiliado/proveedor:
///
/// POST /api/provider/login
///
/// Flujo actual:
/// - El usuario escribe correo y contraseña.
/// - Flutter llama a Laravel.
/// - Laravel devuelve token, user y provider.
/// - Flutter guarda la sesión.
/// - Si el afiliado está aprobado, va a /provider/dashboard.
/// - Si está pendiente, va a /provider/verification-pending.
///
/// Nota:
/// Más adelante, cuando exista login de cliente, este login puede decidir
/// si el usuario es cliente o afiliado según la respuesta del backend.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authController,
  });

  /// Controlador global de autenticación.
  ///
  /// Lo necesitamos para guardar la sesión después de que Laravel
  /// responda correctamente con un token.
  final AuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Llave del formulario.
  ///
  /// Permite validar todos los campos antes de enviar el login.
  final _formKey = GlobalKey<FormState>();

  /// Servicio que llama al backend Laravel para login de afiliado/proveedor.
  final _providerAuthApi = const ProviderAuthApi();

  /// Controlador del correo electrónico.
  final _emailController = TextEditingController();

  /// Controlador de la contraseña.
  final _passwordController = TextEditingController();

  /// Define si la contraseña se muestra o se oculta.
  bool _showPassword = false;

  /// Define si estamos enviando la solicitud de login.
  ///
  /// Cuando es true:
  /// - bloqueamos el botón.
  /// - mostramos loader.
  bool _isLoading = false;

  @override
  void dispose() {
    /// Liberamos los controladores para evitar uso innecesario de memoria.
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  /// Envía el login al backend.
  ///
  /// Este método reemplaza la navegación temporal que antes hacía:
  ///
  /// context.goNamed(RouteNames.clientExplore);
  ///
  /// Ahora hace login real contra Laravel.
  Future<void> _submitLogin() async {
    /// Primero validamos campos del formulario.
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      /// Llamamos al endpoint:
      ///
      /// POST /api/provider/login
      ///
      /// El backend debe devolver:
      /// - token
      /// - user
      /// - provider
      final response = await _providerAuthApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      /// Guardamos sesión localmente.
      ///
      /// Esto es obligatorio antes de navegar a /provider/dashboard.
      ///
      /// Si no guardamos sesión, el router seguirá creyendo que el usuario
      /// no está autenticado y puede devolverlo a /login.
      await widget.authController.saveSession(
        token: response.token,
        userType: 'provider',
        name: response.userName,
        email: response.userEmail,
        providerStatus: response.providerStatus,
      );

      if (!mounted) return;

      /// Redirección según el estado del afiliado/proveedor.
      ///
      /// Si está aprobado, ya puede entrar al dashboard.
      if (response.providerStatus == 'approved') {
        context.goNamed(RouteNames.providerDashboard);
        return;
      }

      /// Si todavía no está aprobado, lo mandamos a la pantalla de revisión.
      ///
      /// Esto evita que un afiliado pending entre al dashboard.
      context.goNamed(RouteNames.providerVerificationPending);
    } catch (e) {
      if (!mounted) return;

      /// Mostramos el error devuelto por Laravel.
      ///
      /// Ejemplos:
      /// - credenciales incorrectas.
      /// - usuario no tiene perfil de proveedor.
      /// - error de conexión.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Muestra mensaje temporal para recuperación de contraseña.
  void _showForgotPasswordMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperación de contraseña pendiente de implementar.'),
      ),
    );
  }

  /// Acción temporal para registro de cliente.
  ///
  /// Todavía no hemos construido el registro de cliente.
  void _goToCustomerRegister() {
    context.goNamed(RouteNames.register);
  }

  /// Envía al flujo de registro de afiliado/proveedor.
  void _goToAffiliateRegister() {
    context.goNamed(RouteNames.affiliateRegister);
  }

  /// Permite entrar a explorar sin iniciar sesión.
  void _continueAsGuest() {
    context.goNamed(RouteNames.clientExplore);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Logo superior.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 36),
              child: Center(
                child: Image.asset(
                  'assets/images/logos/andando_logo.png',
                  width: double.infinity,
                  fit: BoxFit.contain,

                  /// Fallback por si el asset todavía no está configurado.
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'AndanDO',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                      ),
                    );
                  },
                ),
              ),
            ),

            /// Contenido principal.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _LoginTextField(
                            label: 'Correo electrónico',
                            controller: _emailController,
                            hintText: 'tu@correo.com',
                            prefixIcon: Icons.mail_outline,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              final email = value?.trim() ?? '';

                              if (email.isEmpty) {
                                return 'El correo es obligatorio.';
                              }

                              if (!email.contains('@')) {
                                return 'Ingresa un correo válido.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          _LoginTextField(
                            label: 'Contraseña',
                            controller: _passwordController,
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: !_showPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.mutedForeground,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es obligatoria.';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _showForgotPasswordMessage,
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: AppColors.white,
                                disabledBackgroundColor:
                                    AppColors.primaryBlue.withAlpha(120),
                                elevation: 8,
                                shadowColor:
                                    AppColors.primaryBlue.withAlpha(45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Iniciar Sesión',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      '¿No tienes cuenta?',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _goToCustomerRegister,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Crear Cuenta',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: _goToAffiliateRegister,
                      child: const Text(
                        'Me interesa ser afiliado',
                        style: TextStyle(
                          color: AppColors.primaryRed,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextButton(
                      onPressed: _continueAsGuest,
                      child: const Text(
                        'Continuar como invitado →',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// Texto legal inferior.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: const [
                  Text(
                    'Al continuar, aceptas nuestros ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Términos',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  Text(
                    ' y ',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Política de Privacidad',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Campo reutilizable del login general.
///
/// Este widget fuerza el texto oscuro para evitar el problema
/// de que los inputs hereden texto blanco desde el ThemeData global.
class _LoginTextField extends StatelessWidget {
  const _LoginTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
  });

  /// Texto visible encima del campo.
  final String label;

  /// Controlador del input.
  final TextEditingController controller;

  /// Placeholder del campo.
  final String hintText;

  /// Icono izquierdo.
  final IconData prefixIcon;

  /// Tipo de teclado.
  final TextInputType? keyboardType;

  /// Define si el texto se oculta.
  final bool obscureText;

  /// Widget derecho opcional.
  final Widget? suffixIcon;

  /// Validador del formulario.
  final String? Function(String?)? validator;

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

          /// ESTA ES LA LÍNEA CLAVE.
          ///
          /// Esto fuerza el texto escrito a oscuro.
          /// Sin esto, el TextFormField puede heredar blanco del theme.
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),

          /// Color del cursor.
          cursorColor: AppColors.primaryBlue,

          decoration: InputDecoration(
            hintText: hintText,
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