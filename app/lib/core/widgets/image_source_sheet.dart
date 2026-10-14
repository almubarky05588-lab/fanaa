import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../i18n/i18n.dart';
import '../theme/tokens.dart';

/// قائمة سفلية للاختيار بين الكاميرا والاستديو — ترجع null لو أُغلقت
Future<ImageSource?> pickImageSource(BuildContext context) => showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: FnColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: FnColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 18),
            _Option(icon: Icons.photo_camera_outlined, label: tr('التقاط صورة'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            const SizedBox(height: 10),
            _Option(icon: Icons.photo_library_outlined, label: tr('اختيار من الاستديو'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
          ]),
        ),
      ),
    );

class _Option extends StatelessWidget {
  const _Option({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: FnColors.bgBase,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: FnColors.deep, size: 22),
              ),
              const SizedBox(width: 12),
              Text(label, style: FnText.bodyStrong15),
            ]),
          ),
        ),
      );
}
