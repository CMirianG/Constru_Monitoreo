import 'package:flutter/material.dart';

class ColmenaView extends StatefulWidget {
  const ColmenaView({super.key});

  @override
  State<ColmenaView> createState() => _ColmenaViewState();
}

class _ColmenaViewState extends State<ColmenaView>
    with TickerProviderStateMixin {
  // Variables de estado para la UI
  List<Map<String, dynamic>> _colmenas = [];
  List<Map<String, dynamic>> _colmenasFiltradas = [];
  bool _cargando = false;
  String _busqueda = '';
  String _filtroEstado = 'todos';

  // Controladores de formulario
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ubicacionController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Controladores de animación
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  Map<String, dynamic>? _colmenaEditando;

  // Estados predefinidos para colmenas
  final List<Map<String, dynamic>> _estadosColmena = [
    {
      'nombre': 'Activa',
      'icono': Icons.hive,
      'color': Colors.green,
      'descripcion': 'Colmena productiva y saludable'
    },
    {
      'nombre': 'En Desarrollo',
      'icono': Icons.trending_up,
      'color': Colors.orange,
      'descripcion': 'Colmena en crecimiento'
    },
    {
      'nombre': 'Mantenimiento',
      'icono': Icons.build,
      'color': Colors.blue,
      'descripcion': 'Requiere atención técnica'
    },
    {
      'nombre': 'Inactiva',
      'icono': Icons.pause_circle,
      'color': Colors.grey,
      'descripcion': 'Temporalmente fuera de servicio'
    },
    {
      'nombre': 'Problema',
      'icono': Icons.warning,
      'color': Colors.red,
      'descripcion': 'Requiere intervención urgente'
    },
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargarDatosMock();
    _searchController.addListener(_filtrarColmenas);
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    _searchController.dispose();
    _ubicacionController.dispose();
    _estadoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  // Datos mock para la demostración de la UI
  void _cargarDatosMock() {
    setState(() => _cargando = true);

    // Simular carga de datos
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _colmenas = [
            {
              'id': '1',
              'ubicacion': 'Sector A - Fila 1 - Posición 3',
              'estado': 'Activa',
              'descripcionTecnica':
                  'Colmena con excelente producción de miel. Población estable de aproximadamente 60,000 abejas. Última revisión: sin problemas detectados.',
            },
            {
              'id': '2',
              'ubicacion': 'Sector B - Fila 2 - Posición 1',
              'estado': 'En Desarrollo',
              'descripcionTecnica':
                  'Colmena joven establecida hace 3 meses. Crecimiento poblacional constante. Requiere monitoreo semanal.',
            },
            {
              'id': '3',
              'ubicacion': 'Sector A - Fila 3 - Posición 5',
              'estado': 'Mantenimiento',
              'descripcionTecnica':
                  'Requiere cambio de marcos y limpieza general. Programado para el próximo fin de semana.',
            },
            {
              'id': '4',
              'ubicacion': 'Sector C - Fila 1 - Posición 2',
              'estado': 'Problema',
              'descripcionTecnica':
                  'Detectada posible presencia de varroa. Requiere tratamiento inmediato y aislamiento temporal.',
            },
            {
              'id': '5',
              'ubicacion': 'Sector B - Fila 4 - Posición 7',
              'estado': 'Inactiva',
              'descripcionTecnica':
                  'Colmena temporalmente vacía. Preparada para nueva colonia en primavera.',
            },
          ];
          _cargando = false;
        });
        _filtrarColmenas();
        _animationController.forward();
        _fabAnimationController.forward();
      }
    });
  }

  void _filtrarColmenas() {
    setState(() {
      _colmenasFiltradas = _colmenas.where((colmena) {
        final coincideBusqueda = _busqueda.isEmpty ||
            colmena['ubicacion']
                .toLowerCase()
                .contains(_busqueda.toLowerCase()) ||
            colmena['descripcionTecnica']
                .toLowerCase()
                .contains(_busqueda.toLowerCase());

        final coincideEstado = _filtroEstado == 'todos' ||
            colmena['estado'].toLowerCase() == _filtroEstado.toLowerCase();

        return coincideBusqueda && coincideEstado;
      }).toList();

      // Ordenar por estado (problemas primero, luego activas)
      _colmenasFiltradas.sort((a, b) {
        final prioridadA = _obtenerPrioridadEstado(a['estado']);
        final prioridadB = _obtenerPrioridadEstado(b['estado']);
        return prioridadA.compareTo(prioridadB);
      });
    });
  }

  int _obtenerPrioridadEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'problema':
        return 0; // Más alta prioridad
      case 'activa':
        return 1;
      case 'en desarrollo':
        return 2;
      case 'mantenimiento':
        return 3;
      case 'inactiva':
        return 4;
      default:
        return 5;
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: esError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarFormulario({Map<String, dynamic>? colmena}) {
    _colmenaEditando = colmena;
    _ubicacionController.text = colmena?['ubicacion'] ?? '';
    _estadoController.text = colmena?['estado'] ?? 'Activa';
    _descripcionController.text = colmena?['descripcionTecnica'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
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
                          color: const Color(0xFFFFA726).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          colmena == null
                              ? Icons.add_business
                              : Icons.edit_location,
                          color: const Color(0xFFFFA726),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              colmena == null
                                  ? "Nueva Colmena"
                                  : "Editar Colmena",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              colmena == null
                                  ? "Registra una nueva colmena en el apiario"
                                  : "Modifica los datos de la colmena",
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

                  // Campo ubicación
                  Text(
                    "Ubicación",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ubicacionController,
                    decoration: InputDecoration(
                      hintText: "Ej: Sector A - Fila 3 - Posición 5",
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'La ubicación es obligatoria' : null,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),

                  // Selector de estado
                  Text(
                    "Estado de la colmena",
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
                    child: DropdownButtonFormField<String>(
                      value: _estadoController.text.isNotEmpty
                          ? _estadoController.text
                          : 'Activa',
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      items: _estadosColmena.map((estado) {
                        return DropdownMenuItem<String>(
                          value: estado['nombre'],
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: estado['color'].withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  estado['icono'],
                                  color: estado['color'],
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      estado['nombre'],
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      estado['descripcion'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _estadoController.text = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo descripción técnica
                  Text(
                    "Descripción técnica",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descripcionController,
                    decoration: InputDecoration(
                      hintText:
                          "Detalles técnicos, observaciones, características especiales...",
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    maxLines: 3,
                    validator: (value) => value!.isEmpty
                        ? 'La descripción técnica es obligatoria'
                        : null,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 32),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            _limpiarFormulario();
                          },
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
                          onPressed: () => _guardarColmena(dialogContext),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA726),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                              colmena == null ? "Registrar" : "Actualizar"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _guardarColmena(BuildContext dialogContext) {
    if (_formKey.currentState!.validate()) {
      // Simular guardado
      Navigator.pop(dialogContext);
      _limpiarFormulario();
      _mostrarMensaje(_colmenaEditando == null
          ? "Colmena registrada exitosamente"
          : "Colmena actualizada exitosamente");

      // En una implementación real, aquí llamarías al controlador
      // await _controller.addColmena(nuevaColmena) o updateColmena
    }
  }

  void _limpiarFormulario() {
    _ubicacionController.clear();
    _estadoController.clear();
    _descripcionController.clear();
    _colmenaEditando = null;
  }

  void _eliminarColmena(String id, String ubicacion) {
    showDialog(
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
            const Text("¿Estás seguro de que deseas eliminar esta colmena?"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFFFA726)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ubicacion,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Esta acción eliminará todos los datos asociados y no se puede deshacer.",
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarMensaje("Colmena eliminada exitosamente");
              // En implementación real: await _controller.deleteColmena(id);
            },
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      appBar: AppBar(
        title: const Text("🐝 Gestión de Colmenas"),
        backgroundColor: const Color(0xFFFFA726),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargando ? null : _cargarDatosMock,
            tooltip: 'Actualizar colmenas',
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimationController,
        child: FloatingActionButton.extended(
          onPressed: _cargando ? null : () => _mostrarFormulario(),
          backgroundColor: const Color(0xFFFFA726),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text("Nueva Colmena"),
        ),
      ),
      body: Column(
        children: [
          // Header con estadísticas y búsqueda
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFA726),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Estadísticas del apiario
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
                        _colmenas.length.toString(),
                        Icons.hive,
                      ),
                      _buildEstadistica(
                        "Activas",
                        _colmenas
                            .where((c) => c['estado'].toLowerCase() == 'activa')
                            .length
                            .toString(),
                        Icons.check_circle,
                      ),
                      _buildEstadistica(
                        "Problemas",
                        _colmenas
                            .where(
                                (c) => c['estado'].toLowerCase() == 'problema')
                            .length
                            .toString(),
                        Icons.warning,
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
                      _filtrarColmenas();
                    },
                    decoration: InputDecoration(
                      hintText: "Buscar colmenas por ubicación...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _busqueda.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _busqueda = '';
                                });
                                _filtrarColmenas();
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

                // Filtros por estado
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroEstado('todos', 'Todas', Icons.all_inclusive),
                      const SizedBox(width: 8),
                      _buildFiltroEstado('activa', 'Activas', Icons.hive),
                      const SizedBox(width: 8),
                      _buildFiltroEstado(
                          'en desarrollo', 'En Desarrollo', Icons.trending_up),
                      const SizedBox(width: 8),
                      _buildFiltroEstado(
                          'mantenimiento', 'Mantenimiento', Icons.build),
                      const SizedBox(width: 8),
                      _buildFiltroEstado(
                          'problema', 'Problemas', Icons.warning),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de colmenas
          Expanded(
            child: _cargando
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFFFFA726)),
                        SizedBox(height: 16),
                        Text("Cargando colmenas del apiario..."),
                      ],
                    ),
                  )
                : _colmenasFiltradas.isEmpty
                    ? _buildEstadoVacio()
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: RefreshIndicator(
                          onRefresh: () async => _cargarDatosMock(),
                          color: const Color(0xFFFFA726),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _colmenasFiltradas.length,
                            itemBuilder: (context, index) {
                              final colmena = _colmenasFiltradas[index];
                              return _buildColmenaCard(colmena, index);
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

  Widget _buildFiltroEstado(String valor, String etiqueta, IconData icono) {
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
        _filtrarColmenas();
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              _busqueda.isNotEmpty || _filtroEstado != 'todos'
                  ? Icons.search_off
                  : Icons.hive,
              size: 64,
              color: const Color(0xFFFFA726),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _busqueda.isNotEmpty || _filtroEstado != 'todos'
                ? "No se encontraron colmenas"
                : "No hay colmenas registradas",
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
                : "Comienza registrando tu primera colmena",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_busqueda.isEmpty && _filtroEstado == 'todos')
            ElevatedButton.icon(
              onPressed: () => _mostrarFormulario(),
              icon: const Icon(Icons.add),
              label: const Text("Registrar Primera Colmena"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726),
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

  Widget _buildColmenaCard(Map<String, dynamic> colmena, int index) {
    final estadoInfo = _estadosColmena.firstWhere(
      (estado) =>
          estado['nombre'].toLowerCase() == colmena['estado'].toLowerCase(),
      orElse: () => _estadosColmena[0],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: estadoInfo['color'], width: 4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con ubicación y estado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: estadoInfo['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        estadoInfo['icono'],
                        color: estadoInfo['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            colmena['ubicacion'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: estadoInfo['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              colmena['estado'],
                              style: TextStyle(
                                color: estadoInfo['color'],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'editar') {
                          _mostrarFormulario(colmena: colmena);
                        } else if (value == 'eliminar') {
                          _eliminarColmena(colmena['id'], colmena['ubicacion']);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'editar',
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Color(0xFFFFA726)),
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

                // Descripción técnica
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Descripción Técnica",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        colmena['descripcionTecnica'],
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Footer con información adicional
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "ID: ${colmena['id']}",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      estadoInfo['descripcion'],
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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
}
