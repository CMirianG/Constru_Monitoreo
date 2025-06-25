import 'package:cloud_firestore/cloud_firestore.dart';

class Sensor {
  final double co2;
  final double sonido;
  final DateTime fecha;

  Sensor({required this.co2, required this.sonido, required this.fecha});

  factory Sensor.fromMap(Map<String, dynamic> data) {
    return Sensor(
      co2: data['co2'],
      sonido: data['sonido'],
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'co2': co2, 'sonido': sonido, 'fecha': fecha};
  }
}
