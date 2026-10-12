import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repo.dart';
import '../payment/payment_success_screen.dart';

final _invoiceProvider = FutureProvider.family<Invoice?, String>((ref, id) => ref.watch(orderRepoProvider).invoice(id));

/// 12b فاتورة الطلب — فاتورة ضريبية مبسطة مع QR الزكاة
class InvoiceScreen extends ConsumerWidget {
  const InvoiceScreen({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = ref.watch(orderProvider(orderId)).valueOrNull;
    final inv = ref.watch(_invoiceProvider(orderId));
    return Scaffold(
      appBar: FnAppBar(
        title: 'الفاتورة',
        action: FnIconButton(
          size: 40, radius: 14,
          onTap: o == null ? null : () => Share.share('فاتورة طلب #${o.orderNumber} — ${Fmt.money(o.total)}'),
          child: const Icon(Icons.ios_share_rounded, size: 18, color: FnColors.ink),
        ),
      ),
      body: inv.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(_invoiceProvider(orderId))),
        data: (i) {
          if (o == null) return const FnLoading();
          if (i == null) {
            return const FnEmpty(title: 'ستصدر الفاتورة بعد التوصيل', icon: Icons.receipt_long_outlined);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
            children: [
              FnCard(
                shadow: true, radius: 24,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const FnLogoLockup(markSize: 30, markColor: FnColors.primary),
                    const Spacer(),
                    const FnBadge('فاتورة ضريبية مبسطة'),
                  ]),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(child: Column(children: [
                      FnKV('رقم الفاتورة', i.invoiceNumber),
                      FnKV('التاريخ والوقت', Fmt.dateTime(i.issuedAt)),
                      FnKV('رقم الطلب', '#${o.orderNumber}'),
                    ])),
                    const SizedBox(width: 12),
                    if (i.zatcaQr != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(10)),
                        child: QrImageView(data: i.zatcaQr!, size: 84, padding: EdgeInsets.zero),
                      ),
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: FnDivider()),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _Party('البائع', i.sellerName, i.sellerVat == null ? null : 'الرقم الضريبي ${i.sellerVat}')),
                    const SizedBox(width: 14),
                    Expanded(child: _Party('المشتري', o.customerName?.isNotEmpty == true ? o.customerName! : 'عميل فناء', o.addressLine)),
                  ]),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: FnDivider()),
                  Row(children: [
                    Expanded(child: Text('الصنف', style: FnText.caption11.muted)),
                    SizedBox(width: 48, child: Text('الكمية', style: FnText.caption11.muted, textAlign: TextAlign.center)),
                    SizedBox(width: 74, child: Text('الإجمالي', style: FnText.caption11.muted, textAlign: TextAlign.end)),
                  ]),
                  const SizedBox(height: 6),
                  for (final it in o.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Expanded(child: Text('${it.name}${it.variantName != null ? ' — ${it.variantName}' : ''}', style: FnText.body15)),
                        SizedBox(width: 48, child: Text('${it.qty}', style: FnText.label13.muted, textAlign: TextAlign.center)),
                        SizedBox(width: 74, child: Text(it.lineTotal.toStringAsFixed(2), style: FnText.label13, textAlign: TextAlign.end)),
                      ]),
                    ),
                  if (o.deliveryFee > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Expanded(child: Text('توصيل', style: FnText.body15)),
                        SizedBox(width: 48, child: Text('1', style: FnText.label13.muted, textAlign: TextAlign.center)),
                        SizedBox(width: 74, child: Text(o.deliveryFee.toStringAsFixed(2), style: FnText.label13, textAlign: TextAlign.end)),
                      ]),
                    ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: FnDivider()),
                  FnKV('مجموع المنتجات', Fmt.money(o.subtotal)),
                  FnKV('رسوم التوصيل', Fmt.money(o.deliveryFee)),
                  if (o.discount > 0) FnKV('الخصم', '− ${Fmt.money(o.discount)}'),
                  FnKV('منها ضريبة القيمة المضافة 15%', Fmt.money(i.vatAmount)),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: FnDivider()),
                  FnKV('الإجمالي المستحق', Fmt.money(i.total), strong: true),
                  const SizedBox(height: 8),
                  Text('فاتورة مطابقة لمتطلبات هيئة الزكاة والضريبة والجمارك', style: FnText.caption11.muted),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Party extends StatelessWidget {
  const _Party(this.t, this.name, this.sub);
  final String t, name;
  final String? sub;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: FnText.caption11.muted),
        Text(name, style: FnText.bodyStrong15),
        if (sub != null) Text(sub!, style: FnText.caption11.muted),
      ]);
}
