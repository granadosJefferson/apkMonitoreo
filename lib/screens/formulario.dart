import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/db.dart';
import '../data/registro.dart';
import '../services/ubicacion.dart';

class Formulario extends StatefulWidget {
  final Registro? registro;
  const Formulario({super.key, this.registro});
  @override
  State<Formulario> createState() => _FormularioState();
}

class _FormularioState extends State<Formulario> {
  final _key = GlobalKey<FormState>();
  final _scroll = ScrollController();
  final _codigo = TextEditingController();
  final _especie = TextEditingController();
  final _antebrazo = TextEditingController();
  final _tibia = TextEditingController();
  final _peso = TextEditingController();
  final _cantidad = TextEditingController();
  final _obs = TextEditingController();

  bool _parasito = false;
  String _tipo = 'Ácaro';
  bool _activo = true;
  bool _adulto = true;
  // Sin valor por defecto: el sexo lo elige quien registra.
  String? _sexo;
  bool _sexoSinElegir = false;
  List<String> _especies = [];

  double? _lat, _lon, _precision;
  bool _buscandoGps = false;
  bool _guardando = false;
  // Unidad de antebrazo y tibia en pantalla. Siempre se guarda en milímetros.
  bool _cm = false;

  bool get _editando => widget.registro != null;

  @override
  void initState() {
    super.initState();
    Db.instance.especies().then((e) {
      if (mounted) setState(() => _especies = e);
    });
    final r = widget.registro;
    if (r != null) {
      _codigo.text = r.codigo;
      _especie.text = r.especie;
      _antebrazo.text = r.antebrazo?.toString() ?? '';
      _tibia.text = r.tibia?.toString() ?? '';
      _peso.text = r.peso?.toString() ?? '';
      _cantidad.text = r.cantidadParasito?.toString() ?? '';
      _obs.text = r.observaciones;
      _parasito = r.parasito;
      _tipo = r.tipoParasito ?? 'Ácaro';
      _activo = r.activo;
      _adulto = r.adulto;
      _sexo = r.sexo;
      _lat = r.lat;
      _lon = r.lon;
      _precision = r.precision;
    } else {
      _sugerirCodigo();
      _obtenerGps();
      // En registros nuevos se recuerda la última unidad usada.
      SharedPreferences.getInstance().then((p) {
        final cm = p.getBool('largo_en_cm') ?? false;
        if (mounted && cm != _cm && _antebrazo.text.isEmpty && _tibia.text.isEmpty) {
          setState(() => _cm = cm);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in [_codigo, _especie, _antebrazo, _tibia, _peso, _cantidad, _obs]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Propone el código siguiente al último registrado (ej. M-007 -> M-008).
  Future<void> _sugerirCodigo() async {
    final todos = await Db.instance.todos();
    if (!mounted || todos.isEmpty || _codigo.text.isNotEmpty) return;
    final m = RegExp(r'^(.*?)(\d+)$').firstMatch(todos.first.codigo);
    if (m == null) return;
    final numero = m.group(2)!;
    final siguiente = (int.parse(numero) + 1).toString().padLeft(numero.length, '0');
    setState(() => _codigo.text = '${m.group(1)}$siguiente');
  }

  Future<void> _obtenerGps() async {
    setState(() => _buscandoGps = true);
    final p = await Ubicacion.actual();
    if (!mounted) return;
    setState(() {
      _buscandoGps = false;
      if (p != null) {
        _lat = p.latitude;
        _lon = p.longitude;
        _precision = p.accuracy;
      }
    });
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.'));

  Future<bool> _confirmar(String titulo, String texto, String si, String no) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(titulo),
          content: Text(texto),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(no)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(si)),
          ],
        ),
      ) ??
      false;

  Future<void> _guardar({bool yNuevo = false}) async {
    final formOk = _key.currentState!.validate();
    if (_sexo == null) setState(() => _sexoSinElegir = true);
    if (!formOk || _sexo == null) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
      return;
    }

    // Sin GPS: avisar antes de guardar un registro sin ubicación.
    if (!_editando && _lat == null && !_buscandoGps) {
      final guardarIgual = await _confirmar(
          'Sin ubicación',
          'No se obtuvo la posición GPS. Puedes reintentar o guardar sin ubicación.',
          'Guardar sin ubicación',
          'Reintentar GPS');
      if (!guardarIgual) {
        _obtenerGps();
        return;
      }
    }

    final codigo = _codigo.text.trim();
    if (await Db.instance.existeCodigo(codigo, excepto: widget.registro?.id)) {
      if (!mounted) return;
      final igual = await _confirmar('Código repetido',
          'Ya existe un registro con el código $codigo. ¿Guardar de todos modos?',
          'Guardar igual', 'Cambiar código');
      if (!igual) return;
    }
    if (!mounted) return;

    setState(() => _guardando = true);
    final mensajes = ScaffoldMessenger.of(context);
    final r = Registro(
      id: widget.registro?.id,
      codigo: codigo,
      parasito: _parasito,
      tipoParasito: _parasito ? _tipo : null,
      cantidadParasito: _parasito ? int.tryParse(_cantidad.text) : null,
      especie: _especie.text.trim(),
      // Hora exacta del momento de guardar (se conserva al editar).
      fechaHora: widget.registro?.fechaHora ?? DateTime.now(),
      activo: _activo,
      adulto: _adulto,
      sexo: _sexo!,
      antebrazo: _enMm(_antebrazo),
      tibia: _enMm(_tibia),
      peso: _num(_peso),
      observaciones: _obs.text.trim(),
      lat: _lat,
      lon: _lon,
      precision: _precision,
    );
    try {
      _editando ? await Db.instance.actualizar(r) : await Db.instance.insertar(r);
    } catch (e) {
      if (mounted) setState(() => _guardando = false);
      mensajes.showSnackBar(SnackBar(
          content: Text('No se pudo guardar: $e. Tus datos siguen en pantalla.')));
      return;
    }
    mensajes.showSnackBar(SnackBar(content: Text('Guardado: $codigo')));
    if (!mounted) return;

    if (yNuevo) {
      // Se conservan especie, estado y edad; se limpia lo propio de cada animal.
      setState(() {
        _guardando = false;
        _sexo = null;
        _sexoSinElegir = false;
        _parasito = false;
        _lat = _lon = _precision = null;
      });
      for (final c in [_antebrazo, _tibia, _peso, _cantidad, _obs]) {
        c.clear();
      }
      _codigo.clear();
      await _sugerirCodigo();
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOutCubic);
      _obtenerGps();
    } else {
      Navigator.pop(context);
    }
  }

  /// Campo numérico sin límites de tamaño: solo se exige que sea un número.
  Widget _decimal(TextEditingController c, String label, String sufijo) =>
      TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, suffixText: sufijo),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
        validator: (_) =>
            c.text.trim().isNotEmpty && _num(c) == null ? 'Número no válido' : null,
      );

  /// Número sin ceros ni errores de coma flotante (12.30 -> 12.3).
  String _limpio(double v) {
    final s = v.toStringAsFixed(2);
    return s.contains('.') ? s.replaceFirst(RegExp(r'\.?0+$'), '') : s;
  }

  /// Valor escrito en la unidad elegida, convertido a milímetros para guardar.
  double? _enMm(TextEditingController c) {
    final v = _num(c);
    if (v == null) return null;
    return _cm ? double.parse((v * 10).toStringAsFixed(2)) : v;
  }

  /// Al cambiar mm <-> cm se convierten los valores ya escritos.
  void _cambiarUnidad(bool cm) {
    if (cm == _cm) return;
    for (final c in [_antebrazo, _tibia]) {
      final v = _num(c);
      if (v != null) c.text = _limpio(cm ? v / 10 : v * 10);
    }
    setState(() => _cm = cm);
    SharedPreferences.getInstance().then((p) => p.setBool('largo_en_cm', cm));
  }

  Widget _etiqueta(String texto) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(texto,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar registro' : 'Nuevo registro')),
      body: Form(
        key: _key,
        child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              TextFormField(
                controller: _codigo,
                decoration: const InputDecoration(labelText: 'Código *'),
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v!.trim().isEmpty ? 'Escribe el código' : null,
              ),
              const SizedBox(height: 12),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _especie.text),
                optionsBuilder: (t) => _especies
                    .where((e) => e.toLowerCase().contains(t.text.toLowerCase())),
                onSelected: (v) => _especie.text = v,
                fieldViewBuilder: (_, c, f, _) {
                  c.addListener(() => _especie.text = c.text);
                  return TextFormField(
                    controller: c,
                    focusNode: f,
                    decoration: const InputDecoration(labelText: 'Especie *'),
                    validator: (v) => v!.trim().isEmpty ? 'Escribe la especie' : null,
                  );
                },
              ),
              _etiqueta('Sexo *'),
              SegmentedButton<String>(
                emptySelectionAllowed: true,
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'Macho', label: Text('Macho')),
                  ButtonSegment(value: 'Hembra', label: Text('Hembra')),
                ],
                selected: _sexo == null ? <String>{} : {_sexo!},
                onSelectionChanged: (s) => setState(() {
                  _sexo = s.isEmpty ? null : s.first;
                  _sexoSinElegir = false;
                }),
              ),
              if (_sexoSinElegir)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text('Elige macho o hembra',
                      style: TextStyle(color: esquema.error, fontSize: 12)),
                ),
              _etiqueta('Estado'),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Activo')),
                  ButtonSegment(value: false, label: Text('Inactivo')),
                ],
                selected: {_activo},
                onSelectionChanged: (s) => setState(() => _activo = s.first),
              ),
              _etiqueta('Edad'),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text('Adulto')),
                  ButtonSegment(value: false, label: Text('No adulto')),
                ],
                selected: {_adulto},
                onSelectionChanged: (s) => setState(() => _adulto = s.first),
              ),
              _etiqueta('Medidas'),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text('mm')),
                  ButtonSegment(value: true, label: Text('cm')),
                ],
                selected: {_cm},
                onSelectionChanged: (s) => _cambiarUnidad(s.first),
              ),
              const SizedBox(height: 12),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: _decimal(_antebrazo, 'Antebrazo', _cm ? 'cm' : 'mm')),
                const SizedBox(width: 8),
                Expanded(child: _decimal(_tibia, 'Tibia', _cm ? 'cm' : 'mm')),
                const SizedBox(width: 8),
                Expanded(child: _decimal(_peso, 'Peso', 'g')),
              ]),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Trae parásito'),
                value: _parasito,
                onChanged: (v) => setState(() => _parasito = v),
              ),
              if (_parasito)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: const ['Ácaro', 'Mosca']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _tipo = v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cantidad,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          _parasito && v!.trim().isEmpty ? 'Indica cuántos' : null,
                    ),
                  ),
                ]),
              _etiqueta('Observaciones'),
              TextFormField(
                controller: _obs,
                decoration: const InputDecoration(hintText: 'Opcional'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: _buscandoGps
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(_lat == null ? Icons.location_off : Icons.location_on),
                  title: Text(_lat == null
                      ? (_buscandoGps ? 'Obteniendo ubicación…' : 'Sin ubicación')
                      : '${_lat!.toStringAsFixed(6)}, ${_lon!.toStringAsFixed(6)}'),
                  subtitle: _precision == null
                      ? null
                      : Text('Precisión ±${_precision!.toStringAsFixed(0)} m'),
                  trailing: IconButton(
                      tooltip: 'Reintentar ubicación',
                      icon: const Icon(Icons.refresh),
                      onPressed: _buscandoGps ? null : _obtenerGps),
                ),
              ),
            ]),
      ),
      // Acciones siempre a la vista y al alcance del pulgar.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: [
            if (!_editando) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _guardando ? null : () => _guardar(yNuevo: true),
                  child: const Text('Guardar y nuevo'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton.icon(
                onPressed: _guardando ? null : () => _guardar(),
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
