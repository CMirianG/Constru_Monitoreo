import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';

class UsuariosView extends StatefulWidget {
  const UsuariosView({super.key});

  @override
  State<UsuariosView> createState() => _UsuariosViewState();
}

class _UsuariosViewState extends State<UsuariosView>
    with TickerProviderStateMixin {
  final UserController _controller = UserController();
  List<Usuario> _usuarios = [];
  List<Usuario> _usuariosFiltrados = [];
  bool _isLoading = false;
  String _filtroTexto = '';
  String _filtroRol = 'todos';

  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargarUsuarios();
    _searchController.addListener(_filtrarUsuarios);
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuarios() async {
    setState(() => _isLoading = true);
    try {
      final usuarios = await _controller.getUsuarios();
      setState(() {
        _usuarios = usuarios;
        _isLoading = false;
      });
      _filtrarUsuarios();
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarError("Error al cargar usuarios: ${e.toString()}");
    }
  }

  void _filtrarUsuarios() {
    setState(() {
      _usuariosFiltrados =
          _usuarios.where((usuario) {
            final coincideTexto =
                usuario.nombre.toLowerCase().contains(
                  _filtroTexto.toLowerCase(),
                ) ||
                usuario.email.toLowerCase().contains(
                  _filtroTexto.toLowerCase(),
                );
            final coincideRol =
                _filtroRol == 'todos' || usuario.rol == _filtroRol;
            return coincideTexto && coincideRol;
          }).toList();
    });
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _mostrarExito(String mensaje) {
    if (mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Color _getRoleColor(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return Colors.purple[700]!;
      case 'admin':
        return Colors.blue[700]!;
      default:
        return Colors.teal[700]!;
    }
  }

  String _getRoleDisplayName(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return 'Super Admin';
      case 'admin':
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }

  IconData _getRoleIcon(String rol) {
    switch (rol.toLowerCase()) {
      case 'superadmin':
        return Icons.admin_panel_settings;
      case 'admin':
        return Icons.manage_accounts;
      default:
        return Icons.person;
    }
  }

  void _mostrarFormulario({Usuario? usuario}) {
    final nombreCtrl = TextEditingController(text: usuario?.nombre ?? '');
    final emailCtrl = TextEditingController(text: usuario?.email ?? '');
    final passwordCtrl = TextEditingController();
    String rolSeleccionado = usuario?.rol ?? 'usuario';
    bool guardando = false;
    bool mostrarPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setDialogState) => Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header del diálogo
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getRoleColor(rolSeleccionado),
                                _getRoleColor(rolSeleccionado).withOpacity(0.8),
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  usuario == null
                                      ? Icons.person_add
                                      : Icons.edit,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      usuario == null
                                          ? "Nuevo Usuario"
                                          : "Editar Usuario",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      usuario == null
                                          ? "Crear una nueva cuenta de usuario"
                                          : "Modificar información del usuario",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Contenido del formulario
                        Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                // Campo Nombre
                                TextFormField(
                                  controller: nombreCtrl,
                                  decoration: InputDecoration(
                                    labelText: "Nombre completo",
                                    hintText: "Ingresa el nombre completo",
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _getRoleColor(rolSeleccionado),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  enabled: !guardando,
                                ),
                                const SizedBox(height: 20),

                                // Campo Email
                                TextFormField(
                                  controller: emailCtrl,
                                  decoration: InputDecoration(
                                    labelText: "Correo electrónico",
                                    hintText: "ejemplo@correo.com",
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.email,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: _getRoleColor(rolSeleccionado),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !guardando && usuario == null,
                                ),
                                const SizedBox(height: 20),

                                // Campo Contraseña (solo para nuevos usuarios)
                                if (usuario == null) ...[
                                  TextFormField(
                                    controller: passwordCtrl,
                                    decoration: InputDecoration(
                                      labelText: "Contraseña",
                                      hintText: "Mínimo 6 caracteres",
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[50],
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.orange[700],
                                        ),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          mostrarPassword
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.grey[600],
                                        ),
                                        onPressed: () {
                                          setDialogState(
                                            () =>
                                                mostrarPassword =
                                                    !mostrarPassword,
                                          );
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: _getRoleColor(rolSeleccionado),
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    obscureText: !mostrarPassword,
                                    enabled: !guardando,
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                // Selector de Rol
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: rolSeleccionado,
                                    decoration: InputDecoration(
                                      labelText: "Rol del usuario",
                                      prefixIcon: Container(
                                        margin: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _getRoleColor(
                                            rolSeleccionado,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          _getRoleIcon(rolSeleccionado),
                                          color: _getRoleColor(rolSeleccionado),
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'usuario',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.person,
                                              color: Colors.teal[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Usuario'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'admin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.manage_accounts,
                                              color: Colors.blue[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Administrador'),
                                          ],
                                        ),
                                      ),
                                      DropdownMenuItem(
                                        value: 'superadmin',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.admin_panel_settings,
                                              color: Colors.purple[700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Super Administrador'),
                                          ],
                                        ),
                                      ),
                                    ],
                                    onChanged:
                                        guardando
                                            ? null
                                            : (value) {
                                              setDialogState(
                                                () => rolSeleccionado = value!,
                                              );
                                            },
                                  ),
                                ),

                                if (guardando) ...[
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Guardando usuario...",
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Botones de acción
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed:
                                      guardando
                                          ? null
                                          : () => Navigator.pop(dialogContext),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text("Cancelar"),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed:
                                      guardando
                                          ? null
                                          : () async {
                                            // Validaciones
                                            if (nombreCtrl.text
                                                .trim()
                                                .isEmpty) {
                                              _mostrarError(
                                                "El nombre es obligatorio",
                                              );
                                              return;
                                            }
                                            if (emailCtrl.text.trim().isEmpty) {
                                              _mostrarError(
                                                "El email es obligatorio",
                                              );
                                              return;
                                            }
                                            if (!emailCtrl.text.contains('@')) {
                                              _mostrarError("Email no válido");
                                              return;
                                            }
                                            if (usuario == null &&
                                                passwordCtrl.text.length < 6) {
                                              _mostrarError(
                                                "La contraseña debe tener al menos 6 caracteres",
                                              );
                                              return;
                                            }

                                            setDialogState(
                                              () => guardando = true,
                                            );

                                            try {
                                              if (usuario == null) {
                                                await _controller
                                                    .crearUsuarioConPassword(
                                                      nombre:
                                                          nombreCtrl.text
                                                              .trim(),
                                                      email:
                                                          emailCtrl.text.trim(),
                                                      password:
                                                          passwordCtrl.text,
                                                      rol: rolSeleccionado,
                                                    );
                                                _mostrarExito(
                                                  "Usuario creado correctamente",
                                                );
                                              } else {
                                                final usuarioActualizado =
                                                    usuario.copyWith(
                                                      nombre:
                                                          nombreCtrl.text
                                                              .trim(),
                                                      rol: rolSeleccionado,
                                                    );
                                                await _controller.updateUsuario(
                                                  usuarioActualizado,
                                                );
                                                _mostrarExito(
                                                  "Usuario actualizado correctamente",
                                                );
                                              }

                                              Navigator.pop(dialogContext);
                                              await _cargarUsuarios();
                                            } catch (e) {
                                              setDialogState(
                                                () => guardando = false,
                                              );
                                              String errorMsg = e.toString();
                                              if (errorMsg.contains(
                                                'email-already-in-use',
                                              )) {
                                                errorMsg =
                                                    "Este email ya está registrado";
                                              } else if (errorMsg.contains(
                                                'weak-password',
                                              )) {
                                                errorMsg =
                                                    "La contraseña es muy débil";
                                              }
                                              _mostrarError("Error: $errorMsg");
                                            }
                                          },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _getRoleColor(
                                      rolSeleccionado,
                                    ),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        usuario == null
                                            ? Icons.person_add
                                            : Icons.save,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        usuario == null
                                            ? "Crear Usuario"
                                            : "Guardar Cambios",
                                      ),
                                    ],
                                  ),
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

  Future<void> _eliminarUsuario(String uid, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.warning_amber, color: Colors.red[700]),
                ),
                const SizedBox(width: 12),
                const Text("Confirmar eliminación"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("¿Estás seguro de eliminar al usuario?"),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Esta acción no se puede deshacer.",
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
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
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete, size: 18),
                    SizedBox(width: 4),
                    Text("Eliminar"),
                  ],
                ),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        await _controller.deleteUsuario(uid);
        await _cargarUsuarios();
        _mostrarExito("Usuario eliminado correctamente");
      } catch (e) {
        _mostrarError("Error al eliminar: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('👥 Gestión de Usuarios'),
        backgroundColor: Colors.purple[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _cargarUsuarios,
            tooltip: 'Actualizar lista',
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimationController,
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : () => _mostrarFormulario(),
          backgroundColor: Colors.purple[700],
          icon: const Icon(Icons.person_add),
          label: const Text("Nuevo Usuario"),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Header con estadísticas y búsqueda
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[700]!, Colors.purple[500]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Estadísticas
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          "Total Usuarios",
                          "${_usuarios.length}",
                          Icons.people,
                          Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          "Administradores",
                          "${_usuarios.where((u) => u.rol == 'admin' || u.rol == 'superadmin').length}",
                          Icons.admin_panel_settings,
                          Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() => _filtroTexto = value);
                        _filtrarUsuarios();
                      },
                      decoration: InputDecoration(
                        hintText: "Buscar usuarios...",
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        suffixIcon:
                            _filtroTexto.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _filtroTexto = '');
                                    _filtrarUsuarios();
                                  },
                                )
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtro por rol
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleFilter('todos', 'Todos'),
                        _buildRoleFilter('usuario', 'Usuarios'),
                        _buildRoleFilter('admin', 'Admins'),
                        _buildRoleFilter('superadmin', 'Super Admins'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de usuarios
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Cargando usuarios..."),
                          ],
                        ),
                      )
                      : _usuariosFiltrados.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _filtroTexto.isNotEmpty || _filtroRol != 'todos'
                                  ? Icons.search_off
                                  : Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filtroTexto.isNotEmpty || _filtroRol != 'todos'
                                  ? "No se encontraron usuarios"
                                  : "No hay usuarios registrados",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _filtroTexto.isNotEmpty || _filtroRol != 'todos'
                                  ? "Intenta con otros términos de búsqueda"
                                  : "Agrega el primer usuario al sistema",
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _cargarUsuarios,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _usuariosFiltrados.length,
                          itemBuilder: (context, index) {
                            final usuario = _usuariosFiltrados[index];
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    index * 0.1,
                                    1.0,
                                    curve: Curves.easeOutCubic,
                                  ),
                                ),
                              ),
                              child: _buildUserCard(usuario, index),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilter(String rol, String label) {
    final isSelected = _filtroRol == rol;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filtroRol = rol);
          _filtrarUsuarios();
        },
        backgroundColor: Colors.white.withOpacity(0.2),
        selectedColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.purple[700] : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildUserCard(Usuario usuario, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                _getRoleColor(usuario.rol).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getRoleColor(usuario.rol),
                        _getRoleColor(usuario.rol).withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getRoleIcon(usuario.rol),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Información del usuario
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        usuario.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              usuario.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(usuario.rol).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getRoleDisplayName(usuario.rol),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getRoleColor(usuario.rol),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botones de acción
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue[600]),
                      onPressed: () => _mostrarFormulario(usuario: usuario),
                      tooltip: 'Editar usuario',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[600]),
                      onPressed:
                          () => _eliminarUsuario(usuario.uid, usuario.nombre),
                      tooltip: 'Eliminar usuario',
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
