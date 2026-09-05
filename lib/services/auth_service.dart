import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'app_lock_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static const String _serverClientId =
      '1014933764619-er977ds92c2qa9rhc3si7oehipjrgdu5.apps.googleusercontent.com';

  Future<void> _initializeGoogleSignIn() async {
    await _googleSignIn.initialize(
      serverClientId: _serverClientId,
    );
  }

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential?> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    final account = await _googleSignIn.authenticate();

    final googleAuth = account.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> reauthenticateWithGoogle() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Chưa đăng nhập.');
    }

    await _initializeGoogleSignIn();

    final account = await _googleSignIn.authenticate();

    final googleAuth = account.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    await user.reauthenticateWithCredential(credential);
  }

  Future<void> signOut() async {
    AppLockService.instance.unlock();

    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
