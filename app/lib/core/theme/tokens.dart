import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// التوكنز — مستخرجة حرفيًا من ملف Figma (مجموعة Tokens).
abstract final class FnColors {
  // bg
  static const bgBase = Color(0xFFF4F3EE);
  static const surface = Color(0xFFFFFFFF);
  static const sand = Color(0xFFEFE8DA);

  // brand
  static const primary = Color(0xFF157A4E);
  static const deep = Color(0xFF0C3E2A);
  static const soft = Color(0xFFE4F1E8);
  static const lime = Color(0xFFB7E05C);

  // accent
  static const clay = Color(0xFFC8703F);
  static const sky = Color(0xFF5B8FB9);
  static const plum = Color(0xFF8E6BA8);

  // text
  static const ink = Color(0xFF0B2E20);
  static const muted = Color(0xFF5F7268);
  static const faint = Color(0xFF9AA79E);

  // line / state
  static const border = Color(0xFFE5E9E1);
  static const star = Color(0xFFE8A33D);
}

abstract final class FnRadius {
  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 26.0;
  static const pill = 999.0;

  // أقطار شائعة في الشاشات
  static const field = 14.0;
  static const card = 20.0;
  static const sheet = 28.0;
}

abstract final class FnSpace {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  /// الهامش الأفقي القياسي للشاشات (390px frame → 24px)
  static const page = 24.0;
}

abstract final class FnShadow {
  static const card = [
    BoxShadow(color: Color(0x120B2E20), blurRadius: 18, offset: Offset(0, 6), spreadRadius: -2),
  ];
  static const raised = [
    BoxShadow(color: Color(0x290B2E20), blurRadius: 28, offset: Offset(0, 12), spreadRadius: -6),
  ];
  static const bar = [
    BoxShadow(color: Color(0x140B2E20), blurRadius: 16, offset: Offset(0, -4)),
  ];
}

/// سلّم الخطوط — Cairo بنفس الأحجام وارتفاعات الأسطر في Figma.
abstract final class FnText {
  static TextStyle _s(double size, double lineHeight, FontWeight w, [Color c = FnColors.ink]) =>
      GoogleFonts.cairo(fontSize: size, height: lineHeight / size, fontWeight: w, color: c);

  static TextStyle get display28 => _s(28, 40, FontWeight.w700);
  static TextStyle get title22 => _s(22, 34, FontWeight.w700);
  static TextStyle get heading18 => _s(18, 28, FontWeight.w700);
  static TextStyle get body15 => _s(15, 26, FontWeight.w400);
  static TextStyle get bodyStrong15 => _s(15, 26, FontWeight.w600);
  static TextStyle get label13 => _s(13, 20, FontWeight.w600);
  static TextStyle get caption11 => _s(11, 16, FontWeight.w500);
}

/// امتداد سريع لتلوين الأنماط: FnText.body15.muted
extension FnTextColor on TextStyle {
  TextStyle get muted => copyWith(color: FnColors.muted);
  TextStyle get faint => copyWith(color: FnColors.faint);
  TextStyle get deep => copyWith(color: FnColors.deep);
  TextStyle get primary => copyWith(color: FnColors.primary);
  TextStyle get onDark => copyWith(color: FnColors.surface);
  TextStyle get lime => copyWith(color: FnColors.lime);
  TextStyle get soft => copyWith(color: FnColors.soft);
  TextStyle get clay => copyWith(color: FnColors.clay);
  TextStyle get star => copyWith(color: FnColors.star);
}
