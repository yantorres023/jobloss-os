import 'package:flutter/material.dart';

/// Calm, neutral palette. Deliberately avoids Texas flag colors, state seals
/// or anything that could look like a government app (RED_TEAM RT-8).
const _seed = Color(0xFF2F6F62);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 16)),
  );
}

/// Colors with meaning. Always paired with text/icons, never color alone.
class StatusColors {
  static Color overdue(ColorScheme s) => s.error;
  static Color official(ColorScheme s) => s.primary;
  static Color suggested(ColorScheme s) => s.tertiary;
}
