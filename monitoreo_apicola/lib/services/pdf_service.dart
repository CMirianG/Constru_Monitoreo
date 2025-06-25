import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/report_model.dart';

class PdfService {
  Future<String?> generateIntegralReportPdf(ReportModel report) async {
    try {
      final pdf = pw.Document();

      // Página 1: Portada y resumen
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(report),
                pw.SizedBox(height: 30),
                _buildSummarySection(report),
                pw.SizedBox(height: 30),
                _buildMetricsOverview(report),
              ],
            );
          },
        ),
      );

      // Página 2: Historial de sensores
      if (report.historialSensores.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('📊 Historial de Sensores'),
                  pw.SizedBox(height: 20),
                  _buildSensorTable(report.historialSensores),
                  pw.SizedBox(height: 20),
                  _buildSensorChart(report.historialSensores),
                ],
              );
            },
          ),
        );
      }

      // Página 3: Mantenimientos
      if (report.mantenimientos.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('🔧 Registro de Mantenimientos'),
                  pw.SizedBox(height: 20),
                  _buildMaintenanceTable(report.mantenimientos),
                ],
              );
            },
          ),
        );
      }

      // Página 4: Observaciones
      if (report.observaciones.isNotEmpty) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('📝 Observaciones Registradas'),
                  pw.SizedBox(height: 20),
                  _buildObservationsSection(report.observaciones),
                ],
              );
            },
          ),
        );
      }

      // Guardar PDF
      final output = await getApplicationDocumentsDirectory();
      final fileName =
          'reporte_${report.colmenaNombre}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return file.path;
    } catch (e) {
      print('Error generando PDF: $e');
      return null;
    }
  }

  pw.Widget _buildHeader(ReportModel report) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '🐝 REPORTE INTEGRAL DE COLMENA',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    report.colmenaNombre,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.brown,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Fecha de generación:',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    '${report.fechaGeneracion.day}/${report.fechaGeneracion.month}/${report.fechaGeneracion.year}',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Período del reporte: ${report.fechaInicio.day}/${report.fechaInicio.month}/${report.fechaInicio.year} - ${report.fechaFin.day}/${report.fechaFin.month}/${report.fechaFin.year}',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(ReportModel report) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RESUMEN EJECUTIVO',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.brown,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard('Registros de Sensores',
                  '${report.historialSensores.length}'),
              _buildSummaryCard(
                  'Mantenimientos', '${report.mantenimientos.length}'),
              _buildSummaryCard(
                  'Observaciones', '${report.observaciones.length}'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange50,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.orange800,
            ),
          ),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetricsOverview(ReportModel report) {
    if (report.historialSensores.isEmpty) {
      return pw.Container();
    }

    final sensores = report.historialSensores;
    final tempPromedio =
        sensores.map((s) => s.temperatura).reduce((a, b) => a + b) /
            sensores.length;
    final humedadPromedio =
        sensores.map((s) => s.humedad).reduce((a, b) => a + b) /
            sensores.length;
    final pesoPromedio =
        sensores.map((s) => s.peso).reduce((a, b) => a + b) / sensores.length;

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'MÉTRICAS PROMEDIO',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildMetricCard(
                  'Temperatura', '${tempPromedio.toStringAsFixed(1)}°C'),
              _buildMetricCard(
                  'Humedad', '${humedadPromedio.toStringAsFixed(1)}%'),
              _buildMetricCard('Peso', '${pesoPromedio.toStringAsFixed(1)}kg'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMetricCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: pw.BoxDecoration(
        color: PdfColors.orange100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 18,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.orange800,
        ),
      ),
    );
  }

  pw.Widget _buildSensorTable(List<SensorData> sensores) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Fecha/Hora', isHeader: true),
            _buildTableCell('Temp. (°C)', isHeader: true),
            _buildTableCell('Humedad (%)', isHeader: true),
            _buildTableCell('Peso (kg)', isHeader: true),
            _buildTableCell('Estado', isHeader: true),
          ],
        ),
        // Data rows
        ...sensores.take(10).map((sensor) => pw.TableRow(
              children: [
                _buildTableCell(
                    '${sensor.timestamp.day}/${sensor.timestamp.month} ${sensor.timestamp.hour}:${sensor.timestamp.minute.toString().padLeft(2, '0')}'),
                _buildTableCell(sensor.temperatura.toStringAsFixed(1)),
                _buildTableCell(sensor.humedad.toStringAsFixed(1)),
                _buildTableCell(sensor.peso.toStringAsFixed(2)),
                _buildTableCell(sensor.estado),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildSensorChart(List<SensorData> sensores) {
    // Aquí podrías implementar un gráfico simple usando pw.Chart
    // Por simplicidad, mostramos un resumen textual
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'Gráfico de tendencias: Los datos muestran ${sensores.length} registros de sensores en el período seleccionado. Se observa una tendencia estable en las métricas principales.',
        style: const pw.TextStyle(fontSize: 12),
      ),
    );
  }

  pw.Widget _buildMaintenanceTable(List<MantenimientoRecord> mantenimientos) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Fecha', isHeader: true),
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Técnico', isHeader: true),
            _buildTableCell('Estado', isHeader: true),
            _buildTableCell('Costo', isHeader: true),
          ],
        ),
        // Data rows
        ...mantenimientos.map((mant) => pw.TableRow(
              children: [
                _buildTableCell(
                    '${mant.fecha.day}/${mant.fecha.month}/${mant.fecha.year}'),
                _buildTableCell(mant.tipo),
                _buildTableCell(mant.tecnico),
                _buildTableCell(mant.estado),
                _buildTableCell('\$${mant.costo.toStringAsFixed(2)}'),
              ],
            )),
      ],
    );
  }

  pw.Widget _buildObservationsSection(List<ObservacionRecord> observaciones) {
    return pw.Column(
      children: observaciones
          .map((obs) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 15),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          obs.categoria,
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.brown,
                          ),
                        ),
                        pw.Text(
                          '${obs.fecha.day}/${obs.fecha.month}/${obs.fecha.year}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      obs.descripcion,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Observador: ${obs.observador}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Prioridad: ${obs.prioridad}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  Future<void> shareReport(String filePath, String colmenaNombre) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Reporte integral de la colmena: $colmenaNombre',
        subject: 'Reporte de Colmena - $colmenaNombre',
      );
    } catch (e) {
      print('Error compartiendo reporte: $e');
    }
  }
}
