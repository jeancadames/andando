import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../data/datasources/customer_auth_api.dart';
import '../../data/models/legal_document.dart';

class SocialLegalOnboardingScreen extends StatefulWidget {
  const SocialLegalOnboardingScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<SocialLegalOnboardingScreen> createState() =>
      _SocialLegalOnboardingScreenState();
}

class _SocialLegalOnboardingScreenState
    extends State<SocialLegalOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = const CustomerAuthApi();
  final _birthDateController = TextEditingController();

  LegalDocument? _termsDocument;
  LegalDocument? _privacyDocument;

  bool _loadingDocuments = true;
  bool _submitting = false;
  bool _accepted = false;

  String? _documentsError;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() {
      _loadingDocuments = true;
      _documentsError = null;
      _accepted = false;
    });

    try {
      final documents = await Future.wait([
        _api.getLegalDocument(type: 'terms_user'),
        _api.getLegalDocument(type: 'privacy'),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _termsDocument = documents[0];
        _privacyDocument = documents[1];
        _loadingDocuments = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _termsDocument = null;
        _privacyDocument = null;
        _loadingDocuments = false;
        _documentsError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool get _documentsReady {
    return !_loadingDocuments &&
        _termsDocument != null &&
        _privacyDocument != null;
  }

  bool get _canSubmit {
    return !_submitting &&
        _documentsReady &&
        _accepted &&
        _birthDateController.text.trim().isNotEmpty;
  }

  DateTime _maximumBirthDate() {
    final now = DateTime.now();

    return DateTime(now.year - 18, now.month, now.day);
  }

  bool _isAdult(DateTime date) {
    final maximumDate = _maximumBirthDate();

    final normalizedDate = DateTime(date.year, date.month, date.day);

    return !normalizedDate.isAfter(maximumDate);
  }

  Future<void> _selectBirthDate() async {
    final maximumDate = _maximumBirthDate();

    final currentDate = DateTime.tryParse(_birthDateController.text.trim());

    final initialDate = currentDate != null && _isAdult(currentDate)
        ? currentDate
        : DateTime(maximumDate.year - 7, maximumDate.month, maximumDate.day);

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: maximumDate,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
      fieldLabelText: 'Fecha de nacimiento',
      errorFormatText: 'Introduce una fecha válida',
      errorInvalidText: 'Debes tener al menos 18 años',
    );

    if (selectedDate == null) {
      return;
    }

    _birthDateController.text =
        '${selectedDate.year.toString().padLeft(4, '0')}-'
        '${selectedDate.month.toString().padLeft(2, '0')}-'
        '${selectedDate.day.toString().padLeft(2, '0')}';

    setState(() {});
  }

  String? _validateBirthDate(String? value) {
    final normalizedValue = value?.trim() ?? '';

    if (normalizedValue.isEmpty) {
      return 'La fecha de nacimiento es obligatoria.';
    }

    final parsedDate = DateTime.tryParse(normalizedValue);

    if (parsedDate == null) {
      return 'Selecciona una fecha válida.';
    }

    if (!_isAdult(parsedDate)) {
      return 'Debes tener al menos 18 años para utilizar AndanDO.';
    }

    return null;
  }

  String? _safeRedirectFromQuery() {
    final redirect = GoRouterState.of(context).uri.queryParameters['redirect'];

    if (redirect == null || redirect.trim().isEmpty) {
      return null;
    }

    if (!redirect.startsWith('/') || redirect.startsWith('//')) {
      return null;
    }

    if (redirect == '/auth/social/legal-onboarding') {
      return null;
    }

    return redirect;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final token = widget.authController.token;
    final termsDocument = _termsDocument;
    final privacyDocument = _privacyDocument;

    if (token == null || token.trim().isEmpty) {
      _showMessage('La sesión expiró. Inicia sesión nuevamente.');
      return;
    }

    if (!_accepted) {
      _showMessage(
        'Debes aceptar los Términos y confirmar que leíste la Política de Privacidad.',
      );
      return;
    }

    if (termsDocument == null || privacyDocument == null) {
      _showMessage('Los documentos legales todavía no están disponibles.');
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await _api.completeSocialLegalOnboarding(
        apiToken: token,
        birthDate: _birthDateController.text.trim(),
        termsDocumentId: termsDocument.id,
        termsChecksum: termsDocument.checksum,
        acceptTerms: true,
        privacyDocumentId: privacyDocument.id,
        privacyChecksum: privacyDocument.checksum,
        privacyAcknowledged: true,
      );

      await widget.authController.completeLegalOnboarding();

      if (!mounted) {
        return;
      }

      final redirect = _safeRedirectFromQuery();

      if (redirect != null) {
        context.go(redirect);
        return;
      }

      context.goNamed(RouteNames.clientExplore);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await widget.authController.logout();

    if (!mounted) {
      return;
    }

    context.goNamed(RouteNames.login);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      backgroundColor: AppColors.white,
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
                  'Versión ${document.version} · Vigente desde '
                  '${document.effectiveDateLabel}',
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(modalContext).pop();
                    },
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

  Widget _documentsStatus() {
    if (_loadingDocuments) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Cargando documentos legales vigentes...',
              style: TextStyle(color: AppColors.mutedForeground, fontSize: 13),
            ),
          ),
        ],
      );
    }

    final error = _documentsError;

    if (error == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            error,
            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadDocuments,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _legalAgreement() {
    final termsDocument = _termsDocument;
    final privacyDocument = _privacyDocument;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _accepted,
          activeColor: AppColors.primaryBlue,
          onChanged: _documentsReady
              ? (value) {
                  setState(() {
                    _accepted = value ?? false;
                  });
                }
              : null,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Confirmo que tengo 18 años o más, acepto los ',
                  style: TextStyle(fontSize: 14, height: 1.45),
                ),
                GestureDetector(
                  onTap: termsDocument == null
                      ? null
                      : () {
                          _showLegalDocument(termsDocument);
                        },
                  child: Text(
                    'Términos y Condiciones',
                    style: TextStyle(
                      color: termsDocument == null
                          ? AppColors.mutedForeground
                          : AppColors.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text(
                  ' y confirmo que leí la ',
                  style: TextStyle(fontSize: 14, height: 1.45),
                ),
                GestureDetector(
                  onTap: privacyDocument == null
                      ? null
                      : () {
                          _showLegalDocument(privacyDocument);
                        },
                  child: Text(
                    'Política de Privacidad',
                    style: TextStyle(
                      color: privacyDocument == null
                          ? AppColors.mutedForeground
                          : AppColors.primaryBlue,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Text('.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _canSubmit;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Completa tu registro',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Necesitamos confirmar tu edad y aceptación legal antes de continuar.',
                            style: TextStyle(
                              color: AppColors.mutedForeground,
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          if (widget.authController.userEmail != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              widget.authController.userEmail!,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar sesión',
                      onPressed: _submitting ? null : _logout,
                      icon: const Icon(
                        Icons.logout,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecha de nacimiento',
                          style: TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _birthDateController,
                          readOnly: true,
                          onTap: _selectBirthDate,
                          validator: _validateBirthDate,
                          decoration: InputDecoration(
                            hintText: 'AAAA-MM-DD',
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            prefixIcon: const Icon(
                              Icons.calendar_month_outlined,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 18,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Solo las personas de 18 años o más pueden crear una cuenta.',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _documentsStatus(),
                        if (_loadingDocuments || _documentsError != null)
                          const SizedBox(height: 16),
                        _legalAgreement(),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: canSubmit ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.primaryBlue
                                  .withAlpha(120),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.white,
                                    ),
                                  )
                                : const Text(
                                    'Completar registro',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
