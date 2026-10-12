import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/shop_mode.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../core/widgets/store_logo.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../data/repositories/order_repo.dart';
import '../../customer/orders/my_orders_screen.dart' show statusColors;
import '../orders/merchant_orders_screen.dart' show merchantOrdersTabRequest;
import '../../../core/i18n/i18n.dart';

final merchantStatsProvider = FutureProvider.family<Map<String, dynamic>, String>(
    (ref, nid) => ref.watch(orderRepoProvider).merchantStats(nid));
final merchantOrdersProvider = FutureProvider.family<List<Order>, String>(
    (ref, nid) => ref.watch(orderRepoProvider).merchantOrders(nid));

/// ينقل صاحب المتجر لواجهة العميل للتسوّق من المتاجر الأخرى
void startShoppingAsCustomer(BuildContext context) {
  ShopMode.active.value = true;
  context.go('/home');
}

/// غلاف: يجلب متجر التاجر أو يوجّه لإنشائه
class WithMyNursery extends ConsumerWidget {
  const WithMyNursery({super.key, required this.builder});
  final Widget Function(Nursery n) builder;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final my = ref.watch(myNurseryProvider);
    return my.when(
      loading: () => const Scaffold(body: FnLoading()),
      error: (_, __) => Scaffold(body: FnError(onRetry: () => ref.invalidate(myNurseryProvider))),
      data: (n) {
        if (n == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) { if (context.mounted) context.go('/m/setup'); });
          return const Scaffold(body: FnLoading());
        }
        return builder(n);
      },
    );
  }
}

/// 15 لوحة التاجر
class MerchantDashboardScreen extends ConsumerWidget {
  const MerchantDashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WithMyNursery(builder: (n) => _Dash(n: n));
}

class _Dash extends ConsumerWidget {
  const _Dash({required this.n});
  final Nursery n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(merchantStatsProvider(n.id)).valueOrNull;
    final orders = ref.watch(merchantOrdersProvider(n.id)).valueOrNull ?? const <Order>[];
    final daily = (stats?['daily'] as List?)?.cast<double>() ?? List.filled(7, 0.0);
    final maxV = daily.fold<double>(1, (m, v) => v > m ? v : m);
    final days = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    const dayLetters = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

    return Scaffold(
      body: RefreshIndicator(
        color: FnColors.primary,
        onRefresh: () async {
          ref.invalidate(merchantStatsProvider(n.id));
          ref.invalidate(merchantOrdersProvider(n.id));
          ref.invalidate(myNurseryProvider);
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(FnSpace.page, MediaQuery.paddingOf(context).top + 12, FnSpace.page, 24),
          children: [
            Row(children: [
              StoreLogo(url: n.logoUrl, size: 46, radius: 16),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.name, style: FnText.heading18),
                Text(tr('لوحة التاجر'), style: FnText.caption11.muted),
              ])),
              FnIconButton(radius: 16, onTap: () {}, child: const Icon(Icons.notifications_none_rounded, size: 20, color: FnColors.ink)),
            ]),
            const SizedBox(height: 14),
            _OpenToggle(n: n),
            const SizedBox(height: 12),
            Row(children: [
              _Kpi(Fmt.moneyShort((stats?['todaySales'] as num?) ?? 0), tr('مبيعات اليوم'), highlight: true,
                  onTap: () => context.go('/m/wallet')),
              const SizedBox(width: 10),
              _Kpi('${n.ratingAvg.toStringAsFixed(1)} ★', tr('تقييم المتجر ({0})', [n.ratingCount]),
                  onTap: () => context.push('/m/reviews')),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _Kpi('${stats?['newCount'] ?? 0}', tr('طلبات جديدة'), onTap: () {
                merchantOrdersTabRequest.value = 0;
                context.go('/m/orders');
              }),
              const SizedBox(width: 10),
              _Kpi('${stats?['preparing'] ?? 0}', tr('قيد التجهيز'), onTap: () {
                merchantOrdersTabRequest.value = 1;
                context.go('/m/orders');
              }),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _QuickAction(icon: Icons.local_offer_outlined, label: tr('الكوبونات'), onTap: () => context.push('/m/coupons')),
              const SizedBox(width: 10),
              _QuickAction(icon: Icons.shopping_bag_outlined, label: tr('تسوّق كعميل'), onTap: () => startShoppingAsCustomer(context)),
            ]),
            const SizedBox(height: 12),
            FnCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('مبيعات آخر ٧ أيام'), style: FnText.label13),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    for (var i = 0; i < 7; i++)
                      Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Container(
                          width: 22, height: (daily[i] / maxV * 84).clamp(6, 84),
                          decoration: BoxDecoration(color: i == 6 ? FnColors.deep : FnColors.soft, borderRadius: BorderRadius.circular(8)),
                        ),
                        const SizedBox(height: 6),
                        Text(tr(dayLetters[days[i].weekday - 1]), style: FnText.caption11.muted),
                      ]),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 18),
            FnSectionTitle(tr('آخر الطلبات'), action: tr('عرض الكل'), onAction: () => context.go('/m/orders')),
            const SizedBox(height: 10),
            if (orders.isEmpty)
              FnCard(child: Center(child: Text(tr('لا توجد طلبات بعد'), style: FnText.body15.muted)))
            else
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  for (var i = 0; i < orders.take(4).length; i++) ...[
                    _MiniOrder(o: orders[i]),
                    if (i < orders.take(4).length - 1) const FnDivider(),
                  ],
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: FnCard(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          radius: 18,
          child: Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, size: 18, color: FnColors.deep)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: FnText.label13)),
            // chevron_right ينقلبه Flutter في العربية فيشير لليسار ‹ (للأمام)
            const Icon(Icons.chevron_right_rounded, size: 18, color: FnColors.faint),
          ]),
        ),
      );
}

class _OpenToggle extends ConsumerStatefulWidget {
  const _OpenToggle({required this.n});
  final Nursery n;
  @override
  ConsumerState<_OpenToggle> createState() => _OpenToggleState();
}

class _OpenToggleState extends ConsumerState<_OpenToggle> {
  late bool _open = widget.n.isOpen;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_open ? tr('المتجر مفتوح الآن') : tr('المتجر مغلق'), style: FnText.bodyStrong15.onDark),
            Text(_open ? tr('يستقبل الطلبات الآن') : tr('لن تصلك طلبات جديدة'), style: FnText.caption11.soft),
          ])),
          FnSwitch(
            value: _open, lime: true,
            onChanged: (v) async {
              setState(() => _open = v);
              await ref.read(catalogRepoProvider).updateNursery(widget.n.id, {'is_open': v});
              ref.invalidate(myNurseryProvider);
            },
          ),
        ]),
      );
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.v, this.l, {this.highlight = false, this.onTap});
  final String v, l;
  final bool highlight;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: FnCard(
          onTap: onTap,
          radius: 18,
          padding: const EdgeInsets.all(14),
          color: highlight ? FnColors.soft : FnColors.surface,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v, style: highlight ? FnText.heading18.deep : FnText.heading18),
            Text(l, style: FnText.caption11.muted),
          ]),
        ),
      );
}

class _MiniOrder extends StatelessWidget {
  const _MiniOrder({required this.o});
  final Order o;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = statusColors(o.status);
    return InkWell(
      onTap: () => context.push('/m/order/${o.id}'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('#${o.orderNumber}', style: FnText.bodyStrong15),
            Text(tr('{0} • {1} منتجات', [o.customerName?.isNotEmpty == true ? o.customerName : tr('عميل'), o.itemCount]), style: FnText.caption11.muted),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            FnBadge(o.status.labelAr, bg: bg, fg: fg),
            const SizedBox(height: 4),
            Text(Fmt.moneyShort(o.total), style: FnText.label13),
          ]),
        ]),
      ),
    );
  }
}
