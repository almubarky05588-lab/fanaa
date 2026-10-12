import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/i18n/i18n.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';

/// الأيقونات المتاحة للأدمن (اسمها في عمود icon بجدول الأقسام)
const kCategoryIcons = <String, IconData>{
  'plant': Icons.local_florist_outlined, 'flower': Icons.filter_vintage_outlined, 'tree': Icons.park_outlined,
  'yard': Icons.yard_outlined, 'cactus': Icons.spa_outlined, 'seed': Icons.grass_rounded, 'soil': Icons.water_drop_outlined,
  'tools': Icons.handyman_outlined, 'pot': Icons.inventory_2_outlined, 'leaf': Icons.eco_outlined, 'sun': Icons.wb_sunny_outlined,
  'gift': Icons.card_giftcard_outlined, 'star': Icons.star_outline_rounded, 'home': Icons.home_outlined,
  'offer': Icons.local_offer_outlined, 'new': Icons.fiber_new_outlined,
};

/// قسم في الرئيسية — يُعرض كأيقونة أو صورة أو نص فقط حسب اختيار الأدمن
class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.c, required this.index});
  final Category c;
  final int index;
  static const _bgs = [FnColors.soft, Color(0xFFF6E9E1), Color(0xFFE6EEF6), Color(0xFFEFE8F4), Color(0xFFF7F0DE)];
  static const _fgs = [FnColors.deep, FnColors.clay, FnColors.sky, FnColors.plum, FnColors.star];

  Color get _bg {
    final hex = c.bgColor?.replaceAll('#', '');
    if (hex != null && hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    return _bgs[index % 5];
  }

  @override
  Widget build(BuildContext context) {
    final open = () => context.push('/stores?category=${c.id}');
    final name = tr(c.nameAr);
    if (c.displayMode == 'text') {
      // نص فقط: حبّة بالاسم (في المنتصف عموديًا داخل شريط الأقسام)
      return Align(alignment: AlignmentDirectional.topStart, child: GestureDetector(
        onTap: open,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(FnRadius.pill)),
          child: Text(name, style: FnText.label13.copyWith(color: _fgs[index % 5])),
        ),
      ));
    }
    return GestureDetector(
      onTap: open,
      child: SizedBox(
        width: 72,
        child: Column(children: [
          Container(
            width: 64, height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
            child: c.displayMode == 'image' && (c.imageUrl ?? '').isNotEmpty
                ? FnImage(url: c.imageUrl, width: 64, height: 64, radius: 0)   // صورة مربعة 1:1 (يُفضّل 256×256)
                : Icon(kCategoryIcons[c.icon] ?? Icons.eco_outlined, color: _fgs[index % 5], size: 26),
          ),
          const SizedBox(height: 6),
          Text(name, style: FnText.caption11, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }
}
