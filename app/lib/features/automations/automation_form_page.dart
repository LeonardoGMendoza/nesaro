import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/automation.dart';
import '../../data/repositories/automation_repository.dart';

/// Criar ou editar uma automação. Os limites de tamanho batem com as regras do Firestore.
class AutomationFormPage extends StatefulWidget {
  const AutomationFormPage({super.key, required this.uid, this.initial});

  final String uid;
  final Automation? initial;

  @override
  State<AutomationFormPage> createState() => _AutomationFormPageState();
}

class _AutomationFormPageState extends State<AutomationFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _keyword;
  late final TextEditingController _mediaId;
  late final TextEditingController _publicReply;
  late final TextEditingController _dmMessage;
  late final TextEditingController _link;
  late MatchType _matchType;
  late bool _active;
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final a = widget.initial;
    _name = TextEditingController(text: a?.name ?? '');
    _keyword = TextEditingController(text: a?.keyword ?? '');
    _mediaId = TextEditingController(text: a?.mediaId ?? '');
    _publicReply = TextEditingController(text: a?.publicReply ?? '');
    _dmMessage = TextEditingController(
      text: a?.dmMessage ?? 'Olá! Obrigado pelo interesse 💌 Aqui está o link que você pediu: {link}',
    );
    _link = TextEditingController(text: a?.link ?? '');
    _matchType = a?.matchType ?? MatchType.contains;
    _active = a?.active ?? true;
  }

  @override
  void dispose() {
    for (final c in [_name, _keyword, _mediaId, _publicReply, _dmMessage, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final automation = Automation(
      id: widget.initial?.id,
      name: _name.text,
      keyword: _keyword.text,
      matchType: _matchType,
      mediaId: _mediaId.text,
      publicReply: _publicReply.text,
      dmMessage: _dmMessage.text,
      link: _link.text,
      active: _active,
      stats: widget.initial?.stats ?? AutomationStats.zero,
    );

    final repo = context.read<AutomationRepository>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_isEditing) {
        await repo.update(widget.uid, automation);
      } else {
        await repo.create(widget.uid, automation);
      }
      navigator.pop();
    } on Exception {
      messenger.showSnackBar(const SnackBar(content: Text('Não foi possível salvar. Tente de novo.')));
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value, String field, int max) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Informe $field';
    if (v.length > max) return 'Máximo de $max caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar automação' : 'Nova automação')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome da automação', hintText: 'Ex.: Cardápio de bolos'),
              validator: (v) => _required(v, 'um nome', 80),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Gatilho: comentário em post ou Reel'),
            TextFormField(
              controller: _keyword,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Palavra-chave', hintText: 'Ex.: QUERO, LINK, MATERIAL'),
              validator: (v) => _required(v, 'a palavra-chave', 40),
            ),
            const SizedBox(height: 12),
            SegmentedButton<MatchType>(
              segments: [
                for (final t in MatchType.values) ButtonSegment(value: t, label: Text(t.label)),
              ],
              selected: {_matchType},
              onSelectionChanged: (s) => setState(() => _matchType = s.first),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mediaId,
              decoration: const InputDecoration(
                labelText: 'ID do post (opcional)',
                helperText: 'Deixe vazio para valer em todas as publicações.',
              ),
            ),
            const SizedBox(height: 20),
            const _SectionTitle('Resposta'),
            TextFormField(
              controller: _dmMessage,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Mensagem no Direct',
                helperText: 'Use {link} para escolher onde o link aparece.',
                alignLabelWithHint: true,
              ),
              validator: (v) => _required(v, 'a mensagem', 1000),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _link,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Link (opcional)', hintText: 'https://...'),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return null;
                return value.startsWith('http://') || value.startsWith('https://')
                    ? null
                    : 'O link precisa começar com https://';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _publicReply,
              decoration: const InputDecoration(
                labelText: 'Resposta pública no comentário (opcional)',
                hintText: 'Ex.: Te mandei no Direct! 💌',
              ),
              validator: (v) => (v != null && v.trim().length > 300) ? 'Máximo de 300 caracteres' : null,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              contentPadding: EdgeInsets.zero,
              activeTrackColor: NesaroColors.sakura,
              title: const Text('Automação ativa'),
            ),
            const SizedBox(height: 8),
            const Card(
              color: Color(0xFFF7EFE0),
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Regras do Instagram: a DM é enviada uma vez por comentário, em até 7 dias, '
                  'e só para contas profissionais conectadas. Evite mensagens repetitivas para não ser marcado como spam.',
                  style: TextStyle(color: NesaroColors.muted),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: NesaroColors.ink)),
    );
  }
}
