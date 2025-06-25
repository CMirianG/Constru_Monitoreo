import 'package:cloud_firestore/cloud_firestore.dart';

class HistorialLectura {
  final String id;
  final String tipoSensor; // "co2" o "sonido"
  final double valor;
  final DateTime fecha;

  HistorialLectura({
    required this.id,
    required this.tipoSensor,
    required this.valor,
    required this.fecha,
  });

  factory HistorialLectura.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return HistorialLectura(
      id: documentId,
      tipoSensor: data['tipoSensor'],
      valor: data['valor'],
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'tipoSensor': tipoSensor, 'valor': valor, 'fecha': fecha};
  }
}
