import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF0A0809);
  static const surface = Color(0xFF130E12);
  static const sheet = Color(0xFF17101A);
  static const card = Color(0xFF1C1219);
  static const line = Color(0xFF2E1A28);
  static const accent = Color(0xFFB3264F);
  static const berry = Color(0xFF3B1235);
  static const berry2 = Color(0xFF5A1D4E);
  static const muted = Color(0xFFA8A8B0);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(primary: C.accent, surface: C.sheet),
    chipTheme: const ChipThemeData(
      selectedColor: C.accent,
      backgroundColor: C.card,
      labelStyle: TextStyle(color: Colors.white),
      side: BorderSide(color: C.line),
    ),
  );
}
