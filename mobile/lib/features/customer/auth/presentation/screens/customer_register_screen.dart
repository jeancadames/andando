import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../data/datasources/customer_auth_api.dart';
import '../../data/models/legal_document.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = const CustomerAuthApi();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _birthDate = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  LegalDocument? _termsDocument;
  LegalDocument? _privacyDocument;

  bool _loading = false;
  bool _loadingLegalDocuments = true;
  bool _acceptTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _legalDocumentsError;

  @override
  void initState() {
    super.initState();
    _loadLegalDocuments();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _birthDate.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _loadLegalDocuments() async {
    setState(() {
      _loadingLegalDocuments = true;
      _legalDocumentsError = null;
      _acceptTerms = false;
    });

    try {
      final results = await Future.wait([
        _api.getLegalDocument(type: 'terms_user'),
        _api.getLegalDocument(type: 'privacy'),
      ]);

      if (!mounted) return;

      setState(() {
        _termsDocument = results[0];
        _privacyDocument = results[1];
        _loadingLegalDocuments = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _termsDocument = null;
        _privacyDocument = null;
        _loadingLegalDocuments = false;
        _legalDocumentsError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool get _legalDocumentsReady {
    return _termsDocument != null &&
        _privacyDocument != null &&
        !_loadingLegalDocuments;
  }

  bool _canSubmit() {
    return _name.text.trim().isNotEmpty &&
        _email.text.contains('@') &&
        _birthDate.text.trim().isNotEmpty &&
        _password.text.length >= 8 &&
        _password.text == _confirm.text &&
        _acceptTerms &&
        _legalDocumentsReady &&
        !_loading;
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

  void _goBackToLogin() {
    final redirect = _safeRedirectFromQuery();

    if (redirect == null) {
      context.goNamed(RouteNames.login);
      return;
    }

    context.goNamed(RouteNames.login, queryParameters: {'redirect': redirect});
  }

  DateTime _maximumBirthDate() {
    final now = DateTime.now();

    return DateTime(now.year - 18, now.month, now.day);
  }

  bool _isAdult(DateTime date) {
    final limit = _maximumBirthDate();

    final normalizedDate = DateTime(date.year, date.month, date.day);

    return !normalizedDate.isAfter(limit);
  }

  Future<void> _selectBirthDate() async {
    final maximumDate = _maximumBirthDate();
    final currentValue = _birthDate.text.trim();
    final currentDate = DateTime.tryParse(currentValue);

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

    _birthDate.text =
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
      return 'Selecciona una fecha de nacimiento válida.';
    }

    if (!_isAdult(parsedDate)) {
      return 'Debes tener al menos 18 años para crear una cuenta.';
    }

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final termsDocument = _termsDocument;
    final privacyDocument = _privacyDocument;

    if (!_acceptTerms) {
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
      _loading = true;
    });

    try {
      final response = await _api.register(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        birthDate: _birthDate.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirm.text,
        termsDocumentId: termsDocument.id,
        termsChecksum: termsDocument.checksum,
        acceptTerms: true,
        privacyDocumentId: privacyDocument.id,
        privacyChecksum: privacyDocument.checksum,
        privacyAcknowledged: true,
      );

      await widget.authController.saveSession(
        token: response.token,
        userType: response.userType,
        name: response.userName,
        email: response.userEmail,
      );

      if (!mounted) return;

      final redirect = _safeRedirectFromQuery();

      if (redirect != null) {
        context.go(redirect);
        return;
      }

      context.goNamed(RouteNames.clientExplore);
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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

  Future<void> _showLegalModal({required LegalDocument document}) async {
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

  Widget _input({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool toggle = false,
    bool readOnly = false,
    VoidCallback? onToggle,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: (_) {
            setState(() {});
          },
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF7F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: Icon(icon),
            ),
            suffixIcon: toggle
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: IconButton(
                      onPressed: onToggle,
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _legalDocumentsStatus() {
    if (_loadingLegalDocuments) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
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
                style: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final error = _legalDocumentsError;

    if (error != null) {
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
              onPressed: _loadLegalDocuments,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _legalAgreement() {
    final termsDocument = _termsDocument;
    final privacyDocument = _privacyDocument;
    final enabled = _legalDocumentsReady;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _acceptTerms,
          activeColor: AppColors.primaryBlue,
          onChanged: enabled
              ? (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
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
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                GestureDetector(
                  onTap: termsDocument == null
                      ? null
                      : () {
                          _showLegalModal(document: termsDocument);
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
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                GestureDetector(
                  onTap: privacyDocument == null
                      ? null
                      : () {
                          _showLegalModal(document: privacyDocument);
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
                const Text(
                  '.',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _canSubmit();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _goBackToLogin,
                    borderRadius: BorderRadius.circular(100),
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Crear cuenta',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Únete y explora experiencias turísticas',
                    style: TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 15,
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
                    children: [
                      _input(
                        controller: _name,
                        label: 'Nombre completo',
                        hint: 'Juan Pérez',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if ((value?.trim().length ?? 0) < 2) {
                            return 'Introduce tu nombre completo.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: _email,
                        label: 'Correo electrónico',
                        hint: 'tu@correo.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (!email.contains('@')) {
                            return 'Introduce un correo electrónico válido.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: _phone,
                        label: 'Teléfono',
                        hint: '+1 (809) 000-0000',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: _birthDate,
                        label: 'Fecha de nacimiento',
                        hint: 'AAAA-MM-DD',
                        icon: Icons.calendar_month_outlined,
                        readOnly: true,
                        onTap: _selectBirthDate,
                        validator: _validateBirthDate,
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Solo las personas de 18 años o más pueden crear una cuenta.',
                          style: TextStyle(
                            color: AppColors.mutedForeground,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: _password,
                        label: 'Contraseña',
                        hint: 'Mínimo 8 caracteres',
                        icon: Icons.lock_outline,
                        obscure: !_showPassword,
                        toggle: true,
                        validator: (value) {
                          if ((value?.length ?? 0) < 8) {
                            return 'La contraseña debe tener al menos 8 caracteres.';
                          }

                          return null;
                        },
                        onToggle: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: _confirm,
                        label: 'Confirmar contraseña',
                        hint: 'Confirma tu contraseña',
                        icon: Icons.lock_outline,
                        obscure: !_showConfirmPassword,
                        toggle: true,
                        validator: (value) {
                          if (value != _password.text) {
                            return 'Las contraseñas no coinciden.';
                          }

                          return null;
                        },
                        onToggle: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _legalDocumentsStatus(),
                      _legalAgreement(),
                      const SizedBox(height: 20),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: canSubmit
                              ? AppColors.primaryBlue
                              : AppColors.primaryBlue.withAlpha(120),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ElevatedButton(
                          onPressed: canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            elevation: 0,
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Crear cuenta'),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Ya tienes cuenta? '),
                          GestureDetector(
                            onTap: _goBackToLogin,
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
