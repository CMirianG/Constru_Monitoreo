import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener datos de colmena
  Future<Map<String, dynamic>?> getColmenaById(String colmenaId) async {
    try {
      final doc = await _firestore.collection('colmenas').doc(colmenaId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Error al obtener colmena: $e');
    }
  }

  // Obtener historial de sensores
  Future<List<SensorData>> getSensorHistory(
    String colmenaId,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('sensores')
          .where('colmenaId', isEqualTo: colmenaId)
          .where('timestamp', isGreaterThanOrEqualTo: fechaInicio)
          .where('timestamp', isLessThanOrEqualTo: fechaFin)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => SensorData.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener historial de sensores: $e');
    }
  }

  // Obtener mantenimientos
  Future<List<MantenimientoRecord>> getMantenimientos(
    String colmenaId,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('mantenimientos')
          .where('colmenaId', isEqualTo: colmenaId)
          .where('fecha', isGreaterThanOrEqualTo: fechaInicio)
          .where('fecha', isLessThanOrEqualTo: fechaFin)
          .orderBy('fecha', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MantenimientoRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener mantenimientos: $e');
    }
  }

  // Obtener observaciones
  Future<List<ObservacionRecord>> getObservaciones(
    String colmenaId,
    DateTime fechaInicio,
    DateTime fechaFin,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('observaciones')
          .where('colmenaId', isEqualTo: colmenaId)
          .where('fecha', isGreaterThanOrEqualTo: fechaInicio)
          .where('fecha', isLessThanOrEqualTo: fechaFin)
          .orderBy('fecha', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ObservacionRecord.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener observaciones: $e');
    }
  }
}
