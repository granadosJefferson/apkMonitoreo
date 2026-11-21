import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../data/db.dart';
import '../data/registro.dart';

class Exportador {
  static final _fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Genera el .xlsx (con latitud, longitud y precisión GPS) y lo guarda en la carpeta
  /// de la app. Marca los registros como exportados.
  static Future<File?> generar({bool soloPendientes = false}) async {
    final registros = await Db.instance.todos(soloPendientes: soloPendientes);
    if (registros.isEmpty) return null;

    final excel = Excel.createExcel();
    final hoja = excel['Muestreo'];
    excel.delete('Sheet1');
    hoja.appendRow([
      'Código', 'Fecha y hora', 'Especie', 'Activo', 'Adulto', 'Sexo',
      'Antebrazo (mm)', 'Tibia (mm)', 'Peso (g)', 'Parásito',
      'Tipo de parásito', 'Cantidad', 'Observaciones',
      'Latitud', 'Longitud', 'Precisión GPS (m)',
    ].map((e) => TextCellValue(e)).toList());

    for (final r in registros.reversed) {
      hoja.appendRow(_fila(r));
    }

    final dir = await getExternalStorageDirectory() ??
        await getApplicationDocumentsDirectory();
    final nombre =
        'muestreo_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
    final file = File('${dir.path}/$nombre');
    await file.writeAsBytes(excel.encode()!);
    await Db.instance
        .marcarExportados(registros.map((r) => r.id!).toList());
    return file;
  }

  static List<CellValue?> _fila(Registro r) => [
        TextCellValue(r.codigo),
        TextCellValue(_fmt.format(r.fechaHora)),
        TextCellValue(r.especie),
        TextCellValue(r.activo ? 'Activo' : 'Inactivo'),
        TextCellValue(r.adulto ? 'Adulto' : 'No adulto'),
        TextCellValue(r.sexo),
        r.antebrazo == null ? null : DoubleCellValue(r.antebrazo!),
        r.tibia == null ? null : DoubleCellValue(r.tibia!),
        r.peso == null ? null : DoubleCellValue(r.peso!),
        TextCellValue(r.parasito ? 'Sí' : 'No'),
        TextCellValue(r.tipoParasito ?? ''),
        r.cantidadParasito == null ? null : IntCellValue(r.cantidadParasito!),
        TextCellValue(r.observaciones),
        r.lat == null ? null : DoubleCellValue(r.lat!),
        r.lon == null ? null : DoubleCellValue(r.lon!),
        r.precision == null
            ? null
            : DoubleCellValue(double.parse(r.precision!.toStringAsFixed(1))),
      ];

  static Future<void> compartir(File f) =>
      Share.shareXFiles([XFile(f.path)], text: 'Muestreo de murciélagos');
}
