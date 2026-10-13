# Codemod 018: التطبيق يرسل طريقة الدفع المختارة كل محاولة (لو غيّرها العميل قبل الدفع)
import sys, os

def ed(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:60])
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8').write(s)

def run(root):
    os.chdir(root)
    p = 'lib/data/repositories/order_repo.dart'
    if "'method': method" in open(p, encoding='utf-8').read():
        print('018 already applied'); return
    ed(p, [(
        "  Future<String?> createPayment(String orderId) async =>\n      (await _invokeFn('payment-create', {'order_id': orderId}))['url'] as String?;",
        "  Future<String?> createPayment(String orderId, {String? method}) async =>\n      (await _invokeFn('payment-create', {'order_id': orderId, if (method != null) 'method': method}))['url'] as String?;",
    )])
    ed('lib/features/customer/payment/payment_screen.dart', [
        ("    try {\n      final repo = ref.read(orderRepoProvider);\n      final id = _pendingOrderId ??",
         "    try {\n      if (_m == PayMethod.cod && _pendingOrderId != null) {\n        // الطلب الحالي أُنشئ للدفع الإلكتروني — يكمله بطريقة إلكترونية\n        showFnSnack(context, tr('طلبك الحالي للدفع الإلكتروني — اختر Apple Pay أو البطاقة أو STC Pay'), error: true);\n        return;\n      }\n      final repo = ref.read(orderRepoProvider);\n      final id = _pendingOrderId ??"),
        ("final url = await repo.createPayment(id);", "final url = await repo.createPayment(id, method: _m.db);"),
    ])
    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    s = s.replace("\n};\n", "\n  'طلبك الحالي للدفع الإلكتروني — اختر Apple Pay أو البطاقة أو STC Pay': 'This order is set for online payment — choose Apple Pay, card or STC Pay',\n};\n")
    open(p, 'w', encoding='utf-8').write(s)
    print('018 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
