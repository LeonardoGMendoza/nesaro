import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/automation.dart';

class AutomationRepository {
  AutomationRepository({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _db.collection('users').doc(uid).collection('automations');

  Stream<List<Automation>> watchAll(String uid) => _col(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(Automation.fromDoc).toList());

  Future<void> create(String uid, Automation automation) => _col(uid).add({
        ...automation.toWriteMap(),
        'stats': AutomationStats.zero.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> update(String uid, Automation automation) => _col(uid).doc(automation.id).update({
        ...automation.toWriteMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setActive(String uid, String id, bool active) => _col(uid).doc(id).update({
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  /// A cópia nasce pausada, para o cliente revisar antes de ativar.
  Future<void> duplicate(String uid, Automation automation) =>
      create(uid, automation.copyWith(name: '${automation.name} (cópia)', active: false));

  Future<void> delete(String uid, String id) => _col(uid).doc(id).delete();
}
