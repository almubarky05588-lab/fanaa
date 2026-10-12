"""Codemod 012: رفض الدخول بدور مختلف عن دور الرقم المسجّل (قبل إرسال الرسالة) — يشمل الحسابات التجريبية."""
import sys, os

def run(root):
    os.chdir(root)
    p = 'lib/data/repositories/auth_repo.dart'
    s = open(p, encoding='utf-8').read()
    if "'role': role.name});\n  }\n\n  /// يتحقق" in s:
        print('012 already applied'); return
    pairs = [
        ("    if (isDemo(localPhone)) return; // حساب تجريبي — لا رسالة\n    await _call('otp-send', {'phone': Fmt.toE164(localPhone)});",
         "    if (isDemo(localPhone)) {\n      // حساب تجريبي — لا رسالة، لكن نفس قاعدة الدور\n      final demoIsMerchant = Fmt.toE164(localPhone) != '+966500000001';\n      if (demoIsMerchant != (role == UserRole.merchant)) {\n        throw OtpException(demoIsMerchant\n            ? 'هذا الرقم مسجّل كصاحب متجر — سجّل الدخول من «صاحب متجر»'\n            : 'هذا الرقم مسجّل كعميل — سجّل الدخول من «مستخدم»');\n      }\n      return;\n    }\n    await _call('otp-send', {'phone': Fmt.toE164(localPhone), 'role': role.name});"),
    ]
    for a, b in pairs:
        assert s.count(a) == 1, a[:60]
        s = s.replace(a, b)
    open(p, 'w', encoding='utf-8').write(s)

    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    s = s.replace("\n};\n", "\n  'هذا الرقم مسجّل كصاحب متجر — سجّل الدخول من «صاحب متجر»': 'This number is registered as a store owner — sign in as \"Store owner\"',\n  'هذا الرقم مسجّل كعميل — سجّل الدخول من «مستخدم»': 'This number is registered as a customer — sign in as \"Customer\"',\n};\n")
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 012 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
