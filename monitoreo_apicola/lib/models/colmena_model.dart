/// Modelo de datos que representa la información de una colmena en el sistema.
/// Forma parte del RF-003: Gestión de Colmena.
class Colmena {
  /// ID único del documento en Firestore (no se guarda en `toMap`).
  final String id;

  /// Ubicación física de la colmena dentro del apiario.
  final String ubicacion;

  /// Estado actual de la colmena (ejemplo: "Activa", "Mantenimiento", "Problema").
  final String estado;

  /// Descripción técnica y observaciones relevantes sobre la colmena.
  final String descripcionTecnica;

  /// Constructor para inicializar todos los campos obligatorios.
  Colmena({
    required this.id,
    required this.ubicacion,
    required this.estado,
    required this.descripcionTecnica,
  });

  /// Crea una instancia de `Colmena` a partir de un mapa (datos de Firestore).
  /// Se asegura de:
  /// - Convertir todos los valores a String.
  /// - Eliminar espacios en blanco sobrantes.
  /// - Evitar errores si un campo está ausente (`?? ''`).
  factory Colmena.fromMap(Map<String, dynamic> data, String documentId) {
    return Colmena(
      id: documentId,
      ubicacion: (data['ubicacion'] ?? '').toString().trim(),
      estado: (data['estado'] ?? '').toString().trim(),
      descripcionTecnica: (data['descripcionTecnica'] ?? '').toString().trim(),
    );
  }

  /// Convierte la instancia actual a un mapa para guardar en Firestore.
  /// El campo `id` no se incluye porque Firestore lo maneja como clave primaria.
  Map<String, dynamic> toMap() {
    return {
      'ubicacion': ubicacion.trim(),
      'estado': estado.trim(),
      'descripcionTecnica': descripcionTecnica.trim(),
    };
  }

  /// Verifica que los campos obligatorios tengan datos válidos antes de guardar.
  bool esValida() {
    return ubicacion.isNotEmpty &&
        estado.isNotEmpty &&
        descripcionTecnica.isNotEmpty;
  }

  /// Devuelve una copia del objeto, permitiendo modificar uno o más campos.
  /// Útil para actualizaciones parciales sin sobrescribir toda la información.
  Colmena copiarCon({
    String? ubicacion,
    String? estado,
    String? descripcionTecnica,
  }) {
    return Colmena(
      id: id,
      ubicacion: (ubicacion ?? this.ubicacion).trim(),
      estado: (estado ?? this.estado).trim(),
      descripcionTecnica:
          (descripcionTecnica ?? this.descripcionTecnica).trim(),
    );
  }
}
