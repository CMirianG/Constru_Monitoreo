import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alerta_model.dart';

class AlertaController {
  final _db = FirebaseFirestore.instance;

  Future<List<Alerta>> getAlertas() async {
    final snapshot =
        await _db
            .collection('alertas')
            .orderBy('fecha', descending: true)
            .get();
    return snapshot.docs.map((e) => Alerta.fromMap(e.data(), e.id)).toList();
  }

  Future<void> addAlerta(Alerta alerta) async {
    await _db.collection('alertas').add(alerta.toMap());
  }
}
