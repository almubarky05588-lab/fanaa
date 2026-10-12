import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repo.dart';

/// طلباتي
class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key, this.isTab = true});
  final bool isTab;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(myOrdersProvider);
    return Scaffold(
      appBar: FnAppBar(title: 'طلباتي', showBack: !isTab),
      body: orders.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(myOrdersProvider)),
        data: (list) => list.isEmpty
            ? FnEmpty(
                title: 'لا توجد طلبات بعد', subtitle: 'طلباتك ستظهر هنا', icon: Icons.receipt_long_outlined,
                action: SizedBox(width: 180, child: FnButton(label: 'ابدأ التسوّق', height: 50, onPressed: () => context.go('/stores'))),
              )
            : RefreshIndicator(
                color: FnColors.primary,
                onRefresh: () async => ref.invalidate(myOrdersProvider),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _OrderCard(o: list[i]),
                ),
              ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.o});
  final Order o;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = statusColors(o.status);
    return FnCard(
      onTap: () => context.push('/order/${o.id}'),
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        FnImage(url: o.nursery?.logoUrl, size: 52, radius: 16),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('#${o.orderNumber} — ${o.nursery?.name ?? ''}', style: FnText.bodyStrong15, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${o.itemCount} منتجات • ${Fmt.date(o.placedAt)}', style: FnText.caption11.muted),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          FnBadge(o.status.labelAr, bg: bg, fg: fg),
          const SizedBox(height: 4),
          Text(Fmt.moneyShort(o.total), style: FnText.label13),
        ]),
      ]),
    );
  }
}

(Color, Color) statusColors(OrderStatus s) => switch (s) {
      OrderStatus.pending => (FnColors.clay, Colors.white),
      OrderStatus.accepted || OrderStatus.preparing => (FnColors.primary, Colors.white),
      OrderStatus.ready || OrderStatus.outForDelivery => (FnColors.lime, FnColors.deep),
      OrderStatus.delivered => (FnColors.soft, FnColors.deep),
      _ => (FnColors.bgBase, FnColors.muted),
    };
