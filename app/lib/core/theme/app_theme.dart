import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(useMaterial3: true, brightness: Brightness.light);
    final text = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: FnColors.ink,
      displayColor: FnColors.ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: FnColors.bgBase,
      colorScheme: const ColorScheme.light(
        primary: FnColors.deep,
        onPrimary: FnColors.surface,
        secondary: FnColors.primary,
        onSecondary: FnColors.surface,
        tertiary: FnColors.lime,
        surface: FnColors.surface,
        onSurface: FnColors.ink,
        error: FnColors.clay,
        outline: FnColors.border,
      ),
      textTheme: text.copyWith(
        displaySmall: FnText.display28,
        titleLarge: FnText.title22,
        titleMedium: FnText.heading18,
        bodyLarge: FnText.body15,
        bodyMedium: FnText.body15,
        labelLarge: FnText.bodyStrong15,
        labelMedium: FnText.label13,
        labelSmall: FnText.caption11,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: FnColors.bgBase,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: FnText.title22,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FnColors.deep,
          foregroundColor: FnColors.surface,
          minimumSize: const Size.fromHeight(58),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FnRadius.md)),
          textStyle: FnText.bodyStrong15,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FnColors.ink,
          minimumSize: const Size.fromHeight(54),
          side: const BorderSide(color: FnColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: FnText.bodyStrong15,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: FnColors.primary, textStyle: FnText.label13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FnColors.surface,
        hintStyle: FnText.body15.faint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FnRadius.field),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FnRadius.field),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(FnRadius.field),
          borderSide: const BorderSide(color: FnColors.primary, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FnColors.surface,
        selectedColor: FnColors.deep,
        labelStyle: FnText.label13,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FnRadius.pill)),
      ),
      dividerTheme: const DividerThemeData(color: FnColors.border, thickness: 1, space: 1),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: FnColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(FnRadius.sheet)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(FnColors.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? FnColors.deep : FnColors.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: FnColors.deep,
        contentTextStyle: FnText.body15.onDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FnRadius.field)),
      ),
    );
  }
}
