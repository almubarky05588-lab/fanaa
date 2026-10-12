import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repo.dart';
import '../dashboard/merchant_dashboard_screen.dart';

final _walletProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, nid) => ref.watch(orderRepoProvider).wallet(nid));

/// 20 المحفظة والتسويات
class MerchantWalletScreen extends ConsumerWidget {
  const MerchantWalletScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WithMyNursery(builder: (n) => _Wallet(n: n));
}

class _Wallet extends ConsumerWidget {
  const _Wallet({required this.n});
  final Nursery n;

  Future<void> _withdraw(BuildContext context, WidgetRef ref, double balance) async {
    final amount = TextEditingController(text: balance.toStringAsFixed(0));
    final iban = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('طلب سحب', style: FnText.heading18),
          Text('الرصيد المتاح ${Fmt.money(balance)}', style: FnText.caption11.muted),
          const SizedBox(height: 14),
          TextField(controller: amount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'المبلغ', fillColor: FnColors.bgBase)),
          const SizedBox(height: 10),
          TextField(controller: iban, decoration: const InputDecoration(hintText: 'آخر ٤ أرقام من الآيبان', fillColor: FnColors.bgBase),
              keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)]),
          const SizedBox(height: 16),
          FnButton(label: 'تأكيد الطلب', onPressed: () async {
            final a = double.tryParse(amount.text) ?? 0;
            if (a <= 0 || iban.text.length != 4) return;
            try {
              await ref.read(orderRepoProvider).requestPayout(n.id, a, iban.text);
              if (ctx.mounted) Navigator.pop(ctx, true);
            } catch (e) {
              if (ctx.mounted) showFnSnack(ctx, fnErrorText(e), error: true);
            }
          }),
        ]),
      ),
    );
    if (ok == true) {
      ref.invalidate(_walletProvider(n.id));
      if (context.mounted) showFnSnack(context, 'تم استلام طلب السحب');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = ref.watch(_walletProvider(n.id));
    final orders = ref.watch(merchantOrdersProvider(n.id)).valueOrNull ?? const <Order>[];
    final now = DateTime.now();
    final month = orders.where((o) => o.status == OrderStatus.delivered && o.placedAt.month == now.month && o.placedAt.year == now.year);
    final monthSales = month.fold<double>(0, (s, o) => s + o.total);
    final monthComm = month.fold<double>(0, (s, o) => s + o.commission);

    return Scaffold(
      appBar: const FnAppBar(title: 'المحفظة', showBack: false),
      body: w.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(_walletProvider(n.id))),
        data: (d) {
          final bal = d['balance'] as double;
          final pending = d['pending'] as double;
          final tx = d['transactions'] as List<WalletTxn>;
          return RefreshIndicator(
            color: FnColors.primary,
            onRefresh: () async => ref.invalidate(_walletProvider(n.id)),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(24), boxShadow: FnShadow.raised),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('الرصيد المتاح للسحب', style: FnText.caption11.lime),
                    Text(Fmt.money(bal), style: FnText.display28.onDark),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: Text('التحويلات تتم كل خميس', style: FnText.caption11.soft)),
                      GestureDetector(
                        onTap: bal <= 0 ? null : () => _withdraw(context, ref, bal),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          decoration: BoxDecoration(color: bal <= 0 ? FnColors.lime.withValues(alpha: .5) : FnColors.lime, borderRadius: BorderRadius.circular(14)),
                          child: Text('طلب سحب', style: FnText.label13.deep),
                        ),
                      ),
                    ]),
                  ]),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  _S(Fmt.moneyShort(monthSales), 'مبيعات الشهر'),
                  const SizedBox(width: 10),
                  _S(Fmt.moneyShort(monthComm), 'عمولة المنصة'),
                  const SizedBox(width: 10),
                  _S(Fmt.moneyShort(pending), 'قيد التحويل'),
                ]),
                const SizedBox(height: 18),
                const FnSectionTitle('آخر الحركات'),
                const SizedBox(height: 10),
                if (tx.isEmpty)
                  FnCard(child: Center(child: Text('لا توجد حركات بعد', style: FnText.body15.muted)))
                else
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20)),
                    child: Column(children: [
                      for (var i = 0; i < tx.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(tx[i].note ?? _typeLabel(tx[i].type), style: FnText.body15),
                              Text(Fmt.dateTime(tx[i].createdAt), style: FnText.caption11.muted),
                            ])),
                            Text('${tx[i].amount >= 0 ? '+' : '−'} ${Fmt.money(tx[i].amount.abs())}',
                                style: FnText.bodyStrong15.copyWith(color: tx[i].amount >= 0 ? FnColors.deep : FnColors.clay)),
                          ]),
                        ),
                        if (i < tx.length - 1) const FnDivider(),
                      ],
                    ]),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _typeLabel(String t) => switch (t) {
        'order_credit' => 'تحصيل طلب',
        'commission' => 'عمولة المنصة',
        'payout' => 'تحويل بنكي',
        'refund' => 'استرداد',
        _ => 'تسوية',
      };
}

class _S extends StatelessWidget {
  const _S(this.v, this.l);
  final String v, l;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(v, style: FnText.label13, textAlign: TextAlign.center),
            Text(l, style: FnText.caption11.muted, textAlign: TextAlign.center),
          ]),
        ),
      );
}
