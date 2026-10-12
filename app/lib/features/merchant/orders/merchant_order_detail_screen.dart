import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repo.dart';
import '../../customer/payment/payment_success_screen.dart' show orderProvider;

/// 17 تفاصيل الطلب (التاجر)
class MerchantOrderDetailScreen extends ConsumerStatefulWidget {
  const MerchantOrderDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<MerchantOrderDetailScreen> createState() => _State();
}

class _State extends ConsumerState<MerchantOrderDetailScreen> {
  bool _busy = false;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) { if (mounted) setState(() {}); });
  }

  @override
  void dispose() { _tick?.cancel(); super.dispose(); }

  Future<void> _go(OrderStatus s) async {
    setState(() => _busy = true);
    try {
      await ref.read(orderRepoProvider).updateStatus(widget.id, s);
      ref.invalidate(orderProvider(widget.id));
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  (String, OrderStatus)? _next(OrderStatus s) => switch (s) {
        OrderStatus.pending => ('قبول الطلب', OrderStatus.accepted),
        OrderStatus.accepted => ('بدء التجهيز', OrderStatus.preparing),
        OrderStatus.preparing => ('الطلب جاهز للتوصيل', OrderStatus.ready),
        OrderStatus.ready => ('خرج للتوصيل', OrderStatus.outForDelivery),
        OrderStatus.outForDelivery => ('تأكيد التوصيل', OrderStatus.delivered),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(orderProvider(widget.id));
    return Scaffold(
      appBar: FnAppBar(title: async.valueOrNull == null ? 'الطلب' : 'طلب #${async.value!.orderNumber}'),
      body: async.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(orderProvider(widget.id))),
        data: (o) {
          if (o == null) return const FnEmpty(title: 'الطلب غير موجود');
          final due = (o.acceptedAt ?? o.placedAt).add(const Duration(minutes: 45));
          final left = due.difference(DateTime.now());
          return ListView(
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.status.labelAr, style: FnText.bodyStrong15.onDark),
                    Text(o.status.isTerminal ? Fmt.dateTime(o.placedAt) : 'الوقت المتبقي لتجهيز الطلب', style: FnText.caption11.soft),
                  ])),
                  if (!o.status.isTerminal)
                    Text(left.isNegative ? 'متأخر' : '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}',
                        style: FnText.heading18.lime),
                ]),
              ),
              const SizedBox(height: 12),
              FnCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(o.customerName?.isNotEmpty == true ? o.customerName! : 'عميل', style: FnText.bodyStrong15),
                    if (o.customerPhone != null)
                      Directionality(textDirection: TextDirection.ltr, child: Text(Fmt.phone(o.customerPhone!), style: FnText.caption11.muted)),
                    Text(o.addressLine, style: FnText.caption11.muted),
                    if ((o.note ?? '').isNotEmpty) Text('ملاحظة: ${o.note}', style: FnText.caption11.clay),
                  ])),
                  if (o.customerPhone != null)
                    FnIconButton(
                      color: FnColors.soft, radius: 15,
                      onTap: () => launchUrl(Uri.parse('tel:${o.customerPhone}')),
                      child: const Icon(Icons.call_outlined, size: 18, color: FnColors.deep),
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              Text('المنتجات', style: FnText.label13.muted),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  for (var i = 0; i < o.items.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        const FnImage(size: 46, radius: 14),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(o.items[i].name, style: FnText.bodyStrong15),
                          Text('${o.items[i].variantName ?? ''} • الكمية ${o.items[i].qty}', style: FnText.caption11.muted),
                        ])),
                        Text(Fmt.moneyShort(o.items[i].lineTotal), style: FnText.label13),
                      ]),
                    ),
                    if (i < o.items.length - 1) const FnDivider(),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              FnCard(
                child: Column(children: [
                  FnKV('مجموع المنتجات', Fmt.money(o.subtotal)),
                  FnKV('رسوم التوصيل', Fmt.money(o.deliveryFee)),
                  if (o.discount > 0) FnKV('الخصم', '− ${Fmt.money(o.discount)}'),
                  FnKV('عمولة المنصة', '− ${Fmt.money(o.commission)}'),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: FnDivider()),
                  FnKV('صافي مستحقك', Fmt.money(o.netPayout), strong: true),
                ]),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: () {
        final o = async.valueOrNull;
        if (o == null) return null;
        final n = _next(o.status);
        return FnBottomBar(
          child: Row(children: [
            FnIconButton(
              size: 58, radius: 18, color: FnColors.bgBase,
              onTap: o.status == OrderStatus.delivered ? () => context.push('/invoice/${o.id}') : null,
              child: const Icon(Icons.print_outlined, color: FnColors.ink),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: n == null
                  ? FnButton(label: o.status.labelAr, onPressed: null)
                  : FnButton(label: n.$1, loading: _busy, onPressed: () => _go(n.$2)),
            ),
          ]),
        );
      }(),
    );
  }
}
