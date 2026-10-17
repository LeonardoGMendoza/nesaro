import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/repositories/auth_repository.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_shell.dart';
import 'widgets/nesaro_logo.dart';

class NesaroApp extends StatelessWidget {
  const NesaroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nesaro',
      debugShowCheckedModeBanner: false,
      theme: buildNesaroTheme(),
      home: const AuthGate(),
    );
  }
}

/// Mostra o login ou o app, conforme a sessão do Firebase.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: context.read<AuthRepository>().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: NesaroLogo(size: 96)));
        }
        final user = snapshot.data;
        return user == null ? const LoginPage() : HomeShell(user: user);
      },
    );
  }
}
