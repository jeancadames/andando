import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../data/services/password_reset_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final PasswordResetService _passwordResetService = PasswordResetService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    try {
      final message = await _passwordResetService.sendResetLink(
        email: _emailController.text.trim(),
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
        _isSending = false;
      });
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }

    if (!email.contains('@')) {
      return 'Ingresa un correo válido.';
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
          onPressed: () => context.goNamed(RouteNames.login),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF111827),
          ),
        ),
        title: const Text(
          'Recuperar contraseña',
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
              child: const Row(
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: Color(0xFF003B73),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Te enviaremos un enlace para crear una nueva contraseña.',
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
            TextFormField(
              controller: _emailController,
              validator: _validateEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Correo electrónico',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.email_outlined),
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
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003B73),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  _isSending ? 'Enviando...' : 'Enviar enlace',
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