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
        final Widget child;
        if (snapshot.connectionState == ConnectionState.waiting) {
          child = const Scaffold(
            key: ValueKey('splash'),
            body: Center(child: NesaroWordmark(logoSize: 140)),
          );
        } else if (snapshot.data == null) {
          child = const LoginPage(key: ValueKey('login'));
        } else {
          child = HomeShell(key: ValueKey(snapshot.data!.uid), user: snapshot.data!);
        }
        return AnimatedSwitcher(duration: const Duration(milliseconds: 400), child: child);
      },
    );
  }
}
