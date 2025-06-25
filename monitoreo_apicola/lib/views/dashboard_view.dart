import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

// Importar todas las vistas
import 'colmena_view.dart';
import 'historial_view.dart';
import 'lectura_thingspeak_view.dart';
import 'mantenimiento_view.dart';
import 'observacion_view.dart';
import 'umbral_view.dart';
import 'usuarios_view.dart';
import 'panel_estado_view.dart';
import 'report_view.dart';

// ✅ CLASE HELPER PARA RESPONSIVIDAD MEJORADA
class ResponsiveHelper {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 900;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 900;
  }

  static double getResponsivePadding(BuildContext context) {
    if (isSmallScreen(context)) return 16.0;
    if (isMediumScreen(context)) return 20.0;
    return 24.0;
  }

  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) return baseSize * 0.85;
    if (screenWidth < 400) return baseSize * 0.9;
    if (screenWidth > 600) return baseSize * 1.1;
    return baseSize;
  }

  static int getGridCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 1;
    if (width < 600) return 2;
    if (width < 900) return 2;
    return 3;
  }

  static double getCardAspectRatio(BuildContext context) {
    if (isSmallScreen(context)) return 1.6; // Más alto para móviles
    if (isMediumScreen(context)) return 1.4;
    return 1.3;
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with TickerProviderStateMixin {
  String rol = '';
  String nombreUsuario = '';
  String emailUsuario = '';
  bool isLoading = true;

  Map<String, int> contadores = {
    'colmenas': 0,
    'mantenimientos': 0,
    'observaciones': 0,
    'usuarios': 0,
    'lecturas': 0,
    'umbrales': 0,
    'reportes': 0,
  };

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargarDatosUsuario();
    _cargarContadores();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);

    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _rotationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (mounted) {
          // ✅ AGREGAR ESTA VERIFICACIÓN
          setState(() {
            rol = doc.data()?['rol'] ?? 'admin';
            nombreUsuario =
                doc.data()?['nombre'] ?? user.displayName ?? 'Usuario';
            emailUsuario = doc.data()?['email'] ?? user.email ?? '';
            isLoading = false;
          });
        }

        if (!doc.exists) {
          await _crearDocumentoUsuario(user);
        }
      }
    } catch (e) {
      print("❌ Error al cargar datos del usuario: $e");
      if (mounted) {
        // ✅ AGREGAR ESTA VERIFICACIÓN
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _crearDocumentoUsuario(User user) async {
    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set({
        'nombre': user.displayName ?? 'Usuario',
        'email': user.email ?? '',
        'rol': 'admin',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'activo': true,
      });

      if (mounted) {
        // ✅ AGREGAR ESTA VERIFICACIÓN
        setState(() {
          rol = 'admin';
        });
      }
    } catch (e) {
      print("❌ Error al crear documento de usuario: $e");
    }
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

      final lecturasCount = await _contarLecturasRecientes();

      if (mounted) {
        // ✅ AGREGAR ESTA VERIFICACIÓN
        setState(() {
          contadores = {
            'colmenas': colmenasSnapshot.docs.length,
            'mantenimientos': mantenimientosSnapshot.docs.length,
            'observaciones': observacionesSnapshot.docs.length,
            'usuarios': usuariosSnapshot.docs.length,
            'umbrales': umbralesSnapshot.docs.length,
            'lecturas': lecturasCount,
            'reportes': reportesSnapshot.docs.length,
          };
        });
      }
    } catch (e) {
      print("❌ Error al cargar contadores: $e");
      if (mounted) {
        // ✅ AGREGAR ESTA VERIFICACIÓN
        setState(() {
          contadores = {
            'colmenas': 0,
            'mantenimientos': 0,
            'observaciones': 0,
            'usuarios': 0,
            'umbrales': 0,
            'lecturas': 0,
            'reportes': 0,
          };
        });
      }
    }
  }

  Future<int> _contarLecturasRecientes() async {
    try {
      final fechaLimite = DateTime.now().subtract(const Duration(days: 7));
      final snapshot = await FirebaseFirestore.instance
          .collection('historial')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fechaLimite))
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _cerrarSesion() async {
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
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, color: Colors.red[700]),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                "Cerrar sesión",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: const Text(
          "¿Estás seguro de que quieres cerrar sesión?",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancelar",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Cerrar sesión"),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al cerrar sesión: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    }
  }

  Color _getColorByRole(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return const Color(0xFF6A1B9A);
      case 'admin':
        return const Color(0xFF1565C0);
      default:
        return const Color(0xFF00695C);
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'Super Administrador';
      case 'admin':
        return 'Administrador';
      default:
        return 'Usuario';
    }
  }

  bool _puedeGestionarUsuarios() {
    return rol.toLowerCase() == 'superadmin' || rol.toLowerCase() == 'admin';
  }

  String _formatearFecha(DateTime fecha) {
    try {
      return DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'es_ES').format(fecha);
    } catch (e) {
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getColorByRole(rol),
                _getColorByRole(rol).withOpacity(0.8),
                _getColorByRole(rol).withOpacity(0.6),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: Container(
                        width:
                            ResponsiveHelper.isSmallScreen(context) ? 80 : 100,
                        height:
                            ResponsiveHelper.isSmallScreen(context) ? 80 : 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.hive,
                          size:
                              ResponsiveHelper.isSmallScreen(context) ? 40 : 50,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveHelper.getResponsivePadding(context),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Sistema Apícola',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 24),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Cargando Dashboard...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: ResponsiveHelper.getResponsiveFontSize(
                              context, 16),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // App Bar mejorado
            _buildModernAppBar(),

            // Contenido principal
            SliverToBoxAdapter(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Padding(
                  padding: EdgeInsets.all(
                      ResponsiveHelper.getResponsivePadding(context)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tarjetas de estadísticas mejoradas
                      _buildModernStatsGrid(),
                      SizedBox(
                          height: ResponsiveHelper.isSmallScreen(context)
                              ? 24
                              : 32),

                      // Panel de Estado del Sistema
                      _buildSystemStatusSection(),
                      SizedBox(
                          height: ResponsiveHelper.isSmallScreen(context)
                              ? 24
                              : 32),

                      // Sección de monitoreo
                      _buildMonitoringSection(),
                      SizedBox(
                          height: ResponsiveHelper.isSmallScreen(context)
                              ? 24
                              : 32),

                      // Sección de gestión
                      _buildManagementSection(),
                      SizedBox(
                          height: ResponsiveHelper.isSmallScreen(context)
                              ? 24
                              : 32),

                      // Sección de reportes
                      _buildReportsSection(),
                      SizedBox(
                          height: ResponsiveHelper.isSmallScreen(context)
                              ? 24
                              : 32),

                      // Sección de administración
                      if (_puedeGestionarUsuarios()) _buildAdminSection(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    final isSmall = ResponsiveHelper.isSmallScreen(context);

    return SliverAppBar(
      expandedHeight: isSmall ? 180 : 220,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _getColorByRole(rol),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getColorByRole(rol),
                _getColorByRole(rol).withOpacity(0.9),
                _getColorByRole(rol).withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(
                  ResponsiveHelper.getResponsivePadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Header principal mejorado
                  _buildModernHeader(),
                  SizedBox(height: isSmall ? 16 : 20),
                  // Información adicional
                  _buildHeaderInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    final isSmall = ResponsiveHelper.isSmallScreen(context);

    return Row(
      children: [
        // Avatar mejorado
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: isSmall ? 60 : 70,
                height: isSmall ? 60 : 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isSmall ? 18 : 22),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.hive,
                  color: Colors.white,
                  size: isSmall ? 28 : 32,
                ),
              ),
            );
          },
        ),
        SizedBox(width: isSmall ? 16 : 20),

        // Información del usuario mejorada
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "¡Hola, $nombreUsuario!",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 26),
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: isSmall ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 12 : 16,
                  vertical: isSmall ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _getRoleDisplayName(rol),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize:
                        ResponsiveHelper.getResponsiveFontSize(context, 13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Botones de acción mejorados
        _buildModernActionButtons(),
      ],
    );
  }

  Widget _buildModernActionButtons() {
    final isSmall = ResponsiveHelper.isSmallScreen(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () async {
              await _cargarDatosUsuario();
              await _cargarContadores();
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.white,
              size: isSmall ? 22 : 26,
            ),
            tooltip: 'Actualizar',
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'perfil') {
                _mostrarPerfil();
              } else if (value == 'logout') {
                _cerrarSesion();
              }
            },
            icon: Icon(
              Icons.more_vert,
              color: Colors.white,
              size: isSmall ? 22 : 26,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'perfil',
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey),
                    SizedBox(width: 12),
                    Text('Mi Perfil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time,
            color: Colors.white.withOpacity(0.9),
            size: ResponsiveHelper.isSmallScreen(context) ? 16 : 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatearFecha(DateTime.now()),
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
              maxLines: ResponsiveHelper.isSmallScreen(context) ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatsGrid() {
    final stats = [
      {
        'title': 'Colmenas',
        'value': contadores['colmenas'].toString(),
        'icon': Icons.hive,
        'color': const Color(0xFFFF8F00),
        'trend': '+2.5%',
        'subtitle': 'Activas',
        'gradient': [const Color(0xFFFF8F00), const Color(0xFFFFB74D)],
      },
      {
        'title': 'Lecturas',
        'value': contadores['lecturas'].toString(),
        'icon': Icons.sensors,
        'color': const Color(0xFF00C853),
        'trend': '+12.3%',
        'subtitle': 'Esta semana',
        'gradient': [const Color(0xFF00C853), const Color(0xFF4CAF50)],
      },
      {
        'title': 'Mantenimientos',
        'value': contadores['mantenimientos'].toString(),
        'icon': Icons.build_circle,
        'color': const Color(0xFF3F51B5),
        'trend': '-5.2%',
        'subtitle': 'Pendientes',
        'gradient': [const Color(0xFF3F51B5), const Color(0xFF5C6BC0)],
      },
      {
        'title': 'Reportes',
        'value': contadores['reportes'].toString(),
        'icon': Icons.picture_as_pdf,
        'color': const Color(0xFFE91E63),
        'trend': '+15.7%',
        'subtitle': 'Generados',
        'gradient': [const Color(0xFFE91E63), const Color(0xFFEC407A)],
      },
    ];

    // Para móviles, usar ListView horizontal
    if (ResponsiveHelper.isSmallScreen(context)) {
      return SizedBox(
        height: 140,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: stats.length,
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              child: _buildModernStatCard(
                title: stat['title'] as String,
                value: stat['value'] as String,
                icon: stat['icon'] as IconData,
                color: stat['color'] as Color,
                trend: stat['trend'] as String,
                subtitle: stat['subtitle'] as String,
                gradient: stat['gradient'] as List<Color>,
                isCompact: true,
              ),
            );
          },
        ),
      );
    }

    // Para tablets y pantallas grandes
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.getGridCrossAxisCount(context),
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: ResponsiveHelper.getCardAspectRatio(context),
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return _buildModernStatCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
          trend: stat['trend'] as String,
          subtitle: stat['subtitle'] as String,
          gradient: stat['gradient'] as List<Color>,
          isCompact: false,
        );
      },
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
    required String subtitle,
    required List<Color> gradient,
    required bool isCompact,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header con icono y trend
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isCompact ? 20 : 24,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trend.startsWith('+')
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: trend.startsWith('+')
                          ? Colors.green[200]!
                          : Colors.red[200]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: trend.startsWith('+')
                          ? Colors.green[700]
                          : Colors.red[700],
                      fontSize: isCompact ? 10 : 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            // Valor principal
            Text(
              value,
              style: TextStyle(
                fontSize: isCompact ? 28 : 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            // Título y subtítulo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemStatusSection() {
    return _buildModernSection(
      title: '📋 Estado General del Sistema',
      children: [
        _buildModernMenuItem(
          context: context,
          title: 'Panel de Estado Completo',
          subtitle: 'Gráficos, alertas y monitoreo en tiempo real',
          icon: Icons.dashboard,
          color: const Color(0xFF4CAF50),
          badge: 'GRÁFICOS',
          view: const PanelEstadoView(),
        ),
      ],
    );
  }

  Widget _buildMonitoringSection() {
    return _buildModernSection(
      title: '📊 Monitoreo y Análisis',
      children: [
        _buildModernMenuItem(
          context: context,
          title: 'Monitoreo en Tiempo Real',
          subtitle: 'Sensores activos y datos actuales',
          icon: Icons.wifi_tethering,
          color: const Color(0xFF00C853),
          badge:
              contadores['lecturas']! > 0 ? '${contadores['lecturas']}' : null,
          view: const LecturaThingSpeakView(),
        ),
        _buildModernMenuItem(
          context: context,
          title: 'Historial de Datos',
          subtitle: 'Análisis histórico y tendencias',
          icon: Icons.analytics,
          color: const Color(0xFF2196F3),
          view: const LeerHistorialView(),
        ),
      ],
    );
  }

  Widget _buildManagementSection() {
    return _buildModernSection(
      title: '🐝 Gestión Apícola',
      children: [
        _buildModernMenuItem(
          context: context,
          title: 'Gestión de Colmenas',
          subtitle: 'Administrar y monitorear colmenas',
          icon: Icons.hive,
          color: const Color(0xFFFF8F00),
          badge: '${contadores['colmenas']}',
          view: const ColmenaView(),
        ),
        _buildModernMenuItem(
          context: context,
          title: 'Configurar Umbrales',
          subtitle: 'Límites y alertas del sistema',
          icon: Icons.tune,
          color: const Color(0xFFFF5722),
          badge: '${contadores['umbrales']}',
          view: const UmbralView(),
        ),
        _buildModernMenuItem(
          context: context,
          title: 'Mantenimientos',
          subtitle: 'Programar y gestionar mantenimientos',
          icon: Icons.build_circle,
          color: const Color(0xFF3F51B5),
          badge: '${contadores['mantenimientos']}',
          view: const MantenimientosView(),
        ),
        _buildModernMenuItem(
          context: context,
          title: 'Observaciones',
          subtitle: 'Registros y notas importantes',
          icon: Icons.visibility,
          color: const Color(0xFF00BCD4),
          badge: '${contadores['observaciones']}',
          view: const ObservacionesView(),
        ),
      ],
    );
  }

  Widget _buildReportsSection() {
    return _buildModernSection(
      title: '📊 Reportes del Sistema',
      children: [
        _buildModernMenuItem(
          context: context,
          title: 'Generar Reporte PDF',
          subtitle: 'Crear reporte con estadísticas del dashboard',
          icon: Icons.picture_as_pdf,
          color: const Color(0xFFE91E63),
          badge: 'PDF',
          view: const SimpleReportView(),
        ),
      ],
    );
  }

  Widget _buildAdminSection() {
    return _buildModernSection(
      title: '⚙️ Administración',
      children: [
        _buildModernMenuItem(
          context: context,
          title: 'Gestión de Usuarios',
          subtitle: 'Administrar cuentas y permisos',
          icon: Icons.manage_accounts,
          color: const Color(0xFF9C27B0),
          badge: '${contadores['usuarios']}',
          view: const UsuariosView(),
        ),
        _buildModernMenuItem(
          context: context,
          title: 'Configuración del Sistema',
          subtitle: 'Ajustes generales y preferencias',
          icon: Icons.settings,
          color: const Color(0xFF795548),
          view: _buildComingSoonView('Configuración del Sistema'),
        ),
      ],
    );
  }

  Widget _buildModernSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveHelper.getResponsiveFontSize(context, 22),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildModernMenuItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget view,
    String? badge,
  }) {
    final isSmall = ResponsiveHelper.isSmallScreen(context);

    return Container(
      margin: EdgeInsets.only(bottom: isSmall ? 12 : 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => view),
          ),
          child: Container(
            padding: EdgeInsets.all(isSmall ? 16 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.grey[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: color.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono mejorado
                Container(
                  width: isSmall ? 50 : 56,
                  height: isSmall ? 50 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isSmall ? 24 : 28,
                  ),
                ),
                SizedBox(width: isSmall ? 16 : 20),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: isSmall ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: isSmall ? 13 : 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: isSmall ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Badge y flecha
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badge != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmall ? 8 : 12,
                          vertical: isSmall ? 4 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: badge == 'GRÁFICOS'
                              ? Colors.green
                              : badge == 'NUEVO'
                                  ? const Color(0xFFE91E63)
                                  : badge == 'PRÓXIMO'
                                      ? Colors.orange
                                      : color,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (badge == 'GRÁFICOS'
                                      ? Colors.green
                                      : badge == 'NUEVO'
                                          ? const Color(0xFFE91E63)
                                          : badge == 'PRÓXIMO'
                                              ? Colors.orange
                                              : color)
                                  .withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmall ? 10 : 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    SizedBox(width: isSmall ? 8 : 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[600],
                        size: 14,
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

  Widget _buildComingSoonView(String feature) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          feature,
          style: TextStyle(
            fontSize: ResponsiveHelper.getResponsiveFontSize(context, 18),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFFFE0B2),
        foregroundColor: const Color(0xFF8D6E63),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFFFF8E1),
      body: Center(
        child: Padding(
          padding:
              EdgeInsets.all(ResponsiveHelper.getResponsivePadding(context)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: ResponsiveHelper.isSmallScreen(context) ? 120 : 140,
                height: ResponsiveHelper.isSmallScreen(context) ? 120 : 140,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE0B2), Color(0xFFFFCC02)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    ResponsiveHelper.isSmallScreen(context) ? 60 : 70,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFE0B2).withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.construction,
                  size: ResponsiveHelper.isSmallScreen(context) ? 60 : 70,
                  color: const Color(0xFF8D6E63),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                feature,
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 26),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8D6E63),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Esta funcionalidad estará disponible próximamente',
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 16),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7043),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal:
                        ResponsiveHelper.isSmallScreen(context) ? 24 : 32,
                    vertical: ResponsiveHelper.isSmallScreen(context) ? 12 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFFF7043).withOpacity(0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarPerfil() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: ResponsiveHelper.isSmallScreen(context) ? 50 : 60,
              height: ResponsiveHelper.isSmallScreen(context) ? 50 : 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getColorByRole(rol),
                    _getColorByRole(rol).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _getColorByRole(rol).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                "Mi Perfil",
                style: TextStyle(
                  fontSize: ResponsiveHelper.getResponsiveFontSize(context, 20),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileRow("Nombre:", nombreUsuario),
              _buildProfileRow("Email:", emailUsuario),
              _buildProfileRow("Rol:", _getRoleDisplayName(rol)),
              _buildProfileRow(
                  "UID:", FirebaseAuth.instance.currentUser?.uid ?? ""),
              const Divider(thickness: 1),
              _buildProfileRow(
                "Última conexión:",
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cerrar",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Edición de perfil - Próximamente"),
                  backgroundColor: _getColorByRole(rol),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _getColorByRole(rol),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text("Editar Perfil"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveHelper.isSmallScreen(context) ? 90 : 110,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
                fontSize: ResponsiveHelper.getResponsiveFontSize(context, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
