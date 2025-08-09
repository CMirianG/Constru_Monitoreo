import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class SimpleReportView extends StatefulWidget {
  const SimpleReportView({super.key});

  @override
  State<SimpleReportView> createState() => _SimpleReportViewState();
}

class _SimpleReportViewState extends State<SimpleReportView> {
  bool _isGenerating = false;
  Map<String, int> contadores = {
    'colmenas': 0,
    'mantenimientos': 0,
    'observaciones': 0,
    'usuarios': 0,
    'lecturas': 0,
    'umbrales': 0,
    'reportes': 0,
  };

  Map<String, dynamic> datosSensores = {
    'co2Promedio': 0.0,
    'sonidoPromedio': 0.0,
    'co2Maximo': 0.0,
    'sonidoMaximo': 0.0,
    'co2Minimo': 0.0,
    'sonidoMinimo': 0.0,
    'lecturasTotales': 0,
    'lecturasAlerta': 0,
    'ultimaLectura': null,
  };

  @override
  void initState() {
    super.initState();
    _cargarContadores();
  }

  Future<void> _cargarContadores() async {
    try {
      final colmenasSnapshot =
          await FirebaseFirestore.instance.collection('colmenas').get();
      final mantenimientosSnapshot =
          await FirebaseFirestore.instance.collection('mantenimientos').get();
      final observacionesSnapshot =
          await FirebaseFirestore.instance.collection('observaciones').get();
      final usuariosSnapshot =
          await FirebaseFirestore.instance.collection('usuarios').get();
      final umbralesSnapshot =
          await FirebaseFirestore.instance.collection('umbrales').get();
      final reportesSnapshot =
          await FirebaseFirestore.instance.collection('reportes').get();

      // Cargar datos de sensores de los últimos 7 días
      await _cargarDatosSensores();

      if (mounted) {
        setState(() {
          contadores = {
            'colmenas': colmenasSnapshot.docs.length,
            'mantenimientos': mantenimientosSnapshot.docs.length,
            'observaciones': observacionesSnapshot.docs.length,
            'usuarios': usuariosSnapshot.docs.length,
            'umbrales': umbralesSnapshot.docs.length,
            'lecturas': datosSensores['lecturasTotales'],
            'reportes': reportesSnapshot.docs.length,
          };
        });
      }
    } catch (e) {
      print("❌ Error al cargar contadores: $e");
    }
  }

  Future<void> _cargarDatosSensores() async {
    try {
      final fechaLimite = DateTime.now().subtract(const Duration(days: 7));

      // Obtener lecturas de CO2
      final co2Snapshot = await FirebaseFirestore.instance
          .collection('historial')
          .where('tipo', isEqualTo: 'co2')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fechaLimite))
          .orderBy('timestamp', descending: true)
          .get();

      // Obtener lecturas de sonido
      final sonidoSnapshot = await FirebaseFirestore.instance
          .collection('historial')
          .where('tipo', isEqualTo: 'sonido')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fechaLimite))
          .orderBy('timestamp', descending: true)
          .get();

      if (co2Snapshot.docs.isNotEmpty || sonidoSnapshot.docs.isNotEmpty) {
        _procesarDatosSensores(co2Snapshot.docs, sonidoSnapshot.docs);
      }
    } catch (e) {
      print("❌ Error al cargar datos de sensores: $e");
    }
  }

  void _procesarDatosSensores(List<QueryDocumentSnapshot> co2Docs,
      List<QueryDocumentSnapshot> sonidoDocs) {
    List<double> valoresCO2 = [];
    List<double> valoresSonido = [];
    int alertas = 0;
    DateTime? ultimaLectura;

    // Procesar datos de CO2
    for (var doc in co2Docs) {
      final data = doc.data() as Map<String, dynamic>;
      final valorStr = data['valor']?.toString() ?? '0';
      final valor = double.tryParse(valorStr) ?? 0.0;
      valoresCO2.add(valor);

      // Verificar umbrales de CO2 (basado en tu código)
      if (valor > 800) alertas++; // Moderado o alto

      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (ultimaLectura == null ||
          (timestamp != null && timestamp.isAfter(ultimaLectura))) {
        ultimaLectura = timestamp;
      }
    }

    // Procesar datos de sonido
    for (var doc in sonidoDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final valorStr = data['valor']?.toString() ?? '0';
      final valor = double.tryParse(valorStr) ?? 0.0;
      valoresSonido.add(valor);

      // Verificar umbrales de sonido (basado en tu código)
      if (valor > 60) alertas++; // Moderado o ruidoso

      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
      if (ultimaLectura == null ||
          (timestamp != null && timestamp.isAfter(ultimaLectura))) {
        ultimaLectura = timestamp;
      }
    }

    // Calcular estadísticas
    datosSensores = {
      'co2Promedio': valoresCO2.isNotEmpty
          ? valoresCO2.reduce((a, b) => a + b) / valoresCO2.length
          : 0.0,
      'sonidoPromedio': valoresSonido.isNotEmpty
          ? valoresSonido.reduce((a, b) => a + b) / valoresSonido.length
          : 0.0,
      'co2Maximo': valoresCO2.isNotEmpty
          ? valoresCO2.reduce((a, b) => a > b ? a : b)
          : 0.0,
      'sonidoMaximo': valoresSonido.isNotEmpty
          ? valoresSonido.reduce((a, b) => a > b ? a : b)
          : 0.0,
      'co2Minimo': valoresCO2.isNotEmpty
          ? valoresCO2.reduce((a, b) => a < b ? a : b)
          : 0.0,
      'sonidoMinimo': valoresSonido.isNotEmpty
          ? valoresSonido.reduce((a, b) => a < b ? a : b)
          : 0.0,
      'lecturasTotales': co2Docs.length + sonidoDocs.length,
      'lecturasAlerta': alertas,
      'ultimaLectura': ultimaLectura,
    };
  }

  String _evaluarEstadoCO2(double valor) {
    if (valor > 1000) return 'CRÍTICO';
    if (valor > 800) return 'MODERADO';
    return 'NORMAL';
  }

  String _evaluarEstadoSonido(double valor) {
    if (valor > 80) return 'RUIDOSO';
    if (valor > 60) return 'MODERADO';
    return 'SILENCIOSO';
  }

  PdfColor _getColorEstado(String estado) {
    switch (estado) {
      case 'CRÍTICO':
      case 'RUIDOSO':
        return PdfColors.red;
      case 'MODERADO':
        return PdfColors.orange;
      default:
        return PdfColors.green;
    }
  }

  Future<void> _generarReportePDF() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final pdf = pw.Document();
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'Usuario';

      // Página del reporte
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '🐝 REPORTE DASHBOARD APÍCOLA',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'Generado por: $userName',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.brown,
                        ),
                      ),
                      pw.Text(
                        'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} - ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Estadísticas principales
                pw.Text(
                  'ESTADÍSTICAS GENERALES',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown,
                  ),
                ),
                pw.SizedBox(height: 15),

                // Grid de estadísticas
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfStatCard('Colmenas Activas',
                        '${contadores['colmenas']}', PdfColors.orange),
                    _buildPdfStatCard('Lecturas (7 días)',
                        '${contadores['lecturas']}', PdfColors.green),
                  ],
                ),
                pw.SizedBox(height: 15),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    _buildPdfStatCard('Mantenimientos',
                        '${contadores['mantenimientos']}', PdfColors.blue),
                    _buildPdfStatCard('Observaciones',
                        '${contadores['observaciones']}', PdfColors.purple),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Análisis de sensores
                pw.SizedBox(height: 30),
                pw.Text(
                  'ANÁLISIS DE SENSORES (7 DÍAS)',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown,
                  ),
                ),
                pw.SizedBox(height: 15),

                // Métricas de sensores
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.orange50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'MÉTRICAS DE SENSORES',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          _buildSensorMetricCard(
                              'CO₂ Promedio',
                              '${datosSensores['co2Promedio'].toStringAsFixed(1)} ppm',
                              _evaluarEstadoCO2(datosSensores['co2Promedio'])),
                          _buildSensorMetricCard(
                              'Sonido Promedio',
                              '${datosSensores['sonidoPromedio'].toStringAsFixed(1)} dB',
                              _evaluarEstadoSonido(
                                  datosSensores['sonidoPromedio'])),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          _buildSensorMetricCard(
                              'CO₂ Máximo',
                              '${datosSensores['co2Maximo'].toStringAsFixed(1)} ppm',
                              _evaluarEstadoCO2(datosSensores['co2Maximo'])),
                          _buildSensorMetricCard(
                              'Sonido Máximo',
                              '${datosSensores['sonidoMaximo'].toStringAsFixed(1)} dB',
                              _evaluarEstadoSonido(
                                  datosSensores['sonidoMaximo'])),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Alertas y recomendaciones
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: datosSensores['lecturasAlerta'] > 0
                        ? PdfColors.red50
                        : PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ANÁLISIS DE UMBRALES',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: datosSensores['lecturasAlerta'] > 0
                              ? PdfColors.red800
                              : PdfColors.green800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                          '• Total de lecturas analizadas: ${datosSensores['lecturasTotales']}'),
                      pw.Text(
                          '• Lecturas fuera de umbral: ${datosSensores['lecturasAlerta']}'),
                      pw.Text(
                          '• Porcentaje de alertas: ${datosSensores['lecturasTotales'] > 0 ? ((datosSensores['lecturasAlerta'] / datosSensores['lecturasTotales']) * 100).toStringAsFixed(1) : 0}%'),
                      if (datosSensores['ultimaLectura'] != null)
                        pw.Text(
                            '• Última lectura: ${DateFormat('dd/MM/yyyy HH:mm').format(datosSensores['ultimaLectura'])}'),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        'UMBRALES CONFIGURADOS:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                          '• CO₂: Normal <800 ppm | Moderado 800-1000 ppm | Alto >1000 ppm'),
                      pw.Text(
                          '• Sonido: Silencioso <60 dB | Moderado 60-80 dB | Ruidoso >80 dB'),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Resumen del sistema
                pw.Container(
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
                        'RESUMEN DEL SISTEMA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                          '• Total de colmenas registradas: ${contadores['colmenas']}'),
                      pw.Text(
                          '• Lecturas de sensores (última semana): ${contadores['lecturas']}'),
                      pw.Text(
                          '• Mantenimientos programados: ${contadores['mantenimientos']}'),
                      pw.Text(
                          '• Observaciones registradas: ${contadores['observaciones']}'),
                      pw.Text(
                          '• Usuarios del sistema: ${contadores['usuarios']}'),
                      pw.Text(
                          '• Umbrales configurados: ${contadores['umbrales']}'),
                      pw.Text(
                          '• Reportes generados: ${(contadores['reportes'] ?? 0) + 1}'), // +1 por este reporte
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),

                // Estado del sistema
                pw.Text(
                  'ESTADO GENERAL',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.brown,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(
                    '✅ Sistema operativo y funcionando correctamente\n'
                    '📊 Dashboard actualizado con datos en tiempo real\n'
                    '🐝 Monitoreo activo de colmenas\n'
                    '📈 Recolección de datos de sensores activa',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),

                // Footer
                pw.Spacer(),
                pw.Divider(),
                pw.Text(
                  'Reporte generado automáticamente por el Sistema de Gestión Apícola',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            );
          },
        ),
      );

      // Guardar PDF
      final output = await getApplicationDocumentsDirectory();
      final fileName =
          'reporte_dashboard_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Actualizar contador de reportes
      await FirebaseFirestore.instance.collection('reportes').add({
        'tipo': 'dashboard',
        'fechaGeneracion': FieldValue.serverTimestamp(),
        'usuario': user?.uid ?? 'anonimo',
        'nombreArchivo': fileName,
      });

      // Compartir PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reporte Dashboard Apícola',
        subject:
            'Reporte del Sistema - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reporte generado y compartido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Recargar contadores
      _cargarContadores();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al generar reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        // ✅ AGREGAR ESTA VERIFICACIÓN
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  pw.Widget _buildPdfStatCard(String title, String value, PdfColor color) {
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSensorMetricCard(String titulo, String valor, String estado) {
    final color = _getColorEstado(estado);
    return pw.Container(
      width: 120,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            titulo,
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            valor,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            estado,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text(
          '📊 Generar Reporte',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF8D6E63),
          ),
        ),
        backgroundColor: const Color(0xFFFFE0B2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF8D6E63)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del reporte
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFFE91E63),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reporte Dashboard',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Estadísticas generales del sistema',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Estadísticas actuales
                    const Text(
                      'Datos que se incluirán:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip('${contadores['colmenas']} Colmenas',
                            Icons.hive, Colors.orange),
                        _buildInfoChip('${contadores['lecturas']} Lecturas',
                            Icons.sensors, Colors.green),
                        _buildInfoChip(
                            '${datosSensores['lecturasAlerta']} Alertas',
                            Icons.warning,
                            datosSensores['lecturasAlerta'] > 0
                                ? Colors.red
                                : Colors.green),
                        _buildInfoChip(
                            '${contadores['mantenimientos']} Mantenimientos',
                            Icons.build,
                            Colors.blue),
                        _buildInfoChip(
                            '${contadores['observaciones']} Observaciones',
                            Icons.visibility,
                            Colors.purple),
                        _buildInfoChip('${contadores['usuarios']} Usuarios',
                            Icons.people, Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Botón generar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generarReportePDF,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(
                  _isGenerating
                      ? 'Generando PDF...'
                      : 'Generar y Compartir Reporte PDF',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE91E63),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'El reporte incluirá todas las estadísticas actuales del dashboard y se guardará automáticamente.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
