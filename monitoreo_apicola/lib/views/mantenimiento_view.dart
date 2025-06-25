import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/mantenimiento_controller.dart';
import '../models/mantenimiento_model.dart';

class MantenimientosView extends StatefulWidget {
  const MantenimientosView({super.key});

  @override
  State<MantenimientosView> createState() => _MantenimientosViewState();
}

class _MantenimientosViewState extends State<MantenimientosView>
    with TickerProviderStateMixin {
  final MantenimientoController _controller = MantenimientoController();
  List<Mantenimiento> _lista = [];
  List<Mantenimiento> _listaFiltrada = [];
  bool _isLoading = false;
  String _filtroEstado = 'todos';
  String _busqueda = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargar();
    _searchController.addListener(_filtrarLista);
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _isLoading = true);
    try {
      final datos = await _controller.getMantenimientos();
      setState(() {
        _lista = datos;
        _isLoading = false;
      });
      _filtrarLista();
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError("Error al cargar datos: $e");
    }
  }

  void _filtrarLista() {
    setState(() {
      _listaFiltrada = _lista.where((mantenimiento) {
        final coincideBusqueda = _busqueda.isEmpty ||
            mantenimiento.descripcion
                .toLowerCase()
                .contains(_busqueda.toLowerCase());

        final coincideEstado = _filtroEstado == 'todos' ||
            mantenimiento.estado.toLowerCase() == _filtroEstado.toLowerCase();

        return coincideBusqueda && coincideEstado;
      }).toList();
    });
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _formulario({Mantenimiento? mantenimiento}) {
    final descripcion = TextEditingController(
      text: mantenimiento?.descripcion ?? '',
    );
    String estadoSeleccionado = mantenimiento?.estado ?? 'Pendiente';
    DateTime fecha = mantenimiento?.fecha ?? DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
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
                        color: const Color(0xFF3F51B5).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        mantenimiento == null ? Icons.add_task : Icons.edit,
                        color: const Color(0xFF3F51B5),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mantenimiento == null
                                ? "Nuevo Mantenimiento"
                                : "Editar Mantenimiento",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            mantenimiento == null
                                ? "Registra una nueva tarea de mantenimiento"
                                : "Modifica los datos del mantenimiento",
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
                TextFormField(
                  controller: descripcion,
                  decoration: InputDecoration(
                    labelText: "Descripción del mantenimiento",
                    hintText:
                        "Ej: Revisión de sensores, limpieza de colmenas...",
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 20),

                // Selector de estado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Estado del mantenimiento",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey[50],
                      ),
                      child: Column(
                        children: [
                          _buildEstadoOption(
                            'Pendiente',
                            Icons.schedule,
                            Colors.orange,
                            estadoSeleccionado,
                            (value) => setDialogState(
                                () => estadoSeleccionado = value),
                          ),
                          const Divider(height: 1),
                          _buildEstadoOption(
                            'En Progreso',
                            Icons.play_circle,
                            Colors.blue,
                            estadoSeleccionado,
                            (value) => setDialogState(
                                () => estadoSeleccionado = value),
                          ),
                          const Divider(height: 1),
                          _buildEstadoOption(
                            'Completado',
                            Icons.check_circle,
                            Colors.green,
                            estadoSeleccionado,
                            (value) => setDialogState(
                                () => estadoSeleccionado = value),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Selector de fecha
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fecha,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF3F51B5),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() => fecha = picked);
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F51B5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF3F51B5),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Fecha programada",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, dd MMMM yyyy', 'es_ES')
                                  .format(fecha),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Icon(Icons.edit, color: Colors.grey[400], size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
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
                        onPressed: () async {
                          // Validaciones
                          if (descripcion.text.trim().isEmpty) {
                            _mostrarError("La descripción es obligatoria");
                            return;
                          }

                          final nuevo = Mantenimiento(
                            id: mantenimiento?.id ?? '',
                            descripcion: descripcion.text.trim(),
                            estado: estadoSeleccionado,
                            fecha: fecha,
                          );

                          bool exito = false;
                          if (mantenimiento == null) {
                            exito = await _controller.addMantenimiento(nuevo);
                          } else {
                            exito =
                                await _controller.updateMantenimiento(nuevo);
                          }

                          if (exito) {
                            Navigator.pop(dialogContext);
                            await _cargar();
                            _mostrarExito(
                              mantenimiento == null
                                  ? "Mantenimiento agregado exitosamente"
                                  : "Mantenimiento actualizado exitosamente",
                            );
                          } else {
                            _mostrarError("Error al guardar el mantenimiento");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F51B5),
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
      ),
    );
  }

  Widget _buildEstadoOption(
    String estado,
    IconData icono,
    Color color,
    String estadoSeleccionado,
    Function(String) onChanged,
  ) {
    final isSelected = estadoSeleccionado == estado;

    return RadioListTile<String>(
      value: estado,
      groupValue: estadoSeleccionado,
      onChanged: (value) => onChanged(value!),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icono, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            estado,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      activeColor: color,
      dense: true,
    );
  }

  Future<void> _eliminar(String id, String descripcion) async {
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
                "¿Estás seguro de que deseas eliminar este mantenimiento?"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                descripcion,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                ),
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
      final exito = await _controller.deleteMantenimiento(id);
      if (exito) {
        await _cargar();
        _mostrarExito("Mantenimiento eliminado exitosamente");
      } else {
        _mostrarError("Error al eliminar el mantenimiento");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("🛠️ Mantenimientos"),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargar,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Nuevo"),
      ),
      body: Column(
        children: [
          // Header con búsqueda y filtros
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF3F51B5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
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
                      _filtrarLista();
                    },
                    decoration: InputDecoration(
                      hintText: "Buscar mantenimientos...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _busqueda = '';
                                });
                                _filtrarLista();
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

                // Filtros de estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroChip('todos', 'Todos', Icons.list),
                      const SizedBox(width: 8),
                      _buildFiltroChip(
                          'pendiente', 'Pendientes', Icons.schedule),
                      const SizedBox(width: 8),
                      _buildFiltroChip(
                          'en progreso', 'En Progreso', Icons.play_circle),
                      const SizedBox(width: 8),
                      _buildFiltroChip(
                          'completado', 'Completados', Icons.check_circle),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de mantenimientos
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF3F51B5)),
                        SizedBox(height: 16),
                        Text("Cargando mantenimientos..."),
                      ],
                    ),
                  )
                : _listaFiltrada.isEmpty
                    ? _buildEstadoVacio()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: _cargar,
                          color: const Color(0xFF3F51B5),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _listaFiltrada.length,
                            itemBuilder: (context, index) {
                              final mantenimiento = _listaFiltrada[index];
                              return _buildMantenimientoCard(
                                  mantenimiento, index);
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String valor, String etiqueta, IconData icono) {
    final isSelected = _filtroEstado == valor;

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
          _filtroEstado = valor;
        });
        _filtrarLista();
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
              _busqueda.isNotEmpty || _filtroEstado != 'todos'
                  ? Icons.search_off
                  : Icons.build_circle,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _busqueda.isNotEmpty || _filtroEstado != 'todos'
                ? "No se encontraron mantenimientos"
                : "No hay mantenimientos registrados",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _busqueda.isNotEmpty || _filtroEstado != 'todos'
                ? "Intenta cambiar los filtros de búsqueda"
                : "Comienza agregando tu primer mantenimiento",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_busqueda.isEmpty && _filtroEstado == 'todos')
            ElevatedButton.icon(
              onPressed: () => _formulario(),
              icon: const Icon(Icons.add),
              label: const Text("Agregar Mantenimiento"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3F51B5),
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

  Widget _buildMantenimientoCard(Mantenimiento mantenimiento, int index) {
    final colorEstado = _getColorEstado(mantenimiento.estado);
    final iconoEstado = _getIconoEstado(mantenimiento.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: colorEstado, width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con estado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorEstado.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(iconoEstado, color: colorEstado, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mantenimiento.estado,
                            style: TextStyle(
                              color: colorEstado,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy', 'es_ES')
                                .format(mantenimiento.fecha),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          _formulario(mantenimiento: mantenimiento);
                        } else if (value == 'eliminar') {
                          _eliminar(
                              mantenimiento.id, mantenimiento.descripcion);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
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

                // Descripción
                Text(
                  mantenimiento.descripcion,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Footer con información adicional
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        "Programado para ${DateFormat('EEEE, dd MMMM', 'es_ES').format(mantenimiento.fecha)}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return Colors.green;
      case 'en progreso':
        return Colors.blue;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'completado':
        return Icons.check_circle;
      case 'en progreso':
        return Icons.play_circle;
      case 'pendiente':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }
}
