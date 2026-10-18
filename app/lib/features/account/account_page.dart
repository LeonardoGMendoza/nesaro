import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme.dart';
import '../../data/models/instagram_status.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../widgets/motion.dart';
import '../../widgets/responsive.dart';

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
    final initials = (user.displayName ?? user.email ?? '?').trim().split(' ').where((p) => p.isNotEmpty).take(2).map((p) => p[0].toUpperCase()).join();

    return Scaffold(
      appBar: AppBar(title: const Text('Conta')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        children: [
          ResponsiveCenter(
            maxWidth: 720,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideIn(
                  child: StreamBuilder<InstagramStatus>(
                    stream: account.watchInstagram(user.uid),
                    builder: (context, snapshot) => _InstagramCard(
                      status: snapshot.data ?? InstagramStatus.disconnected,
                      busy: _busy,
                      onConnect: _connect,
                      onDisconnect: _disconnect,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: Card(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: NesaroColors.ink,
                            child: Text(initials, style: const TextStyle(color: NesaroColors.paper, fontWeight: FontWeight.w700)),
                          ),
                          title: Text(user.displayName ?? 'Sem nome', style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(user.email ?? ''),
                        ),
                        const Divider(height: 1),
                        const ListTile(
                          leading: Icon(Icons.workspace_premium_outlined, color: NesaroColors.sakura),
                          title: Text('Plano'),
                          subtitle: Text('Teste grátis · planos e pagamento chegam em breve'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.support_agent_outlined),
                          title: const Text('Ajuda e suporte'),
                          subtitle: const Text('Fale com a gente pelo WhatsApp'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstagramCard extends StatelessWidget {
  const _InstagramCard({
    required this.status,
    required this.busy,
    required this.onConnect,
    required this.onDisconnect,
  });

  final InstagramStatus status;
  final bool busy;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(gradient: NesaroColors.instagramGradient),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: NesaroColors.instagramGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              status.connected ? '@${status.username ?? ''}' : 'Instagram não conectado',
                              key: ValueKey(status.connected),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.connected ? 'Conectado e respondendo comentários' : 'Conta Comercial ou Criador de conteúdo',
                            style: TextStyle(color: status.connected ? NesaroColors.success : NesaroColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'A autorização é feita na página oficial da Meta. A Nesaro nunca pede nem guarda sua senha.',
                  style: TextStyle(color: NesaroColors.muted, height: 1.35),
                ),
                const SizedBox(height: 16),
                if (status.connected)
                  OutlinedButton.icon(
                    onPressed: busy ? null : onDisconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text('Desconectar'),
                  )
                else
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: NesaroColors.instagramGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: FilledButton.icon(
                      onPressed: busy ? null : onConnect,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                      ),
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Icon(Icons.link),
                      label: Text(busy ? 'Abrindo...' : 'Conectar Instagram'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
