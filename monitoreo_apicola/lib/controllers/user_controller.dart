import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtener todos los usuarios
  Future<List<Usuario>> getUsuarios() async {
    try {
      print("🔄 Obteniendo usuarios...");
      final snapshot = await _db.collection('usuarios').orderBy('nombre').get();

      final usuarios =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return Usuario.fromMap(data, doc.id);
          }).toList();

      print("✅ Usuarios obtenidos: ${usuarios.length}");
      return usuarios;
    } catch (e) {
      print("❌ Error al obtener usuarios: $e");
      rethrow;
    }
  }

  /// Obtener un usuario específico por UID
  Future<Usuario?> getUsuarioById(String uid) async {
    try {
      print("🔄 Obteniendo usuario: $uid");
      final doc = await _db.collection('usuarios').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final usuario = Usuario.fromMap(data, doc.id);
        print("✅ Usuario encontrado: ${usuario.nombre}");
        return usuario;
      }

      print("⚠️ Usuario no encontrado: $uid");
      return null;
    } catch (e) {
      print("❌ Error al obtener usuario: $e");
      rethrow;
    }
  }

  /// Método original addUsuario (mantener compatibilidad)
  Future<void> addUsuario(Usuario usuario) async {
    try {
      print("🔄 Agregando usuario (método legacy): ${usuario.email}");
      await _db.collection('usuarios').doc(usuario.uid).set(usuario.toMap());
      print("✅ Usuario agregado: ${usuario.uid}");
    } catch (e) {
      print("❌ Error al agregar usuario: $e");
      rethrow;
    }
  }

  /// Crear nuevo usuario con email y contraseña (método recomendado)
  Future<String> crearUsuarioConPassword({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      print("🔄 Creando usuario con auth: $email");

      // Validaciones
      if (nombre.trim().isEmpty) {
        throw Exception("El nombre no puede estar vacío");
      }
      if (email.trim().isEmpty) {
        throw Exception("El email no puede estar vacío");
      }
      if (!email.contains('@')) {
        throw Exception("Email no válido");
      }
      if (password.length < 6) {
        throw Exception("La contraseña debe tener al menos 6 caracteres");
      }

      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;

        // Actualizar displayName en Firebase Auth
        await userCredential.user!.updateDisplayName(nombre);

        // Crear documento en Firestore
        final usuario = Usuario(
          uid: uid,
          nombre: nombre.trim(),
          email: email.trim(),
          rol: rol,
          fechaCreacion: DateTime.now(),
          emailVerificado: userCredential.user!.emailVerified,
        );

        await _db.collection('usuarios').doc(uid).set(usuario.toMap());

        print("✅ Usuario creado exitosamente: $uid");
        return uid;
      } else {
        throw Exception("Error al crear usuario en Firebase Auth");
      }
    } catch (e) {
      print("❌ Error al crear usuario: $e");
      rethrow;
    }
  }

  /// Actualizar usuario existente
  Future<void> updateUsuario(Usuario usuario) async {
    try {
      print("🔄 Actualizando usuario: ${usuario.uid}");

      // Verificar que el usuario existe en Firestore
      final doc = await _db.collection('usuarios').doc(usuario.uid).get();
      if (!doc.exists) {
        throw Exception("El usuario no existe en Firestore");
      }

      // Actualizar en Firestore
      final usuarioActualizado = usuario.copyWith(
        fechaActualizacion: DateTime.now(),
      );

      await _db
          .collection('usuarios')
          .doc(usuario.uid)
          .update(usuarioActualizado.toMap());

      // Actualizar displayName en Firebase Auth si es necesario
      final authUser = await _getAuthUserById(usuario.uid);
      if (authUser != null && authUser.displayName != usuario.nombre) {
        await authUser.updateDisplayName(usuario.nombre);
      }

      print("✅ Usuario actualizado: ${usuario.uid}");
    } catch (e) {
      print("❌ Error al actualizar usuario: $e");
      rethrow;
    }
  }

  /// Eliminar usuario (Firebase Auth + Firestore)
  Future<void> deleteUsuario(String uid) async {
    try {
      print("🔄 Eliminando usuario: $uid");

      // Verificar que el usuario existe
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (!doc.exists) {
        throw Exception("El usuario no existe");
      }

      // Eliminar de Firestore
      await _db.collection('usuarios').doc(uid).delete();

      print("✅ Usuario eliminado de Firestore: $uid");
    } catch (e) {
      print("❌ Error al eliminar usuario: $e");
      rethrow;
    }
  }

  /// Cambiar contraseña de un usuario (solo el usuario actual)
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception("No hay usuario autenticado");
      }

      // Re-autenticar con la contraseña actual
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordActual,
      );

      await user.reauthenticateWithCredential(credential);

      // Cambiar a la nueva contraseña
      await user.updatePassword(passwordNuevo);

      print("✅ Contraseña cambiada exitosamente");
    } catch (e) {
      print("❌ Error al cambiar contraseña: $e");
      rethrow;
    }
  }

  /// Restablecer contraseña por email
  Future<void> restablecerPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      print("✅ Email de restablecimiento enviado a: $email");
    } catch (e) {
      print("❌ Error al enviar email de restablecimiento: $e");
      rethrow;
    }
  }

  /// Cambiar estado del usuario (activar/desactivar)
  Future<void> cambiarEstadoUsuario(String uid, bool activo) async {
    try {
      await _db.collection('usuarios').doc(uid).update({
        'activo': activo,
        'fechaActualizacion': Timestamp.fromDate(DateTime.now()),
      });
      print("✅ Estado del usuario cambiado: $uid -> $activo");
    } catch (e) {
      print("❌ Error al cambiar estado del usuario: $e");
      rethrow;
    }
  }

  /// Obtener usuario de Firebase Auth por UID
  Future<User?> _getAuthUserById(String uid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        return currentUser;
      }
      return null;
    } catch (e) {
      print("❌ Error al obtener usuario de Auth: $e");
      return null;
    }
  }

  /// Verificar si un email ya existe
  Future<bool> emailExiste(String email) async {
    try {
      final query =
          await _db
              .collection('usuarios')
              .where('email', isEqualTo: email.trim().toLowerCase())
              .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print("❌ Error al verificar email: $e");
      return false;
    }
  }

  /// Stream de usuarios para tiempo real
  Stream<List<Usuario>> getUsuariosStream() {
    return _db.collection('usuarios').orderBy('nombre').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        return Usuario.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
}
