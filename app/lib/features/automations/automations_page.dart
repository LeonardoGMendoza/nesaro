import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/automation.dart';
import '../../data/repositories/automation_repository.dart';
import 'automation_form_page.dart';

class AutomationsPage extends StatelessWidget {
  const AutomationsPage({super.key, required this.uid});

  final String uid;

  void _openForm(BuildContext context, [Automation? automation]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AutomationFormPage(uid: uid, initial: automation)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AutomationRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Automações')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
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
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data!;
          if (list.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _AutomationCard(
              automation: list[i],
              onEdit: () => _openForm(context, list[i]),
              onToggle: (value) => repo.setActive(uid, list[i].id!, value),
              onDuplicate: () => repo.duplicate(uid, list[i]),
              onDelete: () => _confirmDelete(context, repo, list[i]),
            ),
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
              Text(
                'Palavra-chave: ${a.keyword.toUpperCase()} · ${a.matchType == MatchType.exact ? 'exata' : 'contém'}'
                '${a.mediaId == null ? ' · todos os posts' : ' · um post'}',
                style: const TextStyle(color: NesaroColors.muted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  Text('${a.stats.matched} comentários'),
                  Text('${a.stats.sent} enviadas', style: const TextStyle(color: NesaroColors.success)),
                  if (a.stats.failed > 0) Text('${a.stats.failed} falhas', style: const TextStyle(color: NesaroColors.seal)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt, size: 48, color: NesaroColors.sakura),
            SizedBox(height: 12),
            Text('Nenhuma automação ainda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'Crie a primeira: escolha uma palavra como QUERO e a mensagem que vai no Direct.',
              textAlign: TextAlign.center,
              style: TextStyle(color: NesaroColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
