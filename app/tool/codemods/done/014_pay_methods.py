"""Codemod 014: طرق الدفع — Apple Pay، بطاقة بنكية (مدى/فيزا/ماستر)، STC Pay، الدفع عند الاستلام (بدون تابي)."""
import sys, os

def ed(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) >= 1, (p, a[:60])
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8').write(s)

def run(root):
    os.chdir(root)
    p = 'lib/features/customer/checkout/checkout_state.dart'
    if 'kShownPayMethods' in open(p, encoding='utf-8').read():
        print('014 already applied'); return
    ed(p, [
        ("        PayMethod.mada => tr('مدى'),", "        PayMethod.mada => tr('بطاقة بنكية'),"),
        ("        PayMethod.mada => tr('بطاقة مدى البنكية'),", "        PayMethod.mada => tr('مدى • فيزا • ماستركارد'),"),
        ("enum PayMethod { applePay, mada, creditCard, stcPay, tabby, cod }",
         "enum PayMethod { applePay, mada, creditCard, stcPay, tabby, cod }\n\n/// الطرق الظاهرة للعميل (البطاقة البنكية تشمل مدى وفيزا وماستركارد)\nconst kShownPayMethods = [PayMethod.applePay, PayMethod.mada, PayMethod.stcPay, PayMethod.cod];"),
    ])
    ed('lib/features/customer/payment/payment_screen.dart', [("PayMethod.values", "kShownPayMethods")])
    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    s = s.replace("\n};\n", "\n  'بطاقة بنكية': 'Bank card',\n  'مدى • فيزا • ماستركارد': 'mada • Visa • Mastercard',\n};\n")
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 014 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
