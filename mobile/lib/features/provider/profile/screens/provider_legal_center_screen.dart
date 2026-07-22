import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../customer/auth/data/models/legal_document.dart';
import '../../onboarding/data/datasources/provider_auth_api.dart';
import '../data/models/provider_legal_settings_model.dart';
import '../data/services/provider_legal_settings_service.dart';
import '../../../../core/router/route_names.dart';

class ProviderLegalCenterScreen extends StatefulWidget {
  const ProviderLegalCenterScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProviderLegalCenterScreen> createState() =>
      _ProviderLegalCenterScreenState();
}

class _ProviderLegalCenterScreenState extends State<ProviderLegalCenterScreen> {
  final ProviderLegalSettingsService _service =
      const ProviderLegalSettingsService();

  final ProviderAuthApi _providerAuthApi = const ProviderAuthApi();

  late Future<ProviderLegalSettingsModel> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();
  }

  Future<ProviderLegalSettingsModel> _loadSettings() {
    final token = widget.authController.token;

    if (token == null || token.trim().isEmpty) {
      throw Exception('No existe una sesión válida del afiliado.');
    }

    return _service.getLegalSettings(token: token);
  }

  Future<void> _refresh() async {
    setState(() {
      _settingsFuture = _loadSettings();
    });

    await _settingsFuture;
  }

  Future<void> _openLegalDocument(ProviderLegalDocumentModel summary) async {
    var loadingDialogOpen = false;

    try {
      loadingDialogOpen = true;
      _showLoadingDialog();

      final document = await _providerAuthApi.getLegalDocument(
        type: summary.type,
      );

      if (!mounted) return;

      if (loadingDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();

        loadingDialogOpen = false;
      }

      await _showLegalDocument(document);
    } catch (error) {
      if (!mounted) return;

      if (loadingDialogOpen) {
        final navigator = Navigator.of(context, rootNavigator: true);

        if (navigator.canPop()) {
          navigator.pop();
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        );
      },
    );
  }

  String _cleanMarkdown(String content) {
    return content
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll(RegExp(r'^\s*---\s*$', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*-\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  Future<void> _showLegalDocument(LegalDocument document) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDADDE2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  document.title,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versión ${document.version} · '
                  'Vigente desde ${document.effectiveDateLabel}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(right: 12, bottom: 16),
                      child: SelectableText(
                        _cleanMarkdown(document.content),
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 14,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(modalContext).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }

            context.goNamed(
              RouteNames.providerProfile,
            );
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF111827)),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Centro Legal',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Documentos legales para afiliados',
                style: TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
      body: FutureBuilder<ProviderLegalSettingsModel>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return _LegalErrorView(
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              onRetry: _refresh,
            );
          }

          final settings = snapshot.data;

          if (settings == null) {
            return _LegalErrorView(
              message: 'No se pudo cargar el Centro Legal.',
              onRetry: _refresh,
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryBlue,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _LegalStatusBanner(settings: settings),
                const SizedBox(height: 20),
                _DocumentsSection(
                  documents: settings.documents,
                  onDocumentTap: _openLegalDocument,
                ),
                const SizedBox(height: 20),
                const _InformationCard(),
                const SizedBox(height: 24),
                _LegalFooter(
                  operatorName: settings.operatorName,
                  rnc: settings.rnc,
                  supportEmail: settings.supportEmail,
                  commercialEmail: settings.commercialEmail,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegalStatusBanner extends StatelessWidget {
  const _LegalStatusBanner({required this.settings});

  final ProviderLegalSettingsModel settings;

  @override
  Widget build(BuildContext context) {
    final isComplete =
        settings.summary.allRequiredDocumentsAccepted &&
        !settings.requiresAction;

    final title = isComplete
        ? 'Documentación legal completada'
        : 'Acción legal pendiente';

    final subtitle = isComplete
        ? 'Aceptaste los documentos obligatorios de tu cuenta de afiliado.'
        : '${settings.summary.acceptedRequiredDocumentsCount} de '
              '${settings.summary.requiredDocumentsCount} documentos '
              'obligatorios registrados.';

    final background = isComplete
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFFFBEB);

    final border = isComplete
        ? const Color(0xFFBBF7D0)
        : const Color(0xFFFDE68A);

    final primary = isComplete
        ? const Color(0xFF166534)
        : const Color(0xFF92400E);

    final secondary = isComplete
        ? const Color(0xFF16A34A)
        : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isComplete
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isComplete
                  ? Icons.verified_user_outlined
                  : Icons.warning_amber_rounded,
              color: secondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: primary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({
    required this.documents,
    required this.onDocumentTap,
  });

  final List<ProviderLegalDocumentModel> documents;

  final ValueChanged<ProviderLegalDocumentModel> onDocumentTap;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Text(
          'No hay documentos legales disponibles.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF6B7280)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos legales',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...documents.map(
          (document) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LegalDocumentCard(
              document: document,
              onTap: () => onDocumentTap(document),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalDocumentCard extends StatelessWidget {
  const _LegalDocumentCard({required this.document, required this.onTap});

  final ProviderLegalDocumentModel document;
  final VoidCallback onTap;

  IconData get _icon {
    switch (document.type) {
      case 'terms_provider':
        return Icons.description_outlined;
      case 'provider_standards':
        return Icons.health_and_safety_outlined;
      case 'privacy':
        return Icons.privacy_tip_outlined;
      default:
        return Icons.article_outlined;
    }
  }

  Color get _statusColor {
    if (document.accepted) {
      return const Color(0xFF16A34A);
    }

    if (document.requiresAcceptance) {
      return const Color(0xFFD97706);
    }

    return AppColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final acceptedLabel = document.acceptedLabel?.trim();

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_icon, color: AppColors.primaryBlue, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      document.version,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      document.statusLabel,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (document.accepted &&
                        acceptedLabel != null &&
                        acceptedLabel.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        document.type == 'privacy'
                            ? 'Confirmado el $acceptedLabel'
                            : 'Aceptado el $acceptedLabel',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primaryBlue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Selecciona un documento para consultar su contenido completo, versión vigente y condiciones aplicables a tu cuenta de afiliado.',
              style: TextStyle(
                color: Color(0xFF1E3A5F),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({
    required this.operatorName,
    required this.rnc,
    required this.supportEmail,
    required this.commercialEmail,
  });

  final String operatorName;
  final String rnc;
  final String supportEmail;
  final String commercialEmail;

  @override
  Widget build(BuildContext context) {
    final hasRnc = rnc.trim().isNotEmpty;

    return Column(
      children: [
        Text(
          hasRnc
              ? '$operatorName · RNC: $rnc'
              : '$operatorName · RNC en proceso',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
        const SizedBox(height: 4),
        const Text(
          'Santo Domingo, República Dominicana',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          supportEmail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          commercialEmail,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
        ),
      ],
    );
  }
}

class _LegalErrorView extends StatelessWidget {
  const _LegalErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
