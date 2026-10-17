import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchType {
  contains('Contém a palavra'),
  exact('Exatamente a palavra');

  const MatchType(this.label);
  final String label;

  static MatchType fromName(String? value) =>
      value == MatchType.exact.name ? MatchType.exact : MatchType.contains;
}

class AutomationStats {
  const AutomationStats({this.matched = 0, this.sent = 0, this.failed = 0});

  static const zero = AutomationStats();

  /// Comentários que casaram com a regra.
  final int matched;

  /// DMs enviadas com sucesso.
  final int sent;

  /// Tentativas que falharam.
  final int failed;

  int get attempts => sent + failed;

  factory AutomationStats.fromMap(Map<String, dynamic>? map) => AutomationStats(
        matched: (map?['matched'] as num?)?.toInt() ?? 0,
        sent: (map?['sent'] as num?)?.toInt() ?? 0,
        failed: (map?['failed'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {'matched': matched, 'sent': sent, 'failed': failed};

  AutomationStats operator +(AutomationStats other) => AutomationStats(
        matched: matched + other.matched,
        sent: sent + other.sent,
        failed: failed + other.failed,
      );
}

/// Espelha users/{uid}/automations/{id} no Firestore (o backend .NET lê o mesmo formato).
class Automation {
  const Automation({
    this.id,
    required this.name,
    required this.keyword,
    this.matchType = MatchType.contains,
    this.mediaId,
    this.publicReply,
    required this.dmMessage,
    this.link,
    this.active = true,
    this.stats = AutomationStats.zero,
    this.createdAt,
    this.updatedAt,
  });

  final String? id;
  final String name;
  final String keyword;
  final MatchType matchType;

  /// ID de um post/Reel específico. Nulo = todas as publicações.
  final String? mediaId;
  final String? publicReply;
  final String dmMessage;
  final String? link;
  final bool active;
  final AutomationStats stats;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Automation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Automation(
      id: doc.id,
      name: d['name'] as String? ?? '',
      keyword: d['keyword'] as String? ?? '',
      matchType: MatchType.fromName(d['matchType'] as String?),
      mediaId: d['mediaId'] as String?,
      publicReply: d['publicReply'] as String?,
      dmMessage: d['dmMessage'] as String? ?? '',
      link: d['link'] as String?,
      active: d['active'] as bool? ?? false,
      stats: AutomationStats.fromMap(d['stats'] as Map<String, dynamic>?),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Campos que o app pode gravar. "stats" fica de fora: só o backend altera.
  Map<String, dynamic> toWriteMap() => {
        'name': name.trim(),
        'triggerType': 'comment',
        'keyword': keyword.trim(),
        'matchType': matchType.name,
        'mediaId': _nullIfEmpty(mediaId),
        'publicReply': _nullIfEmpty(publicReply),
        'dmMessage': dmMessage.trim(),
        'link': _nullIfEmpty(link),
        'active': active,
      };

  Automation copyWith({String? name, bool? active}) => Automation(
        id: id,
        name: name ?? this.name,
        keyword: keyword,
        matchType: matchType,
        mediaId: mediaId,
        publicReply: publicReply,
        dmMessage: dmMessage,
        link: link,
        active: active ?? this.active,
        stats: stats,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static String? _nullIfEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
