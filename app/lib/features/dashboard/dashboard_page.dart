import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/automation.dart';
import '../../data/models/execution.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/automation_repository.dart';
import '../../data/repositories/execution_repository.dart';
import '../../widgets/nesaro_logo.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final automations = context.read<AutomationRepository>();
    final executions = context.read<ExecutionRepository>();
    final firstName = (user.displayName ?? '').split(' ').first;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            NesaroLogo(size: 32),
            SizedBox(width: 8),
            Text('Nesaro', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            firstName.isEmpty ? 'Olá!' : 'Olá, $firstName!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text('Veja como suas automações estão indo.', style: TextStyle(color: NesaroColors.muted)),
          if (!user.emailVerified) ...[
            const SizedBox(height: 16),
            const _VerifyEmailCard(),
          ],
          const SizedBox(height: 16),
          StreamBuilder<List<Automation>>(
            stream: automations.watchAll(user.uid),
            builder: (context, snapshot) {
              final list = snapshot.data ?? const <Automation>[];
              final totals = list.fold(AutomationStats.zero, (sum, a) => sum + a.stats);
              final active = list.where((a) => a.active).length;

              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(label: 'Automações', value: list.length, icon: Icons.bolt),
                  _StatCard(label: 'Ativas / pausadas', text: '$active / ${list.length - active}', icon: Icons.toggle_on_outlined),
                  _StatCard(label: 'Comentários identificados', value: totals.matched, icon: Icons.chat_bubble_outline),
                  _StatCard(label: 'Tentativas de envio', value: totals.attempts, icon: Icons.send_outlined),
                  _StatCard(label: 'Mensagens enviadas', value: totals.sent, icon: Icons.check_circle_outline, color: NesaroColors.success),
                  _StatCard(label: 'Falhas de envio', value: totals.failed, icon: Icons.error_outline, color: NesaroColors.seal),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Text('Atividade recente', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          StreamBuilder<List<Execution>>(
            stream: executions.watchRecent(user.uid),
            builder: (context, snapshot) {
              final list = snapshot.data ?? const <Execution>[];
              if (list.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Ainda não há atividade. Quando alguém comentar a palavra-chave, aparece aqui.',
                      style: TextStyle(color: NesaroColors.muted),
                    ),
                  ),
                );
              }
              return Card(
                child: Column(
                  children: [
                    for (final e in list) _ExecutionTile(execution: e),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, this.value, this.text, required this.icon, this.color = NesaroColors.ink});

  final String label;
  final int? value;
  final String? text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 22),
            Text(
              text ?? NumberFormat.decimalPattern('pt_BR').format(value ?? 0),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color),
            ),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NesaroColors.muted)),
          ],
        ),
      ),
    );
  }
}

class _ExecutionTile extends StatelessWidget {
  const _ExecutionTile({required this.execution});

  final Execution execution;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (execution.status) {
      ExecutionStatus.sent => (Icons.check_circle, NesaroColors.success),
      ExecutionStatus.failed => (Icons.error, NesaroColors.seal),
      ExecutionStatus.processing => (Icons.schedule, NesaroColors.muted),
    };
    final who = execution.commenterUsername == null ? 'Alguém' : '@${execution.commenterUsername}';
    final when = execution.createdAt == null ? '' : DateFormat('dd/MM HH:mm').format(execution.createdAt!);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text('$who · ${execution.automationName}', maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        execution.status == ExecutionStatus.failed && execution.error != null
            ? execution.error!
            : '"${execution.commentText}"',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(when, style: const TextStyle(color: NesaroColors.muted, fontSize: 12)),
    );
  }
}

class _VerifyEmailCard extends StatelessWidget {
  const _VerifyEmailCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFCEEF2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirme seu e-mail', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Enviamos um link de confirmação. Depois de confirmar, saia e entre de novo.'),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await context.read<AuthRepository>().resendVerification();
                messenger.showSnackBar(const SnackBar(content: Text('E-mail reenviado.')));
              },
              child: const Text('Reenviar e-mail'),
            ),
          ],
        ),
      ),
    );
  }
}
