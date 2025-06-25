import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/observacion_model.dart';

class ObservacionController {
  final CollectionReference _observacionesRef = FirebaseFirestore.instance
      .collection('observaciones');

  Future<List<Observacion>> getObservaciones() async {
    try {
      print("🔄 Obteniendo observaciones...");
      final snapshot =
          await _observacionesRef.orderBy('fecha', descending: true).get();
      print("✅ Observaciones obtenidas: ${snapshot.docs.length}");
      return snapshot.docs
          .map(
            (doc) =>
                Observacion.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print("⚠️ Error al obtener observaciones ordenadas: $e");
      try {
        // Intenta sin ordenar si falla el orderBy
        final snapshot = await _observacionesRef.get();
        return snapshot.docs
            .map(
              (doc) => Observacion.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
      } catch (e2) {
        print("❌ Error crítico al obtener observaciones: $e2");
        rethrow;
      }
    }
  }

  Future<String> addObservacion(Observacion observacion) async {
    try {
      print("🔄 Guardando observación: ${observacion.descripcion}");

      // Validaciones
      if (observacion.descripcion.trim().isEmpty) {
        throw Exception("La descripción no puede estar vacía");
      }

      final docRef = await _observacionesRef.add(observacion.toMap());
      print("✅ Observación guardada con ID: ${docRef.id}");
      return docRef.id;
    } catch (e) {
      print("❌ Error al agregar observación: $e");
      rethrow;
    }
  }

  Future<void> updateObservacion(Observacion observacion) async {
    try {
      print("🔄 Actualizando observación: ${observacion.id}");

      if (observacion.id.isEmpty) {
        throw Exception("ID de la observación no puede estar vacío");
      }

      if (observacion.descripcion.trim().isEmpty) {
        throw Exception("La descripción no puede estar vacía");
      }

      // Verificar que el documento existe
      final doc = await _observacionesRef.doc(observacion.id).get();
      if (!doc.exists) {
        throw Exception("La observación no existe");
      }

      await _observacionesRef.doc(observacion.id).update(observacion.toMap());
      print("✅ Observación actualizada: ${observacion.id}");
    } catch (e) {
      print("❌ Error al actualizar observación: $e");
      rethrow;
    }
  }

  Future<void> deleteObservacion(String id) async {
    try {
      print("🔄 Eliminando observación: $id");

      if (id.isEmpty) {
        throw Exception("ID de la observación no puede estar vacío");
      }

      // Verificar que el documento existe
      final doc = await _observacionesRef.doc(id).get();
      if (!doc.exists) {
        throw Exception("La observación no existe");
      }

      await _observacionesRef.doc(id).delete();
      print("✅ Observación eliminada: $id");
    } catch (e) {
      print("❌ Error al eliminar observación: $e");
      rethrow;
    }
  }

  // Método para verificar conectividad
  Future<bool> testConnection() async {
    try {
      await _observacionesRef.limit(1).get();
      return true;
    } catch (e) {
      print("❌ Error de conexión con Firestore: $e");
      return false;
    }
  }
}
