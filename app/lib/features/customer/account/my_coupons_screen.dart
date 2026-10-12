import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/coupon_repo.dart';
import '../../../core/i18n/i18n.dart';

/// الكوبونات التي استخدمها العميل
class MyCouponsScreen extends ConsumerWidget {
  const MyCouponsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myRedemptionsProvider);
    return Scaffold(
      appBar: FnAppBar(title: tr('كوبوناتي')),
      body: async.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(myRedemptionsProvider)),
        data: (list) {
          final saved = list.fold<double>(0, (s, r) => s + ((r['order']?['discount'] as num?)?.toDouble() ?? 0));
          return ListView(
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(22)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('وفّرت معنا'), style: FnText.caption11.soft),
                    Text(Fmt.money(saved), style: FnText.title22.onDark),
                  ])),
                  Text(tr('{0} كوبون', [list.length]), style: FnText.label13.lime),
                ]),
              ),
              const SizedBox(height: 14),
              if (list.isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: FnEmpty(title: tr('لم تستخدم كوبونات بعد'),
                      subtitle: tr('أدخل كود الخصم في السلة قبل إتمام الطلب'), icon: Icons.local_offer_outlined),
                )
              else
                for (final r in list) ...[
                  FnCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52, alignment: Alignment.center,
                        decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(16)),
                        child: Text(
                          r['coupons']?['type'] == 'percent'
                              ? '${(r['coupons']['value'] as num).toStringAsFixed(0)}%'
                              : Fmt.moneyShort((r['coupons']?['value'] as num?)?.toDouble() ?? 0),
                          style: FnText.label13.deep),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Directionality(textDirection: TextDirection.ltr,
                            child: Text(r['code'], style: FnText.bodyStrong15.copyWith(letterSpacing: 1.2))),
                        Text([
                          r['coupons']?['nurseries']?['name'],
                          if (r['order'] != null) tr('طلب #{0}', [r['order']['order_number']]),
                          Fmt.date(DateTime.parse(r['created_at']).toLocal()),
                        ].whereType<String>().join(' • '), style: FnText.caption11.muted),
                      ])),
                      if (r['order'] != null)
                        Text('− ${Fmt.moneyShort((r['order']['discount'] as num).toDouble())}', style: FnText.label13.primary),
                    ]),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}
