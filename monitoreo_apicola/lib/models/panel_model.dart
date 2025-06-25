import 'package:monitoreo_apicola/models/alerta_model.dart';
import 'package:monitoreo_apicola/models/mantenimiento_model.dart';
import 'package:monitoreo_apicola/models/observacion_model.dart';
import 'package:monitoreo_apicola/models/sensor_model.dart';

class PanelEstado {
  final Sensor sensoresActuales;
  final List<Alerta> alertas;
  final List<Mantenimiento> mantenimientos;
  final List<Observacion> observaciones;

  PanelEstado({
    required this.sensoresActuales,
    required this.alertas,
    required this.mantenimientos,
    required this.observaciones,
  });
}
