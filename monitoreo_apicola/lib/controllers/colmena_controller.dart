import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/colmena_model.dart';

class ColmenaController {
  final _ref = FirebaseFirestore.instance.collection('colmenas');

  Future<List<Colmena>> getColmenas() async {
    final snapshot = await _ref.get();
    return snapshot.docs
        .map((doc) => Colmena.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addColmena(Colmena colmena) async {
    await _ref.add(colmena.toMap());
  }

  Future<void> updateColmena(Colmena colmena) async {
    await _ref.doc(colmena.id).update(colmena.toMap());
  }

  Future<void> deleteColmena(String id) async {
    await _ref.doc(id).delete();
  }
}
