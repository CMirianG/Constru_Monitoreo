import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TemaAplicacion {
  // Colores personalizados
  static const Color _tealPrimary = Color(0xFF00695C);
  static const Color _tealSecondary = Color(0xFF4DB6AC);
  static const Color _amber = Color(0xFFFFC107);
  static const Color _red = Color(0xFFE53935);
  static const Color _green = Color(0xFF43A047);
  static const Color _blue = Color(0xFF1E88E5);
  static const Color _purple = Color(0xFF8E24AA);

  // Tema claro mejorado
  static ThemeData get temaClaro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: _tealPrimary,
        brightness: Brightness.light,
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _tealPrimary,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // ✅ CORREGIDO: CardThemeData en lugar de CardTheme
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _tealPrimary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _tealPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _tealPrimary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ✅ AGREGADO: IconThemeData correctamente definido
      iconTheme: const IconThemeData(color: _tealPrimary, size: 24),
    );
  }

  // Tema oscuro
  static ThemeData get temaOscuro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.fromSeed(
        seedColor: _tealSecondary,
        brightness: Brightness.dark,
      ),

      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      // ✅ CORREGIDO: IconThemeData en lugar de ThemeData
      iconTheme: const IconThemeData(color: _tealSecondary, size: 24),

      // ✅ CORREGIDO: CardThemeData correctamente definido
      cardTheme: const CardThemeData(
        elevation: 4,
        color: Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _tealSecondary, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _tealSecondary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _tealSecondary,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF2A2A2A),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  // Método para obtener tema por rol
  static ThemeData temaParaRol(String rol, {bool modoOscuro = false}) {
    Color colorPrincipal;

    switch (rol.toLowerCase()) {
      case 'superadmin':
        colorPrincipal = _purple;
        break;
      case 'admin':
        colorPrincipal = _blue;
        break;
      default:
        colorPrincipal = _tealPrimary;
    }

    final temaBase = modoOscuro ? temaOscuro : temaClaro;

    return temaBase.copyWith(
      colorScheme: temaBase.colorScheme.copyWith(primary: colorPrincipal),
      appBarTheme: temaBase.appBarTheme.copyWith(
        backgroundColor: colorPrincipal,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: temaBase.elevatedButtonTheme.style?.copyWith(
          backgroundColor: WidgetStateProperty.all(colorPrincipal),
        ),
      ),
      floatingActionButtonTheme: temaBase.floatingActionButtonTheme.copyWith(
        backgroundColor: colorPrincipal,
      ),
      // ✅ AGREGADO: IconTheme personalizado por rol
      iconTheme: temaBase.iconTheme.copyWith(color: colorPrincipal),
    );
  }

  // Colores de estado
  static const Map<String, Color> coloresEstado = {
    'exito': _green,
    'advertencia': _amber,
    'error': _red,
    'info': _blue,
  };

  // ✅ AGREGADO: Método para obtener color por estado
  static Color obtenerColorEstado(String estado) {
    return coloresEstado[estado] ?? _blue;
  }

  // ✅ AGREGADO: Gradientes personalizados
  static LinearGradient gradientePrincipal(
    String rol, {
    bool modoOscuro = false,
  }) {
    Color colorPrincipal;

    switch (rol.toLowerCase()) {
      case 'superadmin':
        colorPrincipal = _purple;
        break;
      case 'admin':
        colorPrincipal = _blue;
        break;
      default:
        colorPrincipal = _tealPrimary;
    }

    return LinearGradient(
      colors: [colorPrincipal, colorPrincipal.withOpacity(0.7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// Clase simple para manejar el tema sin provider
class GestorTema {
  static bool _modoOscuro = false;
  static String _rolUsuario = 'usuario';
  static final List<VoidCallback> _listeners = [];

  static bool get modoOscuro => _modoOscuro;
  static String get rolUsuario => _rolUsuario;

  static ThemeData get tema =>
      TemaAplicacion.temaParaRol(_rolUsuario, modoOscuro: _modoOscuro);

  static get SharedPreferences => null;

  // ✅ AGREGADO: Sistema de listeners para notificar cambios
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  static void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  static Future<void> inicializar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _modoOscuro = prefs.getBool('modo_oscuro') ?? false;
      _rolUsuario = prefs.getString('rol_usuario') ?? 'usuario';
      _notifyListeners();
    } catch (e) {
      print('Error al inicializar tema: $e');
    }
  }

  static Future<void> cambiarModoOscuro(bool valor) async {
    try {
      _modoOscuro = valor;
      var SharedPreferences;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('modo_oscuro', valor);
      _notifyListeners();
    } catch (e) {
      print('Error al cambiar modo oscuro: $e');
    }
  }

  static Future<void> cambiarRolUsuario(String rol) async {
    try {
      _rolUsuario = rol;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('rol_usuario', rol);
      _notifyListeners();
    } catch (e) {
      print('Error al cambiar rol: $e');
    }
  }

  static Future<void> alternarModoOscuro() async {
    await cambiarModoOscuro(!_modoOscuro);
  }

  // ✅ AGREGADO: Método para obtener color por rol
  static Color obtenerColorRol(String? rol) {
    switch ((rol ?? _rolUsuario).toLowerCase()) {
      case 'superadmin':
        return TemaAplicacion._purple;
      case 'admin':
        return TemaAplicacion._blue;
      default:
        return TemaAplicacion._tealPrimary;
    }
  }

  // ✅ AGREGADO: Método para resetear tema
  static Future<void> resetearTema() async {
    await cambiarModoOscuro(false);
    await cambiarRolUsuario('usuario');
  }
}

// ✅ AGREGADO: Widget helper para aplicar tema dinámicamente
class TemaWidget extends StatefulWidget {
  final Widget child;

  const TemaWidget({super.key, required this.child});

  @override
  State<TemaWidget> createState() => _TemaWidgetState();
}

class _TemaWidgetState extends State<TemaWidget> {
  @override
  void initState() {
    super.initState();
    GestorTema.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    GestorTema.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(data: GestorTema.tema, child: widget.child);
  }
}
