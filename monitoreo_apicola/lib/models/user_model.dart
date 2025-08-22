import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Usuario {
  // ===== Campos de dominio =====
  final String uid;
  final String nombre;
  final String email;
  final String rol;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final bool emailVerificado;
  final bool activo;

  const Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.fechaCreacion,
    this.fechaActualizacion,
    required this.emailVerificado,
    required this.activo,
  });

  // ===== Utilidades de dominio =====
  static String normalizarEmail(String e) => e.trim().toLowerCase();

  Usuario copyWith({
    String? uid,
    String? nombre,
    String? email,
    String? rol,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? emailVerificado,
    bool? activo,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      activo: activo ?? this.activo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      if (fechaActualizacion != null)
        'fechaActualizacion': Timestamp.fromDate(fechaActualizacion!),
      'emailVerificado': emailVerificado,
      'activo': activo,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map, String id) {
    DateTime _toDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return Usuario(
      uid: id,
      nombre: (map['nombre'] ?? '').toString(),
      email: normalizarEmail(map['email'] ?? ''),
      rol: (map['rol'] ?? 'admin').toString(),
      fechaCreacion: _toDate(map['fechaCreacion']),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? _toDate(map['fechaActualizacion'])
          : null,
      emailVerificado: (map['emailVerificado'] ?? false) as bool,
      activo: (map['activo'] ?? true) as bool,
    );
  }

  // ====== Acceso a servicios (pediste métodos en el model) ======
  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // --- Obtener todos los usuarios (antes: getUsuarios) ---
  static Future<List<Usuario>> getUsuarios() async {
    try {
      print("🔄 Obteniendo usuarios...");
      final snapshot = await _db.collection('usuarios').orderBy('nombre').get();
      final usuarios = snapshot.docs
          .map((doc) => Usuario.fromMap(doc.data(), doc.id))
          .toList();
      print("✅ Usuarios obtenidos: ${usuarios.length}");
      return usuarios;
    } catch (e) {
      print("❌ Error al obtener usuarios: $e");
      rethrow;
    }
  }

  // --- Obtener usuario por ID (antes: getUsuarioById) ---
  static Future<Usuario?> getUsuarioById(String uid) async {
    try {
      print("🔄 Obteniendo usuario: $uid");
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final u = Usuario.fromMap(doc.data()!, doc.id);
        print("✅ Usuario encontrado: ${u.nombre}");
        return u;
      }
      print("⚠️ Usuario no encontrado: $uid");
      return null;
    } catch (e) {
      print("❌ Error al obtener usuario: $e");
      rethrow;
    }
  }

  // --- Agregar usuario (legacy) (antes: addUsuario) ---
  static Future<void> addUsuario(Usuario usuario) async {
    try {
      print("🔄 Agregando usuario (legacy): ${usuario.email}");
      await _db.collection('usuarios').doc(usuario.uid).set(usuario.toMap());
      print("✅ Usuario agregado: ${usuario.uid}");
    } catch (e) {
      print("❌ Error al agregar usuario: $e");
      rethrow;
    }
  }

  // --- Crear usuario con email/contraseña (antes: crearUsuarioConPassword) ---
  static Future<String> crearUsuarioConPassword({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    try {
      print("🔄 Creando usuario con auth: $email");

      // Validaciones mínimas
      if (nombre.trim().isEmpty)
        throw Exception("El nombre no puede estar vacío");
      if (email.trim().isEmpty)
        throw Exception("El email no puede estar vacío");
      if (!email.contains('@')) throw Exception("Email no válido");
      if (password.length < 6) {
        throw Exception("La contraseña debe tener al menos 6 caracteres");
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = cred.user;
      if (user == null)
        throw Exception("Error al crear usuario en Firebase Auth");

      // displayName
      await user.updateDisplayName(nombre);

      // Documento en Firestore
      final nuevo = Usuario(
        uid: user.uid,
        nombre: nombre.trim(),
        email: normalizarEmail(email),
        rol: rol,
        fechaCreacion: DateTime.now(),
        fechaActualizacion: null,
        emailVerificado: user.emailVerified,
        activo: true,
      );

      await _db.collection('usuarios').doc(user.uid).set(nuevo.toMap());
      print("✅ Usuario creado exitosamente: ${user.uid}");
      return user.uid;
    } catch (e) {
      print("❌ Error al crear usuario: $e");
      rethrow;
    }
  }

  // --- Actualizar usuario (antes: updateUsuario) ---
  static Future<void> updateUsuario(Usuario usuario) async {
    try {
      print("🔄 Actualizando usuario: ${usuario.uid}");

      final doc = await _db.collection('usuarios').doc(usuario.uid).get();
      if (!doc.exists) throw Exception("El usuario no existe en Firestore");

      final actualizado = usuario.copyWith(fechaActualizacion: DateTime.now());
      await _db
          .collection('usuarios')
          .doc(usuario.uid)
          .update(actualizado.toMap());

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

  // --- Eliminar usuario (antes: deleteUsuario) ---
  static Future<void> deleteUsuario(String uid) async {
    try {
      print("🔄 Eliminando usuario: $uid");
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (!doc.exists) throw Exception("El usuario no existe");
      await _db.collection('usuarios').doc(uid).delete();
      print("✅ Usuario eliminado de Firestore: $uid");
    } catch (e) {
      print("❌ Error al eliminar usuario: $e");
      rethrow;
    }
  }

  // --- Cambiar contraseña (antes: cambiarPassword) ---
  static Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("No hay usuario autenticado");

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: passwordActual,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(passwordNuevo);

      print("✅ Contraseña cambiada exitosamente");
    } catch (e) {
      print("❌ Error al cambiar contraseña: $e");
      rethrow;
    }
  }

  // --- Restablecer contraseña (antes: restablecerPassword) ---
  static Future<void> restablecerPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      print("✅ Email de restablecimiento enviado a: $email");
    } catch (e) {
      print("❌ Error al enviar email de restablecimiento: $e");
      rethrow;
    }
  }

  // --- Cambiar estado (antes: cambiarEstadoUsuario) ---
  static Future<void> cambiarEstadoUsuario(String uid, bool activo) async {
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

  // --- Verificar si email existe (antes: emailExiste) ---
  static Future<bool> emailExiste(String email) async {
    try {
      final query = await _db
          .collection('usuarios')
          .where('email', isEqualTo: normalizarEmail(email))
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      print("❌ Error al verificar email: $e");
      return false;
    }
  }

  // --- Stream de usuarios (antes: getUsuariosStream) ---
  static Stream<List<Usuario>> getUsuariosStream() {
    return _db.collection('usuarios').orderBy('nombre').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Usuario.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // --- Helper privado (antes: _getAuthUserById) ---
  static Future<User?> _getAuthUserById(String uid) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == uid) return currentUser;
      return null; // Desde cliente no se puede leer otros perfiles de Auth
    } catch (e) {
      print("❌ Error al obtener usuario de Auth: $e");
      return null;
    }
  }
}
