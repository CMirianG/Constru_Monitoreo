import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import '../services/guardar_historial_service.dart';

class LecturaSensor {
  final String co2;
  final String sonido;
  final DateTime fecha;

  LecturaSensor({required this.co2, required this.sonido, required this.fecha});

  factory LecturaSensor.fromJson(Map<String, dynamic> json) {
    return LecturaSensor(
      co2: json['field2'] ?? 'N/D',
      sonido: json['field1'] ?? 'N/D',
      fecha: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class LecturaThingSpeakView extends StatefulWidget {
  const LecturaThingSpeakView({super.key});

  @override
  State<LecturaThingSpeakView> createState() => _LecturaThingSpeakViewState();
}

class _LecturaThingSpeakViewState extends State<LecturaThingSpeakView>
    with TickerProviderStateMixin {
  LecturaSensor? lectura;
  DateTime? ultimaFechaGuardada;
  bool cargando = true;
  bool error = false;
  Timer? temporizador;

  // Controladores de animación
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    obtenerDatos();
    temporizador = Timer.periodic(
      const Duration(seconds: 10),
      (_) => obtenerDatos(),
    );
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    temporizador?.cancel();
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> obtenerDatos() async {
    try {
      final url = Uri.parse(
        'https://api.thingspeak.com/channels/2956848/feeds/last.json?api_key=MXNX7N6W79QIZ3IZ',
      );
      final respuesta = await http.get(url);

      if (respuesta.statusCode == 200) {
        final data = json.decode(respuesta.body);
        final nuevaLectura = LecturaSensor.fromJson(data);

        setState(() {
          lectura = nuevaLectura;
          cargando = false;
          error = false;
        });

        // Guardar solo si es nueva lectura
        if (ultimaFechaGuardada == null ||
            nuevaLectura.fecha.isAfter(ultimaFechaGuardada!)) {
          await guardarLecturaEnFirestore(
            tipo: 'co2',
            valor: nuevaLectura.co2,
            fecha: nuevaLectura.fecha,
          );
          await guardarLecturaEnFirestore(
            tipo: 'sonido',
            valor: nuevaLectura.sonido,
            fecha: nuevaLectura.fecha,
          );
          ultimaFechaGuardada = nuevaLectura.fecha;
        }
      } else {
        setState(() {
          cargando = false;
          error = true;
        });
      }
    } catch (e) {
      setState(() {
        cargando = false;
        error = true;
      });
      print("❌ Error HTTP: $e");
    }
  }

  Color _getCO2StatusColor(String valor) {
    final numericValue = double.tryParse(valor) ?? 0;
    if (numericValue > 1000) return Colors.red;
    if (numericValue > 800) return Colors.orange;
    return Colors.green;
  }

  Color _getSoundStatusColor(String valor) {
    final numericValue = double.tryParse(valor) ?? 0;
    if (numericValue > 80) return Colors.red;
    if (numericValue > 60) return Colors.orange;
    return Colors.blue;
  }

  String _getCO2StatusText(String valor) {
    final numericValue = double.tryParse(valor) ?? 0;
    if (numericValue > 1000) return 'Alto';
    if (numericValue > 800) return 'Moderado';
    return 'Normal';
  }

  String _getSoundStatusText(String valor) {
    final numericValue = double.tryParse(valor) ?? 0;
    if (numericValue > 80) return 'Ruidoso';
    if (numericValue > 60) return 'Moderado';
    return 'Silencioso';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('📡 Monitoreo en Tiempo Real'),
        backgroundColor: Colors.teal[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: obtenerDatos,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: obtenerDatos,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con estado de conexión
                  _buildConnectionHeader(),
                  const SizedBox(height: 24),

                  // Contenido principal
                  if (cargando)
                    _buildLoadingState()
                  else if (error)
                    _buildErrorState()
                  else
                    _buildSensorData(),

                  const SizedBox(height: 24),
                  _buildInfoFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              error
                  ? [Colors.red[400]!, Colors.red[600]!]
                  : [Colors.teal[400]!, Colors.teal[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (error ? Colors.red : Colors.teal).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: error ? 1.0 : _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    error ? Icons.signal_wifi_off : Icons.wifi_tethering,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error ? 'Desconectado' : 'Conectado a ThingSpeak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error
                      ? 'Error al obtener datos del servidor'
                      : lectura != null
                      ? 'Última actualización: ${DateFormat('HH:mm:ss').format(lectura!.fecha)}'
                      : 'Obteniendo datos...',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          if (cargando)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal, strokeWidth: 3),
            SizedBox(height: 20),
            Text(
              'Obteniendo datos de sensores...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              'Error de conexión',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se pudieron obtener los datos de ThingSpeak',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: obtenerDatos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorData() {
    return Column(
      children: [
        // Tarjetas de sensores
        Row(
          children: [
            Expanded(
              child: _buildModernSensorCard(
                nombre: 'CO₂',
                valor: lectura!.co2,
                unidad: 'ppm',
                icono: Icons.cloud_outlined,
                color: _getCO2StatusColor(lectura!.co2),
                status: _getCO2StatusText(lectura!.co2),
                fecha: lectura!.fecha,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernSensorCard(
                nombre: 'Sonido',
                valor: lectura!.sonido,
                unidad: 'dB',
                icono: Icons.graphic_eq,
                color: _getSoundStatusColor(lectura!.sonido),
                status: _getSoundStatusText(lectura!.sonido),
                fecha: lectura!.fecha,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Información de tiempo
        _buildTimeInfo(),
      ],
    );
  }

  Widget _buildModernSensorCard({
    required String nombre,
    required String valor,
    required String unidad,
    required IconData icono,
    required Color color,
    required String status,
    required DateTime fecha,
  }) {
    final ahora = DateTime.now();
    final diferenciaMin = ahora.difference(fecha).inMinutes;
    final isRecent = diferenciaMin <= 5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono y estado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nombre del sensor
          Text(
            nombre,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),

          // Valor principal
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                valor,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unidad,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Indicador de tiempo
          Row(
            children: [
              Icon(
                isRecent ? Icons.access_time : Icons.schedule,
                size: 14,
                color: isRecent ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isRecent
                      ? 'Actualizado hace $diferenciaMin min'
                      : 'Dato antiguo ($diferenciaMin min)',
                  style: TextStyle(
                    fontSize: 11,
                    color: isRecent ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Información de Tiempo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    'Última Lectura',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm:ss').format(lectura!.fecha),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              Container(width: 1, height: 40, color: Colors.blue[200]),
              Column(
                children: [
                  Text(
                    'Fecha',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(lectura!.fecha),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Información del Sistema',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoItem('Canal', '2956848'),
              _buildInfoItem('Actualización', '10 seg'),
              _buildInfoItem('Estado', error ? 'Error' : 'Activo'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
