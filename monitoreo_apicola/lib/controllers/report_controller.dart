import 'package:flutter/material.dart';
import '../models/report_model.dart';
import '../services/report_service.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';

class ReportController extends ChangeNotifier {
  final ReportService _reportService = ReportService();
  final FirestoreService _firestoreService = FirestoreService();
  final PdfService _pdfService = PdfService();

  bool _isLoading = false;
  String? _error;
  List<ReportModel> _reports = [];
  ReportModel? _currentReport;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ReportModel> get reports => _reports;
  ReportModel? get currentReport => _currentReport;

  // Generar reporte integral
  Future<String?> generateIntegralReport({
    required String colmenaId,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String tipoReporte = 'integral',
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Obtener datos de la colmena
      final colmenaData = await _firestoreService.getColmenaById(colmenaId);
      if (colmenaData == null) {
        throw Exception('Colmena no encontrada');
      }

      // Obtener historial de sensores
      final sensores = await _firestoreService.getSensorHistory(
        colmenaId,
        fechaInicio,
        fechaFin,
      );

      // Obtener mantenimientos
      final mantenimientos = await _firestoreService.getMantenimientos(
        colmenaId,
        fechaInicio,
        fechaFin,
      );

      // Obtener observaciones
      final observaciones = await _firestoreService.getObservaciones(
        colmenaId,
        fechaInicio,
        fechaFin,
      );

      // Crear modelo de reporte
      final report = ReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        colmenaId: colmenaId,
        colmenaNombre: colmenaData['nombre'] ?? 'Sin nombre',
        fechaGeneracion: DateTime.now(),
        historialSensores: sensores,
        mantenimientos: mantenimientos,
        observaciones: observaciones,
        tipoReporte: tipoReporte,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      _currentReport = report;

      // Generar PDF
      final pdfPath = await _pdfService.generateIntegralReportPdf(report);

      // Guardar reporte en Firestore
      await _reportService.saveReport(report);

      // Actualizar lista local
      _reports.insert(0, report);
      notifyListeners();

      return pdfPath;
    } catch (e) {
      _setError('Error al generar reporte: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Obtener reportes existentes
  Future<void> loadReports({String? colmenaId}) async {
    try {
      _setLoading(true);
      _clearError();

      _reports = await _reportService.getReports(colmenaId: colmenaId);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar reportes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Eliminar reporte
  Future<bool> deleteReport(String reportId) async {
    try {
      _setLoading(true);
      _clearError();

      await _reportService.deleteReport(reportId);
      _reports.removeWhere((report) => report.id == reportId);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Error al eliminar reporte: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Compartir reporte
  Future<bool> shareReport(String reportId) async {
    try {
      final report = _reports.firstWhere((r) => r.id == reportId);
      final pdfPath = await _pdfService.generateIntegralReportPdf(report);

      if (pdfPath != null) {
        await _pdfService.shareReport(pdfPath, report.colmenaNombre);
        return true;
      }
      return false;
    } catch (e) {
      _setError('Error al compartir reporte: ${e.toString()}');
      return false;
    }
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
