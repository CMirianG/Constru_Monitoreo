import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/umbral_controller.dart';
import '../models/umbral_model.dart';

class PanelEstadoView extends StatefulWidget {
  const PanelEstadoView({super.key});

  @override
  State<PanelEstadoView> createState() => _PanelEstadoViewState();
}

class _PanelEstadoViewState extends State<PanelEstadoView> {
  final UmbralController _umbralController = UmbralController();

  bool cargando = true;
  List<QueryDocumentSnapshot> todasLasLecturas = [];
  Map<String, List<QueryDocumentSnapshot>> lecturasPorTipo = {};
  Map<String, int> estadisticas = {};
  List<Map<String, dynamic>> alertas = [];
  Map<String, Umbral> umbrales = {};

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    try {
      print("🔄 Cargando datos del historial y umbrales...");

      // Cargar umbrales primero
      await _cargarUmbrales();

      // Luego cargar lecturas
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('historial')
          .orderBy('timestamp', descending: true)
          .limit(200)
          .get();

      print("📊 Total de documentos obtenidos: ${snapshot.docs.length}");

      todasLasLecturas = snapshot.docs;
      _procesarDatos();
      _generarAlertasConUmbrales();

      setState(() {
        cargando = false;
      });

      print("✅ Datos cargados exitosamente");
      print("📈 Estadísticas: $estadisticas");
      print("🚨 Alertas generadas: ${alertas.length}");
    } catch (e) {
      print("❌ Error al cargar datos: $e");
      setState(() {
        cargando = false;
      });
    }
  }

  Future<void> _cargarUmbrales() async {
    try {
      final sensores = ['co2', 'sonido', 'temperatura', 'humedad'];

      for (String sensor in sensores) {
        final umbral = await _umbralController.obtenerUmbral(sensor);
        if (umbral != null) {
          umbrales[sensor] = umbral;
        } else {
          // Valores por defecto si no hay umbrales configurados
          umbrales[sensor] = Umbral(
            tipoSensor: sensor,
            minimo: _getValorDefectoMinimo(sensor),
            maximo: _getValorDefectoMaximo(sensor),
          );
        }
      }

      print("🎯 Umbrales cargados: ${umbrales.keys.toList()}");
    } catch (e) {
      print("❌ Error al cargar umbrales: $e");
    }
  }

  double _getValorDefectoMinimo(String sensor) {
    switch (sensor) {
      case 'co2':
        return 300.0;
      case 'sonido':
        return 30.0;
      case 'temperatura':
        return 15.0;
      case 'humedad':
        return 40.0;
      default:
        return 0.0;
    }
  }

  double _getValorDefectoMaximo(String sensor) {
    switch (sensor) {
      case 'co2':
        return 1000.0;
      case 'sonido':
        return 80.0;
      case 'temperatura':
        return 35.0;
      case 'humedad':
        return 70.0;
      default:
        return 100.0;
    }
  }

  void _procesarDatos() {
    lecturasPorTipo.clear();
    estadisticas.clear();

    for (final doc in todasLasLecturas) {
      final data = doc.data() as Map<String, dynamic>;
      final tipo = (data['tipo'] ?? 'desconocido').toString().toLowerCase();

      lecturasPorTipo.putIfAbsent(tipo, () => []).add(doc);
      estadisticas[tipo] = (estadisticas[tipo] ?? 0) + 1;
    }
  }

  void _generarAlertasConUmbrales() {
    alertas.clear();

    for (String tipoSensor in umbrales.keys) {
      if (lecturasPorTipo.containsKey(tipoSensor) &&
          lecturasPorTipo[tipoSensor]!.isNotEmpty) {
        final ultimaLectura = lecturasPorTipo[tipoSensor]!.first;
        final data = ultimaLectura.data() as Map<String, dynamic>;
        final valor = double.tryParse(data['valor'].toString()) ?? 0;
        final umbral = umbrales[tipoSensor]!;
        final timestamp = data['timestamp'] as Timestamp?;
        final fecha = timestamp?.toDate() ?? DateTime.now();

        // Verificar si está fuera del rango
        if (valor < umbral.minimo) {
          alertas.add({
            'tipo': 'BAJO',
            'sensor': tipoSensor,
            'valor': valor,
            'umbral': umbral.minimo,
            'mensaje':
                '📉 ${tipoSensor.toUpperCase()}: Valor bajo (${valor.toStringAsFixed(1)} < ${umbral.minimo})',
            'color': Colors.blue,
            'icono': Icons.trending_down,
            'fecha': fecha,
            'severidad': 'media',
          });
        } else if (valor > umbral.maximo) {
          alertas.add({
            'tipo': 'ALTO',
            'sensor': tipoSensor,
            'valor': valor,
            'umbral': umbral.maximo,
            'mensaje':
                '📈 ${tipoSensor.toUpperCase()}: Valor alto (${valor.toStringAsFixed(1)} > ${umbral.maximo})',
            'color': Colors.red,
            'icono': Icons.trending_up,
            'fecha': fecha,
            'severidad': 'alta',
          });
        }
      }
    }

    // Verificar lecturas recientes
    if (todasLasLecturas.isNotEmpty) {
      final ultimaLectura = todasLasLecturas.first;
      final data = ultimaLectura.data() as Map<String, dynamic>;
      final timestamp = data['timestamp'] as Timestamp?;

      if (timestamp != null) {
        final fecha = timestamp.toDate();
        final diferencia = DateTime.now().difference(fecha);

        if (diferencia.inHours > 2) {
          alertas.add({
            'tipo': 'TIEMPO',
            'sensor': 'sistema',
            'valor': diferencia.inHours,
            'mensaje': '⏰ Sin lecturas recientes (${diferencia.inHours}h)',
            'color': Colors.orange,
            'icono': Icons.access_time,
            'fecha': fecha,
            'severidad': 'media',
          });
        }
      }
    }

    // Ordenar alertas por severidad
    alertas.sort((a, b) {
      final severidadA =
          a['severidad'] == 'alta' ? 3 : (a['severidad'] == 'media' ? 2 : 1);
      final severidadB =
          b['severidad'] == 'alta' ? 3 : (b['severidad'] == 'media' ? 2 : 1);
      return severidadB.compareTo(severidadA);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('🔍 Panel de Estado'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                cargando = true;
              });
              cargarDatos();
            },
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/umbrales');
            },
            tooltip: 'Configurar umbrales',
          ),
        ],
      ),
      body: cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  SizedBox(height: 16),
                  Text('Cargando estado del sistema...'),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: cargarDatos,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildEstadoGeneral(),
                    const SizedBox(height: 24),
                    _buildEstadisticasRapidas(),
                    const SizedBox(height: 24),
                    _buildEstadoAlertas(),
                    const SizedBox(height: 24),
                    _buildGraficosCO2(),
                    const SizedBox(height: 24),
                    _buildGraficosSonido(),
                    const SizedBox(height: 24),
                    _buildUltimasLecturas(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEstadoGeneral() {
    final alertasAltas = alertas.where((a) => a['severidad'] == 'alta').length;
    final sistemaOK = alertasAltas == 0 && todasLasLecturas.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sistemaOK
              ? [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]
              : alertasAltas > 0
                  ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
                  : [const Color(0xFFFF9800), const Color(0xFFFFB74D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (sistemaOK
                    ? Colors.green
                    : alertasAltas > 0
                        ? Colors.red
                        : Colors.orange)
                .withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            sistemaOK
                ? Icons.check_circle
                : alertasAltas > 0
                    ? Icons.error
                    : Icons.warning,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            sistemaOK
                ? 'Sistema Operativo'
                : alertasAltas > 0
                    ? 'Alertas Críticas'
                    : 'Alertas Menores',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sistemaOK
                ? 'Todos los sensores dentro de rangos normales'
                : '${alertas.length} alerta(s) activa(s) - ${alertasAltas} crítica(s)',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasRapidas() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: Color(0xFF4CAF50)),
              SizedBox(width: 12),
              Text(
                'Estadísticas Rápidas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildEstadistica('Total', todasLasLecturas.length.toString(),
                  Icons.sensors, Colors.blue),
              _buildEstadistica('CO2', (estadisticas['co2'] ?? 0).toString(),
                  Icons.cloud, Colors.green),
              _buildEstadistica(
                  'Sonido',
                  (estadisticas['sonido'] ?? 0).toString(),
                  Icons.graphic_eq,
                  Colors.orange),
              _buildEstadistica('Alertas', alertas.length.toString(),
                  Icons.warning, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadistica(
      String titulo, String valor, IconData icono, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoAlertas() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications,
                color: alertas.isEmpty ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 12),
              Text(
                alertas.isEmpty
                    ? 'Sin Alertas Activas'
                    : 'Alertas del Sistema (${alertas.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (alertas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Todos los parámetros están dentro de los umbrales configurados',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else
            ...alertas.take(5).map((alerta) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (alerta['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (alerta['color'] as Color).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: alerta['color'],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          alerta['icono'],
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alerta['mensaje'],
                              style: TextStyle(
                                color: alerta['color'],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (alerta['fecha'] != null)
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(alerta['fecha']),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: alerta['color'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alerta['severidad'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }

  Widget _buildGraficosCO2() {
    if (!lecturasPorTipo.containsKey('co2') ||
        lecturasPorTipo['co2']!.isEmpty) {
      return _buildSeccionVacia(
          '📊 Gráfico CO2', 'No hay datos de CO2 disponibles');
    }

    final lecturasCO2 = lecturasPorTipo['co2']!.take(20).toList();
    final spots = <FlSpot>[];

    for (int i = 0; i < lecturasCO2.length; i++) {
      final data = lecturasCO2[i].data() as Map<String, dynamic>;
      final valor = double.tryParse(data['valor'].toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), valor));
    }

    return _buildSeccionGrafico(
      titulo: '📊 Niveles de CO2',
      subtitulo: '${lecturasCO2.length} lecturas recientes',
      color: Colors.green,
      spots: spots,
      unidad: 'ppm',
      umbral: umbrales['co2'],
    );
  }

  Widget _buildGraficosSonido() {
    if (!lecturasPorTipo.containsKey('sonido') ||
        lecturasPorTipo['sonido']!.isEmpty) {
      return _buildSeccionVacia(
          '🔊 Gráfico Sonido', 'No hay datos de sonido disponibles');
    }

    final lecturasSonido = lecturasPorTipo['sonido']!.take(20).toList();
    final spots = <FlSpot>[];

    for (int i = 0; i < lecturasSonido.length; i++) {
      final data = lecturasSonido[i].data() as Map<String, dynamic>;
      final valor = double.tryParse(data['valor'].toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), valor));
    }

    return _buildSeccionGrafico(
      titulo: '🔊 Niveles de Sonido',
      subtitulo: '${lecturasSonido.length} lecturas recientes',
      color: Colors.orange,
      spots: spots,
      unidad: 'dB',
      umbral: umbrales['sonido'],
    );
  }

  Widget _buildSeccionGrafico({
    required String titulo,
    required String subtitulo,
    required Color color,
    required List<FlSpot> spots,
    required String unidad,
    Umbral? umbral,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (umbral != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rango: ${umbral.minimo}-${umbral.maximo}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: spots.isNotEmpty
                      ? (spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) -
                              spots
                                  .map((e) => e.y)
                                  .reduce((a, b) => a < b ? a : b)) /
                          4
                      : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300]!,
                      strokeWidth: 1,
                    );
                  },
                ),
                // Líneas de umbral
                extraLinesData: umbral != null
                    ? ExtraLinesData(
                        horizontalLines: [
                          HorizontalLine(
                            y: umbral.minimo,
                            color: Colors.blue.withOpacity(0.7),
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (line) => 'Min: ${umbral.minimo}',
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 10),
                            ),
                          ),
                          HorizontalLine(
                            y: umbral.maximo,
                            color: Colors.red.withOpacity(0.7),
                            strokeWidth: 2,
                            dashArray: [5, 5],
                            label: HorizontalLineLabel(
                              show: true,
                              labelResolver: (line) => 'Max: ${umbral.maximo}',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 10),
                            ),
                          ),
                        ],
                      )
                    : null,
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: spots.length > 10 ? spots.length / 5 : 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: spots.isNotEmpty
                          ? (spots
                                      .map((e) => e.y)
                                      .reduce((a, b) => a > b ? a : b) -
                                  spots
                                      .map((e) => e.y)
                                      .reduce((a, b) => a < b ? a : b)) /
                              3
                          : 1,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          '${value.toInt()}$unidad',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 50,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 0,
                maxX: spots.isNotEmpty ? spots.length.toDouble() - 1 : 0,
                minY: spots.isNotEmpty
                    ? spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) *
                        0.9
                    : 0,
                maxY: spots.isNotEmpty
                    ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) *
                        1.1
                    : 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.3)],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionVacia(String titulo, String mensaje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            mensaje,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildUltimasLecturas() {
    final ultimasLecturas = todasLasLecturas.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history, color: Color(0xFF4CAF50)),
              SizedBox(width: 12),
              Text(
                'Últimas Lecturas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ultimasLecturas.isEmpty)
            const Text('No hay lecturas disponibles')
          else
            ...ultimasLecturas.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final tipo = (data['tipo'] ?? 'desconocido').toString();
              final valor = double.tryParse(data['valor'].toString()) ?? 0;
              final timestamp = data['timestamp'] as Timestamp?;
              final fecha = timestamp?.toDate() ?? DateTime.now();

              // Verificar si está dentro del umbral
              final umbral = umbrales[tipo.toLowerCase()];
              Color colorEstado = Colors.green;
              IconData iconoEstado = Icons.check_circle;

              if (umbral != null) {
                if (valor < umbral.minimo || valor > umbral.maximo) {
                  colorEstado = Colors.red;
                  iconoEstado = Icons.warning;
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  // ✅ CORRECCIÓN: Usar Border() constructor en lugar de Border.left
                  border: Border(
                    left: BorderSide(
                      color: colorEstado,
                      width: 4,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIconoTipo(tipo),
                      color: _getColorTipo(tipo),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${tipo.toUpperCase()}: ${valor.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm:ss').format(fecha),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      iconoEstado,
                      color: colorEstado,
                      size: 16,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  IconData _getIconoTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'co2':
        return Icons.cloud;
      case 'sonido':
        return Icons.graphic_eq;
      case 'temperatura':
        return Icons.thermostat;
      case 'humedad':
        return Icons.water_drop;
      default:
        return Icons.sensors;
    }
  }

  Color _getColorTipo(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'co2':
        return Colors.green;
      case 'sonido':
        return Colors.orange;
      case 'temperatura':
        return Colors.red;
      case 'humedad':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
