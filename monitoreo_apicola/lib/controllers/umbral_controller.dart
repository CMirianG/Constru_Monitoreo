import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/umbral_model.dart';

class UmbralController {
  final _ref = FirebaseFirestore.instance.collection('umbrales');

  Future<void> guardarUmbral(Umbral umbral) async {
    await _ref.doc(umbral.tipoSensor).set(umbral.toMap());
  }

  Future<Umbral?> obtenerUmbral(String tipoSensor) async {
    final doc = await _ref.doc(tipoSensor).get();
    if (doc.exists) {
      return Umbral.fromMap(doc.data()!);
    }
    return null;
  }

  Future<List<Umbral>> listarTodos() async {
    final snapshot = await _ref.get();
    return snapshot.docs.map((e) => Umbral.fromMap(e.data())).toList();
  }
}
