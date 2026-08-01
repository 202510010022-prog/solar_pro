import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'password_recovery_page.dart';
import '../services/solarpro_repository.dart';
import '../theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage(
      {super.key, required this.repository, required this.onLoggedIn});

  final SolarProRepository repository;
  final VoidCallback onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String error = '';
  String notice = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = '';
      notice = '';
    });
    try {
      await widget.repository.signIn(
        emailController.text.trim(),
        passwordController.text,
      );
      widget.onLoggedIn();
    } on AuthException catch (exception) {
      setState(() => error = exception.message.contains('Invalid')
          ? 'Email ou senha incorretos.'
          : 'Não foi possível autenticar: ${exception.message}');
    } catch (_) {
      setState(() =>
          error = 'Falha de conexão. Verifique a internet e tente novamente.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openPasswordRecovery() async {
    final recovered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PasswordRecoveryPage(repository: widget.repository),
      ),
    );
    if (!mounted || recovered != true) return;
    setState(() {
      error = '';
      notice = 'Senha alterada com sucesso. Entre novamente.';
      passwordController.clear();
    });
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
                    const SizedBox(height: 28),
                    Container(
                      height: 190,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.08),
                            Colors.white.withValues(alpha: 0.02),
                          ],
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wb_sunny_rounded,
                              color: Color(0xFFFFC83D), size: 42),
                          SizedBox(height: 8),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                    text: 'solar',
                                    style: TextStyle(color: Colors.white)),
                                TextSpan(
                                    text: 'pro',
                                    style: TextStyle(color: AppTheme.green)),
                              ],
                            ),
                            style: TextStyle(
                                fontSize: 38, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Soluções inteligentes em energia solar',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Bem-vindo!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Faça login para acessar sua conta',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 28),
                    const Text('E-mail',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.text),
                      decoration: const InputDecoration(
                        hintText: 'seu@email.com',
                        labelText: null,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Senha',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: AppTheme.text),
                      decoration: const InputDecoration(
                        hintText: '••••••••',
                        suffixIcon: Icon(Icons.visibility_outlined),
                      ),
                      onSubmitted: (_) => submit(),
                    ),
                    if (error.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(error,
                          style: const TextStyle(color: Colors.redAccent)),
                    ],
                    if (notice.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(notice,
                          style: const TextStyle(color: AppTheme.green)),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: loading ? null : openPasswordRecovery,
                        child: const Text(
                          'Esqueci minha senha',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Versão 1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
