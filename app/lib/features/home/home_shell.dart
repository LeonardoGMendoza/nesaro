import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/nesaro_logo.dart';
import '../../widgets/responsive.dart';
import '../account/account_page.dart';
import '../automations/automations_page.dart';
import '../dashboard/dashboard_page.dart';

/// Navegação adaptável: barra inferior no celular, menu lateral no tablet e no computador.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.user});

  final User user;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _items = [
    (icon: Icons.insights_outlined, selected: Icons.insights, label: 'Painel'),
    (icon: Icons.bolt_outlined, selected: Icons.bolt, label: 'Automações'),
    (icon: Icons.person_outline, selected: Icons.person, label: 'Conta'),
  ];

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(user: widget.user, onNavigate: _go),
      AutomationsPage(uid: widget.user.uid),
      AccountPage(user: widget.user),
    ];

    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      child: KeyedSubtree(key: ValueKey(_index), child: pages[_index]),
    );

    if (Breakpoints.isPhone(context)) {
      return Scaffold(
        body: body,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _go,
          destinations: [
            for (final item in _items)
              NavigationDestination(icon: Icon(item.icon), selectedIcon: Icon(item.selected), label: item.label),
          ],
        ),
      );
    }

    final extended = Breakpoints.isDesktop(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 220,
            selectedIndex: _index,
            onDestinationSelected: _go,
            labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: extended
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NesaroLogo(size: 40, animated: true),
                        SizedBox(width: 8),
                        AliceFlowName(fontSize: 20),
                      ],
                    )
                  : const NesaroLogo(size: 40, animated: true),
            ),
            destinations: [
              for (final item in _items)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selected, color: NesaroColors.sakura),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, color: NesaroColors.line),
          Expanded(child: body),
        ],
      ),
    );
  }
}
