import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/estadisticas_model.dart';

class EstadisticasController {
  Future<EstadisticaSensor> generarEstadistica(String tipoSensor) async {
    // Leer historial filtrado directamente desde Firestore
    final snapshot =
        await FirebaseFirestore.instance
            .collection('historial')
            .where('tipo', isEqualTo: tipoSensor)
            .orderBy('timestamp', descending: true)
            .limit(50) // puedes ajustar según necesidad
            .get();

    final valores =
        snapshot.docs
            .map((doc) => double.tryParse(doc['valor'].toString()) ?? 0.0)
            .where((v) => v > 0)
            .toList();

    if (valores.isEmpty) {
      return EstadisticaSensor(
        tipoSensor: tipoSensor,
        promedio: 0,
        maximo: 0,
        minimo: 0,
        tendencia: [],
      );
    }

    final promedio = valores.reduce((a, b) => a + b) / valores.length;
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final tendencia = valores.take(10).toList();

    return EstadisticaSensor(
      tipoSensor: tipoSensor,
      promedio: promedio,
      maximo: maximo,
      minimo: minimo,
      tendencia: tendencia,
    );
  }
}
