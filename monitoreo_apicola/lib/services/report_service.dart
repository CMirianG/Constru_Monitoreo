import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reportes';

  // Guardar reporte en Firestore
  Future<void> saveReport(ReportModel report) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(report.id)
          .set(report.toJson());
    } catch (e) {
      throw Exception('Error al guardar reporte: $e');
    }
  }

  // Obtener reportes
  Future<List<ReportModel>> getReports({String? colmenaId}) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .orderBy('fechaGeneracion', descending: true);

      if (colmenaId != null) {
        query = query.where('colmenaId', isEqualTo: colmenaId);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map(
              (doc) => ReportModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener reportes: $e');
    }
  }

  // Eliminar reporte
  Future<void> deleteReport(String reportId) async {
    try {
      await _firestore.collection(_collection).doc(reportId).delete();
    } catch (e) {
      throw Exception('Error al eliminar reporte: $e');
    }
  }

  // Obtener reporte por ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(reportId).get();
      if (doc.exists) {
        return ReportModel.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener reporte: $e');
    }
  }
}
