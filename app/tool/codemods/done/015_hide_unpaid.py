"""Codemod 015: «طلباتي» لا تعرض محاولات الدفع الإلكتروني غير المكتملة (تظهر بعد الدفع فقط)."""
import sys, os

def run(root):
    os.chdir(root)
    p = 'lib/data/repositories/order_repo.dart'
    s = open(p, encoding='utf-8').read()
    if "payment_method.eq.cod,payment_status.in.(paid,refunded)" in s:
        print('015 already applied'); return
    old = "        .eq('user_id', uid).order('placed_at', ascending: false);\n    return rows.map((e) => Order.fromJson(e)).toList();\n  }"
    new = ("        .eq('user_id', uid)\n"
           "        // الطلب الإلكتروني يظهر بعد الدفع فقط — محاولات الدفع غير المكتملة لا تُعرض\n"
           "        .or('payment_method.eq.cod,payment_status.in.(paid,refunded)')\n"
           "        .order('placed_at', ascending: false);\n"
           "    return rows.map((e) => Order.fromJson(e)).toList();\n  }")
    assert s.count(old) == 1
    s = s.replace(old, new)
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 015 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
