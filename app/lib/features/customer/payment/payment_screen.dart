import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/order_repo.dart';
import '../checkout/checkout_state.dart';
import 'pay_webview_screen.dart';
import '../../../core/i18n/i18n.dart';

/// 11 بوابة الدفع
class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PayMethod _m = PayMethod.mada;
  bool _loading = false;

  /// الطلب الإلكتروني الذي أُنشئ ولم يُدفع بعد — يُعاد استخدامه عند إعادة المحاولة
  String? _pendingOrderId;

  Future<void> _pay() async {
    final d = ref.read(checkoutDraftProvider);
    if (d == null || d.address == null) return;
    setState(() => _loading = true);
    try {
      if (_m == PayMethod.cod && _pendingOrderId != null) {
        // الطلب الحالي أُنشئ للدفع الإلكتروني — يكمله بطريقة إلكترونية
        showFnSnack(context, tr('طلبك الحالي للدفع الإلكتروني — اختر Apple Pay أو البطاقة أو STC Pay'), error: true);
        return;
      }
      final repo = ref.read(orderRepoProvider);
      final id = _pendingOrderId ?? await repo.placeOrder(
            nurseryId: d.nurseryId, addressId: d.address!.id, paymentMethod: _m.db,
            coupon: d.coupon, note: d.note, scheduledAt: d.scheduledAt);
      ref.invalidate(cartsProvider);
      ref.invalidate(myOrdersProvider);
      if (_m == PayMethod.cod) {
        if (mounted) context.go('/payment/success/$id');
        return;
      }
      _pendingOrderId = id;
      // رابط الدفع ينشئه الخادم بالمبلغ المحفوظ في القاعدة
      final url = await repo.createPayment(id, method: _m.db);
      if (!mounted) return;
      if (url != null) await PayWebViewScreen.open(context, url);
      // التأكيد الفعلي من ماي فاتورة نفسها (لا نعتمد على صفحة الرجوع)
      final paid = await repo.verifyPayment(id);
      if (!mounted) return;
      if (paid) {
        _pendingOrderId = null;
        ref.invalidate(myOrdersProvider);
        context.go('/payment/success/$id');
      } else {
        showFnSnack(context, tr('لم يكتمل الدفع — تقدر تحاول مرة ثانية'), error: true);
      }
    } catch (e) {
      if (mounted) showFnSnack(context, e is PaymentException ? tr(e.message) : fnErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(checkoutDraftProvider);
    if (d == null) return Scaffold(body: FnEmpty(title: tr('لا يوجد طلب')));
    return Scaffold(
      appBar: FnAppBar(title: tr('الدفع')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
            decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(22)),
            child: Column(children: [
              Text(tr('المبلغ المستحق'), style: FnText.caption11.lime),
              Text(Fmt.moneyShort(d.total), style: FnText.display28.onDark),
              Text(d.nurseryName, style: FnText.caption11.soft),
            ]),
          ),
          const SizedBox(height: 14),
          Text(tr('اختر طريقة الدفع'), style: FnText.label13.muted),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              for (var i = 0; i < kShownPayMethods.length; i++) ...[
                _MethodRow(m: kShownPayMethods[i], selected: _m == kShownPayMethods[i], onTap: () => setState(() => _m = kShownPayMethods[i])),
                if (i < kShownPayMethods.length - 1) const FnDivider(),
              ],
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              const Icon(Icons.lock_outline_rounded, size: 14, color: FnColors.deep),
              const SizedBox(width: 8),
              Expanded(child: Text(_m == PayMethod.cod ? tr('ادفع نقدًا أو بالشبكة عند استلام طلبك') : tr('ستنتقل لصفحة الدفع الآمنة من ماي فاتورة'),
                  style: FnText.caption11.deep)),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: FnBottomBar(
        child: FnButton(label: _m == PayMethod.cod ? tr('تأكيد الطلب') : tr('ادفع {0}', [Fmt.moneyShort(d.total)]), loading: _loading, onPressed: _pay),
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({required this.m, required this.selected, required this.onTap});
  final PayMethod m;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: selected ? FnColors.soft : Colors.transparent, borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            Container(width: 44, height: 30, decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(9)),
                child: Icon(_icon, size: 18, color: FnColors.muted)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m.title, style: FnText.bodyStrong15),
              Text(m.subtitle, style: FnText.caption11.muted),
            ])),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? FnColors.deep : Colors.transparent,
                border: selected ? null : Border.all(color: FnColors.border, width: 1.5),
              ),
              child: selected ? Center(child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))) : null,
            ),
          ]),
        ),
      );

  IconData get _icon => switch (m) {
        PayMethod.applePay => Icons.apple,
        PayMethod.stcPay => Icons.account_balance_wallet_outlined,
        PayMethod.tabby => Icons.calendar_month_outlined,
        PayMethod.cod => Icons.payments_outlined,
        _ => Icons.credit_card_rounded,
      };
}
