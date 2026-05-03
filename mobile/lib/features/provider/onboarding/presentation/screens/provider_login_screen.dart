import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../data/datasources/provider_auth_api.dart';
import '../widgets/provider_onboarding_header.dart';
import '../widgets/provider_text_field.dart';

/// Pantalla de inicio de sesión del proveedor.
///
/// Esta pantalla tiene 3 responsabilidades:
///
/// 1. Recibir email y contraseña.
/// 2. Enviar credenciales al backend.
/// 3. Guardar sesión y redirigir según el estado del proveedor.
///
/// Si provider.status == approved:
/// - va al dashboard.
///
/// Si provider.status == pending/rejected/suspended:
/// - va a la pantalla de estado/verificación.
class ProviderLoginScreen extends StatefulWidget {
  const ProviderLoginScreen({
    super.key,
    required this.authController,
  });

  /// Controlador global de autenticación.
  ///
  /// Lo recibimos desde AppRouter para poder guardar la sesión
  /// después de un login exitoso.
  final AuthController authController;

  @override
  State<ProviderLoginScreen> createState() => _ProviderLoginScreenState();
}

class _ProviderLoginScreenState extends State<ProviderLoginScreen> {
  /// Llave del formulario.
  ///
  /// Permite ejecutar validaciones de todos los campos con:
  /// _formKey.currentState!.validate()
  final _formKey = GlobalKey<FormState>();

  /// Servicio API que llama a Laravel.
  final _api = const ProviderAuthApi();

  /// Controlador para leer el correo.
  final _emailController = TextEditingController();

  /// Controlador para leer la contraseña.
  final _passwordController = TextEditingController();

  /// Controla si la contraseña se ve o se oculta.
  bool _showPassword = false;

  /// Controla si se está enviando la petición.
  ///
  /// Si es true:
  /// - desactivamos el botón.
  /// - mostramos loader.
  bool _isLoading = false;

  @override
  void dispose() {
    /// Siempre hay que liberar TextEditingController.
    ///
    /// Si no lo hacemos, Flutter puede mantener referencias
    /// innecesarias en memoria.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Envía el login al backend.
  ///
  /// Flujo:
  /// 1. Valida campos.
  /// 2. Activa loading.
  /// 3. Llama API.
  /// 4. Guarda sesión local.
  /// 5. Redirige según providerStatus.
  /// 6. Si hay error, muestra SnackBar.
  Future<void> _submitLogin() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await widget.authController.saveSession(
        token: response.token,
        userType: 'provider',
        name: response.userName,
        email: response.userEmail,
        providerStatus: response.providerStatus,
      );

      if (!mounted) return;

      if (response.providerStatus == 'approved') {
        context.goNamed(RouteNames.providerDashboard);
      } else {
        context.goNamed(RouteNames.providerVerificationPending);
      }
    } catch (e) {
      if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            ProviderAuthHeader(
              title: 'Bienvenido de vuelta',
              subtitle: 'Ingresa a tu panel de proveedor',
              onBack: () {
                context.goNamed(RouteNames.welcome);
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ProviderTextField(
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
                          ProviderTextField(
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
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'La contraseña es obligatoria.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () {
                                /// Esto queda pendiente para cuando
                                /// implementemos recuperación de contraseña.
                              },
                              child: const Text(
                                '¿Olvidaste tu contraseña?',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
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
                                elevation: 0,
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
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '¿Nuevo en AndanDO?',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          context.goNamed(RouteNames.providerRegister);
                        },
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
                          'Crear Cuenta de Proveedor',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryBlue.withAlpha(18),
                            AppColors.primaryRed.withAlpha(18),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Por qué ser proveedor?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 14),
                          Text('✓ Llega a miles de turistas'),
                          SizedBox(height: 8),
                          Text('✓ Gestiona tus reservas fácilmente'),
                          SizedBox(height: 8),
                          Text('✓ Recibe pagos seguros'),
                          SizedBox(height: 8),
                          Text('✓ Análisis de tu negocio'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}