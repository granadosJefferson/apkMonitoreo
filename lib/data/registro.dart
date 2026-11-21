class Registro {
  final int? id;
  final String codigo;
  final bool parasito;
  final String? tipoParasito; // 'Ácaro' | 'Mosca'
  final int? cantidadParasito;
  final String especie;
  final DateTime fechaHora;
  final bool activo;
  final bool adulto;
  final String sexo; // 'Macho' | 'Hembra'
  final double? antebrazo; // mm
  final double? tibia; // mm
  final double? peso; // g
  final String observaciones;
  final double? lat;
  final double? lon;
  final double? precision;
  final bool exportado;

  const Registro({
    this.id,
    required this.codigo,
    required this.parasito,
    this.tipoParasito,
    this.cantidadParasito,
    required this.especie,
    required this.fechaHora,
    required this.activo,
    required this.adulto,
    required this.sexo,
    this.antebrazo,
    this.tibia,
    this.peso,
    this.observaciones = '',
    this.lat,
    this.lon,
    this.precision,
    this.exportado = false,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'codigo': codigo,
        'parasito': parasito ? 1 : 0,
        'tipo_parasito': tipoParasito,
        'cantidad_parasito': cantidadParasito,
        'especie': especie,
        'fecha_hora': fechaHora.toIso8601String(),
        'activo': activo ? 1 : 0,
        'adulto': adulto ? 1 : 0,
        'sexo': sexo,
        'antebrazo': antebrazo,
        'tibia': tibia,
        'peso': peso,
        'observaciones': observaciones,
        'lat': lat,
        'lon': lon,
        'precision_m': precision,
        'exportado': exportado ? 1 : 0,
      };

  factory Registro.fromMap(Map<String, Object?> m) => Registro(
        id: m['id'] as int?,
        codigo: m['codigo'] as String,
        parasito: m['parasito'] == 1,
        tipoParasito: m['tipo_parasito'] as String?,
        cantidadParasito: m['cantidad_parasito'] as int?,
        especie: m['especie'] as String,
        fechaHora: DateTime.parse(m['fecha_hora'] as String),
        activo: m['activo'] == 1,
        adulto: m['adulto'] == 1,
        sexo: m['sexo'] as String,
        antebrazo: (m['antebrazo'] as num?)?.toDouble(),
        tibia: (m['tibia'] as num?)?.toDouble(),
        peso: (m['peso'] as num?)?.toDouble(),
        observaciones: (m['observaciones'] as String?) ?? '',
        lat: (m['lat'] as num?)?.toDouble(),
        lon: (m['lon'] as num?)?.toDouble(),
        precision: (m['precision_m'] as num?)?.toDouble(),
        exportado: m['exportado'] == 1,
      );
}
