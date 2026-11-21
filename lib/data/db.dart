import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'registro.dart';

class Db {
  Db._();
  static final Db instance = Db._();
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'murcielagos.db');
    _db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE registros(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codigo TEXT NOT NULL,
          parasito INTEGER NOT NULL,
          tipo_parasito TEXT,
          cantidad_parasito INTEGER,
          especie TEXT NOT NULL,
          fecha_hora TEXT NOT NULL,
          activo INTEGER NOT NULL,
          adulto INTEGER NOT NULL,
          sexo TEXT NOT NULL,
          antebrazo REAL,
          tibia REAL,
          peso REAL,
          observaciones TEXT,
          lat REAL,
          lon REAL,
          precision_m REAL,
          exportado INTEGER NOT NULL DEFAULT 0
        )''');
    });
    return _db!;
  }

  Future<int> insertar(Registro r) async =>
      (await _database).insert('registros', r.toMap()..remove('id'));

  Future<void> actualizar(Registro r) async => (await _database)
      .update('registros', r.toMap(), where: 'id = ?', whereArgs: [r.id]);

  Future<void> borrar(int id) async =>
      (await _database).delete('registros', where: 'id = ?', whereArgs: [id]);

  Future<List<Registro>> todos({bool soloPendientes = false}) async {
    final rows = await (await _database).query('registros',
        where: soloPendientes ? 'exportado = 0' : null,
        orderBy: 'fecha_hora DESC');
    return rows.map(Registro.fromMap).toList();
  }

  Future<bool> existeCodigo(String codigo, {int? excepto}) async {
    final rows = await (await _database).query('registros',
        columns: ['id'],
        where: excepto == null ? 'codigo = ?' : 'codigo = ? AND id != ?',
        whereArgs: excepto == null ? [codigo] : [codigo, excepto],
        limit: 1);
    return rows.isNotEmpty;
  }

  Future<void> marcarExportados(List<int> ids) async {
    if (ids.isEmpty) return;
    await (await _database).update('registros', {'exportado': 1},
        where: 'id IN (${List.filled(ids.length, '?').join(',')})',
        whereArgs: ids);
  }

  Future<List<String>> especies() async {
    final rows = await (await _database).rawQuery(
        'SELECT DISTINCT especie FROM registros ORDER BY especie COLLATE NOCASE');
    return rows.map((r) => r['especie'] as String).toList();
  }
}
