import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/data/datasources/customer_auth_api.dart';
import '../../../auth/data/models/legal_document.dart';

import '../../data/datasources/customer_profile_remote_datasource.dart';
import '../../data/models/customer_legal_settings_model.dart';
import '../../../shared/widgets/customer_bottom_navigation.dart';

class CustomerTermsConditionsScreen extends StatefulWidget {
  const CustomerTermsConditionsScreen({super.key});

  @override
  State<CustomerTermsConditionsScreen> createState() =>
      _CustomerTermsConditionsScreenState();
}

class _CustomerTermsConditionsScreenState
    extends State<CustomerTermsConditionsScreen> {
  final CustomerProfileRemoteDataSource _dataSource =
      CustomerProfileRemoteDataSource();

  final CustomerAuthApi _customerAuthApi = const CustomerAuthApi();

  bool _isLoadingLegalSettings = true;
  CustomerLegalSettingsModel? _legalSettings;

  @override
  void initState() {
    super.initState();
    _loadLegalSettings();
  }

  Future<void> _loadLegalSettings() async {
    try {
      final settings = await _dataSource.getLegalSettings();

      if (!mounted) return;

      setState(() {
        _legalSettings = settings;
        _isLoadingLegalSettings = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoadingLegalSettings = false;
      });
    }
  }

  Future<void> _openLegalDocument(
    CustomerLegalDocumentModel documentSummary,
  ) async {
    try {
      _showLoadingDialog();

      final document = await _customerAuthApi.getLegalDocument(
        type: documentSummary.type,
      );

      if (!mounted) return;

      Navigator.of(context, rootNavigator: true).pop();

      await _showLegalDocument(document);
    } catch (error) {
      if (!mounted) return;

      final navigator = Navigator.of(context, rootNavigator: true);

      if (navigator.canPop()) {
        navigator.pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
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
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> _showLegalDocument(LegalDocument document) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
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
                    color: Color(0xFF003B73),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Versión ${document.version} · Vigente desde '
                  '${document.effectiveDateLabel}',
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
                      padding: const EdgeInsets.only(
                        right: 12,
                        bottom: 16,
                      ),
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
                    onPressed: () => Navigator.of(modalContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF003B73),
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

  String _cleanMarkdown(String content) {
    return content
        .replaceAll(
          RegExp(r'^#{1,6}\s+', multiLine: true),
          '',
        )
        .replaceAll('**', '')
        .replaceAll('__', '')
        .replaceAll(
          RegExp(r'^\s*---\s*$', multiLine: true),
          '',
        )
        .replaceAll(
          RegExp(r'^\s*-\s+', multiLine: true),
          '• ',
        )
        .replaceAll(
          RegExp(r'\n{3,}'),
          '\n\n',
        )
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final settings = _legalSettings;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
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
                'Documentos legales de AndanDO',
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
      body: RefreshIndicator(
        onRefresh: _loadLegalSettings,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            _AcceptanceBanner(
              accepted: settings?.termsAccepted ?? false,
              acceptedLabel: settings?.termsAcceptedLabel,
              isLoading: _isLoadingLegalSettings,
            ),
            const SizedBox(height: 20),
            _DocumentsSection(
              documents: settings?.documents ?? const [],
              isLoading: _isLoadingLegalSettings,
              onDocumentTap: _openLegalDocument,
            ),
            const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFBFDBFE),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF003B73),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Selecciona cualquiera de los documentos anteriores para consultar su contenido completo y vigente.',
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
              ),
            const SizedBox(height: 24),
            _LegalFooter(
              rnc: settings?.rnc,
              supportEmail: settings?.supportEmail,
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavigation(
        currentItem: CustomerBottomNavItem.profile,
      ),
    );
  }
}

class _AcceptanceBanner extends StatelessWidget {
  const _AcceptanceBanner({
    required this.accepted,
    required this.acceptedLabel,
    required this.isLoading,
  });

  final bool accepted;
  final String? acceptedLabel;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool showPositiveStyle = isLoading || accepted;

    final String title = isLoading
        ? 'Consultando aceptación'
        : accepted
            ? 'Términos aceptados'
            : 'Pendiente de aceptación';

    final String subtitle = isLoading
        ? 'Cargando fecha de aceptación...'
        : accepted
            ? acceptedLabel != null && acceptedLabel!.trim().isNotEmpty
                ? 'Aceptaste los términos el $acceptedLabel'
                : 'Aceptaste los términos al crear tu cuenta'
            : 'Debes aceptar los términos durante el registro';

    final Color backgroundColor = showPositiveStyle
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFFFFBEB);

    final Color borderColor = showPositiveStyle
        ? const Color(0xFFBBF7D0)
        : const Color(0xFFFDE68A);

    final Color circleColor = showPositiveStyle
        ? const Color(0xFFDCFCE7)
        : const Color(0xFFFEF3C7);

    final Color primaryColor = showPositiveStyle
        ? const Color(0xFF166534)
        : const Color(0xFF92400E);

    final Color secondaryColor = showPositiveStyle
        ? const Color(0xFF16A34A)
        : const Color(0xFFD97706);

    final IconData icon = isLoading
        ? Icons.hourglass_top_rounded
        : accepted
            ? Icons.shield_outlined
            : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: secondaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: secondaryColor,
                    fontSize: 12,
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
    required this.isLoading,
    required this.onDocumentTap,
  });

  final List<CustomerLegalDocumentModel> documents;
  final bool isLoading;
  final ValueChanged<CustomerLegalDocumentModel> onDocumentTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
          ),
        ),
        child: const Text(
          'No se pudieron cargar los documentos legales.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
          ),
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: documents.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final document = documents[index];

            return _DocumentCard(
              icon: _iconForDocument(document.type),
              title: document.title,
              subtitle: document.version,
              accepted: document.accepted,
              acceptanceScope: document.acceptanceScope,
              onTap: () => onDocumentTap(document),
            );
          },
        ),
      ],
    );
  }

  IconData _iconForDocument(String type) {
    switch (type) {
      case 'terms_user':
        return Icons.description_outlined;
      case 'privacy':
        return Icons.shield_outlined;
      case 'cookies':
        return Icons.cookie_outlined;
      case 'payment_policy':
        return Icons.payments_outlined;
      case 'waiver':
        return Icons.health_and_safety_outlined;
      case 'minors':
        return Icons.family_restroom_outlined;
      default:
        return Icons.article_outlined;
    }
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accepted,
    required this.onTap,
    required this.acceptanceScope,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool accepted;
  final VoidCallback onTap;
  final String acceptanceScope;

  String _statusLabel() {
    if (accepted) {
      return 'Aceptado';
    }

    switch (acceptanceScope) {
      case 'booking':
        return 'Se acepta al reservar';
      case 'booking_with_minors':
        return 'Aplica con menores';
      case 'account':
        return 'Pendiente';
      default:
        return 'Documento informativo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 118,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF003B73),
                  size: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _statusLabel(),
                style: TextStyle(
                  color: accepted
                    ? const Color(0xFF16A34A)
                    : acceptanceScope == 'account'
                        ? const Color(0xFFD97706)
                        : const Color(0xFF003B73),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalFooter extends StatelessWidget {
  const _LegalFooter({
    required this.rnc,
    required this.supportEmail,
  });

  final String? rnc;
  final String? supportEmail;

  @override
  Widget build(BuildContext context) {
    final hasRnc = rnc != null && rnc!.trim().isNotEmpty;

    return Center(
      child: Column(
        children: [
          Text(
            hasRnc
                ? 'ABC VANTEK GROUP, S.R.L. · RNC: $rnc'
                : 'ABC VANTEK GROUP, S.R.L. · RNC en proceso',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Santo Domingo, República Dominicana',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            supportEmail ?? 'soporte@andando.do',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
