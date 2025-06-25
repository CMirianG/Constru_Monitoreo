import 'package:cloud_firestore/cloud_firestore.dart';

class Observacion {
  final String id;
  final String descripcion;
  final DateTime fecha;

  Observacion({
    required this.id,
    required this.descripcion,
    required this.fecha,
  });

  /// Crea una instancia desde un documento Firestore
  factory Observacion.fromMap(Map<String, dynamic> data, String documentId) {
    DateTime fechaConvertida;

    // Manejo seguro de la conversión de fecha
    try {
      if (data['fecha'] is Timestamp) {
        fechaConvertida = (data['fecha'] as Timestamp).toDate();
      } else if (data['fecha'] is String) {
        fechaConvertida = DateTime.parse(data['fecha']);
      } else {
        print("⚠️ Campo fecha no válido, usando fecha actual");
        fechaConvertida = DateTime.now();
      }
    } catch (e) {
      print("⚠️ Error al convertir fecha: $e");
      fechaConvertida = DateTime.now();
    }

    return Observacion(
      id: documentId,
      descripcion: data['descripcion']?.toString() ?? '',
      fecha: fechaConvertida,
    );
  }

  /// Convierte el objeto a un mapa para guardarlo en Firestore
  Map<String, dynamic> toMap() {
    return {'descripcion': descripcion, 'fecha': Timestamp.fromDate(fecha)};
  }

  /// Método para crear una copia con cambios
  Observacion copyWith({String? id, String? descripcion, DateTime? fecha}) {
    return Observacion(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      fecha: fecha ?? this.fecha,
    );
  }

  @override
  String toString() {
    return 'Observacion{id: $id, descripcion: $descripcion, fecha: $fecha}';
  }
}
