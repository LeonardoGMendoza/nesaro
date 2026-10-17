import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../data/models/instagram_status.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/auth_repository.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key, required this.user});

  final User user;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool _busy = false;

  Future<void> _connect() async {
    final account = context.read<AccountRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final url = await account.startInstagramConnection();
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened) {
        messenger.showSnackBar(const SnackBar(content: Text('Não foi possível abrir o navegador.')));
      }
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final account = context.read<AccountRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desconectar Instagram?'),
        content: const Text('As automações param de funcionar até você conectar de novo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Desconectar')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await account.disconnectInstagram();
    } on Exception catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<AccountRepository>();
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<InstagramStatus>(
            stream: account.watchInstagram(user.uid),
            builder: (context, snapshot) {
              final status = snapshot.data ?? InstagramStatus.disconnected;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            status.connected ? Icons.check_circle : Icons.link_off,
                            color: status.connected ? NesaroColors.success : NesaroColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              status.connected ? 'Instagram @${status.username ?? ''}' : 'Instagram não conectado',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        status.connected
                            ? 'Suas automações estão ouvindo os comentários desta conta.'
                            : 'Conecte uma conta profissional (Comercial ou Criador de conteúdo). '
                                'A autorização é feita na página oficial da Meta: a Nesaro nunca pede sua senha.',
                        style: const TextStyle(color: NesaroColors.muted),
                      ),
                      const SizedBox(height: 16),
                      if (status.connected)
                        OutlinedButton(
                          onPressed: _busy ? null : _disconnect,
                          child: const Text('Desconectar'),
                        )
                      else
                        FilledButton(
                          onPressed: _busy ? null : _connect,
                          child: Text(_busy ? 'Abrindo...' : 'Conectar Instagram'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(user.displayName ?? 'Sem nome'),
                  subtitle: Text(user.email ?? ''),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: NesaroColors.seal),
                  title: const Text('Sair', style: TextStyle(color: NesaroColors.seal)),
                  onTap: () => context.read<AuthRepository>().signOut(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
