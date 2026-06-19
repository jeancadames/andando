import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseGoogleAuthResult {
  const FirebaseGoogleAuthResult({
    required this.idToken,
    required this.email,
    required this.name,
    required this.photoUrl,
    required this.firebaseUid,
  });

  final String idToken;
  final String? email;
  final String? name;
  final String? photoUrl;
  final String firebaseUid;
}

class FirebaseGoogleAuthService {
  FirebaseGoogleAuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Future<FirebaseGoogleAuthResult> signInWithGoogle() async {
    if (!kIsWeb) {
      throw UnsupportedError(
        'Google Sign-In nativo se configurará después. '
        'Por ahora este flujo está habilitado para Flutter Web.',
      );
    }

    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    final userCredential = await _firebaseAuth.signInWithPopup(provider);
    final user = userCredential.user;

    if (user == null) {
      throw Exception('No se pudo obtener el usuario de Google.');
    }

    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw Exception('No se pudo obtener el ID token de Firebase.');
    }

    return FirebaseGoogleAuthResult(
      idToken: idToken,
      email: user.email,
      name: user.displayName,
      photoUrl: user.photoURL,
      firebaseUid: user.uid,
    );
  }

  Future<void> signOutFromFirebase() async {
    await _firebaseAuth.signOut();
  }
}