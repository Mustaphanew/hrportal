import 'package:flutter/material.dart';

/// Centralized app themes.
///
/// Keep all ThemeData configuration here to avoid spreading styling logic
/// across the app.
class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    colorSchemeSeed: Colors.blue,
    useMaterial3: true,
    brightness: Brightness.light,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
  );

  static final ThemeData dark = ThemeData(
    colorSchemeSeed: Colors.blue,
    useMaterial3: true,
    brightness: Brightness.dark,
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      filled: true,
    ),
  );
}
