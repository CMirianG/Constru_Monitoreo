/// Modelo de dominio para la entidad Colmena.
/// - Representa la única colmena gestionada por el sistema (RF-003).
/// - Define reglas de (de)serialización y validación antes de persistir en Firestore.
class Colmena {
  /// ID del documento en Firestore (no se serializa en `toMap`).
  final String id;

  /// Ubicación física dentro del apiario (ej.: "Sector A - Fila 3 - Posición 5").
  final String ubicacion;

  /// Estado actual de la colmena (ej.: "Activa", "Mantenimiento", "Problema").
  final String estado;

  /// Descripción técnica y observaciones relevantes.
  final String descripcionTecnica;

  Colmena({
    required this.id,
    required this.ubicacion,
    required this.estado,
    required this.descripcionTecnica,
  });

  /// Crea una Colmena desde un mapa de Firestore de forma **defensiva**:
  /// - Convierte todo a String con `toString()`.
  /// - Aplica `trim()` para evitar espacios residuales.
  /// - Usa `?? ''` para tolerar claves faltantes y prevenir NPEs.
  factory Colmena.fromMap(Map<String, dynamic> data, String documentId) {
    return Colmena(
      id: documentId,
      ubicacion: (data['ubicacion'] ?? '').toString().trim(),
      estado: (data['estado'] ?? '').toString().trim(),
      descripcionTecnica: (data['descripcionTecnica'] ?? '').toString().trim(),
    );
  }

  /// Serializa el objeto a mapa para Firestore.
  /// **Nota:** El `id` no se envía porque Firestore usa el ID del documento.
  Map<String, dynamic> toMap() {
    return {
      'ubicacion': ubicacion.trim(),
      'estado': estado.trim(),
      'descripcionTecnica': descripcionTecnica.trim(),
    };
  }

  /// Validación de dominio mínima antes de persistir/actualizar.
  /// Retorna `true` si los campos obligatorios están completos.
  bool esValida() {
    return ubicacion.isNotEmpty &&
        estado.isNotEmpty &&
        descripcionTecnica.isNotEmpty;
  }

  /// Permite crear una copia del objeto cambiando uno o más campos.
  /// Útil para **actualizaciones parciales** sin reconstruir toda la instancia.
  Colmena copiarCon({
    String? ubicacion,
    String? estado,
    String? descripcionTecnica,
  }) {
    return Colmena(
      id: id, // el ID no cambia aquí
      ubicacion: (ubicacion ?? this.ubicacion).trim(),
      estado: (estado ?? this.estado).trim(),
      descripcionTecnica:
          (descripcionTecnica ?? this.descripcionTecnica).trim(),
    );
  }
}
