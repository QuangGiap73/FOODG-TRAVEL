import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
    AuthService._internal();
    static final AuthService _instance = AuthService._internal();
    factory AuthService() => _instance;
    final FirebaseAuth _auth = FirebaseAuth.instance;

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
    Future<void> logout() => _auth.signOut();
}