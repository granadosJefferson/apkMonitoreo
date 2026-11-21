import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Perfil y preferencias de la persona que usa la app.
/// La foto se guarda reducida (base64) para que funcione igual en móvil y web.
class Perfil extends ChangeNotifier {
  Perfil._();
  static final Perfil instance = Perfil._();

  String nombre = '';
  Uint8List? foto;
  bool oscuro = true;

  Future<void> cargar() async {
    final p = await SharedPreferences.getInstance();
    nombre = p.getString('perfil_nombre') ?? '';
    oscuro = p.getBool('modo_oscuro') ?? true;
    final f = p.getString('perfil_foto');
    foto = f == null ? null : base64Decode(f);
    notifyListeners();
  }

  Future<void> cambiarNombre(String v) async {
    nombre = v.trim();
    notifyListeners();
    (await SharedPreferences.getInstance()).setString('perfil_nombre', nombre);
  }

  Future<void> cambiarFoto(Uint8List? bytes) async {
    foto = bytes;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    bytes == null
        ? await p.remove('perfil_foto')
        : await p.setString('perfil_foto', base64Encode(bytes));
  }

  Future<void> cambiarOscuro(bool v) async {
    oscuro = v;
    notifyListeners();
    (await SharedPreferences.getInstance()).setBool('modo_oscuro', v);
  }
}
