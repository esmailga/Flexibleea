import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper over FirebaseAuth. The instance is resolved lazily so the
/// class can be constructed (and subclassed in tests) without Firebase.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _override = auth;

  final FirebaseAuth? _override;

  FirebaseAuth get _auth => _override ?? FirebaseAuth.instance;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Passwords were trimmed at sign-up in earlier versions, so keep trimming
  // to let those accounts continue signing in.
  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
  }

  Future<User> register({required String email, required String password}) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password.trim(),
    );
    return credential.user!;
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());

  Future<void> signOut() => _auth.signOut();

  /// Admins carry the custom claim `admin: true` (set with tool/admin).
  Future<bool> isAdmin(User user, {bool forceRefresh = false}) async {
    final token = await user.getIdTokenResult(forceRefresh);
    return token.claims?['admin'] == true;
  }
}
