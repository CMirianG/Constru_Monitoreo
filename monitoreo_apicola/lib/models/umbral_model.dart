class Umbral {
  final String tipoSensor; // 'co2' o 'sonido'
  final double minimo;
  final double maximo;

  Umbral({
    required this.tipoSensor,
    required this.minimo,
    required this.maximo,
  });

  factory Umbral.fromMap(Map<String, dynamic> data) {
    return Umbral(
      tipoSensor: data['tipoSensor'],
      minimo: (data['minimo'] as num).toDouble(),
      maximo: (data['maximo'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipoSensor': tipoSensor,
      'minimo': minimo,
      'maximo': maximo,
    };
  }
}
