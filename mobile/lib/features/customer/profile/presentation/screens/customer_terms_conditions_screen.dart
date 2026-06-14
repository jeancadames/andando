import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  int? _openSection = 0;
  final bool _accepted = true;

  bool _isLoadingLegalSettings = true;
  CustomerLegalSettingsModel? _legalSettings;

  final List<_TermsSection> _sections = const [
    _TermsSection(
      title: '1. Aceptación de Términos',
      content:
          'Al descargar, instalar o usar la aplicación AndanDO, usted acepta quedar vinculado por estos Términos y Condiciones. Si no está de acuerdo con alguno de los términos, no podrá usar la aplicación. AndanDO se reserva el derecho de modificar estos términos en cualquier momento, notificando a los usuarios con 30 días de anticipación.',
    ),
    _TermsSection(
      title: '2. Descripción del Servicio',
      content:
          'AndanDO es un marketplace digital que conecta a viajeros con proveedores de experiencias turísticas en la República Dominicana. Actuamos como intermediarios y no somos responsables de la ejecución directa de las experiencias. La responsabilidad de la calidad del servicio recae en los afiliados verificados.',
    ),
    _TermsSection(
      title: '3. Registro y Cuenta de Usuario',
      content:
          'Para usar AndanDO debe crear una cuenta con información verídica. Es responsable de mantener la confidencialidad de su contraseña. Debe notificarnos inmediatamente de cualquier uso no autorizado.',
    ),
    _TermsSection(
      title: '4. Reservas y Cancelaciones',
      content:
          'Las reservas se confirman al completar el pago. El cliente puede cancelar sin cargo hasta 24 horas antes de la experiencia. Las cancelaciones posteriores estarán sujetas a las políticas aplicables.',
    ),
    _TermsSection(
      title: '5. Política de Pagos y Reembolsos',
      content:
          'Los pagos se procesan mediante sistemas certificados PCI DSS. Los reembolsos se procesan al método de pago original según las condiciones de cada experiencia.',
    ),
    _TermsSection(
      title: '6. Responsabilidades del Usuario',
      content:
          'El usuario se compromete a participar en las experiencias con respeto, seguir instrucciones de seguridad y no utilizar la plataforma para actividades ilegales.',
    ),
    _TermsSection(
      title: '7. Propiedad Intelectual',
      content:
          'Todo el contenido de AndanDO incluyendo diseño, logotipo, textos e imágenes es propiedad de AndanDO SRL y está protegido por la legislación aplicable.',
    ),
    _TermsSection(
      title: '8. Privacidad y Datos Personales',
      content:
          'AndanDO recopila y procesa datos personales conforme a la legislación vigente de República Dominicana y a nuestra Política de Privacidad.',
    ),
    _TermsSection(
      title: '9. Limitación de Responsabilidad',
      content:
          'AndanDO no será responsable por daños indirectos, incidentales o consecuentes derivados del uso de la plataforma.',
    ),
    _TermsSection(
      title: '10. Legislación Aplicable',
      content:
          'Estos términos se rigen por las leyes de la República Dominicana y cualquier disputa será sometida a los tribunales competentes de Santo Domingo.',
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    final settings = _legalSettings;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos y Condiciones',
              style: TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Última actualización: 1 de junio de 2026',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLegalSettings,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            _AcceptanceBanner(
              accepted: _accepted,
              acceptedLabel: settings?.termsAcceptedLabel,
              isLoading: _isLoadingLegalSettings,
            ),
            const SizedBox(height: 20),
            _DocumentsSection(
              termsVersion: settings?.termsVersion ?? 'v1.0',
              privacyVersion: settings?.privacyVersion ?? 'v1.0',
              cookiesVersion: settings?.cookiesVersion ?? 'v1.0',
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: List.generate(
                  _sections.length,
                  (index) {
                    final section = _sections[index];
                    final isOpen = _openSection == index;

                    return _TermsTile(
                      section: section,
                      isOpen: isOpen,
                      showDivider: index != _sections.length - 1,
                      onTap: () {
                        setState(() {
                          _openSection = isOpen ? null : index;
                        });
                      },
                    );
                  },
                ),
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
    final subtitle = isLoading
        ? 'Cargando fecha de aceptación...'
        : accepted
            ? 'Aceptaste los términos el ${acceptedLabel ?? 'crear tu cuenta'}'
            : 'Lee y acepta para continuar usando la app';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accepted ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accepted ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color:
                  accepted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              accepted ? Icons.shield_outlined : Icons.warning_amber_rounded,
              color:
                  accepted ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accepted ? 'Términos aceptados' : 'Pendiente de aceptación',
                  style: TextStyle(
                    color: accepted
                        ? const Color(0xFF166534)
                        : const Color(0xFF92400E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: accepted
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
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
    required this.termsVersion,
    required this.privacyVersion,
    required this.cookiesVersion,
  });

  final String termsVersion;
  final String privacyVersion;
  final String cookiesVersion;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DocumentCard(
            icon: Icons.description_outlined,
            title: 'Términos de Servicio',
            subtitle: termsVersion,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DocumentCard(
            icon: Icons.shield_outlined,
            title: 'Política de Privacidad',
            subtitle: privacyVersion,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DocumentCard(
            icon: Icons.article_outlined,
            title: 'Política de Cookies',
            subtitle: cookiesVersion,
          ),
        ),
      ],
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
        ],
      ),
    );
  }
}

class _TermsTile extends StatelessWidget {
  const _TermsTile({
    required this.section,
    required this.isOpen,
    required this.showDivider,
    required this.onTap,
  });

  final _TermsSection section;
  final bool isOpen;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(color: Color(0xFFF3F4F6)),
                )
              : null,
        ),
        child: Column(
          children: [
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        section.title,
                        style: TextStyle(
                          color: isOpen
                              ? const Color(0xFF003B73)
                              : const Color(0xFF374151),
                          fontWeight:
                              isOpen ? FontWeight.w900 : FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Icon(
                      isOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isOpen
                          ? const Color(0xFF003B73)
                          : const Color(0xFF9CA3AF),
                    ),
                  ],
                ),
              ),
            ),
            if (isOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    section.content,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      height: 1.45,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
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
    return Center(
      child: Column(
        children: [
          Text(
            'AndanDO SRL · RNC: ${rnc ?? ''}',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Santo Domingo, República Dominicana',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            supportEmail ?? 'soporte@andando.com.do',
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

class _TermsSection {
  const _TermsSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;
}