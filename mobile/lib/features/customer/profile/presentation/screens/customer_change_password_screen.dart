import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/application/auth_controller.dart';
import '../../../../auth/data/services/password_reset_service.dart';

class CustomerChangePasswordScreen extends StatefulWidget {
  const CustomerChangePasswordScreen({
    super.key,
    required this.authController,
  });

  final AuthController authController;

  @override
  State<CustomerChangePasswordScreen> createState() =>
      _CustomerChangePasswordScreenState();
}

class _CustomerChangePasswordScreenState
    extends State<CustomerChangePasswordScreen> {
  final PasswordResetService _passwordResetService = PasswordResetService();

  bool _isSending = false;

  Future<void> _sendResetLink() async {
    final email = widget.authController.userEmail?.trim() ?? '';

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pudimos identificar el correo de tu cuenta.'),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      final message = await _passwordResetService.sendResetLink(
        email: email,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.authController.userEmail ?? 'tu correo registrado';

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
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFF003B73),
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Te enviaremos un enlace seguro',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Por seguridad, no cambiaremos tu contraseña dentro de la app. Te enviaremos un enlace a:',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF003B73),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendResetLink,
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
        ],
      ),
    );
  }
}