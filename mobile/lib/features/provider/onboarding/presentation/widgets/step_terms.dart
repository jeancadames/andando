import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Paso 4 del registro de proveedor.
///
/// En este paso el proveedor:
/// - revisa un resumen de términos.
/// - acepta términos y condiciones.
/// - acepta política de privacidad.
/// - ve los próximos pasos.
///
/// Este paso es importante legalmente porque el backend debe recibir:
/// - accept_terms = true
/// - accept_privacy = true
///
/// En Laravel guardaremos también:
/// - terms_accepted_at
/// - privacy_accepted_at
/// - terms_version
/// - privacy_version
class StepTerms extends StatelessWidget {
  const StepTerms({
    super.key,
    required this.acceptTerms,
    required this.acceptPrivacy,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
  });

  /// Indica si el usuario aceptó términos.
  final bool acceptTerms;

  /// Indica si el usuario aceptó privacidad.
  final bool acceptPrivacy;

  /// Callback cuando cambia el checkbox de términos.
  final ValueChanged<bool?> onTermsChanged;

  /// Callback cuando cambia el checkbox de privacidad.
  final ValueChanged<bool?> onPrivacyChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Título del paso.
        const Text(
          'Términos y Condiciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        /// Subtítulo.
        const Text(
          'Revisa y acepta nuestras políticas',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedForeground,
          ),
        ),

        const SizedBox(height: 24),

        /// Caja scrollable con resumen de términos.
        ///
        /// Tiene altura fija para simular el comportamiento del diseño:
        /// el usuario puede hacer scroll dentro del resumen.
        Container(
          width: double.infinity,
          height: 210,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen de Términos',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 14),
                _TermsParagraph(
                  text:
                      '• Como afiliado verificado, te comprometes a ofrecer experiencias de calidad y seguras.',
                ),
                _TermsParagraph(
                  text:
                      '• Debes mantener tus experiencias actualizadas con información precisa.',
                ),
                _TermsParagraph(
                  text:
                      '• AndanDO cobra una comisión del 15% por reserva confirmada.',
                ),
                _TermsParagraph(
                  text:
                      '• Los pagos se procesan 48 horas después de completar la experiencia.',
                ),
                _TermsParagraph(
                  text:
                      '• Debes responder a consultas de clientes en menos de 24 horas.',
                ),
                _TermsParagraph(
                  text:
                      '• Mantienes la propiedad de tu contenido, pero otorgas licencia a AndanDO para mostrarlo.',
                ),
                _TermsParagraph(
                  text:
                      '• Debes cumplir con todas las regulaciones turísticas locales.',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        /// Checkbox de términos.
        _PolicyCheckbox(
          value: acceptTerms,
          onChanged: onTermsChanged,
          children: const [
            TextSpan(text: 'Acepto los '),
            TextSpan(
              text: 'Términos y Condiciones',
              style: TextStyle(
                color: AppColors.primaryBlue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' de AndanDO'),
          ],
        ),

        const SizedBox(height: 12),

        /// Checkbox de privacidad.
        _PolicyCheckbox(
          value: acceptPrivacy,
          onChanged: onPrivacyChanged,
          children: const [
            TextSpan(text: 'Acepto la '),
            TextSpan(
              text: 'Política de Privacidad',
              style: TextStyle(
                color: AppColors.primaryBlue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: ' y el tratamiento de mis datos'),
          ],
        ),

        const SizedBox(height: 28),

        /// Tarjeta de próximos pasos.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryBlue.withAlpha(16),
                AppColors.primaryRed.withAlpha(16),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: AppColors.primaryBlue,
                    size: 22,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Próximos pasos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              _NextStepText(
                text: '1. Verificaremos tus documentos en 24-48 horas',
              ),
              _NextStepText(
                text: '2. Recibirás un correo de confirmación',
              ),
              _NextStepText(
                text: '3. Podrás crear tu primera experiencia',
              ),
              _NextStepText(
                text: '4. ¡Comienza a recibir reservas!',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Párrafo dentro del resumen de términos.
class _TermsParagraph extends StatelessWidget {
  const _TermsParagraph({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 13,
          height: 1.35,
        ),
      ),
    );
  }
}

/// Checkbox reutilizable para aceptación legal.
///
/// Usa RichText para poder mezclar texto normal
/// con texto azul subrayado.
class _PolicyCheckbox extends StatelessWidget {
  const _PolicyCheckbox({
    required this.value,
    required this.onChanged,
    required this.children,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final List<TextSpan> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: GestureDetector(
            onTap: () {
              /// Permite marcar/desmarcar tocando también el texto.
              onChanged(!value);
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  height: 1.35,
                ),
                children: children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Línea dentro de la tarjeta "Próximos pasos".
class _NextStepText extends StatelessWidget {
  const _NextStepText({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 13,
        ),
      ),
    );
  }
}