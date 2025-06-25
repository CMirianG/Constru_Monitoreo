import 'package:cloud_firestore/cloud_firestore.dart';

class Mantenimiento {
  final String id;
  final String descripcion;
  final String estado;
  final DateTime fecha;

  Mantenimiento({
    required this.id,
    required this.descripcion,
    required this.estado,
    required this.fecha,
  });

  factory Mantenimiento.fromMap(Map<String, dynamic> data, String id) {
    DateTime fechaConvertida;

    // Manejo seguro de la conversión de fecha
    try {
      if (data['fecha'] is Timestamp) {
        fechaConvertida = (data['fecha'] as Timestamp).toDate();
      } else if (data['fecha'] is String) {
        fechaConvertida = DateTime.parse(data['fecha']);
      } else {
        fechaConvertida = DateTime.now(); // Fecha por defecto
      }
    } catch (e) {
      print("⚠️ Error al convertir fecha: $e");
      fechaConvertida = DateTime.now();
    }

    return Mantenimiento(
      id: id,
      descripcion: data['descripcion']?.toString() ?? '',
      estado: data['estado']?.toString() ?? '',
      fecha: fechaConvertida,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'descripcion': descripcion,
      'estado': estado,
      'fecha': Timestamp.fromDate(fecha),
    };
  }

  // Método para crear una copia con cambios
  Mantenimiento copyWith({
    String? id,
    String? descripcion,
    String? estado,
    DateTime? fecha,
  }) {
    return Mantenimiento(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      estado: estado ?? this.estado,
      fecha: fecha ?? this.fecha,
    );
  }
}
