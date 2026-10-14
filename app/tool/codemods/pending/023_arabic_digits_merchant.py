# Codemod 023: الأرقام العربية (١٢٣) تتحوّل تلقائيًا في كل خانات الأرقام عند التاجر
# (السعر، الكمية، الإعدادات، الآيبان، المحفظة، الكوبونات) — كانت تنحذف أو تنحفظ فاضية
import sys, os, re

IMPORT = "import '../../auth/phone_login_screen.dart' show EnglishDigitsFormatter;\n"
FILES = [
    'lib/features/merchant/products/add_product_screen.dart',
    'lib/features/merchant/settings/merchant_settings_screen.dart',
    'lib/features/merchant/wallet/merchant_wallet_screen.dart',
    'lib/features/merchant/setup/merchant_setup_screen.dart',
]

def add_import(s):
    if 'EnglishDigitsFormatter' in s.split('class ', 1)[0]:
        return s
    i = s.rfind("\nimport ", 0, s.find('\nclass ') if '\nclass ' in s else len(s))
    j = s.index(';\n', i) + 2
    return s[:j] + IMPORT + s[j:]

def run(root):
    os.chdir(root)
    if 'const EnglishDigitsFormatter(), FilteringTextInputFormatter' in open(FILES[0], encoding='utf-8').read():
        print('023 already applied'); return
    total = 0
    for p in FILES:
        s = open(p, encoding='utf-8').read()
        out, pos, n = [], 0, 0
        for m in re.finditer(r'TextInputType\.(number\b|numberWithOptions\([^)]*\))', s):
            k = s.find('inputFormatters: [', m.end(), m.end() + 260)
            if k < 0 or k < pos:
                continue
            k += len('inputFormatters: [')
            out.append(s[pos:k]); out.append('const EnglishDigitsFormatter(), '); pos = k; n += 1
        out.append(s[pos:])
        s = ''.join(out)
        assert n > 0, p
        open(p, 'w', encoding='utf-8').write(add_import(s))
        total += n

    p = 'lib/features/merchant/coupons/merchant_coupons_screen.dart'
    s = open(p, encoding='utf-8').read()
    old = ": (number ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null),"
    assert s.count(old) == 1
    s = s.replace(old, ": (number ? [const EnglishDigitsFormatter(), FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null),")
    open(p, 'w', encoding='utf-8').write(add_import(s))
    print('023 applied (%d fields)' % (total + 1))

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
