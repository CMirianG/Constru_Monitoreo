import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user;
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<User?> register(
    String email,
    String password,
    String nombre,
    String rol,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = result.user!.uid;

    await _db.collection('usuarios').doc(uid).set({
      'nombre': nombre,
      'email': email,
      'rol': rol,
    });

    return result.user;
  }

  Stream<User?> get userChanges => _auth.authStateChanges();
}
