import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../account/account_page.dart';
import '../automations/automations_page.dart';
import '../dashboard/dashboard_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});

  final User user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final uid = widget.user.uid;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardPage(user: widget.user),
          AutomationsPage(uid: uid),
          AccountPage(user: widget.user),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Painel'),
          NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Automações'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Conta'),
        ],
      ),
    );
  }
}
