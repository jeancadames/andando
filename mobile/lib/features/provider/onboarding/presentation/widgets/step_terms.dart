import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../customer/auth/data/models/legal_document.dart';

/// Paso legal del onboarding del afiliado.
class StepTerms extends StatelessWidget {
  const StepTerms({
    super.key,
    required this.termsDocument,
    required this.standardsDocument,
    required this.privacyDocument,
    required this.isLoading,
    required this.errorMessage,
    required this.acceptTerms,
    required this.acceptStandards,
    required this.acceptPrivacy,
    required this.onRetry,
    required this.onOpenDocument,
    required this.onTermsChanged,
    required this.onStandardsChanged,
    required this.onPrivacyChanged,
  });

  final LegalDocument? termsDocument;
  final LegalDocument? standardsDocument;
  final LegalDocument? privacyDocument;

  final bool isLoading;
  final String? errorMessage;

  final bool acceptTerms;
  final bool acceptStandards;
  final bool acceptPrivacy;

  final VoidCallback onRetry;
  final ValueChanged<LegalDocument> onOpenDocument;

  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onStandardsChanged;
  final ValueChanged<bool?> onPrivacyChanged;

  bool get _documentsReady {
    return termsDocument != null &&
        standardsDocument != null &&
        privacyDocument != null &&
        !isLoading;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos legales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Revisa los documentos vigentes antes de enviar tu solicitud.',
          style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
        ),
        const SizedBox(height: 24),

        if (isLoading) const _LoadingLegalDocuments(),

        if (!isLoading && errorMessage != null)
          _LegalDocumentsError(message: errorMessage!, onRetry: onRetry),

        if (_documentsReady) ...[
          _LegalDocumentCard(
            document: termsDocument!,
            icon: Icons.description_outlined,
            onPressed: () {
              onOpenDocument(termsDocument!);
            },
          ),
          const SizedBox(height: 12),
          _LegalDocumentCard(
            document: standardsDocument!,
            icon: Icons.health_and_safety_outlined,
            onPressed: () {
              onOpenDocument(standardsDocument!);
            },
          ),
          const SizedBox(height: 12),
          _LegalDocumentCard(
            document: privacyDocument!,
            icon: Icons.privacy_tip_outlined,
            onPressed: () {
              onOpenDocument(privacyDocument!);
            },
          ),
          const SizedBox(height: 22),

          _PolicyCheckbox(
            value: acceptTerms,
            enabled: _documentsReady,
            onChanged: onTermsChanged,
            prefix: 'He leído y acepto los ',
            linkText: 'Términos y Condiciones para Afiliados',
            suffix: '.',
            onLinkTap: () {
              onOpenDocument(termsDocument!);
            },
          ),
          const SizedBox(height: 14),

          _PolicyCheckbox(
            value: acceptStandards,
            enabled: _documentsReady,
            onChanged: onStandardsChanged,
            prefix: 'He leído y acepto los ',
            linkText: 'Estándares de Publicación, Operación y Seguridad',
            suffix: '.',
            onLinkTap: () {
              onOpenDocument(standardsDocument!);
            },
          ),
          const SizedBox(height: 14),

          _PolicyCheckbox(
            value: acceptPrivacy,
            enabled: _documentsReady,
            onChanged: onPrivacyChanged,
            prefix: 'Confirmo que he leído la ',
            linkText: 'Política de Privacidad',
            suffix: ' y comprendo el tratamiento de mis datos.',
            onLinkTap: () {
              onOpenDocument(privacyDocument!);
            },
          ),
        ],

        const SizedBox(height: 28),

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
                text:
                    '1. Revisaremos la información y los documentos suministrados.',
              ),
              _NextStepText(
                text: '2. Recibirás una notificación con el resultado.',
              ),
              _NextStepText(
                text: '3. Cuando seas aprobado podrás publicar experiencias.',
              ),
              _NextStepText(
                text:
                    '4. Tus publicaciones también deberán cumplir los estándares aceptados.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegalDocumentCard extends StatelessWidget {
  const _LegalDocumentCard({
    required this.document,
    required this.icon,
    required this.onPressed,
  });

  final LegalDocument document;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final summary = document.summary?.trim();

    return Material(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withAlpha(18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryBlue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Versión ${document.version} · '
                      'Vigente desde ${document.effectiveDateLabel}',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                    if (summary != null && summary.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        summary,
                        style: const TextStyle(
                          color: AppColors.mutedForeground,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                      'Abrir documento completo',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.primaryBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyCheckbox extends StatelessWidget {
  const _PolicyCheckbox({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.prefix,
    required this.linkText,
    required this.suffix,
    required this.onLinkTap,
  });

  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  final String prefix;
  final String linkText;
  final String suffix;
  final VoidCallback onLinkTap;

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
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                GestureDetector(
                  onTap: enabled
                      ? () {
                          onChanged(!value);
                        }
                      : null,
                  child: Text(
                    prefix,
                    style: TextStyle(
                      color: enabled
                          ? AppColors.textDark
                          : AppColors.mutedForeground,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: enabled ? onLinkTap : null,
                  child: Text(
                    linkText,
                    style: TextStyle(
                      color: enabled
                          ? AppColors.primaryBlue
                          : AppColors.mutedForeground,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: enabled
                      ? () {
                          onChanged(!value);
                        }
                      : null,
                  child: Text(
                    suffix,
                    style: TextStyle(
                      color: enabled
                          ? AppColors.textDark
                          : AppColors.mutedForeground,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadingLegalDocuments extends StatelessWidget {
  const _LoadingLegalDocuments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cargando documentos legales vigentes...',
              style: TextStyle(color: AppColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalDocumentsError extends StatelessWidget {
  const _LegalDocumentsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _NextStepText extends StatelessWidget {
  const _NextStepText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.mutedForeground, fontSize: 13),
      ),
    );
  }
}
