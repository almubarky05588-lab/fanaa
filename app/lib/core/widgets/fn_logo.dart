import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../i18n/i18n.dart';

/// علامة فناء — ثلاث أوراق بدوّامة نمو. نفس الهندسة المستخدمة في Figma.
class FnLogoMark extends StatelessWidget {
  const FnLogoMark({super.key, this.size = 48, this.color, this.gradient = true});
  final double size;
  final Color? color;
  final bool gradient;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _MarkPainter(color: color, gradient: gradient),
      );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({this.color, required this.gradient});
  final Color? color;
  final bool gradient;

  static const _pts = [[0.0, 0.0], [34.0, -8.0], [36.0, -42.0], [6.0, -58.0], [-6.0, -38.0], [-17.0, -18.0], [0.0, 0.0]];

  Path _leaf(double angle, double scale, double cx, double cy) {
    final a = angle * math.pi / 180;
    List<Offset> p = _pts.map((q) {
      final sx = q[0] * scale, sy = q[1] * scale;
      return Offset(cx + sx * math.cos(a) - sy * math.sin(a), cy + sx * math.sin(a) + sy * math.cos(a));
    }).toList();
    return Path()
      ..moveTo(p[0].dx, p[0].dy)
      ..cubicTo(p[1].dx, p[1].dy, p[2].dx, p[2].dy, p[3].dx, p[3].dy)
      ..cubicTo(p[4].dx, p[4].dy, p[5].dx, p[5].dy, p[6].dx, p[6].dy)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 120;
    final path = Path()
      ..addPath(_leaf(8, 1.20 * k, 60 * k, 60 * k), Offset.zero)
      ..addPath(_leaf(130, 0.94 * k, 60 * k, 60 * k), Offset.zero)
      ..addPath(_leaf(248, 0.70 * k, 60 * k, 60 * k), Offset.zero);
    // محاذاة الشكل في منتصف المربع
    final b = path.getBounds();
    final dx = (size.width - b.width) / 2 - b.left, dy = (size.height - b.height) / 2 - b.top;
    final centered = path.shift(Offset(dx, dy));
    final paint = Paint()..style = PaintingStyle.fill;
    if (color != null || !gradient) {
      paint.color = color ?? FnColors.primary;
    } else {
      paint.shader = const LinearGradient(
        begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [FnColors.deep, FnColors.lime],
      ).createShader(Offset.zero & size);
    }
    canvas.drawPath(centered, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) => old.color != color || old.gradient != gradient;
}

/// الشعار الكامل: العلامة + الاسم
class FnLogoLockup extends StatelessWidget {
  const FnLogoLockup({super.key, this.markSize = 40, this.textStyle, this.markColor});
  final double markSize;
  final TextStyle? textStyle;
  final Color? markColor;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FnLogoMark(size: markSize, color: markColor, gradient: markColor == null),
          const SizedBox(width: 10),
          Text(tr('فناء'), style: textStyle ?? FnText.title22.deep),
        ],
      );
}
