import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/mantenimiento_model.dart';

class MantenimientoController {
  final _ref = FirebaseFirestore.instance.collection('mantenimientos');

  Future<List<Mantenimiento>> getMantenimientos() async {
    try {
      final snapshot = await _ref.orderBy('fecha', descending: true).get();
      return snapshot.docs
          .map((doc) => Mantenimiento.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print("⚠️ Error al obtener mantenimientos ordenados: $e");
      try {
        final snapshot = await _ref.get(); // Recupera sin ordenar
        return snapshot.docs
            .map((doc) => Mantenimiento.fromMap(doc.data(), doc.id))
            .toList();
      } catch (e2) {
        print("❌ Error al obtener mantenimientos: $e2");
        return []; // Retorna lista vacía en caso de error
      }
    }
  }

  Future<bool> addMantenimiento(Mantenimiento m) async {
    try {
      await _ref.add(m.toMap());
      return true;
    } catch (e) {
      print("❌ Error al agregar mantenimiento: $e");
      return false;
    }
  }

  Future<bool> updateMantenimiento(Mantenimiento m) async {
    try {
      await _ref.doc(m.id).update(m.toMap());
      return true;
    } catch (e) {
      print("❌ Error al actualizar mantenimiento: $e");
      return false;
    }
  }

  Future<bool> deleteMantenimiento(String id) async {
    try {
      await _ref.doc(id).delete();
      return true;
    } catch (e) {
      print("❌ Error al eliminar mantenimiento: $e");
      return false;
    }
  }
}
