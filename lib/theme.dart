import 'package:flutter/material.dart';

/// Colores de estado propios de la app (siempre acompañados de texto + icono).
class Estados {
  static Color pendiente(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFE6BA62) : const Color(0xFF8A5A00);
  static Color exportado(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF93C795) : const Color(0xFF2E6B3A);
  static Color conexion(Brightness b) =>
      b == Brightness.dark ? const Color(0xFF8FB7C9) : const Color(0xFF1F5F7A);
}

ThemeData _tema(ColorScheme esquema, Color fondo, Color superficie, Color snack) {
  final borde = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: esquema.outlineVariant),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: fondo,
    appBarTheme: AppBarTheme(
      backgroundColor: fondo,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    drawerTheme: DrawerThemeData(backgroundColor: fondo),
    cardTheme: CardThemeData(
      color: superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: esquema.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: superficie,
      border: borde,
      enabledBorder: borde,
      focusedBorder: borde.copyWith(
          borderSide: BorderSide(color: esquema.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(minimumSize: const Size(48, 52)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: snack,
      contentTextStyle: TextStyle(color: esquema.onInverseSurface),
      actionTextColor: esquema.inversePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: esquema.outlineVariant, space: 1),
    listTileTheme: const ListTileThemeData(minVerticalPadding: 10),
  );
}

/// Oscuro de baja luminosidad para muestreo nocturno: fondo casi negro con
/// matiz verde, texto marfil, un solo acento musgo.
ThemeData temaOscuro() {
  const fondo = Color(0xFF0E1410);
  const superficie = Color(0xFF16201A);
  final esquema = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6F9A6B),
    brightness: Brightness.dark,
  ).copyWith(
    surface: fondo,
    surfaceContainer: superficie,
    surfaceContainerHigh: const Color(0xFF1D2A22),
    onSurface: const Color(0xFFE6EBE0),
    onSurfaceVariant: const Color(0xFFABB8A8),
    primary: const Color(0xFF9CC79A),
    onPrimary: fondo,
    error: const Color(0xFFFFB4A8),
    onInverseSurface: const Color(0xFFE6EBE0),
  );
  return _tema(esquema, fondo, superficie, const Color(0xFF26352B));
}

/// Claro para uso de día: papel cálido y verde bosque profundo.
ThemeData temaClaro() {
  const fondo = Color(0xFFF6F7F1);
  const superficie = Color(0xFFFFFFFF);
  final esquema = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3B5B3A),
    brightness: Brightness.light,
  ).copyWith(
    surface: fondo,
    surfaceContainer: superficie,
    surfaceContainerHigh: const Color(0xFFE6EBDD),
    onSurface: const Color(0xFF1A211B),
    onSurfaceVariant: const Color(0xFF4A5649),
  );
  return _tema(esquema, fondo, superficie, const Color(0xFF2B352C));
}
