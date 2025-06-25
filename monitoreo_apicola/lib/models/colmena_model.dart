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
      ubicacion: data['ubicacion'],
      estado: data['estado'],
      descripcionTecnica: data['descripcionTecnica'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ubicacion': ubicacion,
      'estado': estado,
      'descripcionTecnica': descripcionTecnica,
    };
  }
}
