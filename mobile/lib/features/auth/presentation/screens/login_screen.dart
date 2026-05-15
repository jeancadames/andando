import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/auth_controller.dart';

/// Pantalla de login general de AndanDO.
///
/// Esta pantalla permite:
/// - iniciar sesión con email y contraseña.
/// - autenticar usuarios normales/clientes.
/// - autenticar afiliados/proveedores.
/// - mostrar botón visual para Google.
/// - mostrar botón visual para Apple.
/// - crear cuenta.
/// - ir al registro de afiliado.
/// - continuar como invitado.
///
/// Flujo correcto:
/// - customer/client → /client/explore
/// - provider/affiliate approved → /provider/dashboard
/// - provider/affiliate pending/rejected → /provider/verification-pending
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authController,
  });

  /// Controlador global de autenticación.
  ///
  /// Lo usamos para guardar la sesión después de que Laravel
  /// responda correctamente con token y datos del usuario.
  final AuthController authController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Llave del formulario.
  ///
  /// Permite validar email y contraseña antes de enviar.
  final _formKey = GlobalKey<FormState>();

  /// API general de autenticación.
  ///
  /// Esta clase está definida al final de este mismo archivo
  /// para que no tengas que crear archivos adicionales ahora.
  final _authApi = const _GeneralAuthApi();

  /// Controlador del campo email.
  final _emailController = TextEditingController();

  /// Controlador del campo contraseña.
  final _passwordController = TextEditingController();

  /// Define si la contraseña se muestra o se oculta.
  bool _showPassword = false;

  /// Indica si el login por email/contraseña está enviándose.
  bool _isLoading = false;

  /// Indica si se presionó el botón de Google.
  bool _isGoogleLoading = false;

  /// Indica si se presionó el botón de Apple.
  bool _isAppleLoading = false;

  @override
  void dispose() {
    /// Siempre liberamos los controladores para evitar fugas de memoria.
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  /// Envía login por email y contraseña.
  ///
  /// Este método ahora usa:
  ///
  /// POST /api/auth/login
  ///
  /// Ese endpoint debe aceptar tanto clientes como afiliados/proveedores.
  Future<void> _submitLogin() async {
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _authApi.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final normalizedUserType = _normalizeUserType(response.userType);

      final isProvider = _isProviderType(normalizedUserType);

      await widget.authController.saveSession(
        token: response.token,
        userType: normalizedUserType,
        name: response.userName,
        email: response.userEmail,

        /// Solo guardamos providerStatus cuando el usuario es afiliado/proveedor.
        ///
        /// Para usuarios normales, esto debe ir null para que AuthController
        /// limpie cualquier providerStatus viejo.
        providerStatus: isProvider ? response.providerStatus : null,
      );

      if (!mounted) return;

      _redirectAfterLogin(
        userType: normalizedUserType,
        providerStatus: response.providerStatus,
      );
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

  /// Normaliza el tipo de usuario recibido desde Laravel.
  ///
  /// Esto nos permite aceptar distintos nombres internos:
  /// - customer
  /// - client
  /// - user
  /// - provider
  /// - affiliate
  /// - afiliado
  String _normalizeUserType(String userType) {
    final type = userType.trim().toLowerCase();

    if (type == 'provider' || type == 'affiliate' || type == 'afiliado') {
      return 'provider';
    }

    if (type == 'customer' || type == 'client' || type == 'user') {
      return 'customer';
    }

    return type.isEmpty ? 'customer' : type;
  }

  /// Determina si el usuario pertenece al flujo de afiliado/proveedor.
  bool _isProviderType(String userType) {
    return userType == 'provider';
  }

  /// Redirige al usuario según su tipo y estado.
  ///
  /// Reglas:
  /// - Cliente → explorar.
  /// - Proveedor aprobado → dashboard.
  /// - Proveedor pendiente/rechazado/suspendido → pantalla de verificación.
  void _redirectAfterLogin({
    required String userType,
    required String? providerStatus,
  }) {
    if (_isProviderType(userType)) {
      if (providerStatus == 'approved') {
        context.goNamed(RouteNames.providerDashboard);
        return;
      }

      context.goNamed(RouteNames.providerVerificationPending);
      return;
    }

    context.goNamed(RouteNames.clientExplore);
  }

  /// Acción temporal del botón "Continuar con Google".
  ///
  /// Por ahora NO llama backend.
  /// Solo dejamos el botón visualmente listo para conectar después.
  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isGoogleLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Inicio de sesión con Google pendiente de conectar.',
        ),
      ),
    );
  }

  /// Acción temporal del botón "Continuar con Apple".
  ///
  /// Por ahora NO llama backend.
  /// Solo dejamos el botón visualmente listo para conectar después.
  Future<void> _handleAppleLogin() async {
    setState(() {
      _isAppleLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    setState(() {
      _isAppleLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Inicio de sesión con Apple pendiente de conectar.',
        ),
      ),
    );
  }

  /// Acción temporal para recuperación de contraseña.
  void _showForgotPasswordMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Recuperación de contraseña pendiente de implementar.'),
      ),
    );
  }

  /// Navega al registro de cliente.
  void _goToCustomerRegister() {
    context.goNamed(RouteNames.register);
  }

  /// Navega al registro de afiliado.
  void _goToAffiliateRegister() {
    context.goNamed(RouteNames.affiliateRegister);
  }

  /// Permite explorar la app sin autenticarse.
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 310,
                        ),
                        child: Image.asset(
                          'assets/images/logos/andando_logo.png',
                          fit: BoxFit.contain,
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

                    const SizedBox(height: 72),

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

                          const SizedBox(height: 22),

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
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
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
                                elevation: 10,
                                shadowColor:
                                    AppColors.primaryBlue.withAlpha(55),
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
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    const _OrDivider(),

                    const SizedBox(height: 28),

                    _SocialLoginButton(
                      label: 'Continuar con Google',
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.textDark,
                      borderColor: const Color(0xFFE5E7EB),
                      isLoading: _isGoogleLoading,
                      icon: const _GoogleIcon(),
                      onPressed: _isGoogleLoading ? null : _handleGoogleLogin,
                    ),

                    const SizedBox(height: 14),

                    _SocialLoginButton(
                      label: 'Continuar con Apple',
                      backgroundColor: Colors.black,
                      foregroundColor: AppColors.white,
                      borderColor: Colors.black,
                      isLoading: _isAppleLoading,
                      icon: const _AppleIcon(),
                      onPressed: _isAppleLoading ? null : _handleAppleLogin,
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      '¿No tienes cuenta?',
                      style: TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                            fontWeight: FontWeight.w800,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: _continueAsGuest,
                      child: const Text(
                        'Continuar como invitado →',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(24, 10, 24, 20),
              child: _LegalFooter(),
            ),
          ],
        ),
      ),
    );
  }
}

/// API general de login.
///
/// Esta clase llama al backend Laravel:
///
/// POST /api/auth/login
///
/// Debe servir tanto para:
/// - clientes/usuarios.
/// - afiliados/proveedores.
class _GeneralAuthApi {
  const _GeneralAuthApi();

  Future<_AuthLoginResponse> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${Environment.apiBaseUrl}/auth/login');

    final response = await http.post(
      uri,
      headers: {
        'Accept': 'application/json',
      },
      body: {
        'email': email,
        'password': password,
      },
    );

    return _handleResponse(response);
  }

  _AuthLoginResponse _handleResponse(http.Response response) {
    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('El servidor respondió con un formato inválido.');
    }

    final isSuccessful = response.statusCode >= 200 && response.statusCode < 300;

    if (isSuccessful) {
      return _AuthLoginResponse.fromJson(body);
    }

    if (body.containsKey('errors')) {
      final errors = body['errors'] as Map<String, dynamic>;

      if (errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
      }
    }

    throw Exception(
      body['message']?.toString() ?? 'No se pudo iniciar sesión.',
    );
  }
}

/// Modelo de respuesta del login general.
///
/// Laravel debe responder algo como:
///
/// Cliente:
/// {
///   "token": "...",
///   "user": {
///     "id": 1,
///     "name": "Jean",
///     "email": "jean@email.com",
///     "type": "customer"
///   },
///   "provider": null
/// }
///
/// Afiliado/proveedor:
/// {
///   "token": "...",
///   "user": {
///     "id": 2,
///     "name": "Proveedor",
///     "email": "proveedor@email.com",
///     "type": "provider"
///   },
///   "provider": {
///     "id": 1,
///     "status": "approved"
///   }
/// }
class _AuthLoginResponse {
  const _AuthLoginResponse({
    required this.token,
    required this.userName,
    required this.userEmail,
    required this.userType,
    this.providerStatus,
  });

  final String token;
  final String userName;
  final String userEmail;
  final String userType;
  final String? providerStatus;

  factory _AuthLoginResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;

    if (user == null) {
      throw Exception('La respuesta del servidor no contiene el usuario.');
    }

    final provider = json['provider'] as Map<String, dynamic>?;

    final rawType = (user['type'] ?? user['role'] ?? '').toString();

    final inferredType = rawType.trim().isNotEmpty
        ? rawType
        : provider != null
            ? 'provider'
            : 'customer';

    return _AuthLoginResponse(
      token: json['token']?.toString() ?? '',
      userName: (user['name'] ?? user['full_name'] ?? 'Usuario').toString(),
      userEmail: (user['email'] ?? '').toString(),
      userType: inferredType,
      providerStatus: provider?['status']?.toString(),
    );
  }
}

/// Campo reusable del formulario de login.
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

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
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
              size: 22,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 50,
              minHeight: 56,
            ),
            suffixIcon: suffixIcon,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 50,
              minHeight: 56,
            ),
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

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Divider(
            color: Color(0xFFE5E7EB),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFE5E7EB),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: backgroundColor == AppColors.white ? 3 : 0,
          shadowColor: Colors.black.withAlpha(25),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: borderColor,
              width: 1.4,
            ),
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: Center(
                      child: icon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0.0, -1.5),
      child: const Icon(
        Icons.apple,
        color: AppColors.white,
        size: 30,
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  const _GoogleIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double strokeWidth = size.width * 0.17;

    final Rect rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    Paint buildArcPaint(Color color) {
      return Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true;
    }

    const Color googleBlue = Color(0xFF4285F4);
    const Color googleRed = Color(0xFFEA4335);
    const Color googleYellow = Color(0xFFFBBC05);
    const Color googleGreen = Color(0xFF34A853);

    canvas.drawArc(
      rect,
      -0.05 * math.pi,
      0.48 * math.pi,
      false,
      buildArcPaint(googleBlue),
    );

    canvas.drawArc(
      rect,
      -0.78 * math.pi,
      0.50 * math.pi,
      false,
      buildArcPaint(googleRed),
    );

    canvas.drawArc(
      rect,
      -1.25 * math.pi,
      0.42 * math.pi,
      false,
      buildArcPaint(googleYellow),
    );

    canvas.drawArc(
      rect,
      -1.70 * math.pi,
      0.58 * math.pi,
      false,
      buildArcPaint(googleGreen),
    );

    final Paint horizontalPaint = Paint()
      ..color = googleBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final double y = size.height * 0.52;

    canvas.drawLine(
      Offset(size.width * 0.53, y),
      Offset(size.width * 0.88, y),
      horizontalPaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.88, y),
      Offset(size.width * 0.88, size.height * 0.43),
      horizontalPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  @override
  Widget build(BuildContext context) {
    return Wrap(
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
            fontWeight: FontWeight.w800,
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
            fontWeight: FontWeight.w800,
            decoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}