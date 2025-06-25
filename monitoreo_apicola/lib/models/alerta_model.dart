import 'package:cloud_firestore/cloud_firestore.dart';

class Alerta {
  final String id;
  final String tipoSensor; // "co2" o "sonido"
  final double valor;
  final String mensaje;
  final DateTime fecha;

  Alerta({
    required this.id,
    required this.tipoSensor,
    required this.valor,
    required this.mensaje,
    required this.fecha,
  });

  factory Alerta.fromMap(Map<String, dynamic> data, String documentId) {
    return Alerta(
      id: documentId,
      tipoSensor: data['tipoSensor'],
      valor: data['valor'],
      mensaje: data['mensaje'],
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipoSensor': tipoSensor,
      'valor': valor,
      'mensaje': mensaje,
      'fecha': fecha,
    };
  }
}
