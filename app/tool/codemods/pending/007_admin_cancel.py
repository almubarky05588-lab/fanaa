"""Codemod 007: الإلغاء من الإدارة فقط (حذف زر الإلغاء للعميل) + أنواع إشعارات جديدة."""
import sys, os
EDITS = {
 "lib/features/customer/orders/tracking_screen.dart": [
  [
   "\n                    else if (o.status == OrderStatus.pending)\n                      FnGhostButton(\n                        label: tr('إلغاء الطلب'), textColor: FnColors.clay,\n                        onPressed: () async {\n                          try {\n                            await ref.read(orderRepoProvider).updateStatus(o.id, OrderStatus.cancelled, note: tr('ألغاه العميل'));\n                            ref.invalidate(myOrdersProvider);\n                          } catch (e) {\n                            if (context.mounted) showFnSnack(context, fnErrorText(e), error: true);\n                          }\n                        },\n                      )",
   ""
  ]
 ],
 "lib/features/common/notifications_screen.dart": [
  [
   "ancel_outlined,\n        ",
   "ancel_outlined,\n        'order_received' => Icons.task_alt_rounded,\n        "
  ]
 ],
 "lib/data/repositories/content_repo.dart": [
  [
   "rder_cancelled' => tr('ط",
   "rder_cancelled' || 'order_received' => tr('ط"
  ],
  [
   "العميل الطلب",
   "العميل أكّد استلام الطلب"
  ],
  [
   "'ألغى العميل",
   "'ألغى الإدارة الطلب'),\n        'order_received' => tr('العميل"
  ],
  [
   "r('ألغى الإدا",
   "r('ألغت الإدا"
  ]
 ],
 "lib/core/i18n/en.dart": [
  [
   "t support',\n};\n",
   "t support',\n  'ألغت الإدارة الطلب': 'Order cancelled by admin',\n  'العميل أكّد استلام الطلب': 'Customer confirmed receipt',\n  'إلغاء الطلب يتم عن طريق الإدارة — تواصل مع الدعم': 'Orders can only be cancelled by admin — contact support',\n  'انتقال غير صالح': 'Invalid status change',\n};\n"
  ]
 ]
}

def run(root):
    os.chdir(root)
    if 'order_received' in open('lib/data/repositories/content_repo.dart', encoding='utf-8').read():
        print('007 already applied'); return
    for path, ops in EDITS.items():
        s = open(path, encoding='utf-8').read()
        for old, new in ops:
            assert s.count(old) == 1, (path, old[:60])
            s = s.replace(old, new)
        open(path, 'w', encoding='utf-8').write(s)
    print('✅ 007 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
