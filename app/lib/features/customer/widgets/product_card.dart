import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.p, this.onAdd, this.width});
  final Product p;
  final VoidCallback? onAdd;
  final double? width;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/product/${p.id}'),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.card)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(aspectRatio: 1, child: FnImage(url: p.cover, radius: 16, bg: FnColors.soft)),
            const SizedBox(height: 8),
            Text(p.name, style: FnText.label13, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (p.categoryName != null) Text(p.categoryName!, style: FnText.caption11.muted, maxLines: 1),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(child: Text(Fmt.moneyShort(p.fromPrice), style: FnText.label13.deep)),
              Material(
                color: FnColors.deep,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: onAdd ?? () => context.push('/product/${p.id}'),
                  borderRadius: BorderRadius.circular(10),
                  child: const SizedBox(width: 30, height: 30, child: Icon(Icons.add_rounded, size: 18, color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
      );
}
