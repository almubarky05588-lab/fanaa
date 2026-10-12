"""Codemod 003: تعيين العنوان الافتراضي + ترجمات عنوان الرئيسية."""
import sys, os
EDITS = {
 "lib/core/i18n/en.dart": [
  [
   "اكا': 'Sakaka',\n};\n",
   "اكا': 'Sakaka',\n  'التوصيل إلى {0}': 'Deliver to {0}',\n  'تم تعيين عنوان التوصيل': 'Delivery address updated',\n};\n"
  ]
 ],
 "lib/data/repositories/order_repo.dart": [
  [
   "Json(j);\n  }\n\n  // -------------",
   "Json(j);\n  }\n\n  Future<void> setDefaultAddress(String id) async {\n    final uid = _c.auth.currentUser!.id;\n    await _c.from('addresses').update({'is_default': false}).eq('user_id', uid);\n    await _c.from('addresses').update({'is_default': true}).eq('id', id);\n  }\n\n  // -------------"
  ]
 ]
}

def run(root):
    os.chdir(root)
    if 'setDefaultAddress' in open('lib/data/repositories/order_repo.dart', encoding='utf-8').read():
        print('003 already applied'); return
    for path, ops in EDITS.items():
        s = open(path, encoding='utf-8').read()
        for old, new in ops:
            assert s.count(old) == 1, (path, old[:60])
            s = s.replace(old, new)
        open(path, 'w', encoding='utf-8').write(s)
    print('✅ 003 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
