import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';
import '../utils/friendly_error.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key, required this.repository});

  final SolarProRepository repository;

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool loading = false;
  bool codeSent = false;
  String error = '';
  String notice = '';

  @override
  void dispose() {
    emailController.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  String get _email => emailController.text.trim();

  Future<void> sendCode() async {
    if (_email.isEmpty || !_email.contains('@')) {
      setState(() => error = 'Informe um email válido.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
      notice = '';
    });

    try {
      await widget.repository.sendPasswordRecoveryCode(_email);
      if (!mounted) return;
      setState(() {
        codeSent = true;
        notice =
            'Se este email estiver cadastrado, enviaremos um código de recuperação.';
      });
    } on AuthException catch (exception) {
      if (!mounted) return;
      if (_isRateLimitError(exception)) {
        setState(() => error =
            'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.');
      } else {
        setState(() {
          codeSent = true;
          notice =
              'Se este email estiver cadastrado, enviaremos um código de recuperação.';
        });
      }
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = friendlyNetworkError(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> resetPassword() async {
    final code = codeController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (code.length != 6 || int.tryParse(code) == null) {
      setState(() => error = 'Informe o código de 6 dígitos.');
      return;
    }
    if (password.length < 6) {
      setState(() => error = 'Use uma senha com pelo menos 6 caracteres.');
      return;
    }
    if (password != confirmPassword) {
      setState(() => error = 'As senhas informadas não conferem.');
      return;
    }

    setState(() {
      loading = true;
      error = '';
      notice = '';
    });

    try {
      await widget.repository.resetPasswordWithRecoveryCode(
        email: _email,
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthException catch (exception) {
      if (!mounted) return;
      setState(() => error = _friendlyRecoveryError(exception));
    } catch (exception) {
      if (!mounted) return;
      setState(() => error = friendlyNetworkError(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  bool _isRateLimitError(AuthException exception) {
    final text = '${exception.message} ${exception.statusCode}'.toLowerCase();
    return text.contains('rate') ||
        text.contains('too many') ||
        text.contains('429') ||
        text.contains('over_email_send_rate_limit');
  }

  String _friendlyRecoveryError(AuthException exception) {
    final text = '${exception.message} ${exception.statusCode}'.toLowerCase();
    if (_isRateLimitError(exception)) {
      return 'Muitas tentativas. Aguarde alguns minutos antes de tentar novamente.';
    }
    if (text.contains('expired')) {
      return 'Código expirado. Solicite um novo código.';
    }
    if (text.contains('invalid') ||
        text.contains('otp') ||
        text.contains('token')) {
      return 'Código inválido. Confira e tente novamente.';
    }
    if (text.contains('password')) {
      return 'Use uma senha mais forte.';
    }
    return 'Não foi possível redefinir a senha. Confira os dados e tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF06343B), Color(0xFF061C28)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: loading
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: Colors.white,
                        tooltip: 'Voltar',
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Icon(Icons.lock_reset_rounded,
                        color: AppTheme.green, size: 52),
                    const SizedBox(height: 18),
                    const Text(
                      'Recuperar senha',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      codeSent
                          ? 'Digite o código enviado por email e defina sua nova senha.'
                          : 'Informe seu email para receber um código de recuperação.',
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white70, height: 1.4),
                    ),
                    const SizedBox(height: 28),
                    _label('E-mail'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      enabled: !codeSent && !loading,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.text),
                      decoration:
                          const InputDecoration(hintText: 'seu@email.com'),
                    ),
                    if (codeSent) ...[
                      const SizedBox(height: 18),
                      _label('Código de recuperação'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(color: AppTheme.text),
                        decoration: const InputDecoration(
                          hintText: '000000',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 18),
                      _label('Nova senha'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.text),
                        decoration: const InputDecoration(hintText: '••••••••'),
                      ),
                      const SizedBox(height: 18),
                      _label('Confirmar senha'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.text),
                        decoration: const InputDecoration(hintText: '••••••••'),
                        onSubmitted: (_) => loading ? null : resetPassword(),
                      ),
                    ],
                    if (notice.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(notice,
                          style: const TextStyle(
                              color: AppTheme.green, height: 1.35)),
                    ],
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(error,
                          style: const TextStyle(
                              color: Colors.redAccent, height: 1.35)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loading
                          ? null
                          : (codeSent ? resetPassword : sendCode),
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(codeSent ? 'Alterar senha' : 'Enviar código'),
                    ),
                    if (codeSent) ...[
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: loading
                            ? null
                            : () {
                                setState(() {
                                  codeSent = false;
                                  error = '';
                                  notice = '';
                                  codeController.clear();
                                  passwordController.clear();
                                  confirmPasswordController.clear();
                                });
                              },
                        child: const Text(
                          'Usar outro email',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
    );
  }
}
