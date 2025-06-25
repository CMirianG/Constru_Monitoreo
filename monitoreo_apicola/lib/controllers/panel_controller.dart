import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/historial_model.dart';
import '../models/umbral_model.dart';
import '../models/mantenimiento_model.dart';
import '../models/observacion_model.dart';

class PanelController {
  final _historialRef = FirebaseFirestore.instance.collection('historial');
  final _umbralesRef = FirebaseFirestore.instance.collection('umbrales');
  final _mantenimientosRef =
      FirebaseFirestore.instance.collection('mantenimientos');
  final _observacionesRef =
      FirebaseFirestore.instance.collection('observaciones');

  Future<List<HistorialLectura>> obtenerLecturasRecientes() async {
    final snapshot =
        await _historialRef.orderBy('fecha', descending: true).limit(10).get();
    return snapshot.docs
        .map((doc) => HistorialLectura.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<Map<String, Umbral>> obtenerUmbrales() async {
    final snapshot = await _umbralesRef.get();
    final map = <String, Umbral>{};
    for (var doc in snapshot.docs) {
      final umbral = Umbral.fromMap(doc.data());
      map[umbral.tipoSensor] = umbral;
    }
    return map;
  }

  Future<List<Mantenimiento>> obtenerMantenimientos() async {
    final snapshot = await _mantenimientosRef
        .orderBy('fecha', descending: true)
        .limit(5)
        .get();
    return snapshot.docs
        .map((doc) => Mantenimiento.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<Observacion>> obtenerObservaciones() async {
    final snapshot = await _observacionesRef
        .orderBy('fecha', descending: true)
        .limit(5)
        .get();
    return snapshot.docs
        .map((doc) => Observacion.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<String>> obtenerAlertas() async {
    final lecturas = await obtenerLecturasRecientes();
    final umbrales = await obtenerUmbrales();
    List<String> alertas = [];

    for (final lectura in lecturas) {
      final umbral = umbrales[lectura.tipoSensor];
      if (umbral != null) {
        if (lectura.valor < umbral.minimo || lectura.valor > umbral.maximo) {
          alertas.add(
              "⚠️ ${lectura.tipoSensor.toUpperCase()} fuera de umbral: ${lectura.valor}");
        }
      }
    }

    return alertas;
  }
}
