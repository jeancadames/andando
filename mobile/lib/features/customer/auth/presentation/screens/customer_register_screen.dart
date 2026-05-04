import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/route_names.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/application/auth_controller.dart';
import '../../data/datasources/customer_auth_api.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({
    super.key,
    required this.authController,
  });

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
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  bool _acceptTerms = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool _canSubmit() {
    return _name.text.trim().isNotEmpty &&
        _email.text.contains('@') &&
        _password.text.length >= 8 &&
        _password.text == _confirm.text &&
        _acceptTerms &&
        !_loading;
  }

  void _goBackToLogin() {
    context.goNamed(RouteNames.login);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final res = await _api.register(
        fullName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirm.text,
      );

      await widget.authController.saveSession(
        token: res.token,
        userType: res.userType,
        name: res.userName,
        email: res.userEmail,
      );

      if (!mounted) return;
      context.goNamed(RouteNames.clientExplore);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Muestra un modal inferior para revisar documentos legales.
  ///
  /// Se usa para:
  /// - Términos y Condiciones.
  /// - Política de Privacidad.
  void _showLegalModal({
    required String title,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 22),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.mutedForeground,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
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
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          onChanged: (_) => setState(() {}),
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

  @override
  Widget build(BuildContext context) {
    final canSubmit = _canSubmit();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            /// Header alineado a la izquierda.
            Container(
              width: double.infinity,
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
                    'Crear Cuenta',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Únete y explora experiencias turísticas',
                    textAlign: TextAlign.left,
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
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: _email,
                        label: 'Correo electrónico',
                        hint: 'tu@correo.com',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: _phone,
                        label: 'Teléfono',
                        hint: '+1 (809) 000-0000',
                        icon: Icons.phone_outlined,
                      ),
                      const SizedBox(height: 20),
                      _input(
                        controller: _password,
                        label: 'Contraseña',
                        hint: 'Mínimo 8 caracteres',
                        icon: Icons.lock_outline,
                        obscure: !_showPassword,
                        toggle: true,
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
                        onToggle: () {
                          setState(() {
                            _showConfirmPassword = !_showConfirmPassword;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      /// Checkbox con enlaces que abren modales.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _acceptTerms,
                            activeColor: AppColors.primaryBlue,
                            onChanged: (value) {
                              setState(() {
                                _acceptTerms = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Acepto los '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: GestureDetector(
                                        onTap: () {
                                          _showLegalModal(
                                            title: 'Términos y Condiciones',
                                            content:
                                                'Aquí se mostrarán los términos y condiciones de AndanDO. Este contenido debe ser reemplazado por el documento legal final del proyecto.',
                                          );
                                        },
                                        child: const Text(
                                          'Términos y Condiciones',
                                          style: TextStyle(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w800,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const TextSpan(text: ' y la '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: GestureDetector(
                                        onTap: () {
                                          _showLegalModal(
                                            title: 'Política de Privacidad',
                                            content:
                                                'Aquí se mostrará la política de privacidad de AndanDO. Este contenido debe ser reemplazado por el documento legal final del proyecto.',
                                          );
                                        },
                                        child: const Text(
                                          'Política de Privacidad',
                                          style: TextStyle(
                                            color: AppColors.primaryBlue,
                                            fontWeight: FontWeight.w800,
                                            decoration:
                                                TextDecoration.underline,
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
                              : const Text('Crear Cuenta'),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('¿Ya tienes cuenta? '),
                          GestureDetector(
                            onTap: () => context.goNamed(RouteNames.login),
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