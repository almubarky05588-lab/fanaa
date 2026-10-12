import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../core/widgets/store_logo.dart';
import '../../../data/models/catalog.dart';
import '../../../core/i18n/i18n.dart';

/// بطاقة المتجر الأفقية في الرئيسية (غلاف + اسم + تقييم)
class NurseryTileCard extends StatelessWidget {
  const NurseryTileCard({super.key, required this.n, this.width = 168});
  final Nursery n;
  final double width;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/store/${n.id}'),
        child: Container(
          width: width,
          decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.card)),
          clipBehavior: Clip.antiAlias,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              if (n.coverUrl == null && n.logoUrl != null)
                Container(height: 96, width: width, color: FnColors.soft,
                    alignment: Alignment.center, child: StoreLogo(url: n.logoUrl, size: 60))
              else
                FnImage(url: n.coverUrl, height: 96, width: width, radius: 0,
                    bg: FnColors.primary, markColor: Colors.white.withValues(alpha: .55), markFactor: .45),
              if (n.isOpen)
                Positioned(top: 8, left: 8, child: FnBadge(tr('مفتوح'), bg: FnColors.surface)),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.name, style: FnText.bodyStrong15, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Row(children: [
                  Expanded(child: Text(
                    [n.district, if (n.distanceKm != null) Fmt.km(n.distanceKm!)].whereType<String>().join(' • '),
                    style: FnText.caption11.muted, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const Icon(Icons.star_rounded, size: 14, color: FnColors.star),
                  const SizedBox(width: 2),
                  Text(n.ratingAvg.toStringAsFixed(1), style: FnText.caption11),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

/// صف المتجر في شاشة المتاجر (شعار + معلومات + شارات)
class NurseryRowCard extends StatelessWidget {
  const NurseryRowCard({super.key, required this.n});
  final Nursery n;
  @override
  Widget build(BuildContext context) => FnCard(
        onTap: () => context.push('/store/${n.id}'),
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          StoreLogo(url: n.logoUrl ?? n.coverUrl, size: 76, radius: 18),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(n.name, style: FnText.bodyStrong15, maxLines: 1, overflow: TextOverflow.ellipsis)),
              const Icon(Icons.star_rounded, size: 15, color: FnColors.star),
              const SizedBox(width: 2),
              Text(n.ratingAvg.toStringAsFixed(1), style: FnText.label13),
            ]),
            const SizedBox(height: 2),
            Text([n.district ?? n.city, if (n.distanceKm != null) Fmt.km(n.distanceKm!)].join(' • '), style: FnText.caption11.muted),
            const SizedBox(height: 8),
            Row(children: [
              FnBadge(n.isOpen ? tr('مفتوح الآن') : tr('مغلق'), bg: n.isOpen ? FnColors.soft : FnColors.bgBase, fg: n.isOpen ? FnColors.deep : FnColors.muted),
              const SizedBox(width: 6),
              FnBadge(n.freeDelivery ? tr('توصيل مجاني') : tr('توصيل {0}', [Fmt.moneyShort(n.deliveryFee)]), bg: FnColors.bgBase, fg: FnColors.muted),
              const SizedBox(width: 6),
              FnBadge(Fmt.minutes(n.prepTimeMin), bg: FnColors.bgBase, fg: FnColors.muted),
            ]),
          ])),
        ]),
      );
}
