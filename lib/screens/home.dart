import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/db.dart';
import '../data/registro.dart';
import '../services/exportador.dart';
import '../theme.dart';
import 'ajustes_drawer.dart';
import 'formulario.dart';
import 'mapa.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Registro> _registros = [];
  bool _online = false;
  bool _autoExport = false;
  StreamSubscription? _sub;
  final _fmt = DateFormat('dd/MM/yyyy HH:mm:ss');

  @override
  void initState() {
    super.initState();
    _cargar();
    SharedPreferences.getInstance()
        .then((p) => setState(() => _autoExport = p.getBool('auto') ?? false));
    Connectivity().checkConnectivity().then(_conexion);
    _sub = Connectivity().onConnectivityChanged.listen(_conexion);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _aviso(String texto, {SnackBarAction? accion}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto), action: accion));
  }

  Future<void> _conexion(List<ConnectivityResult> r) async {
    final online = r.any((e) => e != ConnectivityResult.none);
    final recienConectado = online && !_online;
    if (mounted) setState(() => _online = online);
    if (recienConectado && _autoExport) {
      try {
        final f = await Exportador.generar(soloPendientes: true);
        if (f != null) {
          await _cargar();
          _aviso('Exportación automática lista: ${f.path.split('/').last}');
        }
      } catch (e) {
        _aviso('No se pudo exportar automáticamente. Tus registros siguen guardados. ($e)');
      }
    }
  }

  Future<void> _cargar() async {
    final r = await Db.instance.todos();
    if (mounted) setState(() => _registros = r);
  }

  Future<void> _exportar() async {
    try {
      final f = await Exportador.generar();
      if (!mounted) return;
      if (f == null) {
        _aviso('No hay registros para exportar');
        return;
      }
      await _cargar();
      await Exportador.compartir(f);
    } catch (e) {
      _aviso('No se pudo exportar. Tus registros siguen guardados. ($e)');
    }
  }

  Future<void> _abrir([Registro? r]) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => Formulario(registro: r)));
    _cargar();
  }

  Future<void> _cambiarAuto(bool v) async {
    setState(() => _autoExport = v);
    (await SharedPreferences.getInstance()).setBool('auto', v);
  }

  Future<void> _borrar(Registro r) async {
    await Db.instance.borrar(r.id!);
    await _cargar();
    _aviso('Registro ${r.codigo} eliminado',
        accion: SnackBarAction(
            label: 'Deshacer',
            onPressed: () async {
              await Db.instance.insertar(r);
              _cargar();
            }));
  }

  Widget _estado(Registro r) {
    final b = Theme.of(context).brightness;
    final color = r.exportado ? Estados.exportado(b) : Estados.pendiente(b);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(r.exportado ? Icons.check_circle : Icons.schedule, size: 16, color: color),
      const SizedBox(width: 4),
      Text(r.exportado ? 'Exportado' : 'Pendiente',
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final pendientes = _registros.where((r) => !r.exportado).length;
    final esquema = Theme.of(context).colorScheme;
    final conexion = Estados.conexion(Theme.of(context).brightness);
    return Scaffold(
      drawer: AjustesDrawer(autoExport: _autoExport, onAutoExport: _cambiarAuto),
      appBar: AppBar(
        title: const Text('Muestreo de murciélagos'),
        actions: [
          IconButton(
            tooltip: 'Mapa',
            icon: const Icon(Icons.map),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => Mapa(registros: _registros))),
          ),
          IconButton(
            tooltip: 'Exportar a Excel',
            icon: const Icon(Icons.table_view),
            onPressed: _exportar,
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(children: [
            Expanded(
              child: Text(
                '${_registros.length} registros · $pendientes sin exportar',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Icon(_online ? Icons.cloud_done : Icons.cloud_off,
                size: 16, color: _online ? conexion : esquema.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(_online ? 'En línea' : 'Sin conexión',
                style: TextStyle(
                    fontSize: 12,
                    color: _online ? conexion : esquema.onSurfaceVariant)),
          ]),
        ),
        const Divider(),
        Expanded(
          child: _registros.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.edit_note, size: 48, color: esquema.onSurfaceVariant),
                      const SizedBox(height: 12),
                      Text('Aún no hay registros',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Toca “Nuevo” para registrar el primer murciélago.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: esquema.onSurfaceVariant)),
                    ]),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: _registros.length,
                  separatorBuilder: (_, _) => const Divider(indent: 16, endIndent: 16),
                  itemBuilder: (_, i) {
                    final r = _registros[i];
                    final detalle =
                        '${r.activo ? 'Activo' : 'Inactivo'} · ${r.adulto ? 'Adulto' : 'No adulto'}'
                        '${r.parasito ? ' · ${r.tipoParasito ?? 'Parásito'} x${r.cantidadParasito ?? '?'}' : ''}';
                    return Dismissible(
                      key: ValueKey(r.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                          color: esquema.errorContainer,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(Icons.delete, color: esquema.onErrorContainer)),
                      confirmDismiss: (_) async => await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('¿Eliminar registro?'),
                              content: Text(r.codigo),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancelar')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Eliminar')),
                              ],
                            ),
                          ) ??
                          false,
                      onDismissed: (_) => _borrar(r),
                      child: ListTile(
                        leading: Semantics(
                          label: r.sexo,
                          child: CircleAvatar(
                            backgroundColor: esquema.surfaceContainerHigh,
                            child: Text(r.sexo == 'Macho' ? 'M' : 'H',
                                style: TextStyle(
                                    color: esquema.primary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        title: Text.rich(TextSpan(children: [
                          TextSpan(
                              text: r.codigo,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          TextSpan(text: '  ${r.especie}'),
                        ])),
                        subtitle: Text('${_fmt.format(r.fechaHora)}\n$detalle'),
                        isThreeLine: true,
                        trailing: _estado(r),
                        onTap: () => _abrir(r),
                      ),
                    );
                  },
                ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrir(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }
}
