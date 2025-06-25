import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/observacion_controller.dart';
import '../models/observacion_model.dart';

class ObservacionesView extends StatefulWidget {
  const ObservacionesView({super.key});

  @override
  State<ObservacionesView> createState() => _ObservacionesViewState();
}

class _ObservacionesViewState extends State<ObservacionesView>
    with TickerProviderStateMixin {
  final ObservacionController _controller = ObservacionController();
  List<Observacion> _observaciones = [];
  List<Observacion> _observacionesFiltradas = [];
  bool _isLoading = false;
  String _busqueda = '';
  String _filtroFecha = 'todas';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _verificarConexionYCargar();
    _searchController.addListener(_filtrarObservaciones);
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _verificarConexionYCargar() async {
    setState(() => _isLoading = true);

    // Verificar conexión primero
    final tieneConexion = await _controller.testConnection();
    if (!tieneConexion) {
      setState(() => _isLoading = false);
      _mostrarError("Sin conexión a internet o problemas con Firebase");
      return;
    }

    await _cargarObservaciones();
  }

  Future<void> _cargarObservaciones() async {
    setState(() => _isLoading = true);
    try {
      final data = await _controller.getObservaciones();
      setState(() {
        _observaciones = data;
        _isLoading = false;
      });
      _filtrarObservaciones();
      _animationController.forward();
      _fabAnimationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError("Error al cargar observaciones: ${e.toString()}");
    }
  }

  void _filtrarObservaciones() {
    setState(() {
      _observacionesFiltradas = _observaciones.where((obs) {
        final coincideBusqueda = _busqueda.isEmpty ||
            obs.descripcion.toLowerCase().contains(_busqueda.toLowerCase());

        final ahora = DateTime.now();
        bool coincideFecha = true;

        switch (_filtroFecha) {
          case 'hoy':
            coincideFecha = _esMismaFecha(obs.fecha, ahora);
            break;
          case 'semana':
            final inicioSemana =
                ahora.subtract(Duration(days: ahora.weekday - 1));
            coincideFecha = obs.fecha
                .isAfter(inicioSemana.subtract(const Duration(days: 1)));
            break;
          case 'mes':
            coincideFecha =
                obs.fecha.month == ahora.month && obs.fecha.year == ahora.year;
            break;
          case 'todas':
          default:
            coincideFecha = true;
        }

        return coincideBusqueda && coincideFecha;
      }).toList();

      // Ordenar por fecha más reciente
      _observacionesFiltradas.sort((a, b) => b.fecha.compareTo(a.fecha));
    });
  }

  bool _esMismaFecha(DateTime fecha1, DateTime fecha2) {
    return fecha1.year == fecha2.year &&
        fecha1.month == fecha2.month &&
        fecha1.day == fecha2.day;
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: _cargarObservaciones,
          ),
        ),
      );
    }
  }

  void _mostrarExito(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _mostrarFormulario({Observacion? observacion}) {
    final descripcionController = TextEditingController(
      text: observacion?.descripcion ?? '',
    );
    DateTime fecha = observacion?.fecha ?? DateTime.now();
    bool guardando = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: const BoxConstraints(maxHeight: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header del diálogo
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          observacion == null
                              ? Icons.note_add
                              : Icons.edit_note,
                          color: const Color(0xFF6366F1),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              observacion == null
                                  ? "Nueva Observación"
                                  : "Editar Observación",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              observacion == null
                                  ? "Registra una nueva observación importante"
                                  : "Modifica los detalles de la observación",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Campo descripción
                  Text(
                    "Descripción",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: descripcionController,
                      decoration: InputDecoration(
                        hintText: "Describe tu observación detalladamente...",
                        prefixIcon: const Icon(Icons.description),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.all(20),
                      ),
                      maxLines: 4,
                      enabled: !guardando,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Selector de fecha
                  Text(
                    "Fecha de la observación",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: guardando
                            ? Colors.grey[300]!
                            : const Color(0xFF6366F1).withOpacity(0.3),
                      ),
                      color: guardando ? Colors.grey[100] : Colors.grey[50],
                    ),
                    child: InkWell(
                      onTap: guardando
                          ? null
                          : () async {
                              final seleccion = await showDatePicker(
                                context: context,
                                initialDate: fecha,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: Color(0xFF6366F1),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (seleccion != null) {
                                setDialogState(() {
                                  fecha = seleccion;
                                });
                              }
                            },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: guardando
                                    ? Colors.grey[300]
                                    : const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.calendar_today,
                                color: guardando
                                    ? Colors.grey
                                    : const Color(0xFF6366F1),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE, dd MMMM yyyy', 'es_ES')
                                        .format(fecha),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: guardando
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    _obtenerTiempoRelativo(fecha),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!guardando)
                              Icon(
                                Icons.edit_calendar,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (guardando) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Guardando observación...",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: guardando
                              ? null
                              : () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Cancelar"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: guardando
                              ? null
                              : () async {
                                  // Validaciones
                                  if (descripcionController.text
                                      .trim()
                                      .isEmpty) {
                                    _mostrarError(
                                        "La descripción es obligatoria");
                                    return;
                                  }

                                  setDialogState(() => guardando = true);

                                  try {
                                    final nuevaObs = Observacion(
                                      id: observacion?.id ?? '',
                                      descripcion:
                                          descripcionController.text.trim(),
                                      fecha: fecha,
                                    );

                                    if (observacion == null) {
                                      await _controller
                                          .addObservacion(nuevaObs);
                                      _mostrarExito(
                                          "Observación agregada exitosamente");
                                    } else {
                                      await _controller
                                          .updateObservacion(nuevaObs);
                                      _mostrarExito(
                                          "Observación actualizada exitosamente");
                                    }

                                    Navigator.pop(dialogContext);
                                    await _cargarObservaciones();
                                  } catch (e) {
                                    setDialogState(() => guardando = false);
                                    _mostrarError(
                                        "Error al guardar: ${e.toString()}");
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text("Guardar"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _obtenerTiempoRelativo(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inDays == 0) {
      return "Hoy";
    } else if (diferencia.inDays == 1) {
      return "Ayer";
    } else if (diferencia.inDays == -1) {
      return "Mañana";
    } else if (diferencia.inDays > 0) {
      return "Hace ${diferencia.inDays} días";
    } else {
      return "En ${-diferencia.inDays} días";
    }
  }

  Future<void> _eliminarObservacion(String id, String descripcion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red[700]),
            ),
            const SizedBox(width: 12),
            const Text("Confirmar eliminación"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "¿Estás seguro de que deseas eliminar esta observación?"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                descripcion,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Esta acción no se puede deshacer.",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _controller.deleteObservacion(id);
        await _cargarObservaciones();
        _mostrarExito("Observación eliminada exitosamente");
      } catch (e) {
        _mostrarError("Error al eliminar: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("📝 Observaciones"),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _cargarObservaciones,
            tooltip: 'Actualizar observaciones',
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : () => _mostrarFormulario(),
          backgroundColor: const Color(0xFF6366F1),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Nueva"),
        ),
      ),
      body: Column(
        children: [
          // Header con búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Estadísticas rápidas
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildEstadistica(
                        "Total",
                        _observaciones.length.toString(),
                        Icons.note_alt,
                      ),
                      _buildEstadistica(
                        "Este mes",
                        _observaciones
                            .where((obs) {
                              final ahora = DateTime.now();
                              return obs.fecha.month == ahora.month &&
                                  obs.fecha.year == ahora.year;
                            })
                            .length
                            .toString(),
                        Icons.calendar_month,
                      ),
                      _buildEstadistica(
                        "Recientes",
                        _observaciones
                            .where((obs) {
                              final diferencia =
                                  DateTime.now().difference(obs.fecha);
                              return diferencia.inDays <= 7;
                            })
                            .length
                            .toString(),
                        Icons.schedule,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Barra de búsqueda
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _busqueda = value;
                      });
                      _filtrarObservaciones();
                    },
                    decoration: InputDecoration(
                      hintText: "Buscar observaciones...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _busqueda = '';
                                });
                                _filtrarObservaciones();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filtros de fecha
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroFecha('todas', 'Todas', Icons.all_inclusive),
                      const SizedBox(width: 8),
                      _buildFiltroFecha('hoy', 'Hoy', Icons.today),
                      const SizedBox(width: 8),
                      _buildFiltroFecha(
                          'semana', 'Esta semana', Icons.date_range),
                      const SizedBox(width: 8),
                      _buildFiltroFecha(
                          'mes', 'Este mes', Icons.calendar_month),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de observaciones
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF6366F1)),
                        SizedBox(height: 16),
                        Text("Cargando observaciones..."),
                      ],
                    ),
                  )
                : _observacionesFiltradas.isEmpty
                    ? _buildEstadoVacio()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: _cargarObservaciones,
                          color: const Color(0xFF6366F1),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _observacionesFiltradas.length,
                            itemBuilder: (context, index) {
                              final observacion =
                                  _observacionesFiltradas[index];
                              return _buildObservacionCard(observacion, index);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadistica(String titulo, String valor, IconData icono) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icono, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltroFecha(String valor, String etiqueta, IconData icono) {
    final isSelected = _filtroFecha == valor;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 16,
            color: isSelected ? Colors.white : Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            etiqueta,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _filtroFecha = valor;
        });
        _filtrarObservaciones();
      },
      backgroundColor: Colors.white.withOpacity(0.2),
      selectedColor: Colors.white.withOpacity(0.3),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: Colors.white.withOpacity(0.3),
      ),
    );
  }

  Widget _buildEstadoVacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _busqueda.isNotEmpty || _filtroFecha != 'todas'
                  ? Icons.search_off
                  : Icons.note_add,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _busqueda.isNotEmpty || _filtroFecha != 'todas'
                ? "No se encontraron observaciones"
                : "No hay observaciones registradas",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _busqueda.isNotEmpty || _filtroFecha != 'todas'
                ? "Intenta cambiar los filtros de búsqueda"
                : "Comienza registrando tu primera observación",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_busqueda.isEmpty && _filtroFecha == 'todas')
            ElevatedButton.icon(
              onPressed: () => _mostrarFormulario(),
              icon: const Icon(Icons.add),
              label: const Text("Agregar Observación"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
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
    );
  }

  Widget _buildObservacionCard(Observacion observacion, int index) {
    final esHoy = _esMismaFecha(observacion.fecha, DateTime.now());
    final esReciente = DateTime.now().difference(observacion.fecha).inDays <= 3;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: esHoy
                ? const Border(
                    left: BorderSide(color: Color(0xFF6366F1), width: 4))
                : esReciente
                    ? Border(
                        left: BorderSide(color: Colors.orange[400]!, width: 4))
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con fecha y acciones
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.note_alt,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy', 'es_ES')
                                .format(observacion.fecha),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _obtenerTiempoRelativo(observacion.fecha),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (esHoy)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "HOY",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          _mostrarFormulario(observacion: observacion);
                        } else if (value == 'eliminar') {
                          _eliminarObservacion(
                              observacion.id, observacion.descripcion);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xFF6366F1)),
                              SizedBox(width: 8),
                              Text('Editar'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Eliminar'),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.more_vert, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Contenido de la observación
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    observacion.descripcion,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
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
}
