import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/automation.dart';
import '../../data/models/automation_template.dart';
import '../../data/repositories/automation_repository.dart';
import '../../widgets/motion.dart';
import '../../widgets/nesaro_logo.dart';
import '../../widgets/responsive.dart';
import 'automation_form_page.dart';

class AutomationsPage extends StatelessWidget {
  const AutomationsPage({super.key, required this.uid});

  final String uid;

  void _openForm(BuildContext context, {Automation? automation, AutomationTemplate? template}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AutomationFormPage(uid: uid, initial: automation, template: template),
      ),
    );
  }

  Future<void> _chooseTemplate(BuildContext context) async {
    final template = await showModalBottomSheet<AutomationTemplate?>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: NesaroColors.paper,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (_) => const _TemplatePicker(),
    );
    if (template != null && context.mounted) {
      _openForm(context, template: template);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AutomationRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Automações')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _chooseTemplate(context),
        backgroundColor: NesaroColors.ink,
        foregroundColor: NesaroColors.paper,
        icon: const Icon(Icons.add),
        label: const Text('Nova automação'),
      ),
      body: StreamBuilder<List<Automation>>(
        stream: repo.watchAll(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Não foi possível carregar as automações.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: NesaroColors.sakura));
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return _EmptyState(onStart: () => _chooseTemplate(context));
          }
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            children: [
              ResponsiveCenter(
                child: AdaptiveGrid(
                  minItemWidth: 320,
                  maxColumns: 3,
                  children: [
                    for (var i = 0; i < list.length; i++)
                      FadeSlideIn(
                        delay: Duration(milliseconds: 50 * i),
                        child: _AutomationCard(
                          automation: list[i],
                          onEdit: () => _openForm(context, automation: list[i]),
                          onToggle: (value) => repo.setActive(uid, list[i].id!, value),
                          onDuplicate: () => repo.duplicate(uid, list[i]),
                          onDelete: () => _confirmDelete(context, repo, list[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AutomationRepository repo, Automation automation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir automação?'),
        content: Text('"${automation.name}" será apagada. O histórico continua no painel.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: NesaroColors.seal),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await repo.delete(uid, automation.id!);
    }
  }
}

// ───────────────────────── Escolher modelo ─────────────────────────

class _TemplatePicker extends StatelessWidget {
  const _TemplatePicker();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Como você quer começar?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Escolha um modelo pronto e ajuste do seu jeito.', style: TextStyle(color: NesaroColors.muted)),
              const SizedBox(height: 16),
              AdaptiveGrid(
                minItemWidth: 220,
                maxColumns: 3,
                children: [
                  for (var i = 0; i < AutomationTemplate.all.length; i++)
                    FadeSlideIn(
                      delay: Duration(milliseconds: 40 * i),
                      child: _TemplateCard(
                        template: AutomationTemplate.all[i],
                        onTap: () => Navigator.pop(context, AutomationTemplate.all[i]),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, const AutomationTemplate(
                  title: 'Em branco',
                  description: '',
                  icon: Icons.edit_outlined,
                  name: '',
                  keyword: '',
                  dmMessage: 'Olá! Obrigado pelo interesse 💌 Aqui está o link que você pediu: {link}',
                )),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Começar do zero'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.template, required this.onTap});

  final AutomationTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: NesaroColors.sakuraMist, borderRadius: BorderRadius.circular(14)),
                child: Icon(template.icon, color: NesaroColors.sakura),
              ),
              const SizedBox(height: 12),
              Text(template.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(template.description, style: const TextStyle(color: NesaroColors.muted, height: 1.3)),
              const SizedBox(height: 10),
              _KeywordChip(keyword: template.keyword),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Cartão da automação ─────────────────────────

enum _MenuAction { edit, duplicate, delete }

class _AutomationCard extends StatelessWidget {
  const _AutomationCard({
    required this.automation,
    required this.onEdit,
    required this.onToggle,
    required this.onDuplicate,
    required this.onDelete,
  });

  final Automation automation;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final a = automation;
    return PressableScale(
      onTap: onEdit,
      child: AnimatedOpacity(
        opacity: a.active ? 1 : 0.65,
        duration: const Duration(milliseconds: 250),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: a.active ? NesaroColors.success : NesaroColors.muted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Switch(value: a.active, onChanged: onToggle, activeTrackColor: NesaroColors.sakura),
                    PopupMenuButton<_MenuAction>(
                      tooltip: 'Mais opções',
                      onSelected: (action) {
                        switch (action) {
                          case _MenuAction.edit:
                            onEdit();
                          case _MenuAction.duplicate:
                            onDuplicate();
                          case _MenuAction.delete:
                            onDelete();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: _MenuAction.edit, child: Text('Editar')),
                        PopupMenuItem(value: _MenuAction.duplicate, child: Text('Duplicar')),
                        PopupMenuItem(value: _MenuAction.delete, child: Text('Excluir')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _KeywordChip(keyword: a.keyword),
                    _InfoChip(label: a.matchType == MatchType.exact ? 'Exata' : 'Contém'),
                    _InfoChip(label: a.mediaId == null ? 'Todos os posts' : 'Um post'),
                    if (a.publicReply != null) const _InfoChip(label: 'Responde no post'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  a.dmMessage.replaceAll('{link}', '🔗'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: NesaroColors.muted, height: 1.35),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    children: [
                      _Metric(label: 'Comentários', value: a.stats.matched, color: NesaroColors.inkSoft),
                      _Metric(label: 'Enviadas', value: a.stats.sent, color: NesaroColors.success),
                      _Metric(label: 'Falhas', value: a.stats.failed, color: NesaroColors.seal),
                    ],
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

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.color});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedCount(value: value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 12, color: NesaroColors.muted)),
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: NesaroColors.ink, borderRadius: BorderRadius.circular(999)),
      child: Text(
        '💬 ${keyword.toUpperCase()}',
        style: const TextStyle(color: NesaroColors.paper, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 0.5),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: NesaroColors.paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: NesaroColors.line),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: NesaroColors.muted, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: FadeSlideIn(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const NesaroLogo(size: 120, animated: true),
                const SizedBox(height: 16),
                const Text('Sua primeira automação', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text(
                  'Escolha uma palavra como QUERO e a mensagem que vai no Direct. A Nesaro responde sozinha, 24 horas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: NesaroColors.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Começar com um modelo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
