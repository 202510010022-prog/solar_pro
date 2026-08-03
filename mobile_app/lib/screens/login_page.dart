import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'password_recovery_page.dart';
import '../services/solarpro_repository.dart';
import '../widgets/solar_login_background.dart';

const Color _solarYellow = Color(0xFFFDD22A);
const Color _solarNavy = Color(0xFF001F33);
const Color _solarPurple = Color(0xFF2300AE);
const Color _solarDeepNavy = Color(0xFF011530);
const Color _pageBackground = Color(0xFFF7F9FC);
const Color _surface = Color(0xFFFFFFFF);
const Color _lightPurple = Color(0xFFE9E4FF);
const Color _softPurple = Color(0xFFF4F1FF);
const Color _lightYellow = Color(0xFFFFF6CF);
const Color _borderColor = Color(0xFFDCE3EA);
const Color _secondaryText = Color(0xFF6C7786);

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.repository,
    required this.onLoggedIn,
  });

  final SolarProRepository repository;
  final VoidCallback onLoggedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();
  bool loading = false;
  bool obscurePassword = true;
  String error = '';
  String notice = '';

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    if (loading || formKey.currentState?.validate() == false) return;
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
      resizeToAvoidBottomInset: true,
      backgroundColor: _pageBackground,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SolarLoginBackground(
          child: SafeArea(
            child: LayoutBuilder(builder: _buildContent),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final width = MediaQuery.sizeOf(context).width;
    final height = constraints.maxHeight;
    final compact = height < 700 || width < 360;
    final horizontalPadding = width < 360 ? 20.0 : 28.0;
    final logoWidth = (width * 0.70).clamp(220.0, 290.0);
    final logoHeight = height < 700 ? 100.0 : 122.0;
    final titleSize = width < 360 ? 28.0 : 32.0;
    final inputHeight = height < 700 ? 54.0 : 58.0;
    final buttonHeight = height < 700 ? 54.0 : 58.0;

    return Center(
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          height < 700 ? 16 : 24,
          horizontalPadding,
          height < 700 ? 16 : 24,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LogoHeader(width: logoWidth, height: logoHeight),
                  SizedBox(height: compact ? 14 : 18),
                  Text(
                    'Bem-vindo!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _solarDeepNavy,
                      fontSize: titleSize,
                      height: 1.08,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Faça login para acessar sua conta',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: width < 360 ? 15 : 16,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: compact ? 24 : 30),
                  _LoginField(
                    label: 'E-mail',
                    controller: emailController,
                    focusNode: emailFocusNode,
                    hintText: 'seu@email.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    leadingIcon: Icons.mail_outline_rounded,
                    height: inputHeight,
                    compact: compact,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Informe seu e-mail.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
                  ),
                  SizedBox(height: compact ? 20 : 24),
                  _LoginField(
                    label: 'Senha',
                    controller: passwordController,
                    focusNode: passwordFocusNode,
                    hintText: '••••••••',
                    obscureText: obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    leadingIcon: Icons.lock_outline_rounded,
                    height: inputHeight,
                    compact: compact,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe sua senha.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => submit(),
                    trailing: Tooltip(
                      message:
                          obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                      child: Semantics(
                        button: true,
                        label:
                            obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                        child: IconButton(
                          onPressed: () => setState(
                            () => obscurePassword = !obscurePassword,
                          ),
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _MessageBox(
                      message: error,
                      color: const Color(0xFFE5484D),
                      backgroundColor: _surface,
                      icon: Icons.error_outline_rounded,
                    ),
                  ],
                  if (notice.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _MessageBox(
                      message: notice,
                      color: _solarPurple,
                      backgroundColor: _lightYellow,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: loading ? null : openPasswordRecovery,
                      style: TextButton.styleFrom(
                        foregroundColor: _solarPurple,
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        textStyle: TextStyle(
                          fontSize: width < 360 ? 14 : 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  SizedBox(height: compact ? 24 : 30),
                  _LoginButton(
                    loading: loading,
                    onPressed: loading ? null : submit,
                    height: buttonHeight,
                    compact: compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoHeader extends StatelessWidget {
  const _LogoHeader({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: height),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: _solarYellow.withValues(alpha: 0.12),
              blurRadius: 38,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Image.asset(
          'assets/branding/solar_pro_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'SOLAR PRO',
              style: TextStyle(
                color: _solarNavy,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.textInputAction,
    required this.autofillHints,
    required this.leadingIcon,
    required this.validator,
    required this.height,
    required this.compact,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final IconData leadingIcon;
  final String? Function(String?) validator;
  final double height;
  final bool compact;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final void Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            label,
            style: TextStyle(
              color: _solarDeepNavy,
              fontSize: compact ? 15 : 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
        SizedBox(height: compact ? 7 : 8),
        SizedBox(
          height: height,
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            validator: validator,
            onFieldSubmitted: onFieldSubmitted,
            style: const TextStyle(
              color: _solarDeepNavy,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
            cursorColor: _solarPurple,
            decoration: InputDecoration(
              hintText: hintText,
              errorMaxLines: 2,
              hintStyle: const TextStyle(
                color: Color(0xFF848A9A),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
              ),
              filled: true,
              fillColor: _softPurple.withValues(alpha: 0.58),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(leadingIcon, size: compact ? 21 : 23),
              ),
              prefixIconColor: const Color(0xFF74798B),
              suffixIcon: trailing,
              suffixIconColor: _solarPurple,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 0,
              ),
              border: _border(_borderColor),
              enabledBorder: _border(_solarPurple.withValues(alpha: 0.58)),
              focusedBorder: _border(_solarPurple, width: 1.6),
              errorBorder: _border(const Color(0xFFE5484D)),
              focusedErrorBorder: _border(const Color(0xFFE5484D), width: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.loading,
    required this.onPressed,
    required this.height,
    required this.compact,
  });

  final bool loading;
  final VoidCallback? onPressed;
  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF4013FF),
            Color(0xFF7A2DFF),
            _lightPurple,
            _solarPurple,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _solarPurple.withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onPressed,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'Entrar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _MessageBox extends StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.color,
    required this.icon,
    this.backgroundColor,
  });

  final String message;
  final Color color;
  final IconData icon;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: (backgroundColor ?? color).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _solarDeepNavy,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
