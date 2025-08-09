import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/colmena_model.dart';

/// Controlador para RF-003: Gestión de Colmena (una sola colmena).
/// - Evita duplicados usando `limit(1)`
/// - Upsert (registrar o actualizar) con SetOptions(merge: true)
/// - Validación con `esValida()`
/// - Métodos con manejo de errores y logs controlados
class ColmenaController {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('colmenas');

  /// Obtiene la ÚNICA colmena registrada (o null si no existe).
  Future<Colmena?> obtenerColmenaUnica() async {
    try {
      final snapshot = await _ref.limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Colmena.fromMap(doc.data(), doc.id);
    } catch (e) {
      // Puedes reemplazar por tu sistema de logging
      print('[ColmenaController] Error obtenerColmenaUnica: $e');
      rethrow;
    }
  }

  /// Escucha cambios en tiempo real de la ÚNICA colmena.
  Stream<Colmena?> escucharColmenaUnica() {
    return _ref.limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      final d = snap.docs.first;
      return Colmena.fromMap(d.data(), d.id);
    });
  }

  /// Registra o actualiza la colmena (upsert).
  /// - Si existe: actualiza con merge.
  /// - Si no existe: crea nueva.
  Future<void> registrarOActualizarColmena(Colmena colmena) async {
    // Validación de dominio antes de persistir
    if (!colmena.esValida()) {
      throw ArgumentError(
          'Datos de colmena incompletos: ubicacion/estado/descripcionTecnica son obligatorios.');
    }

    try {
      final existing = await _ref.limit(1).get();

      if (existing.docs.isNotEmpty) {
        // Actualizar doc existente (id tomado del primer documento)
        final docId = existing.docs.first.id;
        await _ref.doc(docId).set(colmena.toMap(), SetOptions(merge: true));
      } else {
        // Crear nueva colmena
        await _ref.add(colmena.toMap());
      }
    } catch (e) {
      print('[ColmenaController] Error registrarOActualizarColmena: $e');
      rethrow;
    }
  }

  /// Elimina la colmena única si existe.
  Future<void> eliminarColmenaUnica() async {
    try {
      final snapshot = await _ref.limit(1).get();
      if (snapshot.docs.isEmpty) return;
      await _ref.doc(snapshot.docs.first.id).delete();
    } catch (e) {
      print('[ColmenaController] Error eliminarColmenaUnica: $e');
      rethrow;
    }
  }

  // --- (Opcionales) métodos legacy protegidos para no romper otras partes ---

  /// No recomendado en RF-003 (se conserva para compatibilidad).
  Future<List<Colmena>> getColmenas() async {
    final snapshot = await _ref.get();
    return snapshot.docs
        .map((doc) => Colmena.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// No recomendado: puede generar duplicados. Prefiere `registrarOActualizarColmena`.
  Future<void> addColmena(Colmena colmena) async {
    if (!colmena.esValida()) {
      throw ArgumentError('Datos de colmena incompletos.');
    }
    await _ref.add(colmena.toMap());
  }

  /// No recomendado: requiere conocer el ID. Prefiere `registrarOActualizarColmena`.
  Future<void> updateColmena(Colmena colmena) async {
    if (!colmena.esValida()) {
      throw ArgumentError('Datos de colmena incompletos.');
    }
    await _ref.doc(colmena.id).update(colmena.toMap());
  }

  /// No recomendado: requiere ID específico. Prefiere `eliminarColmenaUnica()`.
  Future<void> deleteColmena(String id) async {
    await _ref.doc(id).delete();
  }
}
