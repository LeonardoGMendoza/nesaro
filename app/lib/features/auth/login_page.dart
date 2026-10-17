import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/nesaro_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isRegister = false;
  bool _acceptedTerms = false;
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
      setState(() => _error = _messageFor(e.code));
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
      messenger.showSnackBar(
        const SnackBar(content: Text('Enviamos um link para redefinir a senha.')),
      );
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
        _ => 'Não foi possível continuar ($code).',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NesaroWordmark(),
                    const SizedBox(height: 32),
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nome'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Informe um e-mail válido' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Senha'),
                      validator: (v) => (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
                    ),
                    if (_isRegister)
                      CheckboxListTile(
                        value: _acceptedTerms,
                        onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Li e aceito os termos de uso e a política de privacidade.'),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: NesaroColors.seal)),
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
                      child: Text(_isRegister ? 'Já tenho conta' : 'Criar uma conta grátis'),
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
      ),
    );
  }
}
