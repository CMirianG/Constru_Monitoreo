import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> guardarLecturaEnFirestore({
  required String tipo,
  required String valor,
  required DateTime fecha,
}) async {
  try {
    await FirebaseFirestore.instance.collection('historial').add({
      'tipo': tipo,
      'valor': double.tryParse(valor) ?? 0,
      'timestamp': fecha,
    });
    print("✅ Guardado: $tipo = $valor en $fecha");
  } catch (e) {
    print("❌ Error al guardar en Firestore: $e");
  }
}
