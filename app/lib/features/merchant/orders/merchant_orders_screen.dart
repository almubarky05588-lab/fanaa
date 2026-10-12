import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repo.dart';
import '../dashboard/merchant_dashboard_screen.dart';

/// 16 الطلبات الواردة
class MerchantOrdersScreen extends ConsumerWidget {
  const MerchantOrdersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WithMyNursery(builder: (n) => _Orders(n: n));
}

enum _Tab { pending, preparing, ready, done }

/// تطلبه بطاقات لوحة التاجر لفتح تبويب معيّن: 0 جديدة، 1 قيد التجهيز، 2 جاهزة، 3 مكتملة
final merchantOrdersTabRequest = ValueNotifier<int?>(null);

class _Orders extends ConsumerStatefulWidget {
  const _Orders({required this.n});
  final Nursery n;
  @override
  ConsumerState<_Orders> createState() => _OrdersState();
}

class _OrdersState extends ConsumerState<_Orders> {
  _Tab _tab = _Tab.pending;
  StreamSubscription? _sub;

  void _applyTabRequest() {
    final i = merchantOrdersTabRequest.value;
    if (i == null) return;
    merchantOrdersTabRequest.value = null;
    if (mounted) setState(() => _tab = _Tab.values[i]);
  }

  @override
  void initState() {
    super.initState();
    final i = merchantOrdersTabRequest.value;
    if (i != null) {
      _tab = _Tab.values[i];
      merchantOrdersTabRequest.value = null;
    }
    merchantOrdersTabRequest.addListener(_applyTabRequest);
    // تحديث فوري عند وصول طلب جديد أو تغيّر الحالة
    _sub = ref.read(orderRepoProvider).watchMerchantOrders(widget.n.id).listen((_) {
      ref.invalidate(merchantOrdersProvider(widget.n.id));
      ref.invalidate(merchantStatsProvider(widget.n.id));
    });
  }

  @override
  void dispose() {
    merchantOrdersTabRequest.removeListener(_applyTabRequest);
    _sub?.cancel();
    super.dispose();
  }

  bool _inTab(Order o) => switch (_tab) {
        _Tab.pending => o.status == OrderStatus.pending,
        _Tab.preparing => o.status == OrderStatus.accepted || o.status == OrderStatus.preparing,
        _Tab.ready => o.status == OrderStatus.ready || o.status == OrderStatus.outForDelivery,
        _Tab.done => o.status.isTerminal,
      };

  Future<void> _set(Order o, OrderStatus s, {String? note}) async {
    try {
      await ref.read(orderRepoProvider).updateStatus(o.id, s, note: note);
      ref.invalidate(merchantOrdersProvider(widget.n.id));
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(merchantOrdersProvider(widget.n.id));
    final all = async.valueOrNull ?? const <Order>[];
    int count(_Tab t) {
      final prev = _tab; _tab = t; final c = all.where(_inTab).length; _tab = prev; return c;
    }
    final shown = all.where(_inTab).toList();

    return Scaffold(
      appBar: const FnAppBar(title: 'الطلبات الواردة', showBack: false),
      body: Column(children: [
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 6),
            children: [
              for (final (t, l) in [(_Tab.pending, 'جديدة'), (_Tab.preparing, 'قيد التجهيز'), (_Tab.ready, 'جاهزة'), (_Tab.done, 'مكتملة')])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: FnChip(small: true, label: t == _Tab.done ? l : '$l ${count(t)}', selected: _tab == t,
                      onTap: () => setState(() => _tab = t)),
                ),
            ],
          ),
        ),
        Expanded(
          child: async.isLoading && all.isEmpty
              ? const FnLoading()
              : shown.isEmpty
                  ? const FnEmpty(title: 'لا توجد طلبات هنا', icon: Icons.inbox_outlined)
                  : RefreshIndicator(
                      color: FnColors.primary,
                      onRefresh: () async => ref.invalidate(merchantOrdersProvider(widget.n.id)),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
                        itemCount: shown.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => _IncomingCard(
                          o: shown[i],
                          onAccept: () => _set(shown[i], OrderStatus.accepted),
                          onReject: () => _set(shown[i], OrderStatus.rejected, note: 'رفض المتجر'),
                        ),
                      ),
                    ),
        ),
      ]),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  const _IncomingCard({required this.o, required this.onAccept, required this.onReject});
  final Order o;
  final VoidCallback onAccept, onReject;
  @override
  Widget build(BuildContext context) => FnCard(
        onTap: () => context.push('/m/order/${o.id}'),
        padding: const EdgeInsets.all(14),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('#${o.orderNumber} — ${o.customerName?.isNotEmpty == true ? o.customerName : 'عميل'}', style: FnText.bodyStrong15),
              Text('${o.itemCount} منتجات • ${o.address['district'] ?? o.address['city'] ?? ''}', style: FnText.caption11.muted),
            ])),
            Text(Fmt.moneyShort(o.total), style: FnText.heading18.deep),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Text(Fmt.timeAgo(o.placedAt), style: FnText.caption11.faint),
            const Spacer(),
            if (o.status == OrderStatus.pending) ...[
              GestureDetector(
                onTap: onReject,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(13)),
                    child: Text('رفض', style: FnText.label13.clay)),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAccept,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                    decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(13)),
                    child: Text('قبول الطلب', style: FnText.label13.onDark)),
              ),
            ] else
              FnBadge(o.status.labelAr),
          ]),
        ]),
      );
}
