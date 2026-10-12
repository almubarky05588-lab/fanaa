"""Codemod 006: أيقونة زر الاتجاهات (FnButton يأخذ Widget وليس IconData)."""
import sys, os

def run(root):
    os.chdir(root)
    p = 'lib/features/merchant/orders/merchant_order_detail_screen.dart'
    s = open(p, encoding='utf-8').read()
    old = "icon: Icons.directions_rounded, height: 48"
    if old not in s:
        print('006 already applied'); return
    s = s.replace(old, "icon: const Icon(Icons.directions_rounded, size: 20, color: FnColors.surface), height: 48")
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 006 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
