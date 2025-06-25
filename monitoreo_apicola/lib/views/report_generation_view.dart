class ReportModel {
  final String id;
  final String colmenaId;
  final String colmenaNombre;
  final DateTime fechaGeneracion;
  final List<SensorData> historialSensores;
  final List<MantenimientoRecord> mantenimientos;
  final List<ObservacionRecord> observaciones;
  final String tipoReporte;
  final DateTime fechaInicio;
  final DateTime fechaFin;

  ReportModel({
    required this.id,
    required this.colmenaId,
    required this.colmenaNombre,
    required this.fechaGeneracion,
    required this.historialSensores,
    required this.mantenimientos,
    required this.observaciones,
    required this.tipoReporte,
    required this.fechaInicio,
    required this.fechaFin,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'colmenaId': colmenaId,
      'colmenaNombre': colmenaNombre,
      'fechaGeneracion': fechaGeneracion.toIso8601String(),
      'historialSensores': historialSensores.map((s) => s.toJson()).toList(),
      'mantenimientos': mantenimientos.map((m) => m.toJson()).toList(),
      'observaciones': observaciones.map((o) => o.toJson()).toList(),
      'tipoReporte': tipoReporte,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'],
      colmenaId: json['colmenaId'],
      colmenaNombre: json['colmenaNombre'],
      fechaGeneracion: DateTime.parse(json['fechaGeneracion']),
      historialSensores: (json['historialSensores'] as List)
          .map((s) => SensorData.fromJson(s))
          .toList(),
      mantenimientos: (json['mantenimientos'] as List)
          .map((m) => MantenimientoRecord.fromJson(m))
          .toList(),
      observaciones: (json['observaciones'] as List)
          .map((o) => ObservacionRecord.fromJson(o))
          .toList(),
      tipoReporte: json['tipoReporte'],
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
    );
  }
}

class SensorData {
  final String id;
  final DateTime timestamp;
  final double temperatura;
  final double humedad;
  final double peso;
  final String estado;
  final Map<String, dynamic>? metadatos;

  SensorData({
    required this.id,
    required this.timestamp,
    required this.temperatura,
    required this.humedad,
    required this.peso,
    required this.estado,
    this.metadatos,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'temperatura': temperatura,
      'humedad': humedad,
      'peso': peso,
      'estado': estado,
      'metadatos': metadatos,
    };
  }

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      temperatura: json['temperatura'].toDouble(),
      humedad: json['humedad'].toDouble(),
      peso: json['peso'].toDouble(),
      estado: json['estado'],
      metadatos: json['metadatos'],
    );
  }
}

class MantenimientoRecord {
  final String id;
  final DateTime fecha;
  final String tipo;
  final String descripcion;
  final String tecnico;
  final String estado;
  final List<String> materialesUsados;
  final double costo;
  final String? observaciones;

  MantenimientoRecord({
    required this.id,
    required this.fecha,
    required this.tipo,
    required this.descripcion,
    required this.tecnico,
    required this.estado,
    required this.materialesUsados,
    required this.costo,
    this.observaciones,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'tipo': tipo,
      'descripcion': descripcion,
      'tecnico': tecnico,
      'estado': estado,
      'materialesUsados': materialesUsados,
      'costo': costo,
      'observaciones': observaciones,
    };
  }

  factory MantenimientoRecord.fromJson(Map<String, dynamic> json) {
    return MantenimientoRecord(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      tipo: json['tipo'],
      descripcion: json['descripcion'],
      tecnico: json['tecnico'],
      estado: json['estado'],
      materialesUsados: List<String>.from(json['materialesUsados']),
      costo: json['costo'].toDouble(),
      observaciones: json['observaciones'],
    );
  }
}

class ObservacionRecord {
  final String id;
  final DateTime fecha;
  final String categoria;
  final String descripcion;
  final String observador;
  final String prioridad;
  final List<String>? imagenes;
  final Map<String, dynamic>? datosAdicionales;

  ObservacionRecord({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    required this.observador,
    required this.prioridad,
    this.imagenes,
    this.datosAdicionales,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha.toIso8601String(),
      'categoria': categoria,
      'descripcion': descripcion,
      'observador': observador,
      'prioridad': prioridad,
      'imagenes': imagenes,
      'datosAdicionales': datosAdicionales,
    };
  }

  factory ObservacionRecord.fromJson(Map<String, dynamic> json) {
    return ObservacionRecord(
      id: json['id'],
      fecha: DateTime.parse(json['fecha']),
      categoria: json['categoria'],
      descripcion: json['descripcion'],
      observador: json['observador'],
      prioridad: json['prioridad'],
      imagenes:
          json['imagenes'] != null ? List<String>.from(json['imagenes']) : null,
      datosAdicionales: json['datosAdicionales'],
    );
  }
}
