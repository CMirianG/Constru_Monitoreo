class EstadisticaSensor {
  final String tipoSensor; // "co2" o "sonido"
  final double promedio;
  final double maximo;
  final double minimo;
  final List<double> tendencia;

  EstadisticaSensor({
    required this.tipoSensor,
    required this.promedio,
    required this.maximo,
    required this.minimo,
    required this.tendencia,
  });
}
