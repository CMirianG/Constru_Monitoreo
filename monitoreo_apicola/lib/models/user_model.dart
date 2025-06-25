import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String uid;
  final String nombre;
  final String email;
  final String rol;
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final bool activo;
  final bool emailVerificado;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.email,
    required this.rol,
    DateTime? fechaCreacion,
    this.fechaActualizacion,
    this.activo = true,
    this.emailVerificado = false,
  }) : fechaCreacion = fechaCreacion ?? DateTime.now();

  factory Usuario.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime fechaCreacion;
    DateTime? fechaActualizacion;

    try {
      if (data['fechaCreacion'] is Timestamp) {
        fechaCreacion = (data['fechaCreacion'] as Timestamp).toDate();
      } else {
        fechaCreacion = DateTime.now();
      }

      if (data['fechaActualizacion'] is Timestamp) {
        fechaActualizacion = (data['fechaActualizacion'] as Timestamp).toDate();
      }
    } catch (e) {
      fechaCreacion = DateTime.now();
      fechaActualizacion = null;
    }

    return Usuario(
      uid: documentId,
      nombre: data['nombre']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      rol: data['rol']?.toString() ?? 'usuario',
      fechaCreacion: fechaCreacion,
      fechaActualizacion: fechaActualizacion,
      activo: data['activo'] ?? true,
      emailVerificado: data['emailVerificado'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email.toLowerCase(),
      'rol': rol.toLowerCase(),
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
      'fechaActualizacion':
          fechaActualizacion != null
              ? Timestamp.fromDate(fechaActualizacion!)
              : null,
      'activo': activo,
      'emailVerificado': emailVerificado,
    };
  }

  Usuario copyWith({
    String? uid,
    String? nombre,
    String? email,
    String? rol,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? activo,
    bool? emailVerificado,
  }) {
    return Usuario(
      uid: uid ?? this.uid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      activo: activo ?? this.activo,
      emailVerificado: emailVerificado ?? this.emailVerificado,
    );
  }

  bool get esAdmin => rol.toLowerCase() == 'admin';
  bool get esSuperAdmin => rol.toLowerCase() == 'superadmin';

  @override
  String toString() {
    return 'Usuario{uid: $uid, nombre: $nombre, email: $email, rol: $rol}';
  }
}
