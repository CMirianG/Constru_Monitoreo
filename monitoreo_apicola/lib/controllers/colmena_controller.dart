import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/colmena_model.dart';

/// Controlador para RF-003: gestión de UNA sola colmena.
/// Mejora clave: usamos un ID fijo (docId = "colmena_unica") para evitar duplicados.
class ColmenaController {
  final _colRef = FirebaseFirestore.instance.collection('colmenas');
  static const String _docId = 'colmena_unica'; // ID determinístico

  /// Obtiene la colmena única (o null si no existe).
  Future<Colmena?> obtenerColmenaUnica() async {
    try {
      final doc = await _colRef.doc(_docId).get();
      if (!doc.exists || doc.data() == null) return null;
      return Colmena.fromMap(doc.data()!, doc.id);
    } catch (e) {
      // Puedes integrar tu logger aquí
      // debugPrint('obtenerColmenaUnica error: $e');
      rethrow;
    }
  }

  /// Escucha cambios en tiempo real de la colmena única.
  Stream<Colmena?> escucharColmenaUnica() {
    return _colRef.doc(_docId).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return Colmena.fromMap(snap.data()!, snap.id);
    });
  }

  /// Upsert: registra o actualiza la colmena única con merge.
  /// Añade updatedAt con timestamp del servidor.
  Future<void> registrarOActualizarColmena(Colmena colmena) async {
    if (!colmena.esValida()) {
      throw ArgumentError(
        'Datos incompletos: ubicacion/estado/descripcionTecnica son obligatorios.',
      );
    }
    try {
      await _colRef.doc(_docId).set(
        {
          ...colmena.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // debugPrint('registrarOActualizarColmena error: $e');
      rethrow;
    }
  }

  /// Actualización parcial y segura (solo ciertos campos).
  /// Útil cuando editas 1-2 valores desde la UI sin reconstruir el modelo completo.
  Future<void> actualizarParcial({
    String? ubicacion,
    String? estado,
    String? descripcionTecnica,
  }) async {
    final patch = <String, dynamic>{};
    if (ubicacion != null) patch['ubicacion'] = ubicacion.trim();
    if (estado != null) patch['estado'] = estado.trim();
    if (descripcionTecnica != null) {
      patch['descripcionTecnica'] = descripcionTecnica.trim();
    }
    if (patch.isEmpty) return;

    try {
      await _colRef.doc(_docId).set(
        {
          ...patch,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // debugPrint('actualizarParcial error: $e');
      rethrow;
    }
  }

  /// Elimina la colmena única si existe.
  Future<void> eliminarColmenaUnica() async {
    try {
      await _colRef.doc(_docId).delete();
    } catch (e) {
      // debugPrint('eliminarColmenaUnica error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Métodos legacy (compatibilidad). Si tu app migra totalmente a "una colmena",
  // puedes eliminarlos más adelante para simplificar el controlador.
  // ---------------------------------------------------------------------------

  Future<List<Colmena>> getColmenas() async {
    final snapshot = await _colRef.get();
    return snapshot.docs.map((d) => Colmena.fromMap(d.data(), d.id)).toList();
  }

  Future<void> addColmena(Colmena colmena) async {
    if (!colmena.esValida()) {
      throw ArgumentError('Datos de colmena incompletos.');
    }
    await _colRef.add({
      ...colmena.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateColmena(Colmena colmena) async {
    if (!colmena.esValida()) {
      throw ArgumentError('Datos de colmena incompletos.');
    }
    await _colRef.doc(colmena.id).update({
      ...colmena.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteColmena(String id) async {
    await _colRef.doc(id).delete();
  }
}
