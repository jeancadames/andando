import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';

/// Botón circular de regresar usado en onboarding de proveedor.
///
/// Lo separamos para reutilizarlo en:
/// - login proveedor.
/// - registro proveedor.
/// - pantalla pending.
class ProviderBackButton extends StatelessWidget {
  const ProviderBackButton({
    super.key,
    required this.onPressed,
  });

  /// Función que se ejecuta al tocar el botón.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back,
          color: AppColors.primaryBlue,
          size: 22,
        ),
      ),
    );
  }
}

/// Header utilizado en pantallas simples de proveedor.
///
/// Ejemplo:
/// - ProviderLoginScreen
///
/// Contiene:
/// - botón de volver.
/// - título.
/// - subtítulo.
/// - borde inferior.
class ProviderAuthHeader extends StatelessWidget {
  const ProviderAuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProviderBackButton(onPressed: onBack),
          const SizedBox(height: 32),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Header específico del registro de proveedor.
///
/// Incluye:
/// - botón de volver.
/// - título.
/// - texto "Paso X de 4".
/// - barra de progreso.
class ProviderRegisterHeader extends StatelessWidget {
  const ProviderRegisterHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProviderBackButton(onPressed: onBack),
          const SizedBox(height: 24),
          const Text(
            'Conviértete en Afiliado',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paso $currentStep de $totalSteps',
            style: const TextStyle(
              color: AppColors.mutedForeground,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          /// Barra de progreso.
          Row(
            children: List.generate(totalSteps, (index) {
              final step = index + 1;
              final isActive = step <= currentStep;

              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index == totalSteps - 1 ? 0 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryBlue
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}