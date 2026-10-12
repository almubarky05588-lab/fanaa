import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repo.dart';

final _liveOrderProvider = StreamProvider.family<Order?, String>((ref, id) => ref.watch(orderRepoProvider).watchOrder(id));

/// 12 تتبع الطلب
class TrackingScreen extends ConsumerWidget {
  const TrackingScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_liveOrderProvider(orderId));
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      body: async.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(_liveOrderProvider(orderId))),
        data: (o) {
          if (o == null) return const FnEmpty(title: 'الطلب غير موجود');
          final lat = (o.address['lat'] as num?)?.toDouble();
          final lng = (o.address['lng'] as num?)?.toDouble();
          return Stack(children: [
            SizedBox(
              height: 360 + top,
              child: lat == null
                  ? Container(color: FnColors.sand)
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(target: LatLng(lat, lng!), zoom: 14),
                      markers: {Marker(markerId: const MarkerId('home'), position: LatLng(lat, lng))},
                      zoomControlsEnabled: false, myLocationButtonEnabled: false, mapToolbarEnabled: false,
                    ),
            ),
            Positioned(top: top + 12, right: FnSpace.page, child: FnBackButton(onTap: () => context.canPop() ? context.pop() : context.go('/orders'))),
            DraggableScrollableSheet(
              initialChildSize: .58, minChildSize: .58, maxChildSize: .92,
              builder: (_, scroll) => Container(
                decoration: const BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.vertical(top: Radius.circular(FnRadius.sheet))),
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(FnSpace.page, 18, FnSpace.page, 24),
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('طلب #${o.orderNumber}', style: FnText.title22),
                        Text('${o.nursery?.name ?? ''} • ${o.itemCount} منتجات', style: FnText.caption11.muted),
                      ])),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(o.status.isTerminal ? 'الحالة' : 'الوصول خلال', style: FnText.caption11.muted),
                        Text(o.status.isTerminal ? o.status.labelAr : _eta(o), style: FnText.heading18.deep),
                      ]),
                    ]),
                    const SizedBox(height: 16),
                    if (o.status == OrderStatus.cancelled || o.status == OrderStatus.rejected)
                      FnCard(color: const Color(0xFFF8EAE2), child: Text('تم ${o.status.labelAr} الطلب', style: FnText.bodyStrong15.clay))
                    else
                      _Timeline(o: o),
                    const SizedBox(height: 14),
                    FnCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        FnImage(url: o.nursery?.logoUrl, size: 46, radius: 16),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(o.nursery?.name ?? '', style: FnText.bodyStrong15),
                          Text('المشتل المُجهّز', style: FnText.caption11.muted),
                        ])),
                        if (o.nursery?.phone != null)
                          FnIconButton(
                            color: FnColors.deep, radius: 15,
                            onTap: () => launchUrl(Uri.parse('tel:${o.nursery!.phone}')),
                            child: const Icon(Icons.call_outlined, size: 18, color: Colors.white),
                          ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    FnCard(
                      child: Column(children: [
                        for (final i in o.items) FnKV('${i.name}${i.variantName != null ? ' (${i.variantName})' : ''} × ${i.qty}', Fmt.money(i.lineTotal)),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: FnDivider()),
                        FnKV('الإجمالي', Fmt.money(o.total), strong: true),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    if (o.status == OrderStatus.delivered)
                      FnButton(label: 'عرض الفاتورة', onPressed: () => context.push('/invoice/${o.id}'))
                    else if (o.status == OrderStatus.outForDelivery)
                      FnButton(
                        label: 'استلمت طلبي',
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        onPressed: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (d) => AlertDialog(
                              title: Text('تأكيد الاستلام', style: FnText.heading18),
                              content: Text('هل وصلك الطلب كاملًا؟', style: FnText.body15.muted),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(d, false), child: Text('ليس بعد', style: FnText.label13.muted)),
                                TextButton(onPressed: () => Navigator.pop(d, true), child: Text('نعم، استلمته', style: FnText.label13.primary)),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          try {
                            await ref.read(orderRepoProvider).updateStatus(o.id, OrderStatus.delivered);
                            ref.invalidate(myOrdersProvider);
                            if (context.mounted) showFnSnack(context, 'شكرًا لك! تم تأكيد استلام الطلب');
                          } catch (e) {
                            if (context.mounted) showFnSnack(context, fnErrorText(e), error: true);
                          }
                        },
                      )
                    else if (o.status == OrderStatus.pending)
                      FnGhostButton(
                        label: 'إلغاء الطلب', textColor: FnColors.clay,
                        onPressed: () async {
                          try {
                            await ref.read(orderRepoProvider).updateStatus(o.id, OrderStatus.cancelled, note: 'ألغاه العميل');
                            ref.invalidate(myOrdersProvider);
                          } catch (e) {
                            if (context.mounted) showFnSnack(context, fnErrorText(e), error: true);
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  String _eta(Order o) {
    final base = o.acceptedAt ?? o.placedAt;
    final left = base.add(Duration(minutes: o.nursery?.prepTimeMin ?? 45)).difference(DateTime.now()).inMinutes;
    return left <= 0 ? 'قريبًا' : '$left دقيقة';
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.o});
  final Order o;
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('تم استلام الطلب', o.placedAt),
      ('المشتل يجهّز الطلب', o.acceptedAt),
      ('خرج للتوصيل', o.pickedUpAt),
      ('تم التوصيل', o.deliveredAt),
    ];
    final cur = o.status.step;
    return FnCard(
      child: Column(children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < cur ? FnColors.deep : (i == cur ? FnColors.lime : FnColors.bgBase),
                    border: i > cur ? Border.all(color: FnColors.border, width: 1.5) : null,
                  ),
                  child: i <= cur ? Icon(Icons.check_rounded, size: 14, color: i == cur ? FnColors.deep : Colors.white) : null,
                ),
                if (i < steps.length - 1)
                  Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 2), color: i < cur ? FnColors.deep : FnColors.border)),
              ]),
              const SizedBox(width: 12),
              Expanded(child: Padding(
                padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 18 : 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(steps[i].$1, style: i > cur ? FnText.bodyStrong15.faint : FnText.bodyStrong15),
                  Text(steps[i].$2 == null ? (i == cur + 1 ? 'التالي' : '—') : Fmt.time(steps[i].$2!),
                      style: i == cur ? FnText.caption11.primary : FnText.caption11.muted),
                ]),
              )),
            ]),
          ),
      ]),
    );
  }
}
