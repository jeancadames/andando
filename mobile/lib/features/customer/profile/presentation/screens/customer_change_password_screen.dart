import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/customer_password_service.dart';

class CustomerChangePasswordScreen extends StatefulWidget {
  const CustomerChangePasswordScreen({super.key});

  @override
  State<CustomerChangePasswordScreen> createState() =>
      _CustomerChangePasswordScreenState();
}

class _CustomerChangePasswordScreenState
    extends State<CustomerChangePasswordScreen> {
  final CustomerPasswordService _passwordService = CustomerPasswordService();

  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmationController = TextEditingController();

  bool _isSaving = false;
  bool _obscureCurrent = true;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
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
      await _passwordService.updatePassword(
        currentPassword: _currentPasswordController.text.trim(),
        password: _passwordController.text.trim(),
        passwordConfirmation: _passwordConfirmationController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente.'),
        ),
      );

      context.pop();
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

  String? _validateRequired(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }

    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu nueva contraseña.';
    }

    if (value.trim().length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }

    if (value.trim() == _currentPasswordController.text.trim()) {
      return 'La nueva contraseña debe ser diferente a la actual.';
    }

    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirma tu nueva contraseña.';
    }

    if (value.trim() != _passwordController.text.trim()) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
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
                'Cambiar contraseña',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Actualiza el acceso a tu cuenta',
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
              child: const Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: Color(0xFF003B73),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Usa una contraseña segura y diferente a la actual.',
                      style: TextStyle(
                        color: Color(0xFF003B73),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PasswordField(
              controller: _currentPasswordController,
              label: 'Contraseña actual',
              obscureText: _obscureCurrent,
              onToggleVisibility: () {
                setState(() {
                  _obscureCurrent = !_obscureCurrent;
                });
              },
              validator: (value) => _validateRequired(
                value,
                'Ingresa tu contraseña actual.',
              ),
            ),
            const SizedBox(height: 14),
            _PasswordField(
              controller: _passwordController,
              label: 'Nueva contraseña',
              obscureText: _obscurePassword,
              onToggleVisibility: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: _validateNewPassword,
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