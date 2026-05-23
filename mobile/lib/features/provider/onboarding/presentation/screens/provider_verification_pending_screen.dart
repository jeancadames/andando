import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../data/datasources/provider_auth_api.dart';

/// Pantalla mostrada cuando la solicitud de afiliado está pendiente.
///
/// Esta pantalla se muestra en dos casos:
///
/// 1. Justo después de enviar la solicitud de afiliado.
/// 2. Cuando un afiliado pendiente inicia sesión.
///
/// Además, esta pantalla ahora hace algo importante:
///
/// - Consulta el backend para refrescar el status real.
/// - Si el backend devuelve "approved", redirige al dashboard.
/// - Si sigue "pending", se queda aquí.
/// - Si el usuario toca "Volver al Inicio", cerramos sesión local
///   para que pueda ir al login o entrar como invitado.
class ProviderVerificationPendingScreen extends StatefulWidget {
  const ProviderVerificationPendingScreen({
    super.key,
    required this.authController,
  });

  /// Controlador global de autenticación.
  ///
  /// Aquí vive el token, email, tipo de usuario y providerStatus local.
  final AuthController authController;

  @override
  State<ProviderVerificationPendingScreen> createState() =>
      _ProviderVerificationPendingScreenState();
}

class _ProviderVerificationPendingScreenState
    extends State<ProviderVerificationPendingScreen> {
  /// Servicio API para consultar Laravel.
  final ProviderAuthApi _providerAuthApi = const ProviderAuthApi();

  /// Indica si estamos consultando el backend para refrescar el status.
  bool _isCheckingStatus = false;

  /// Mensaje opcional de error si falla el refresh.
  ///
  /// No bloqueamos la pantalla si falla.
  /// Simplemente dejamos al usuario en pending y puede intentar luego.
  String? _statusError;

  @override
  void initState() {
    super.initState();

    /// Al entrar a esta pantalla, refrescamos el estado del afiliado.
    ///
    /// Esto resuelve el problema de:
    /// "Lo aprobé en base de datos, pero la app sigue viéndolo como pending".
    _refreshProviderStatus();
  }

  /// Consulta el backend para saber si el afiliado ya fue aprobado.
  ///
  /// Flujo:
  /// 1. Lee el token guardado en AuthController.
  /// 2. Llama GET /api/provider/me.
  /// 3. Obtiene provider.status.
  /// 4. Actualiza AuthController.
  /// 5. Si status == approved, redirige al dashboard.
  Future<void> _refreshProviderStatus() async {
    final token = widget.authController.token;

    /// Si no hay token, no podemos consultar /provider/me.
    ///
    /// Esto podría pasar si el usuario ya cerró sesión o si se limpió
    /// el storage local.
    if (token == null || token.trim().isEmpty) {
      return;
    }

    setState(() {
      _isCheckingStatus = true;
      _statusError = null;
    });

    try {
      final status = await _providerAuthApi.getCurrentProviderStatus(
        token: token,
      );

      /// Guardamos el nuevo status localmente.
      ///
      /// Esto actualiza secure storage y notifica al router.
      await widget.authController.updateProviderStatus(status);

      if (!mounted) return;

      /// Si el afiliado ya fue aprobado, lo mandamos al dashboard.
      if (status == 'approved') {
        context.goNamed(RouteNames.providerDashboard);
        return;
      }
    } catch (e) {
      if (!mounted) return;

      /// No forzamos salida si falla.
      /// Solo guardamos un mensaje para mostrarlo de forma discreta.
      setState(() {
        _statusError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  /// Cierra la sesión y manda al inicio.
  ///
  /// Esto es necesario porque si el usuario sigue autenticado como:
  ///
  /// userType = provider
  /// providerStatus = pending
  ///
  /// el router lo va a devolver automáticamente a:
  ///
  /// /provider/verification-pending
  ///
  /// Al cerrar sesión:
  /// - borramos token local.
  /// - borramos providerStatus local.
  /// - el usuario puede ir al login.
  /// - el usuario puede continuar como invitado.
  Future<void> _goToStart() async {
    final token = widget.authController.token;

    /// Intentamos cerrar sesión también en Laravel.
    ///
    /// Si falla, no bloqueamos la salida del usuario.
    /// Lo importante para la navegación es limpiar la sesión local.
    if (token != null && token.trim().isNotEmpty) {
      try {
        await _providerAuthApi.logout(token: token);
      } catch (_) {
        /// Ignoramos errores de logout remoto.
        ///
        /// Ejemplo:
        /// - backend apagado.
        /// - token expirado.
        /// - error de conexión.
      }
    }

    /// Cerramos sesión local.
    ///
    /// Esto limpia secure storage y AuthController.
    await widget.authController.logout();

    if (!mounted) return;

    /// Mandamos al splash/welcome.
    ///
    /// Tu WelcomeScreen luego redirige automáticamente al LoginScreen.
    context.goNamed(RouteNames.welcome);
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.authController.userEmail ?? 'tu correo';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              /// Botón superior de volver.
              ///
              /// Antes solo navegaba al login, pero el router lo devolvía
              /// a pending porque seguía autenticado.
              ///
              /// Ahora primero cierra sesión.
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: _goToStart,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 60),

                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 104,
                            height: 104,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primaryBlue,
                                  AppColors.primaryRed,
                                ],
                              ),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: AppColors.white,
                              size: 56,
                            ),
                          ),
                          Positioned(
                            right: -4,
                            top: -8,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFC107),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.hourglass_top),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        '¡Solicitud Enviada!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Gracias por registrarte como afiliado en AndanDO.\nEstamos revisando tu documentación.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Estado de consulta.
                      ///
                      /// Si el usuario fue aprobado desde backend,
                      /// esta consulta lo moverá automáticamente al dashboard.
                      if (_isCheckingStatus)
                        const _CheckingStatusMessage()
                      else
                        TextButton.icon(
                          onPressed: _refreshProviderStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Actualizar estado'),
                        ),

                      if (_statusError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _statusError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      _VerificationCard(),

                      const SizedBox(height: 24),

                      _NextStepsCard(),

                      const SizedBox(height: 24),

                      Text(
                        '✉️ Revisa tu correo: $email',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        '📞 ¿Preguntas? (809) 000-0000',
                        style: TextStyle(
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Botón inferior.
              ///
              /// Ahora cierra sesión antes de mandar al inicio.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _goToStart,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    side: const BorderSide(
                      color: Color(0xFFE5E7EB),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Volver al Inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mensaje mostrado mientras consultamos el status real en backend.
class _CheckingStatusMessage extends StatelessWidget {
  const _CheckingStatusMessage();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryBlue,
          ),
        ),
        SizedBox(width: 10),
        Text(
          'Consultando estado...',
          style: TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _VerificationCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              'Proceso de Verificación',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          SizedBox(height: 20),
          _StepRow(
            icon: Icons.check,
            title: 'Solicitud recibida',
            subtitle: 'Hoy',
            color: Color(0xFFD1FAE5),
          ),
          SizedBox(height: 18),
          _StepRow(
            icon: Icons.schedule,
            title: 'Revisión de documentos',
            subtitle: '24-48 horas',
            color: Color(0xFFDBEAFE),
          ),
          SizedBox(height: 18),
          _StepRow(
            icon: Icons.looks_3,
            title: 'Aprobación',
            subtitle: 'Pendiente',
            color: Color(0xFFF3F4F6),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: Icon(
            icon,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
        children: [
          Text(
            '¿Qué sigue?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),
          Text('📧 Recibirás un correo cuando completemos la revisión'),
          SizedBox(height: 10),
          Text('🧾 Te notificaremos si necesitamos información adicional'),
          SizedBox(height: 10),
          Text('✅ Una vez aprobado, podrás crear tus experiencias'),
        ],
      ),
    );
  }
}