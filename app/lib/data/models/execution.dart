import 'package:cloud_firestore/cloud_firestore.dart';

enum ExecutionStatus {
  processing('Processando'),
  sent('Enviada'),
  failed('Falhou');

  const ExecutionStatus(this.label);
  final String label;

  static ExecutionStatus fromName(String? value) => ExecutionStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ExecutionStatus.processing,
      );
}

/// Espelha users/{uid}/executions/{id}. Só o backend grava; o app só lê.
class Execution {
  const Execution({
    required this.id,
    required this.automationName,
    required this.commentText,
    this.commenterUsername,
    required this.status,
    this.error,
    this.createdAt,
  });

  final String id;
  final String automationName;
  final String commentText;
  final String? commenterUsername;
  final ExecutionStatus status;
  final String? error;
  final DateTime? createdAt;

  factory Execution.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Execution(
      id: doc.id,
      automationName: d['automationName'] as String? ?? '',
      commentText: d['commentText'] as String? ?? '',
      commenterUsername: d['commenterUsername'] as String?,
      status: ExecutionStatus.fromName(d['status'] as String?),
      error: d['error'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
