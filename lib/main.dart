import 'package:flutter/material.dart';
import 'screens/home.dart';
import 'services/perfil.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Perfil.instance.cargar();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Perfil.instance,
        builder: (_, _) => MaterialApp(
          title: 'Muestreo de Murciélagos',
          debugShowCheckedModeBanner: false,
          theme: temaClaro(),
          darkTheme: temaOscuro(),
          themeMode: Perfil.instance.oscuro ? ThemeMode.dark : ThemeMode.light,
          home: const Home(),
        ),
      );
}
