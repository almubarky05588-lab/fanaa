import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'fn_image.dart';
import 'fn_logo.dart';

/// شعار المتجر: صورة التاجر إن وُجدت، وإلا علامة فناء على خلفية خضراء
class StoreLogo extends StatelessWidget {
  const StoreLogo({super.key, this.url, this.size = 48, this.radius, this.border = false});
  final String? url;
  final double size;
  final double? radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? size * .33;
    final child = (url != null && url!.isNotEmpty)
        ? FnImage(url: url, size: size, radius: r)
        : Container(
            width: size, height: size,
            decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(r)),
            child: Center(child: FnLogoMark(size: size * .6, color: FnColors.lime, gradient: false)),
          );
    if (!border) return child;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(r + 3), boxShadow: FnShadow.card),
      child: child,
    );
  }
}
