import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/execution.dart';

class ExecutionRepository {
  ExecutionRepository({required FirebaseFirestore firestore}) : _db = firestore;

  final FirebaseFirestore _db;

  Stream<List<Execution>> watchRecent(String uid, {int limit = 20}) => _db
      .collection('users')
      .doc(uid)
      .collection('executions')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map(Execution.fromDoc).toList());
}
