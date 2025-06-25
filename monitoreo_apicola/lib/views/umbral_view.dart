import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/umbral_controller.dart';
import '../models/umbral_model.dart';

class UmbralView extends StatefulWidget {
  const UmbralView({super.key});

  @override
  State<UmbralView> createState() => _UmbralViewState();
}

class _UmbralViewState extends State<UmbralView> with TickerProviderStateMixin {
  final UmbralController _controller = UmbralController();

  final _formKey = GlobalKey<FormState>();
  final _minCo2Controller = TextEditingController();
  final _maxCo2Controller = TextEditingController();
  final _minSonidoController = TextEditingController();
  final _maxSonidoController = TextEditingController();
  final _minTemperaturaController = TextEditingController();
  final _maxTemperaturaController = TextEditingController();
  final _minHumedadController = TextEditingController();
  final _maxHumedadController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  String _rolUsuario = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Valores por defecto
  final Map<String, Map<String, double>> _valoresDefecto = {
    'co2': {'minimo': 300.0, 'maximo': 1000.0},
    'sonido': {'minimo': 30.0, 'maximo': 80.0},
    'temperatura': {'minimo': 15.0, 'maximo': 35.0},
    'humedad': {'minimo': 40.0, 'maximo': 70.0},
  };

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _verificarPermisos();
    cargarValores();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _minCo2Controller.dispose();
    _maxCo2Controller.dispose();
    _minSonidoController.dispose();
    _maxSonidoController.dispose();
    _minTemperaturaController.dispose();
    _maxTemperaturaController.dispose();
    _minHumedadController.dispose();
    _maxHumedadController.dispose();
    super.dispose();
  }

  Future<void> _verificarPermisos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        setState(() {
          _rolUsuario = doc.data()?['rol'] ?? 'usuario';
        });
      }
    } catch (e) {
      print("Error al verificar permisos: $e");
    }
  }

  bool _esSuperAdmin() {
    return _rolUsuario.toLowerCase() == 'superadmin';
  }

  Future<void> cargarValores() async {
    try {
      setState(() => _cargando = true);

      final sensores = ['co2', 'sonido', 'temperatura', 'humedad'];

      for (String sensor in sensores) {
        final umbral = await _controller.obtenerUmbral(sensor);

        switch (sensor) {
          case 'co2':
            _minCo2Controller.text = umbral?.minimo.toString() ??
                _valoresDefecto[sensor]!['minimo']!.toString();
            _maxCo2Controller.text = umbral?.maximo.toString() ??
                _valoresDefecto[sensor]!['maximo']!.toString();
            break;
          case 'sonido':
            _minSonidoController.text = umbral?.minimo.toString() ??
                _valoresDefecto[sensor]!['minimo']!.toString();
            _maxSonidoController.text = umbral?.maximo.toString() ??
                _valoresDefecto[sensor]!['maximo']!.toString();
            break;
          case 'temperatura':
            _minTemperaturaController.text = umbral?.minimo.toString() ??
                _valoresDefecto[sensor]!['minimo']!.toString();
            _maxTemperaturaController.text = umbral?.maximo.toString() ??
                _valoresDefecto[sensor]!['maximo']!.toString();
            break;
          case 'humedad':
            _minHumedadController.text = umbral?.minimo.toString() ??
                _valoresDefecto[sensor]!['minimo']!.toString();
            _maxHumedadController.text = umbral?.maximo.toString() ??
                _valoresDefecto[sensor]!['maximo']!.toString();
            break;
        }
      }
    } catch (e) {
      _mostrarError("Error al cargar umbrales: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> guardar() async {
    if (!_esSuperAdmin()) {
      _mostrarError("Solo los Super Administradores pueden modificar umbrales");
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() => _guardando = true);

      try {
        // Validar que mínimo < máximo para cada sensor
        if (!_validarRangos()) {
          setState(() => _guardando = false);
          return;
        }

        final umbrales = [
          Umbral(
            tipoSensor: 'co2',
            minimo: double.parse(_minCo2Controller.text),
            maximo: double.parse(_maxCo2Controller.text),
          ),
          Umbral(
            tipoSensor: 'sonido',
            minimo: double.parse(_minSonidoController.text),
            maximo: double.parse(_maxSonidoController.text),
          ),
          Umbral(
            tipoSensor: 'temperatura',
            minimo: double.parse(_minTemperaturaController.text),
            maximo: double.parse(_maxTemperaturaController.text),
          ),
          Umbral(
            tipoSensor: 'humedad',
            minimo: double.parse(_minHumedadController.text),
            maximo: double.parse(_maxHumedadController.text),
          ),
        ];

        for (Umbral umbral in umbrales) {
          await _controller.guardarUmbral(umbral);
        }

        _mostrarExito("✅ Umbrales actualizados correctamente");
      } catch (e) {
        _mostrarError("Error al guardar umbrales: $e");
      } finally {
        setState(() => _guardando = false);
      }
    }
  }

  bool _validarRangos() {
    final validaciones = [
      {
        'min': _minCo2Controller.text,
        'max': _maxCo2Controller.text,
        'sensor': 'CO2'
      },
      {
        'min': _minSonidoController.text,
        'max': _maxSonidoController.text,
        'sensor': 'Sonido'
      },
      {
        'min': _minTemperaturaController.text,
        'max': _maxTemperaturaController.text,
        'sensor': 'Temperatura'
      },
      {
        'min': _minHumedadController.text,
        'max': _maxHumedadController.text,
        'sensor': 'Humedad'
      },
    ];

    for (var validacion in validaciones) {
      final min = double.tryParse(validacion['min']!) ?? 0;
      final max = double.tryParse(validacion['max']!) ?? 0;

      if (min >= max) {
        _mostrarError(
            "El valor mínimo debe ser menor al máximo en ${validacion['sensor']}");
        return false;
      }
    }
    return true;
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restaurarDefecto(String sensor) {
    if (!_esSuperAdmin()) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.restore, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text("Restaurar valores"),
          ],
        ),
        content: Text(
            "¿Restaurar los valores por defecto para el sensor ${sensor.toUpperCase()}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              _aplicarValoresDefecto(sensor);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
            ),
            child: const Text("Restaurar"),
          ),
        ],
      ),
    );
  }

  void _aplicarValoresDefecto(String sensor) {
    final valores = _valoresDefecto[sensor]!;

    switch (sensor) {
      case 'co2':
        _minCo2Controller.text = valores['minimo']!.toString();
        _maxCo2Controller.text = valores['maximo']!.toString();
        break;
      case 'sonido':
        _minSonidoController.text = valores['minimo']!.toString();
        _maxSonidoController.text = valores['maximo']!.toString();
        break;
      case 'temperatura':
        _minTemperaturaController.text = valores['minimo']!.toString();
        _maxTemperaturaController.text = valores['maximo']!.toString();
        break;
      case 'humedad':
        _minHumedadController.text = valores['minimo']!.toString();
        _maxHumedadController.text = valores['maximo']!.toString();
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('⚙️ Configurar Umbrales'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_esSuperAdmin())
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: cargarValores,
              tooltip: 'Recargar valores',
            ),
        ],
      ),
      body: _cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando configuración...'),
                ],
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header con información de permisos
                      _buildHeaderPermisos(),
                      const SizedBox(height: 24),

                      // Sensores
                      _buildSensorCard(
                        'CO₂',
                        'Dióxido de Carbono',
                        'ppm',
                        Icons.cloud,
                        Colors.green,
                        _minCo2Controller,
                        _maxCo2Controller,
                        'co2',
                      ),
                      const SizedBox(height: 16),

                      _buildSensorCard(
                        'Sonido',
                        'Nivel de Ruido',
                        'dB',
                        Icons.graphic_eq,
                        Colors.orange,
                        _minSonidoController,
                        _maxSonidoController,
                        'sonido',
                      ),
                      const SizedBox(height: 16),

                      // Botón de guardar
                      if (_esSuperAdmin())
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _guardando ? null : guardar,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_guardando
                                ? "Guardando..."
                                : "Guardar Configuración"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D47A1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderPermisos() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _esSuperAdmin()
              ? [const Color(0xFF0D47A1), const Color(0xFF1565C0)]
              : [Colors.grey[600]!, Colors.grey[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                (_esSuperAdmin() ? Colors.blue : Colors.grey).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            _esSuperAdmin() ? Icons.admin_panel_settings : Icons.lock,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            _esSuperAdmin() ? 'Configuración de Umbrales' : 'Solo Lectura',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _esSuperAdmin()
                ? 'Puedes modificar los umbrales del sistema'
                : 'Solo los Super Administradores pueden modificar umbrales',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(
    String nombre,
    String descripcion,
    String unidad,
    IconData icono,
    Color color,
    TextEditingController minController,
    TextEditingController maxController,
    String sensorKey,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
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
          // Header del sensor
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (_esSuperAdmin())
                IconButton(
                  onPressed: () => _restaurarDefecto(sensorKey),
                  icon: Icon(Icons.restore, color: Colors.grey[600]),
                  tooltip: 'Restaurar valores por defecto',
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Campos de entrada
          Row(
            children: [
              Expanded(
                child: _buildCampoUmbral(
                  'Valor Mínimo',
                  minController,
                  unidad,
                  color,
                  enabled: _esSuperAdmin(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCampoUmbral(
                  'Valor Máximo',
                  maxController,
                  unidad,
                  color,
                  enabled: _esSuperAdmin(),
                ),
              ),
            ],
          ),

          // Indicador visual del rango
          const SizedBox(height: 16),
          _buildIndicadorRango(minController, maxController, unidad, color),
        ],
      ),
    );
  }

  Widget _buildCampoUmbral(String label, TextEditingController controller,
      String unidad, Color color,
      {bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unidad,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Campo requerido';
        }
        final numero = double.tryParse(value);
        if (numero == null) {
          return 'Número inválido';
        }
        if (numero < 0) {
          return 'Debe ser positivo';
        }
        return null;
      },
    );
  }

  Widget _buildIndicadorRango(
    TextEditingController minController,
    TextEditingController maxController,
    String unidad,
    Color color,
  ) {
    final min = double.tryParse(minController.text) ?? 0;
    final max = double.tryParse(maxController.text) ?? 100;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            'Rango válido: $min - $max $unidad',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
