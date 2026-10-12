"""Codemod 013: الدفع الإلكتروني عبر ماي فاتورة (صفحة دفع داخل التطبيق + تحقق من الخادم)."""
import sys, os

NEW_PAY = '''  /// الطلب الإلكتروني الذي أُنشئ ولم يُدفع بعد — يُعاد استخدامه عند إعادة المحاولة
  String? _pendingOrderId;

  Future<void> _pay() async {
    final d = ref.read(checkoutDraftProvider);
    if (d == null || d.address == null) return;
    setState(() => _loading = true);
    try {
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
      final url = await repo.createPayment(id);
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
'''

REPO = '''  /// ينشئ رابط دفع ماي فاتورة للطلب (null = الطلب مدفوع أصلًا)
  Future<String?> createPayment(String orderId) async =>
      (await _invokeFn('payment-create', {'order_id': orderId}))['url'] as String?;

  /// يسأل الخادم: هل تأكّد الدفع من ماي فاتورة؟
  Future<bool> verifyPayment(String orderId) async =>
      (await _invokeFn('payment-verify', {'order_id': orderId}))['paid'] == true;

  Future<Map<String, dynamic>> _invokeFn(String fn, Map<String, dynamic> body) async {
    try {
      final r = await _c.functions.invoke(fn, body: body);
      return Map<String, dynamic>.from(r.data as Map);
    } on FunctionException catch (e) {
      final d = e.details;
      throw PaymentException(d is Map && d['error'] is String ? d['error'] as String : 'حدث خطأ غير متوقع');
    }
  }

  Future<List<Order>> myOrders() async {'''

def ed(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:60])
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8').write(s)

def run(root):
    os.chdir(root)
    p = 'lib/features/customer/payment/payment_screen.dart'
    s = open(p, encoding='utf-8').read()
    if 'PayWebViewScreen' in s:
        print('013 already applied'); return
    i = s.index('  Future<void> _pay() async {')
    j = s.index('  @override\n  Widget build(BuildContext context) {')
    s = s[:i] + NEW_PAY + '\n' + s[j:]
    s = s.replace("_m.needsCard ? tr('تُدخل بيانات البطاقة في الخطوة التالية بشكل آمن') : tr('دفع آمن ومشفّر')",
                  "_m == PayMethod.cod ? tr('ادفع نقدًا أو بالشبكة عند استلام طلبك') : tr('ستنتقل لصفحة الدفع الآمنة من ماي فاتورة')")
    s = s.replace("label: _m.needsCard ? tr('المتابعة') : tr('ادفع {0}', [Fmt.moneyShort(d.total)])",
                  "label: _m == PayMethod.cod ? tr('تأكيد الطلب') : tr('ادفع {0}', [Fmt.moneyShort(d.total)])")
    s = s.replace("import '../checkout/checkout_state.dart';\n", "import '../checkout/checkout_state.dart';\nimport 'pay_webview_screen.dart';\n", 1)
    open(p, 'w', encoding='utf-8').write(s)

    p = 'lib/data/repositories/order_repo.dart'
    ed(p, [("  Future<List<Order>> myOrders() async {", REPO)])
    s = open(p, encoding='utf-8').read().rstrip() + '''

/// خطأ من خدمة الدفع برسالة جاهزة للعرض
class PaymentException implements Exception {
  PaymentException(this.message);
  final String message;
  @override
  String toString() => message;
}
'''
    open(p, 'w', encoding='utf-8').write(s)

    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    add = {
        'لم يكتمل الدفع — تقدر تحاول مرة ثانية': 'Payment not completed — you can try again',
        'ادفع نقدًا أو بالشبكة عند استلام طلبك': 'Pay cash or card when you receive your order',
        'ستنتقل لصفحة الدفع الآمنة من ماي فاتورة': "You'll continue to MyFatoorah's secure payment page",
        'بوابة الدفع غير مهيّأة': 'Payment gateway is not configured',
        'هذا الطلب بالدفع عند الاستلام': 'This order is cash on delivery',
        'انتهت مهلة الدفع لهذا الطلب': 'The payment window for this order has expired',
        'تعذّر إنشاء رابط الدفع': 'Could not create the payment link',
        'لم يكتمل الدفع': 'Payment not completed',
    }
    lines = ''.join("  '%s': %s,\n" % (k, "'" + v.replace("'", "\\'") + "'") for k, v in add.items() if f"  '{k}':" not in s)
    s = s.replace("\n};\n", "\n" + lines.rstrip('\n') + "\n};\n")
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 013 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
