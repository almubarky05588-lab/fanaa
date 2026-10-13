# Codemod 019: أندرويد — إخفاء Apple Pay، والاتجاهات للتاجر تفتح خرائط قوقل مباشرة
import sys, os

def ed(p, pairs):
    s = open(p, encoding='utf-8').read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:60])
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8').write(s)

def run(root):
    os.chdir(root)
    p = 'lib/features/customer/checkout/checkout_state.dart'
    if 'TargetPlatform.iOS' in open(p, encoding='utf-8').read():
        print('019 already applied'); return
    ed(p, [
        ("const kShownPayMethods = [PayMethod.applePay, PayMethod.mada, PayMethod.stcPay, PayMethod.cod];",
         "final kShownPayMethods = <PayMethod>[\n  if (defaultTargetPlatform == TargetPlatform.iOS) PayMethod.applePay, // Apple Pay على iPhone فقط\n  PayMethod.mada, PayMethod.stcPay, PayMethod.cod,\n];"),
        ("import 'package:flutter_riverpod/flutter_riverpod.dart';\n",
         "import 'package:flutter/foundation.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';\n"),
    ])
    ed('lib/features/merchant/orders/merchant_order_detail_screen.dart', [(
        "  Future<void> _directions() async {\n    final google = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');",
        "  Future<void> _directions() async {\n"
        "    if (defaultTargetPlatform == TargetPlatform.android) {\n"
        "      await launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving'),\n"
        "          mode: LaunchMode.externalApplication);\n"
        "      return;\n"
        "    }\n"
        "    final google = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');",
    )])
    p = 'lib/features/merchant/orders/merchant_order_detail_screen.dart'
    s = open(p, encoding='utf-8').read()
    if "package:flutter/foundation.dart" not in s:
        s = s.replace("import 'package:flutter/material.dart';\n", "import 'package:flutter/foundation.dart';\nimport 'package:flutter/material.dart';\n", 1)
        open(p, 'w', encoding='utf-8').write(s)
    print('019 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
