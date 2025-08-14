class Colmena {
  final String id;
  final String ubicacion;
  final String estado;
  final String descripcionTecnica;

  Colmena({
    required this.id,
    required this.ubicacion,
    required this.estado,
    required this.descripcionTecnica,
  });

  factory Colmena.fromMap(Map<String, dynamic> data, String documentId) {
    return Colmena(
      id: documentId,
      ubicacion: (data['ubicacion'] ?? '').toString().trim(),
      estado: (data['estado'] ?? '').toString().trim(),
      descripcionTecnica: (data['descripcionTecnica'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ubicacion': ubicacion.trim(),
      'estado': estado.trim(),
      'descripcionTecnica': descripcionTecnica.trim(),
    };
  }

  bool esValida() {
    return ubicacion.isNotEmpty &&
        estado.isNotEmpty &&
        descripcionTecnica.isNotEmpty;
  }

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
