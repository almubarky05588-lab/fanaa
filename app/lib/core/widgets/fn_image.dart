import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'fn_logo.dart';

/// صورة منتج/متجر مع بديل العلامة عند غياب الصورة — مطابق للتصميم
class FnImage extends StatelessWidget {
  const FnImage({super.key, this.url, this.size, this.width, this.height, this.radius = 16,
      this.bg = FnColors.soft, this.markColor = FnColors.primary, this.markFactor = .6});
  final String? url;
  final double? size, width, height;
  final double radius;
  final Color bg;
  final Color markColor;
  final double markFactor;

  @override
  Widget build(BuildContext context) {
    final w = size ?? width, h = size ?? height;
    Widget fallback() => LayoutBuilder(builder: (_, c) {
          final s = (c.maxWidth.isFinite ? c.maxWidth : (w ?? 60)) * markFactor;
          return Center(child: FnLogoMark(size: s, color: markColor, gradient: false));
        });
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: w, height: h, color: bg,
        child: (url == null || url!.isEmpty)
            ? fallback()
            : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover, width: w, height: h,
                placeholder: (_, __) => const SizedBox.shrink(), errorWidget: (_, __, ___) => fallback()),
      ),
    );
  }
}
