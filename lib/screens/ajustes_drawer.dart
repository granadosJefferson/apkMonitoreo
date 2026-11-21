import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/perfil.dart';

/// Menú lateral izquierdo: perfil (foto y nombre) y ajustes.
class AjustesDrawer extends StatelessWidget {
  final bool autoExport;
  final ValueChanged<bool> onAutoExport;
  const AjustesDrawer(
      {super.key, required this.autoExport, required this.onAutoExport});

  Future<void> _elegirFoto(BuildContext context, ImageSource fuente) async {
    final mensajes = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickImage(
          source: fuente, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (x != null) await Perfil.instance.cambiarFoto(await x.readAsBytes());
    } catch (_) {
      mensajes.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la foto. Intenta de nuevo.')));
    }
  }

  void _menuFoto(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
            onTap: () {
              Navigator.pop(c);
              _elegirFoto(context, ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Tomar una foto'),
            onTap: () {
              Navigator.pop(c);
              _elegirFoto(context, ImageSource.camera);
            },
          ),
          if (Perfil.instance.foto != null)
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Quitar foto'),
              onTap: () {
                Navigator.pop(c);
                Perfil.instance.cambiarFoto(null);
              },
            ),
        ]),
      ),
    );
  }

  Future<void> _editarNombre(BuildContext context) async {
    final ctl = TextEditingController(text: Perfil.instance.nombre);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Tu nombre'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nombre y apellido'),
          onSubmitted: (_) => Navigator.pop(c, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) await Perfil.instance.cambiarNombre(ctl.text);
    ctl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: ListenableBuilder(
          listenable: Perfil.instance,
          builder: (_, _) {
            final p = Perfil.instance;
            return ListView(padding: const EdgeInsets.symmetric(vertical: 24), children: [
              Center(
                child: Semantics(
                  button: true,
                  label: 'Cambiar foto de perfil',
                  child: GestureDetector(
                    onTap: () => _menuFoto(context),
                    child: Stack(children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: esquema.surfaceContainerHigh,
                        backgroundImage: p.foto == null ? null : MemoryImage(p.foto!),
                        child: p.foto == null
                            ? Icon(Icons.person, size: 56, color: esquema.onSurfaceVariant)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: esquema.primary,
                          child: Icon(Icons.photo_camera, size: 18, color: esquema.onPrimary),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                onTap: () => _editarNombre(context),
                title: Text(
                  p.nombre.isEmpty ? 'Agregar tu nombre' : p.nombre,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: p.nombre.isEmpty ? esquema.onSurfaceVariant : null),
                ),
                subtitle: const Text('Toca para editar', textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              const Divider(),
              SwitchListTile(
                secondary: Icon(p.oscuro ? Icons.dark_mode : Icons.light_mode),
                title: const Text('Modo oscuro'),
                value: p.oscuro,
                onChanged: p.cambiarOscuro,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Exportar a Excel al tener internet'),
                value: autoExport,
                onChanged: onAutoExport,
              ),
            ]);
          },
        ),
      ),
    );
  }
}
