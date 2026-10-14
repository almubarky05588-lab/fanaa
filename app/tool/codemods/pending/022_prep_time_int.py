# Codemod 022: «وقت التجهيز» يُحفظ رقمًا صحيحًا (كان يُرسل 40.0 فترفضه القاعدة)
import sys, os

def run(root):
    os.chdir(root)
    p = 'lib/features/merchant/settings/merchant_settings_screen.dart'
    s = open(p, encoding='utf-8').read()
    if "intFields" in s:
        print('022 already applied'); return
    old = "    await _update({field: v.isEmpty ? null : double.tryParse(v)});"
    assert s.count(old) == 1
    s = s.replace(old,
        "    final parsed = double.tryParse(v);\n"
        "    // أعمدة أرقام صحيحة في القاعدة (الدقائق) — لا تقبل 40.0\n"
        "    const intFields = {'prep_time_min'};\n"
        "    await _update({field: v.isEmpty ? null : (intFields.contains(field) ? parsed?.round() : parsed)});")
    open(p, 'w', encoding='utf-8').write(s)
    print('022 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
