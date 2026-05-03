import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../data/datasources/provider_auth_api.dart';
import '../../data/models/provider_register_form_data.dart';

import '../widgets/step_personal_info.dart';
import '../widgets/step_business_info.dart';
import '../widgets/step_documents.dart';
import '../widgets/step_terms.dart';

/// Pantalla de registro de proveedor.
///
/// Esta pantalla maneja 4 pasos:
/// 1. Información personal
/// 2. Información del negocio
/// 3. Documentación
/// 4. Términos y condiciones
class ProviderRegisterScreen extends StatefulWidget {
  const ProviderRegisterScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<ProviderRegisterScreen> createState() => _ProviderRegisterScreenState();
}

class _ProviderRegisterScreenState extends State<ProviderRegisterScreen> {
  final _api = const ProviderAuthApi();

  final _formData = ProviderRegisterFormData();

  int _currentStep = 1;
  bool _isSubmitting = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

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

  void _syncControllersToFormData() {
    _formData.fullName = _fullNameController.text.trim();
    _formData.email = _emailController.text.trim();
    _formData.phone = _phoneController.text.trim();
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
            _formData.email.contains('@') &&
            _formData.phone.isNotEmpty &&
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
        return _formData.acceptTerms && _formData.acceptPrivacy;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa los campos requeridos para continuar.'),
        ),
      );
      return;
    }

    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (!_canProceed()) return;

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
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickFile({
    required void Function(PlatformFile file) onSelected,
  }) async {
    final result = await FilePicker.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.size > 5 * 1024 * 1024) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El archivo no puede superar los 5MB.'),
        ),
      );
      return;
    }

    setState(() {
      onSelected(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    final canProceed = _canProceed();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            _RegisterHeader(
              currentStep: _currentStep,
              onBack: _goBack,
            ),

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
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      canProceed && !_isSubmitting ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor:
                        AppColors.primaryBlue.withAlpha(120),
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
                          _currentStep == 4 ? 'Enviar Solicitud' : 'Continuar',
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
          acceptTerms: _formData.acceptTerms,
          acceptPrivacy: _formData.acceptPrivacy,
          onTermsChanged: (value) {
            setState(() {
              _formData.acceptTerms = value ?? false;
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

class _OptionItem {
  const _OptionItem(this.value, this.label);

  final String value;
  final String label;
}

/// Header del registro con progreso.
class _RegisterHeader extends StatelessWidget {
  const _RegisterHeader({
    required this.currentStep,
    required this.onBack,
  });

  final int currentStep;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB)),
        ),
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
            style: const TextStyle(
              color: AppColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(4, (index) {
              final step = index + 1;
              final isActive = step <= currentStep;

              return Expanded(
                child: Container(
                  height: 5,
                  margin: EdgeInsets.only(
                    right: index == 3 ? 0 : 8,
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

class _BackButtonCircle extends StatelessWidget {
  const _BackButtonCircle({
    required this.onPressed,
  });

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
        ),
      ),
    );
  }
}