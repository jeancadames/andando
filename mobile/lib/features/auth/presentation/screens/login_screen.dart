import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
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

  /// Controla la animación de entrada de toda la pantalla.
  late final AnimationController _entranceController;

  /// Fade global de entrada.
  late final Animation<double> _fadeIn;

  /// Desplazamiento vertical suave de entrada.
  late final Animation<Offset> _slideIn;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    /// Siempre liberamos los controladores para evitar fugas de memoria.
    _entranceController.dispose();
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

    FocusScope.of(context).unfocus();

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

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Muestra un error con estilo coherente con el rediseño.
  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.textDark,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withAlpha(45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.primaryRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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

  String? _safeRedirectFromQuery() {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];

    if (redirect == null || redirect.trim().isEmpty) {
      return null;
    }

    if (!redirect.startsWith('/') || redirect.startsWith('//')) {
      return null;
    }

    return redirect;
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

    final redirect = _safeRedirectFromQuery();

    if (redirect != null) {
      context.go(redirect);
      return;
    }

    context.goNamed(RouteNames.clientExplore);
  }

  /// Acción temporal del botón "Continuar con Google".
  ///
  /// Por ahora NO llama backend.
  /// Solo dejamos el botón visualmente listo para conectar después.
  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading || _isLoading || _isAppleLoading) {
      return;
    }

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await widget.authController.loginWithGoogle();

      if (!mounted) return;

      final normalizedUserType = _normalizeUserType(
        widget.authController.userType ?? 'customer',
      );

      _redirectAfterLogin(
        userType: normalizedUserType,
        providerStatus: widget.authController.providerStatus,
      );
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  /// Acción temporal del botón "Continuar con Apple".
  ///
  /// Por ahora NO llama backend.
  /// Solo dejamos el botón visualmente listo para conectar después.
  Future<void> _handleAppleLogin() async {
    if (_isAppleLoading || _isLoading || _isGoogleLoading) {
      return;
    }

    setState(() {
      _isAppleLoading = true;
    });

    try {
      await widget.authController.loginWithApple();

      if (!mounted) return;

      final normalizedUserType = _normalizeUserType(
        widget.authController.userType ?? 'customer',
      );

      _redirectAfterLogin(
        userType: normalizedUserType,
        providerStatus: widget.authController.providerStatus,
      );
    } catch (e) {
      if (!mounted) return;

      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isAppleLoading = false;
        });
      }
    }
  }

  /// Acción temporal para recuperación de contraseña.
  void _goToForgotPassword() {
    context.goNamed(RouteNames.forgotPassword);
  }

  /// Navega al registro de cliente.
  void _goToCustomerRegister() {
    final redirect = _safeRedirectFromQuery();

    if (redirect == null) {
      context.goNamed(RouteNames.register);
      return;
    }

    context.goNamed(
      RouteNames.register,
      queryParameters: {
        'redirect': redirect,
      },
    );
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
    final bool anyLoading = _isLoading || _isGoogleLoading || _isAppleLoading;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Stack(
        children: [
          /// Fondo decorativo: manchas de color desenfocadas + ruta discontinua.
          /// Aporta identidad de marca sin comprometer la legibilidad del formulario.
          const Positioned.fill(
            child: _AuroraBackground(),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideIn,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 36),

                            /// Logo de la marca.
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 220,
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
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.5,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 28),

                            /// Encabezado de bienvenida.
                            const Text(
                              '¡Hola de nuevo!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.6,
                                height: 1.1,
                              ),
                            ),

                            const SizedBox(height: 8),

                            /// Subtítulo con acento de marca en color sólido.
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                text: 'Sigue descubriendo\n',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'República Dominicana',
                                    style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// Tarjeta flotante que contiene el formulario.
                            /// El efecto de elevación separa el input del fondo.
                            Container(
                              padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFEDEFF5),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withAlpha(18),
                                    blurRadius: 40,
                                    spreadRadius: -8,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _LoginTextField(
                                      label: 'Correo electrónico',
                                      controller: _emailController,
                                      hintText: 'tu@correo.com',
                                      prefixIcon: Icons.mail_outline_rounded,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
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

                                    const SizedBox(height: 18),

                                    _LoginTextField(
                                      label: 'Contraseña',
                                      controller: _passwordController,
                                      hintText: '••••••••',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: !_showPassword,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) {
                                        if (!anyLoading) _submitLogin();
                                      },
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _showPassword
                                              ? Icons
                                                  .visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppColors.mutedForeground,
                                          size: 21,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'La contraseña es obligatoria.';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(height: 10),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton(
                                        onPressed: _goToForgotPassword,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 4,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize
                                                  .shrinkWrap,
                                        ),
                                        child: const Text(
                                          '¿Olvidaste tu contraseña?',
                                          style: TextStyle(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    /// Botón principal con degradado de marca.
                                    _PrimaryGradientButton(
                                      label: 'Iniciar sesión',
                                      isLoading: _isLoading,
                                      onPressed:
                                          anyLoading ? null : _submitLogin,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 26),

                            const _OrDivider(),

                            const SizedBox(height: 22),

                            /// Botones sociales en fila compacta.
                            Row(
                              children: [
                                Expanded(
                                  child: _SocialLoginButton(
                                    label: 'Google',
                                    backgroundColor: AppColors.white,
                                    foregroundColor: AppColors.textDark,
                                    borderColor: const Color(0xFFE5E7EB),
                                    isLoading: _isGoogleLoading,
                                    icon: const _GoogleIcon(),
                                    onPressed: anyLoading
                                        ? null
                                        : _handleGoogleLogin,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: _SocialLoginButton(
                                    label: 'Apple',
                                    backgroundColor: AppColors.textDark,
                                    foregroundColor: AppColors.white,
                                    borderColor: AppColors.textDark,
                                    isLoading: _isAppleLoading,
                                    icon: const _AppleIcon(),
                                    onPressed: anyLoading
                                        ? null
                                        : _handleAppleLogin,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 28),

                            /// Bloque de registro.
                            RichText(
                              textAlign: TextAlign.center,
                              text: const TextSpan(
                                text: '¿No tienes cuenta? ',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                children: [],
                              ),
                            ),

                            const SizedBox(height: 14),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed:
                                    anyLoading ? null : _goToCustomerRegister,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                  backgroundColor: AppColors.white,
                                  side: const BorderSide(
                                    color: AppColors.primaryBlue,
                                    width: 1.6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Crear cuenta',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 18),

                            /// Acceso a registro de afiliado, con estilo de chip.
                            _AffiliateChip(
                              onTap:
                                  anyLoading ? null : _goToAffiliateRegister,
                            ),

                            const SizedBox(height: 16),

                            TextButton(
                              onPressed: anyLoading ? null : _continueAsGuest,
                              child: const Text(
                                'Continuar como invitado  →',
                                style: TextStyle(
                                  color: AppColors.mutedForeground,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 6, 24, 14),
                  child: _LegalFooter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fondo decorativo con manchas de color desenfocadas (estilo "aurora")
/// más una ruta discontinua sutil, en línea con la landing page.
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          /// Mancha azul superior izquierda.
          Positioned(
            top: -110,
            left: -90,
            child: _blurBlob(
              size: 320,
              color: AppColors.primaryBlue.withAlpha(60),
            ),
          ),

          /// Mancha roja superior derecha.
          Positioned(
            top: -60,
            right: -80,
            child: _blurBlob(
              size: 240,
              color: AppColors.primaryRed.withAlpha(45),
            ),
          ),

          /// Mancha azul tenue inferior.
          Positioned(
            bottom: -140,
            right: -70,
            child: _blurBlob(
              size: 300,
              color: AppColors.primaryBlue.withAlpha(30),
            ),
          ),

          /// Ruta discontinua de marca en la parte superior.
          Positioned(
            top: 90,
            left: 0,
            right: 0,
            height: 120,
            child: CustomPaint(
              painter: _RouteMotifPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurBlob({required double size, required Color color}) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Traza una ruta punteada curva, guiño al motivo de la landing page.
class _RouteMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryBlue.withAlpha(28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(-20, size.height * 0.7)
      ..cubicTo(
        size.width * 0.25,
        size.height * 0.1,
        size.width * 0.6,
        size.height * 1.0,
        size.width + 20,
        size.height * 0.35,
      );

    _drawDashedPath(canvas, path, paint, dash: 7, gap: 7);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dash;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Botón principal con degradado azul de marca, sombra y estado de carga.
class _PrimaryGradientButton extends StatelessWidget {
  const _PrimaryGradientButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null;

    return Opacity(
      opacity: disabled && !isLoading ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A3FC4),
              AppColors.primaryBlue,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlue.withAlpha(90),
              blurRadius: 22,
              spreadRadius: -4,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip que invita a registrarse como afiliado/proveedor.
class _AffiliateChip extends StatelessWidget {
  const _AffiliateChip({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withAlpha(18),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.primaryRed.withAlpha(70),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.storefront_outlined,
                color: AppColors.primaryRed,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Me interesa ser afiliado',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
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

/// Campo reusable del formulario de login con estado de foco.
///
/// Cambia el color del borde, del ícono y la sombra al enfocarse
/// para dar retroalimentación visual clara.
class _LoginTextField extends StatefulWidget {
  const _LoginTextField({
    required this.label,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  State<_LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<_LoginTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _focused) {
        setState(() {
          _focused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        _focused ? AppColors.primaryBlue : AppColors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: _focused ? AppColors.primaryBlue : AppColors.textDark,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withAlpha(28),
                      blurRadius: 16,
                      spreadRadius: -4,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            validator: widget.validator,
            textInputAction: widget.textInputAction,
            onFieldSubmitted: widget.onFieldSubmitted,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 15.5,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppColors.primaryBlue,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF8A94A6),
                fontSize: 15.5,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: activeColor,
                size: 21,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 50,
                minHeight: 56,
              ),
              suffixIcon: widget.suffixIcon,
              suffixIconConstraints: const BoxConstraints(
                minWidth: 50,
                minHeight: 56,
              ),
              filled: true,
              fillColor: _focused ? AppColors.white : const Color(0xFFF6F7FB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 1.6,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.primaryRed),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primaryRed,
                  width: 1.6,
                ),
              ),
              errorStyle: const TextStyle(
                color: AppColors.primaryRed,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
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
    return Row(
      children: const [
        Expanded(
          child: Divider(
            color: Color(0xFFE1E4EC),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'o continúa con',
            style: TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Color(0xFFE1E4EC),
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
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: backgroundColor == AppColors.white ? 2 : 0,
          shadowColor: Colors.black.withAlpha(25),
          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Center(child: icon),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foregroundColor,
                        fontSize: 15,
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
        size: 26,
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
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