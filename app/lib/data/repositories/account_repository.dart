import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/instagram_status.dart';
import '../services/nesaro_api.dart';

/// Estado da conexão com o Instagram. Lê do Firestore e fala com o backend para conectar/desconectar.
class AccountRepository {
  AccountRepository({required FirebaseFirestore firestore, required NesaroApi api})
      : _db = firestore,
        _api = api;

  final FirebaseFirestore _db;
  final NesaroApi _api;

  Stream<InstagramStatus> watchInstagram(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => InstagramStatus.fromMap(snap.data()?['instagram'] as Map<String, dynamic>?));

  Future<Uri> startInstagramConnection() => _api.startInstagramConnection();

  Future<void> disconnectInstagram() => _api.disconnectInstagram();
}
