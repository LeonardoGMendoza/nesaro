import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/automation.dart';
import '../../data/models/execution.dart';
import '../../data/models/instagram_status.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/automation_repository.dart';
import '../../data/repositories/execution_repository.dart';
import '../../widgets/motion.dart';
import '../../widgets/nesaro_logo.dart';
import '../../widgets/responsive.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user, required this.onNavigate});

  final User user;

  /// Troca de aba (1 = Automações, 2 = Conta).
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final automations = context.read<AutomationRepository>();
    final executions = context.read<ExecutionRepository>();
    final account = context.read<AccountRepository>();
    final firstName = (user.displayName ?? '').trim().split(' ').first;
    final name = firstName.isEmpty ? '' : '${firstName[0].toUpperCase()}${firstName.substring(1)}';

    return Scaffold(
      appBar: Breakpoints.isPhone(context)
          ? AppBar(
              title: const Row(
                children: [
                  NesaroLogo(size: 34, animated: true),
                  SizedBox(width: 8),
                  AliceFlowName(fontSize: 22),
                ],
              ),
            )
          : null,
      body: StreamBuilder<List<Automation>>(
        stream: automations.watchAll(user.uid),
        builder: (context, autoSnap) {
          final list = autoSnap.data ?? const <Automation>[];
          return StreamBuilder<InstagramStatus>(
            stream: account.watchInstagram(user.uid),
            builder: (context, igSnap) {
              final ig = igSnap.data ?? InstagramStatus.disconnected;
              return StreamBuilder<List<Execution>>(
                stream: executions.watchRecent(user.uid, limit: 300),
                builder: (context, exSnap) {
                  final history = exSnap.data ?? const <Execution>[];
                  return ListView(
                    padding: const EdgeInsets.only(top: 20, bottom: 32),
                    children: [
                      ResponsiveCenter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FadeSlideIn(child: _HeroCard(name: name, instagram: ig, onNavigate: onNavigate)),
                            if (!user.emailVerified) ...[
                              const SizedBox(height: 12),
                              const FadeSlideIn(delay: Duration(milliseconds: 80), child: _VerifyEmailCard()),
                            ],
                            const SizedBox(height: 20),
                            _StatsGrid(automations: list),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final chart = FadeSlideIn(
                                  delay: const Duration(milliseconds: 300),
                                  child: _WeekChart(history: history),
                                );
                                final steps = FadeSlideIn(
                                  delay: const Duration(milliseconds: 380),
                                  child: _GettingStarted(
                                    instagramConnected: ig.connected,
                                    hasAutomation: list.isNotEmpty,
                                    hasSent: history.any((e) => e.status == ExecutionStatus.sent),
                                    onNavigate: onNavigate,
                                  ),
                                );
                                if (constraints.maxWidth < 800) {
                                  return Column(children: [chart, const SizedBox(height: 16), steps]);
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 3, child: chart),
                                    const SizedBox(width: 16),
                                    Expanded(flex: 2, child: steps),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            FadeSlideIn(
                              delay: const Duration(milliseconds: 460),
                              child: _RecentActivity(history: history.take(10).toList()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ───────────────────────── Cartão de boas-vindas ─────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.name, required this.instagram, required this.onNavigate});

  final String name;
  final InstagramStatus instagram;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.isPhone(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Olá! 👋' : 'Olá, $name! 👋',
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Cada comentário pode virar um cliente. A AliceFlow responde por você no Direct, 24 horas por dia.',
          style: TextStyle(color: Color(0xFFE9E6FF), fontSize: 15, height: 1.4),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatusPill(connected: instagram.connected, username: instagram.username),
            FilledButton.icon(
              onPressed: () => onNavigate(instagram.connected ? 1 : 2),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: NesaroColors.ink,
                minimumSize: const Size(0, 44),
              ),
              icon: Icon(instagram.connected ? Icons.add : Icons.link),
              label: Text(instagram.connected ? 'Nova automação' : 'Conectar Instagram'),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(phone ? 20 : 28),
      decoration: BoxDecoration(
        gradient: NesaroColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x338B3DFF), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: phone
          ? text
          : Row(
              children: [
                Expanded(child: text),
                const SizedBox(width: 24),
                const NesaroLogo(
                  size: 140,
                  animated: true,
                  inkColor: NesaroColors.paper,
                  petalColor: NesaroColors.sakuraLight,
                  centerColor: NesaroColors.ink,
                ),
              ],
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.connected, this.username});

  final bool connected;
  final String? username;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(color: connected ? const Color(0xFF6EE7A8) : const Color(0xFFFFB4A8)),
          const SizedBox(width: 8),
          Text(
            connected ? 'Conectado: @${username ?? ''}' : 'Instagram não conectado',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Bolinha que pulsa, indicando status ao vivo.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 6 + 8 * _controller.value,
              height: 6 + 8 * _controller.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.5 * (1 - _controller.value)),
              ),
            ),
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Números ─────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.automations});

  final List<Automation> automations;

  @override
  Widget build(BuildContext context) {
    final totals = automations.fold(AutomationStats.zero, (sum, a) => sum + a.stats);
    final active = automations.where((a) => a.active).length;
    final rate = totals.attempts == 0 ? 0 : (totals.sent * 100 / totals.attempts).round();

    final cards = [
      _StatCard(label: 'Automações ativas', value: active, suffix: ' de ${automations.length}', icon: Icons.bolt, color: NesaroColors.sakura),
      _StatCard(label: 'Comentários identificados', value: totals.matched, icon: Icons.chat_bubble_outline, color: NesaroColors.inkSoft),
      _StatCard(label: 'Mensagens enviadas', value: totals.sent, icon: Icons.send_rounded, color: NesaroColors.success),
      _StatCard(label: 'Taxa de entrega', value: rate, suffix: '%', icon: Icons.verified_outlined, color: const Color(0xFF4F5BD5)),
      _StatCard(label: 'Falhas de envio', value: totals.failed, icon: Icons.error_outline, color: NesaroColors.seal),
    ];

    return AdaptiveGrid(
      minItemWidth: 170,
      maxColumns: 5,
      children: [
        for (var i = 0; i < cards.length; i++)
          FadeSlideIn(delay: Duration(milliseconds: 100 + i * 60), child: cards[i]),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.suffix = '',
  });

  final String label;
  final int value;
  final String suffix;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                AnimatedCount(
                  value: value,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: NesaroColors.ink),
                ),
                if (suffix.isNotEmpty)
                  Flexible(
                    child: Text(
                      suffix,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: NesaroColors.muted, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NesaroColors.muted)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Gráfico da semana ─────────────────────────

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.history});

  final List<Execution> history;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final days = [for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i))];
    final sent = <DateTime, int>{for (final d in days) d: 0};
    final failed = <DateTime, int>{for (final d in days) d: 0};

    for (final e in history) {
      final at = e.createdAt;
      if (at == null) continue;
      final day = DateUtils.dateOnly(at);
      if (!sent.containsKey(day)) continue;
      if (e.status == ExecutionStatus.sent) sent[day] = sent[day]! + 1;
      if (e.status == ExecutionStatus.failed) failed[day] = failed[day]! + 1;
    }

    final maxValue = days.map((d) => sent[d]! + failed[d]!).fold(0, (a, b) => a > b ? a : b);
    final total = sent.values.fold(0, (a, b) => a + b);
    final weekday = DateFormat.E('pt_BR');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Mensagens nos últimos 7 dias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                AnimatedCount(
                  value: total,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: NesaroColors.success),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                _Legend(color: NesaroColors.sakura, label: 'Enviadas'),
                SizedBox(width: 14),
                _Legend(color: Color(0xFFE8B4A8), label: 'Falhas'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < days.length; i++)
                    Expanded(
                      child: _Bar(
                        sent: sent[days[i]]!,
                        failed: failed[days[i]]!,
                        maxValue: maxValue,
                        label: i == days.length - 1 ? 'Hoje' : weekday.format(days[i]).replaceAll('.', ''),
                        delay: Duration(milliseconds: 80 * i),
                      ),
                    ),
                ],
              ),
            ),
            if (maxValue == 0)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Quando as automações começarem a responder, o gráfico ganha vida aqui.',
                  style: TextStyle(color: NesaroColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.sent,
    required this.failed,
    required this.maxValue,
    required this.label,
    required this.delay,
  });

  final int sent;
  final int failed;
  final int maxValue;
  final String label;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    const maxHeight = 120.0;
    final scale = maxValue == 0 ? 0.0 : maxHeight / maxValue;
    return Tooltip(
      message: '$label: $sent enviadas, $failed falhas',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800) + delay,
            curve: Curves.easeOutCubic,
            builder: (context, t, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 22,
                  height: (failed * scale * t).clamp(0.0, maxHeight).toDouble(),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8B4A8),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ),
                Container(
                  width: 22,
                  height: (sent * scale * t).clamp(maxValue == 0 ? 4.0 : 0.0, maxHeight).toDouble(),
                  decoration: BoxDecoration(
                    color: maxValue == 0 ? NesaroColors.paperDeep : NesaroColors.sakura,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(failed == 0 ? 6 : 0),
                      bottom: const Radius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: NesaroColors.muted)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: NesaroColors.muted)),
      ],
    );
  }
}

// ───────────────────────── Primeiros passos ─────────────────────────

class _GettingStarted extends StatelessWidget {
  const _GettingStarted({
    required this.instagramConnected,
    required this.hasAutomation,
    required this.hasSent,
    required this.onNavigate,
  });

  final bool instagramConnected;
  final bool hasAutomation;
  final bool hasSent;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final steps = [
      (done: instagramConnected, title: 'Conecte seu Instagram', subtitle: 'Login oficial da Meta, sem senha', tab: 2),
      (done: hasAutomation, title: 'Crie sua primeira automação', subtitle: 'Use um modelo pronto em 1 minuto', tab: 1),
      (done: hasSent, title: 'Faça um teste', subtitle: 'Comente a palavra-chave em um post seu', tab: 1),
    ];
    final doneCount = steps.where((s) => s.done).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Primeiros passos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: doneCount / steps.length),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: NesaroColors.paperDeep,
                  color: NesaroColors.sakura,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text('$doneCount de ${steps.length} concluídos', style: const TextStyle(color: NesaroColors.muted, fontSize: 13)),
            const SizedBox(height: 8),
            for (final step in steps)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: step.done ? null : () => onNavigate(step.tab),
                leading: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                  child: step.done
                      ? const Icon(Icons.check_circle, key: ValueKey('done'), color: NesaroColors.success)
                      : const Icon(Icons.radio_button_unchecked, key: ValueKey('todo'), color: NesaroColors.muted),
                ),
                title: Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: step.done ? TextDecoration.lineThrough : null,
                    color: step.done ? NesaroColors.muted : NesaroColors.ink,
                  ),
                ),
                subtitle: Text(step.subtitle),
                trailing: step.done ? null : const Icon(Icons.chevron_right),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Atividade recente ─────────────────────────

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.history});

  final List<Execution> history;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Atividade recente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.forum_outlined, color: NesaroColors.muted),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ainda não há atividade. Quando alguém comentar a palavra-chave, aparece aqui na hora.',
                        style: TextStyle(color: NesaroColors.muted),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final e in history) _ExecutionTile(execution: e),
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
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.12), child: Icon(icon, color: color, size: 20)),
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
      color: NesaroColors.sakuraMist,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.mark_email_unread_outlined, color: NesaroColors.sakura),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Confirme seu e-mail pelo link que enviamos. Depois, saia e entre de novo.'),
            ),
            TextButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                await context.read<AuthRepository>().resendVerification();
                messenger.showSnackBar(const SnackBar(content: Text('E-mail reenviado.')));
              },
              child: const Text('Reenviar'),
            ),
          ],
        ),
      ),
    );
  }
}
