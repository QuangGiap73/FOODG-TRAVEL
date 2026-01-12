import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
    AuthService._internal();
    static final AuthService _instance = AuthService._internal();
    factory AuthService() => _instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    User? get currentUser => _auth.currentUser;
    Future<UserCredential> registerWithEmail({
        required String email,
        required String password,
    }) {
        return _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
        );
    }
    Future<UserCredential> loginWithEmail({
        required String email,
        required String password,
    }) {
        return _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
        );
    }
    Future<UserCredential> signInWithGoogle() async {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
            throw FirebaseAuthException(
                code: "sign_in_canceled",
                message: "Google sign-in canceled",
            );
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
        );
        return _auth.signInWithCredential(credential);
    }

    Future<void> logout() async {
        await Future.wait([
            _auth.signOut(),
            _googleSignIn.signOut(),
        ]);
    }
    Future<void> changePassword({
        required String currentPassword,
        required String newPassword,
        }) async {
        final user = _auth.currentUser;
        if (user == null) {
            throw FirebaseAuthException(
            code: 'no-user',
            message: 'No user signed in.',
            );
        }

        final providers = user.providerData.map((p) => p.providerId).toList();
        if (!providers.contains('password')) {
            throw FirebaseAuthException(
            code: 'no-password-provider',
            message: 'Password provider not linked.',
            );
        }

        final email = user.email;
        if (email == null || email.isEmpty) {
            throw FirebaseAuthException(
            code: 'no-email',
            message: 'No email for current user.',
            );
        }

        final credential = EmailAuthProvider.credential(
            email: email,
            password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        }

}