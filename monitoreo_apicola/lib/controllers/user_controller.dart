// lib/controllers/user_controller.dart
import '../models/user_model.dart';

/// Controller delgado que delega toda la lógica al modelo `Usuario`.
/// Esto te permite no cambiar las vistas: los nombres de métodos
/// se mantienen iguales a tu implementación original.
class UserController {
  // --- Lecturas ---
  Future<List<Usuario>> getUsuarios() => Usuario.getUsuarios();

  Future<Usuario?> getUsuarioById(String uid) => Usuario.getUsuarioById(uid);

  Stream<List<Usuario>> getUsuariosStream() => Usuario.getUsuariosStream();

  // --- Crear (legacy) ---
  Future<void> addUsuario(Usuario usuario) => Usuario.addUsuario(usuario);

  // --- Crear con Auth recomendado ---
  Future<String> crearUsuarioConPassword({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) =>
      Usuario.crearUsuarioConPassword(
        nombre: nombre,
        email: email,
        password: password,
        rol: rol,
      );

  // --- Actualizar ---
  Future<void> updateUsuario(Usuario usuario) => Usuario.updateUsuario(usuario);

  // --- Eliminar ---
  Future<void> deleteUsuario(String uid) => Usuario.deleteUsuario(uid);

  // --- Seguridad ---
  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) =>
      Usuario.cambiarPassword(
        passwordActual: passwordActual,
        passwordNuevo: passwordNuevo,
      );

  Future<void> restablecerPassword(String email) =>
      Usuario.restablecerPassword(email);

  // --- Estado / utilidades ---
  Future<void> cambiarEstadoUsuario(String uid, bool activo) =>
      Usuario.cambiarEstadoUsuario(uid, activo);

  Future<bool> emailExiste(String email) => Usuario.emailExiste(email);
}
