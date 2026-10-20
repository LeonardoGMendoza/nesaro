import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/alice_avatar.dart';
import '../../widgets/motion.dart';
import '../../widgets/nesaro_logo.dart';
import '../../widgets/responsive.dart';

/// No computador: duas colunas (marca à esquerda, formulário à direita).
/// No celular: logo animado em cima e formulário embaixo.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isDesktop(context)) {
      return const Scaffold(
        body: Row(
          children: [
            Expanded(child: _BrandPanel()),
            Expanded(child: Center(child: SingleChildScrollView(padding: EdgeInsets.all(32), child: _LoginForm()))),
          ],
        ),
      );
    }
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              children: [
                FadeSlideIn(child: AliceAvatar(size: 96)),
                SizedBox(height: 12),
                FadeSlideIn(child: NesaroWordmark(logoSize: 72)),
                SizedBox(height: 28),
                FadeSlideIn(delay: Duration(milliseconds: 200), child: _LoginForm()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.bolt, 'Responde comentários no Direct em segundos'),
      (Icons.schedule, 'Trabalha 24 horas, até enquanto você dorme'),
      (Icons.verified_user_outlined, 'API oficial da Meta: sem risco para sua conta'),
      (Icons.pix, 'Preço em real, pago por Pix'),
    ];

    return Container(
      decoration: const BoxDecoration(gradient: NesaroColors.heroGradient),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FadeSlideIn(
                  child: Row(
                    children: [
                      NesaroLogo(size: 48, animated: true),
                      SizedBox(width: 10),
                      AliceFlowName(fontSize: 26, light: true),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const AliceShowcase(),
                const SizedBox(height: 28),
                const FadeSlideIn(
                  delay: Duration(milliseconds: 300),
                  child: Text(
                    'Seu Instagram trabalhando por você!',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < benefits.length; i++)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 600 + i * 120),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(benefits[i].$1, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefits[i].$2,
                              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isRegister = false;
  bool _acceptedTerms = false;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegister && !_acceptedTerms) {
      setState(() => _error = 'Aceite os termos de uso para criar a conta.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = context.read<AuthRepository>();
    try {
      if (_isRegister) {
        await auth.register(name: _name.text, email: _email.text, password: _password.text);
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => _error = _messageFor(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _google() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthRepository>().signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      // Fechar o pop-up não é erro: só volta para a tela.
      const cancelled = {'popup-closed-by-user', 'cancelled-popup-request', 'web-context-canceled', 'canceled'};
      if (mounted && !cancelled.contains(e.code)) setState(() => _error = _messageFor(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_email.text.trim().isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Digite seu e-mail primeiro.')));
      return;
    }
    try {
      await context.read<AuthRepository>().sendPasswordReset(_email.text);
      messenger.showSnackBar(const SnackBar(content: Text('Enviamos um link para redefinir a senha.')));
    } on FirebaseAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(_messageFor(e.code))));
    }
  }

  String _messageFor(String code) => switch (code) {
        'invalid-credential' || 'wrong-password' || 'user-not-found' => 'E-mail ou senha incorretos.',
        'email-already-in-use' => 'Este e-mail já tem cadastro. Tente entrar.',
        'weak-password' => 'Use uma senha com pelo menos 6 caracteres.',
        'invalid-email' => 'E-mail inválido.',
        'too-many-requests' => 'Muitas tentativas. Aguarde um pouco.',
        'network-request-failed' => 'Sem internet. Verifique a conexão.',
        'popup-blocked' => 'O navegador bloqueou a janela do Google. Libere pop-ups e tente de novo.',
        'account-exists-with-different-credential' =>
          'Este e-mail já entra com senha. Use e-mail e senha.',
        'operation-not-allowed' => 'Login com Google ainda não está ativado no Firebase.',
        'unauthorized-domain' => 'Este endereço não está autorizado no Firebase (Authentication → Configurações → Domínios).',
        _ => 'Não foi possível continuar ($code).',
      };

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _isRegister ? 'Crie sua conta grátis' : 'Bem-vindo de volta',
                      key: ValueKey(_isRegister),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isRegister ? '7 dias para testar, sem cartão.' : 'Entre para ver suas automações.',
                    style: const TextStyle(color: NesaroColors.muted),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: _loading ? null : _google,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: NesaroColors.ink,
                      side: const BorderSide(color: Color(0x3314123A)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleMark(),
                        SizedBox(width: 12),
                        Text('Continuar com Google', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('ou com e-mail', style: TextStyle(color: NesaroColors.muted)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                  ),
                  if (_isRegister) ...[
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Mostrar senha' : 'Esconder senha',
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
                  ),
                  if (_isRegister)
                    CheckboxListTile(
                      value: _acceptedTerms,
                      onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: NesaroColors.sakura,
                      title: const Text('Li e aceito os termos de uso e a política de privacidade.'),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE8E4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_error!, style: const TextStyle(color: NesaroColors.seal)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: NesaroColors.paper),
                          )
                        : Text(_isRegister ? 'Criar conta' : 'Entrar'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () => setState(() {
                              _isRegister = !_isRegister;
                              _error = null;
                            }),
                    child: Text(_isRegister ? 'Já tenho conta' : 'Não tem conta? Criar grátis'),
                  ),
                  if (!_isRegister)
                    TextButton(
                      onPressed: _loading ? null : _forgotPassword,
                      child: const Text('Esqueci minha senha'),
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

/// "G" colorido do Google, desenhado em código.
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GooglePainter()));
  }
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    const deg = 3.1415926535 / 180;
    canvas.drawArc(rect, -40 * deg, -100 * deg, false, arc(const Color(0xFFEA4335))); // vermelho (topo)
    canvas.drawArc(rect, -140 * deg, -90 * deg, false, arc(const Color(0xFFFBBC05))); // amarelo (esquerda)
    canvas.drawArc(rect, -230 * deg, -85 * deg, false, arc(const Color(0xFF34A853))); // verde (baixo)
    canvas.drawArc(rect, -315 * deg, -45 * deg, false, arc(const Color(0xFF4285F4))); // azul (direita)

    // Barra horizontal do "G"
    final bar = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2, size.height / 2 - stroke / 2, size.width / 2, stroke),
      bar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
