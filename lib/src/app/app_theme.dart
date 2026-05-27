import 'package:flutter/material.dart';

const _background = Color(0xFF0C0D0E);
const _surface = Color(0xFF151719);
const _surfaceHigh = Color(0xFF202326);
const _text = Color(0xFFF4F0E8);
const _mutedText = Color(0xFFA9A39A);
const _accent = Color(0xFFE7B85B);

ThemeData buildVelaTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: _accent,
        brightness: Brightness.dark,
        surface: _surface,
      ).copyWith(
        primary: _accent,
        onPrimary: _background,
        surface: _surface,
        onSurface: _text,
        secondary: const Color(0xFF8FB7B0),
        outline: const Color(0xFF34383C),
      );

  final textTheme = Typography.material2021().white.apply(
    bodyColor: _text,
    displayColor: _text,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _background,
    canvasColor: _background,
    dividerColor: const Color(0xFF292D31),
    textTheme: textTheme.copyWith(
      titleLarge: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
      titleMedium: textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
      ),
      bodyMedium: textTheme.bodyMedium?.copyWith(
        color: _mutedText,
        letterSpacing: 0,
      ),
      labelLarge: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: _background,
        minimumSize: const Size(44, 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _text,
        hoverColor: _surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    cardTheme: CardThemeData(
      color: _surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF292D31)),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
