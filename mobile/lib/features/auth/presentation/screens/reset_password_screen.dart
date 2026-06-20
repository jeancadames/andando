import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../data/services/password_reset_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.token,
  });

  final String email;
  final String token;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final PasswordResetService _passwordResetService = PasswordResetService();

  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  bool _isSaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  bool get _hasValidLink =>
      widget.email.trim().isNotEmpty && widget.token.trim().isNotEmpty;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final message = await _passwordResetService.resetPassword(
        email: widget.email.trim(),
        token: widget.token.trim(),
        password: _passwordController.text.trim(),
        passwordConfirmation: _passwordConfirmationController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      context.goNamed(RouteNames.login);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });
    }
  }

  String? _validatePassword(String? value) {
    final password = value?.trim() ?? '';

    if (password.isEmpty) {
      return 'Ingresa tu nueva contraseña.';
    }

    if (password.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }

    return null;
  }

  String? _validateConfirmation(String? value) {
    final confirmation = value?.trim() ?? '';

    if (confirmation.isEmpty) {
      return 'Confirma tu nueva contraseña.';
    }

    if (confirmation != _passwordController.text.trim()) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidLink) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: const Text(
            'Enlace inválido',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.link_off_rounded,
                  color: Color(0xFFEF233C),
                  size: 42,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Este enlace de recuperación no es válido o está incompleto.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.goNamed(RouteNames.forgotPassword),
                  child: const Text('Solicitar nuevo enlace'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => context.goNamed(RouteNames.login),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),
        title: const Text(
          'Nueva contraseña',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFBFDBFE),
                ),
              ),
              child: Text(
                'Crea una nueva contraseña para ${widget.email}.',
                style: const TextStyle(
                  color: Color(0xFF003B73),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _PasswordField(
              controller: _passwordController,
              label: 'Nueva contraseña',
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: _validatePassword,
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _passwordConfirmationController,
              label: 'Confirmar nueva contraseña',
              obscureText: _obscureConfirmation,
              onToggleVisibility: () {
                setState(() {
                  _obscureConfirmation = !_obscureConfirmation;
                });
              },
              validator: _validateConfirmation,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B73),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Guardando...' : 'Actualizar contraseña',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
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

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final String? Function(String? value) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          onPressed: onToggleVisibility,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5E7EB),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFF003B73),
            width: 1.3,
          ),
        ),
      ),
    );
  }
}