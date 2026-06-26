import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAppleAuthResult {
  const FirebaseAppleAuthResult({
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

class FirebaseAppleAuthService {
  FirebaseAppleAuthService({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Future<FirebaseAppleAuthResult> signInWithApple() async {
    final provider = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    final UserCredential userCredential;

    if (kIsWeb) {
      userCredential = await _firebaseAuth.signInWithPopup(provider);
    } else {
      userCredential = await _firebaseAuth.signInWithProvider(provider);
    }

    final user = userCredential.user;

    if (user == null) {
      throw Exception('No se pudo obtener el usuario de Apple.');
    }

    final idToken = await user.getIdToken();

    if (idToken == null || idToken.isEmpty) {
      throw Exception('No se pudo obtener el ID token de Firebase.');
    }

    return FirebaseAppleAuthResult(
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