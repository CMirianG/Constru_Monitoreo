// lib/controllers/auth_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart'; // <- usamos el model Usuario

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
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
    // Delegamos en el modelo para que cree en Auth y en Firestore
    await Usuario.crearUsuarioConPassword(
      nombre: nombre,
      email: email.trim().toLowerCase(),
      password: password,
      rol: rol,
    );
    return _auth.currentUser; // queda consistente con tu firma
  }

  Stream<User?> get userChanges => _auth.authStateChanges();
}
