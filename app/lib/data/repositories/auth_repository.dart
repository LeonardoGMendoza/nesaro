import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Login, cadastro e sessão. As telas nunca usam FirebaseAuth direto: usam este repositório.
class AuthRepository {
  AuthRepository({required FirebaseAuth auth, required FirebaseFirestore firestore})
      : _auth = auth,
        _db = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Usado pelo NesaroApi para mandar o token ao backend.
  Future<String?> idToken() async => _auth.currentUser?.getIdToken();

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user!;

    await user.updateDisplayName(name.trim());
    await _db.collection('users').doc(user.uid).set({
      'name': name.trim(),
      'email': user.email,
      'termsAcceptedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await user.sendEmailVerification();
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> resendVerification() async => _auth.currentUser?.sendEmailVerification();

  /// Atualiza o usuário (ex.: depois que ele confirmou o e-mail).
  Future<User?> reload() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  Future<void> signOut() => _auth.signOut();
}
