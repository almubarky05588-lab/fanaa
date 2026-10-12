import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../dashboard/merchant_dashboard_screen.dart';
import '../../../core/i18n/i18n.dart';

/// تقييمات العملاء — لصاحب المتجر
class MerchantReviewsScreen extends ConsumerWidget {
  const MerchantReviewsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WithMyNursery(builder: (n) => _Reviews(n: n));
}

class _Reviews extends ConsumerWidget {
  const _Reviews({required this.n});
  final Nursery n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nurseryReviewsProvider(n.id));
    return Scaffold(
      appBar: FnAppBar(title: tr('تقييمات العملاء')),
      body: async.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(nurseryReviewsProvider(n.id))),
        data: (list) {
          final dist = List.filled(5, 0);
          for (final r in list) {
            final v = (r['rating'] as num).toInt();
            if (v >= 1 && v <= 5) dist[v - 1]++;
          }
          return RefreshIndicator(
            color: FnColors.primary,
            onRefresh: () async => ref.invalidate(nurseryReviewsProvider(n.id)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
              children: [
                FnCard(
                  child: Row(children: [
                    Column(children: [
                      Text(n.ratingAvg.toStringAsFixed(1), style: FnText.display28.deep),
                      _Stars(n.ratingAvg.round()),
                      const SizedBox(height: 4),
                      Text(tr('{0} تقييم', [n.ratingCount]), style: FnText.caption11.muted),
                    ]),
                    const SizedBox(width: 20),
                    Expanded(child: Column(children: [
                      for (var s = 5; s >= 1; s--)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(children: [
                            SizedBox(width: 14, child: Text('$s', style: FnText.caption11.muted)),
                            const SizedBox(width: 6),
                            Expanded(child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: list.isEmpty ? 0 : dist[s - 1] / list.length,
                                minHeight: 6, backgroundColor: FnColors.bgBase, color: FnColors.star,
                              ),
                            )),
                          ]),
                        ),
                    ])),
                  ]),
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: FnEmpty(title: tr('لا توجد تقييمات بعد'), subtitle: tr('تظهر هنا تقييمات العملاء بعد توصيل طلباتهم'),
                        icon: Icons.star_outline_rounded),
                  )
                else
                  for (final r in list) ...[
                    FnCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(
                              (r['profiles']?['full_name'] as String?)?.isNotEmpty == true ? r['profiles']['full_name'] : tr('عميل'),
                              style: FnText.bodyStrong15)),
                          _Stars((r['rating'] as num).toInt()),
                        ]),
                        const SizedBox(height: 2),
                        Text(Fmt.timeAgo(DateTime.parse(r['created_at']).toLocal()), style: FnText.caption11.faint),
                        if ((r['comment'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(r['comment'], style: FnText.body15),
                        ],
                      ]),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars(this.v);
  final int v;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 1; i <= 5; i++)
          Icon(i <= v ? Icons.star_rounded : Icons.star_outline_rounded, size: 16, color: FnColors.star),
      ]);
}
