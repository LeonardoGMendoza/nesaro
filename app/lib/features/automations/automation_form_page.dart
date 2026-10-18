import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models/automation.dart';
import '../../data/models/automation_template.dart';
import '../../data/repositories/automation_repository.dart';
import '../../widgets/motion.dart';
import '../../widgets/responsive.dart';

/// Criar ou editar uma automação, com prévia ao vivo de como a mensagem chega no Direct.
/// Os limites de tamanho batem com as regras do Firestore.
class AutomationFormPage extends StatefulWidget {
  const AutomationFormPage({super.key, required this.uid, this.initial, this.template});

  final String uid;
  final Automation? initial;
  final AutomationTemplate? template;

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
    final a = widget.initial ?? widget.template?.toAutomation();
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

    // Qualquer digitação atualiza a prévia.
    for (final c in [_keyword, _publicReply, _dmMessage, _link]) {
      c.addListener(_refresh);
    }
  }

  void _refresh() => setState(() {});

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
      messenger.showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Automação atualizada ✓' : 'Automação criada ✓')),
      );
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

  String get _previewMessage {
    final message = _dmMessage.text.trim();
    final link = _link.text.trim();
    if (link.isEmpty) return message.replaceAll('{link}', '').trim();
    return message.contains('{link}') ? message.replaceAll('{link}', link) : '$message\n$link';
  }

  @override
  Widget build(BuildContext context) {
    final preview = _DirectPreview(
      keyword: _keyword.text.trim().isEmpty ? 'QUERO' : _keyword.text.trim().toUpperCase(),
      publicReply: _publicReply.text.trim(),
      message: _previewMessage.isEmpty ? 'Sua mensagem aparece aqui…' : _previewMessage,
    );

    final form = _buildForm();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar automação' : 'Nova automação')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            child: ResponsiveCenter(
              maxWidth: wide ? 1100 : 720,
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: form),
                        const SizedBox(width: 24),
                        Expanded(flex: 2, child: FadeSlideIn(delay: const Duration(milliseconds: 150), child: preview)),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [form, const SizedBox(height: 24), preview],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            number: 1,
            title: 'Gatilho',
            subtitle: 'Quando alguém comentar…',
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome da automação', hintText: 'Ex.: Cardápio de bolos'),
                validator: (v) => _required(v, 'um nome', 80),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keyword,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Palavra-chave',
                  hintText: 'Ex.: QUERO, LINK, MATERIAL',
                  prefixIcon: Icon(Icons.chat_bubble_outline),
                ),
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
                  prefixIcon: Icon(Icons.grid_on_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            number: 2,
            title: 'Resposta',
            subtitle: '…a Nesaro envia no Direct',
            children: [
              TextFormField(
                controller: _dmMessage,
                minLines: 3,
                maxLines: 6,
                maxLength: 1000,
                decoration: const InputDecoration(
                  labelText: 'Mensagem no Direct',
                  helperText: 'Use {link} para escolher onde o link aparece.',
                  alignLabelWithHint: true,
                ),
                validator: (v) => _required(v, 'a mensagem', 1000),
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _link,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Link (opcional)',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link),
                ),
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
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'Resposta pública no comentário (opcional)',
                  hintText: 'Ex.: Te mandei no Direct! 💌',
                  prefixIcon: Icon(Icons.reply_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              activeTrackColor: NesaroColors.sakura,
              title: const Text('Automação ativa', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(_active ? 'Começa a responder assim que salvar' : 'Fica pausada até você ativar'),
            ),
          ),
          const SizedBox(height: 12),
          const _RulesNote(),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: NesaroColors.paper),
                  )
                : const Icon(Icons.check),
            label: Text(_saving ? 'Salvando...' : 'Salvar automação'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.number, required this.title, required this.subtitle, required this.children});

  final int number;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: NesaroColors.ink,
                  child: Text('$number', style: const TextStyle(color: NesaroColors.paper, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(subtitle, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NesaroColors.muted)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RulesNote extends StatelessWidget {
  const _RulesNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFF7EFE0), borderRadius: BorderRadius.circular(16)),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: NesaroColors.muted, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Regras do Instagram: a DM é enviada uma vez por comentário, em até 7 dias, e só para contas '
              'profissionais conectadas. Evite mensagens repetitivas para não ser marcado como spam.',
              style: TextStyle(color: NesaroColors.muted, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Prévia estilo Instagram ─────────────────────────

class _DirectPreview extends StatelessWidget {
  const _DirectPreview({required this.keyword, required this.publicReply, required this.message});

  final String keyword;
  final String publicReply;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Prévia ao vivo', style: TextStyle(fontWeight: FontWeight.w700, color: NesaroColors.muted)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: NesaroColors.line, width: 6),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 8))],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Comentário no post
              Container(
                color: const Color(0xFFFAFAFA),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('No post', style: TextStyle(fontSize: 11, color: NesaroColors.muted, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _CommentRow(user: 'cliente_feliz', text: keyword),
                    if (publicReply.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: _CommentRow(user: 'sua_loja', text: publicReply, isBrand: true),
                      ),
                    ],
                  ],
                ),
              ),
              // Direct
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEFEFEF)))),
                child: const Row(
                  children: [
                    _Avatar(size: 30, isBrand: true),
                    SizedBox(width: 10),
                    Text('sua_loja', style: TextStyle(fontWeight: FontWeight.w700)),
                    Spacer(),
                    Icon(Icons.call_outlined, size: 20),
                    SizedBox(width: 12),
                    Icon(Icons.videocam_outlined, size: 22),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const _Avatar(size: 26, isBrand: true),
                    const SizedBox(width: 8),
                    Flexible(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEFEF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(message, style: const TextStyle(height: 1.35)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({required this.user, required this.text, this.isBrand = false});

  final String user;
  final String text;
  final bool isBrand;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avatar(size: 28, isBrand: isBrand),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$user  ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.size, this.isBrand = false});

  final double size;
  final bool isBrand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: NesaroColors.instagramGradient),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isBrand ? NesaroColors.sakuraMist : const Color(0xFFDDE3F0),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Icon(isBrand ? Icons.storefront : Icons.person, size: size * 0.5, color: NesaroColors.inkSoft),
      ),
    );
  }
}
