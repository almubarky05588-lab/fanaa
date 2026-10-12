import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/order_repo.dart';
import '../checkout/checkout_state.dart';

/// 11c بيانات البطاقة
///
/// ملاحظة: ربط بوابة الدفع (Moyasar) يتم عبر Edge Function تُنشئ الدفعة
/// وتستقبل webhook ثم تستدعي mark_order_paid. حتى يُفعّل الحساب التجاري،
/// يُنشأ الطلب بحالة "غير مدفوع" ولا تُرسل أي بيانات بطاقة إلى خوادمنا.
class CardDetailsScreen extends ConsumerStatefulWidget {
  const CardDetailsScreen({super.key, required this.method});
  final PayMethod method;
  @override
  ConsumerState<CardDetailsScreen> createState() => _CardDetailsScreenState();
}

class _CardDetailsScreenState extends ConsumerState<CardDetailsScreen> {
  final _number = TextEditingController();
  final _exp = TextEditingController();
  final _cvv = TextEditingController();
  final _name = TextEditingController();
  bool _save = true;
  bool _loading = false;

  bool get _valid =>
      _number.text.replaceAll(' ', '').length >= 16 && _exp.text.length == 5 && _cvv.text.length >= 3 && _name.text.trim().length > 2;

  String get _last4 {
    final d = _number.text.replaceAll(' ', '');
    return d.length >= 4 ? d.substring(d.length - 4) : '••••';
  }

  Future<void> _confirm() async {
    final d = ref.read(checkoutDraftProvider);
    if (d == null || d.address == null) return;
    setState(() => _loading = true);
    try {
      final id = await ref.read(orderRepoProvider).placeOrder(
            nurseryId: d.nurseryId, addressId: d.address!.id, paymentMethod: widget.method.db,
            coupon: d.coupon, note: d.note, scheduledAt: d.scheduledAt);
      ref.invalidate(cartsProvider);
      ref.invalidate(myOrdersProvider);
      if (mounted) context.go('/payment/success/$id');
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(checkoutDraftProvider);
    return Scaffold(
      appBar: const FnAppBar(title: 'بيانات البطاقة'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 12, FnSpace.page, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(22), boxShadow: FnShadow.raised),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(widget.method.title, style: FnText.bodyStrong15.onDark),
                const Spacer(),
                Container(width: 38, height: 28, decoration: BoxDecoration(color: FnColors.lime, borderRadius: BorderRadius.circular(7))),
              ]),
              const SizedBox(height: 18),
              Directionality(textDirection: TextDirection.ltr,
                  child: Text('••••  ••••  ••••  $_last4', style: FnText.title22.onDark)),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('حامل البطاقة', style: FnText.caption11.soft),
                  Text(_name.text.isEmpty ? 'الاسم كما في البطاقة' : _name.text, style: FnText.label13.onDark),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('تاريخ الانتهاء', style: FnText.caption11.soft),
                  Text(_exp.text.isEmpty ? 'MM / YY' : _exp.text, style: FnText.label13.onDark),
                ]),
              ]),
            ]),
          ),
          const SizedBox(height: 18),
          _f('رقم البطاقة', _number, '0000 0000 0000 0000', [FilteringTextInputFormatter.digitsOnly, _CardFmt()], ltr: true),
          Row(children: [
            Expanded(child: _f('تاريخ الانتهاء', _exp, 'MM/YY', [FilteringTextInputFormatter.digitsOnly, _ExpFmt()], ltr: true)),
            const SizedBox(width: 12),
            Expanded(child: _f('CVV', _cvv, '•••', [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)], ltr: true, obscure: true)),
          ]),
          _f('الاسم على البطاقة', _name, 'الاسم الكامل', const []),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: Text('احفظ هذه البطاقة للطلبات القادمة', style: FnText.body15)),
            FnSwitch(value: _save, onChanged: (v) => setState(() => _save = v)),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline_rounded, size: 14, color: FnColors.muted),
            const SizedBox(width: 6),
            Text('محمي بتشفير 3-D Secure', style: FnText.caption11.muted),
          ]),
        ],
      ),
      bottomNavigationBar: FnBottomBar(
        child: FnButton(label: 'تأكيد الدفع ${Fmt.moneyShort(d?.total ?? 0)}', loading: _loading, onPressed: _valid ? _confirm : null),
      ),
    );
  }

  Widget _f(String label, TextEditingController c, String hint, List<TextInputFormatter> fmt, {bool ltr = false, bool obscure = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: FnText.label13.muted),
          const SizedBox(height: 6),
          TextField(
            controller: c, inputFormatters: fmt, obscureText: obscure,
            keyboardType: ltr ? TextInputType.number : TextInputType.name,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: ltr ? TextAlign.left : TextAlign.start,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: hint),
          ),
        ]),
      );
}

class _CardFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll(' ', '');
    final s = StringBuffer();
    for (var i = 0; i < d.length && i < 16; i++) { if (i > 0 && i % 4 == 0) s.write(' '); s.write(d[i]); }
    return TextEditingValue(text: s.toString(), selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpFmt extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final d = n.text.replaceAll('/', '');
    final s = d.length <= 2 ? d : '${d.substring(0, 2)}/${d.substring(2, d.length.clamp(2, 4))}';
    return TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}
