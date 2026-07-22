import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../../../customer/auth/data/models/legal_document.dart';
import '../../data/datasources/provider_auth_api.dart';
import '../../data/models/provider_register_form_data.dart';
import '../widgets/step_business_info.dart';
import '../widgets/step_documents.dart';
import '../widgets/step_personal_info.dart';
import '../widgets/step_terms.dart';

class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _api = const ProviderAuthApi();
  final _formData = ProviderRegisterFormData();

  int _currentStep = 1;

  bool _isSubmitting = false;
  bool _loadingLegalDocuments = true;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  String? _legalDocumentsError;

  LegalDocument? _termsDocument;
  LegalDocument? _standardsDocument;
  LegalDocument? _privacyDocument;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _businessNameController = TextEditingController();
  final _rncController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLegalDocuments();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _businessNameController.dispose();
    _rncController.dispose();
    _addressController.dispose();
    _cityController.dispose();

    super.dispose();
  }

  Future<void> _loadLegalDocuments() async {
    setState(() {
      _loadingLegalDocuments = true;
      _legalDocumentsError = null;

      _formData.acceptTerms = false;
      _formData.acceptStandards = false;
      _formData.acceptPrivacy = false;
    });

    try {
      final results = await Future.wait([
        _api.getLegalDocument(type: 'terms_provider'),
        _api.getLegalDocument(type: 'provider_standards'),
        _api.getLegalDocument(type: 'privacy'),
      ]);

      if (!mounted) return;

      final termsDocument = results[0];
      final standardsDocument = results[1];
      final privacyDocument = results[2];

      setState(() {
        _termsDocument = termsDocument;
        _standardsDocument = standardsDocument;
        _privacyDocument = privacyDocument;

        _formData.termsDocumentId = termsDocument.id;
        _formData.termsDocumentChecksum = termsDocument.checksum;

        _formData.standardsDocumentId = standardsDocument.id;
        _formData.standardsDocumentChecksum = standardsDocument.checksum;

        _formData.privacyDocumentId = privacyDocument.id;
        _formData.privacyDocumentChecksum = privacyDocument.checksum;

        _loadingLegalDocuments = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _termsDocument = null;
        _standardsDocument = null;
        _privacyDocument = null;

        _formData.termsDocumentId = null;
        _formData.termsDocumentChecksum = null;

        _formData.standardsDocumentId = null;
        _formData.standardsDocumentChecksum = null;

        _formData.privacyDocumentId = null;
        _formData.privacyDocumentChecksum = null;

        _loadingLegalDocuments = false;

        _legalDocumentsError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  bool get _legalDocumentsReady {
    return !_loadingLegalDocuments &&
        _termsDocument != null &&
        _standardsDocument != null &&
        _privacyDocument != null &&
        _formData.hasLegalDocuments;
  }

  String _normalizeDominicanPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length == 11 && digits.startsWith('1')) {
      return digits.substring(1);
    }

    return digits;
  }

  bool _isValidEmail(String value) {
    final email = value.trim();

    final emailRegex = RegExp(
      r'^[A-Za-z0-9._%+-]+@(?:[A-Za-z0-9-]+\.)+[A-Za-z]{2,}$',
    );

    return emailRegex.hasMatch(email);
  }

  bool _isValidDominicanPhone(String value) {
    final phone = _normalizeDominicanPhone(value);

    return RegExp(r'^(809|829|849)[2-9]\d{6}$').hasMatch(phone);
  }

  String _dominicanPhoneForApi(String value) {
    final phone = _normalizeDominicanPhone(value);

    return '+1$phone';
  }

  void _syncControllersToFormData() {
    _formData.fullName = _fullNameController.text.trim();

    _formData.email = _emailController.text.trim();

    final rawPhone = _phoneController.text.trim();

    _formData.phone = _isValidDominicanPhone(rawPhone)
        ? _dominicanPhoneForApi(rawPhone)
        : rawPhone;

    _formData.password = _passwordController.text;

    _formData.confirmPassword = _confirmPasswordController.text;

    _formData.businessName = _businessNameController.text.trim();

    _formData.rnc = _rncController.text.trim();

    _formData.address = _addressController.text.trim();

    _formData.city = _cityController.text.trim();
  }

  bool _canProceed() {
    _syncControllersToFormData();

    switch (_currentStep) {
      case 1:
        return _formData.fullName.isNotEmpty &&
            _isValidEmail(_emailController.text) &&
            _isValidDominicanPhone(_phoneController.text) &&
            _formData.password.length >= 8 &&
            _formData.password == _formData.confirmPassword;

      case 2:
        return _formData.businessName.isNotEmpty &&
            _formData.businessTypeSlug.isNotEmpty &&
            _formData.rnc.isNotEmpty &&
            _formData.address.isNotEmpty &&
            _formData.city.isNotEmpty &&
            _formData.province.isNotEmpty;

      case 3:
        return _formData.identityCard != null &&
            _formData.rncCertificate != null;

      case 4:
        return _legalDocumentsReady && _formData.hasAcceptedLegalDocuments;

      default:
        return false;
    }
  }

  void _goBack() {
    if (_currentStep == 1) {
      context.goNamed(RouteNames.login);

      return;
    }

    setState(() {
      _currentStep--;
    });
  }

  void _handleContinue() {
    if (!_canProceed()) {
      var message = 'Completa los campos requeridos para continuar.';

      if (_currentStep == 1 &&
          _phoneController.text.trim().isNotEmpty &&
          !_isValidDominicanPhone(_phoneController.text)) {
        message =
            'Ingresa un teléfono dominicano válido. '
            'Ej: 809-123-4567, 829-123-4567 '
            'o +1 849-123-4567.';
      }

      if (_currentStep == 4 && !_legalDocumentsReady) {
        message = 'Los documentos legales todavía no están disponibles.';
      } else if (_currentStep == 4 && !_formData.hasAcceptedLegalDocuments) {
        message = 'Debes completar las tres confirmaciones legales.';
      }

      _showMessage(message);
      return;
    }

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });

      return;
    }

    _submit();
  }

  Future<void> _submit() async {
    if (!_canProceed()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await _api.register(data: _formData);

      await widget.authController.saveSession(
        token: response.token,
        userType: 'provider',
        name: response.userName,
        email: response.userEmail,
        providerStatus: response.providerStatus,
      );

      if (!mounted) return;

      context.goNamed(RouteNames.providerVerificationPending);
    } catch (error) {
      if (!mounted) return;

      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickFile({
    required void Function(PlatformFile file) onSelected,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;

    if (file.size > 5 * 1024 * 1024) {
      if (!mounted) return;

      _showMessage('El archivo no puede superar los 5MB.');

      return;
    }

    setState(() {
      onSelected(file);
    });
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
                  'Versión ${document.version} · '
                  'Vigente desde ${document.effectiveDateLabel}',
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

  @override
  Widget build(BuildContext context) {
    final canProceed = _canProceed();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _RegisterHeader(currentStep: _currentStep, onBack: _goBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: _buildCurrentStep(),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: canProceed && !_isSubmitting
                      ? _handleContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor: AppColors.primaryBlue.withAlpha(
                      120,
                    ),
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _currentStep == 4 ? 'Enviar solicitud' : 'Continuar',
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return StepPersonalInfo(
          fullNameController: _fullNameController,
          emailController: _emailController,
          phoneController: _phoneController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          showPassword: _showPassword,
          showConfirmPassword: _showConfirmPassword,
          emailErrorText:
              _emailController.text.trim().isNotEmpty &&
                  !_isValidEmail(_emailController.text)
              ? 'Ingresa un correo válido. '
                    'Ej: nombre@dominio.com.'
              : null,
          onTogglePassword: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
          onToggleConfirmPassword: () {
            setState(() {
              _showConfirmPassword = !_showConfirmPassword;
            });
          },
          onChanged: () {
            setState(() {});
          },
        );

      case 2:
        return StepBusinessInfo(
          businessNameController: _businessNameController,
          rncController: _rncController,
          addressController: _addressController,
          cityController: _cityController,
          selectedBusinessTypeSlug: _formData.businessTypeSlug,
          selectedProvince: _formData.province,
          onBusinessTypeChanged: (value) {
            setState(() {
              _formData.businessTypeSlug = value ?? '';
            });
          },
          onProvinceChanged: (value) {
            setState(() {
              _formData.province = value ?? '';
            });
          },
          onChanged: () {
            setState(() {});
          },
        );

      case 3:
        return StepDocuments(
          identityCard: _formData.identityCard,
          rncCertificate: _formData.rncCertificate,
          businessLicense: _formData.businessLicense,
          onPickIdentityCard: () {
            _pickFile(
              onSelected: (file) {
                _formData.identityCard = file;
              },
            );
          },
          onPickRncCertificate: () {
            _pickFile(
              onSelected: (file) {
                _formData.rncCertificate = file;
              },
            );
          },
          onPickBusinessLicense: () {
            _pickFile(
              onSelected: (file) {
                _formData.businessLicense = file;
              },
            );
          },
        );

      case 4:
        return StepTerms(
          termsDocument: _termsDocument,
          standardsDocument: _standardsDocument,
          privacyDocument: _privacyDocument,
          isLoading: _loadingLegalDocuments,
          errorMessage: _legalDocumentsError,
          acceptTerms: _formData.acceptTerms,
          acceptStandards: _formData.acceptStandards,
          acceptPrivacy: _formData.acceptPrivacy,
          onRetry: _loadLegalDocuments,
          onOpenDocument: _showLegalDocument,
          onTermsChanged: (value) {
            setState(() {
              _formData.acceptTerms = value ?? false;
            });
          },
          onStandardsChanged: (value) {
            setState(() {
              _formData.acceptStandards = value ?? false;
            });
          },
          onPrivacyChanged: (value) {
            setState(() {
              _formData.acceptPrivacy = value ?? false;
            });
          },
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({required this.currentStep, required this.onBack});

  final int currentStep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButtonCircle(onPressed: onBack),
          const SizedBox(height: 24),
          const Text(
            'Conviértete en Afiliado',
            style: TextStyle(
              color: AppColors.primaryBlue,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paso $currentStep de 4',
            style: const TextStyle(color: AppColors.mutedForeground),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(4, (index) {
              final step = index + 1;
              final isActive = step <= currentStep;

              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
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

class _BackButtonCircle extends StatelessWidget {
  const _BackButtonCircle({required this.onPressed});

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
        child: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
      ),
    );
  }
}
