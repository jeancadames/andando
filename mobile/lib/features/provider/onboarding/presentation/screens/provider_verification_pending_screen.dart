import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_controller.dart';

/// Pantalla mostrada después de enviar la solicitud.
///
/// También se muestra cuando un proveedor pending inicia sesión.
class ProviderVerificationPendingScreen extends StatelessWidget {
  const ProviderVerificationPendingScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final email = authController.userEmail ?? 'tu correo';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: () {
                    context.goNamed(RouteNames.login);
                  },
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

                      const SizedBox(height: 30),

                      _VerificationCard(),

                      const SizedBox(height: 24),

                      _NextStepsCard(),

                      const SizedBox(height: 24),

                      Text(
                        '✉ Revisa tu correo: $email',
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

              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    context.goNamed(RouteNames.welcome);
                  },
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