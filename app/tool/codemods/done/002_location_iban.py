"""Codemod 002: ترجمات الخريطة والآيبان، وصفّا «موقع المتجر» و«الآيبان» في الإعدادات، ودوال الآيبان."""
import sys, os
EDITS = {
 "lib/core/i18n/en.dart": [
  [
   "يقة': '45 min',\n};\n",
   "يقة': '45 min',\n  'حرّك الخريطة حتى يكون الدبوس على الموقع بالضبط': 'Move the map until the pin is exactly on the spot',\n  'جارٍ تحديد العنوان…': 'Finding address…',\n  'موقع محدد على الخريطة': 'Location pinned on map',\n  'تأكيد الموقع': 'Confirm location',\n  'حدّد موقع متجرك': 'Set your store location',\n  'أدخل اسم المتجر': 'Enter the store name',\n  'الآيبان غير صحيح — SA ثم 22 رقمًا': 'Invalid IBAN — SA followed by 22 digits',\n  'حدّد موقع متجرك على الخريطة': 'Pin your store on the map',\n  'الآيبان (لتحويل أرباحك)': 'IBAN (for your payouts)',\n  'موقع المتجر': 'Store location',\n  'تم تحديد الموقع': 'Location set',\n  'ليظهر للعملاء القريبين وتُحسب المسافة': 'So nearby customers can find you and see the distance',\n  'اضغط للتعديل': 'Tap to edit',\n  'حدّد موقع التوصيل': 'Set delivery location',\n  'تم تحديد الموقع على الخريطة': 'Location pinned on the map',\n  'تم تحديث موقع المتجر': 'Store location updated',\n  'تم حفظ الآيبان': 'IBAN saved',\n  'حدّد على الخريطة': 'Set on map',\n  'الآيبان': 'IBAN',\n  'لتحويل أرباحك': 'For your payouts',\n  'جدة': 'Jeddah',\n  'مكة المكرمة': 'Makkah',\n  'المدينة المنورة': 'Madinah',\n  'الدمام': 'Dammam',\n  'الخبر': 'Khobar',\n  'الظهران': 'Dhahran',\n  'الأحساء': 'Al Ahsa',\n  'الجبيل': 'Jubail',\n  'الطائف': 'Taif',\n  'تبوك': 'Tabuk',\n  'بريدة': 'Buraidah',\n  'عنيزة': 'Unaizah',\n  'حائل': 'Hail',\n  'أبها': 'Abha',\n  'خميس مشيط': 'Khamis Mushait',\n  'جازان': 'Jazan',\n  'نجران': 'Najran',\n  'الباحة': 'Al Baha',\n  'ينبع': 'Yanbu',\n  'عرعر': 'Arar',\n  'سكاكا': 'Sakaka',\n};\n"
  ]
 ],
 "lib/features/merchant/settings/merchant_settings_screen.dart": [
  [
   "er/image_picker.",
   "er/image_picker.dart';\nimport '../../../core/location/location_picker."
  ],
  [
   "en.dart';\nimport",
   "en.dart';\nimport '../setup/merchant_setup_screen.dart' show normalizeIban;\nimport"
  ],
  [
   "se(v)});\n  }\n\n  ",
   "se(v)});\n  }\n\n  Future<void> _editLocation(Nursery n) async {\n    final p = await pickLocation(context, title: tr('موقع المتجر'), lat: n.lat, lng: n.lng);\n    if (p == null) return;\n    await _update({'location': 'POINT(${p.lng} ${p.lat})', if (p.district != null) 'district': p.district});\n    if (mounted) showFnSnack(context, tr('تم تحديث موقع المتجر'));\n  }\n\n  Future<void> _editIban(Nursery n) async {\n    final repo = ref.read(catalogRepoProvider);\n    final current = await repo.iban(n.id);\n    if (!mounted) return;\n    final c = TextEditingController(text: current?.substring(2) ?? '');\n    final v = await showModalBottomSheet<String>(\n      context: context, isScrollControlled: true,\n      builder: (ctx) => Padding(\n        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),\n        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [\n          Text(tr('الآيبان (لتحويل أرباحك)'), style: FnText.heading18),\n          const SizedBox(height: 12),\n          Directionality(\n            textDirection: TextDirection.ltr,\n            child: TextField(controller: c, autofocus: true, keyboardType: TextInputType.number,\n                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(22)],\n                decoration: const InputDecoration(prefixText: 'SA  ', fillColor: FnColors.bgBase)),\n          ),\n          const SizedBox(height: 16),\n          FnButton(label: tr('حفظ'), onPressed: () => Navigator.pop(ctx, c.text.trim())),\n        ]),\n      ),\n    );\n    if (v == null) return;\n    final iban = normalizeIban(v);\n    if (iban == null) {\n      if (mounted) showFnSnack(context, tr('الآيبان غير صحيح — SA ثم 22 رقمًا'), error: true);\n      return;\n    }\n    try {\n      await repo.setIban(n.id, iban);\n      if (mounted) showFnSnack(context, tr('تم حفظ الآيبان'));\n    } catch (e) {\n      if (mounted) showFnSnack(context, fnErrorText(e), error: true);\n    }\n  }\n\n  "
  ],
  [
   "le: tr('تسوّق كع",
   "le: tr('الآيبان'), subtitle: tr('لتحويل أرباحك'), icon: Icons.account_balance_outlined,\n                onTap: () => _editIban(n)),\n            FnListRow(title: tr('تسوّق كع"
  ],
  [
   "والرسوم')),\n          _Group(children: [\n            FnListRow(title: tr('نطاق ا",
   "والرسوم')),\n          _Group(children: [\n            FnListRow(title: tr('موقع المتجر'), icon: Icons.place_outlined, value: n.district ?? tr('حدّد على الخريطة'),\n                onTap: () => _editLocation(n)),\n            FnListRow(title: tr('نطاق ا"
  ]
 ],
 "lib/data/repositories/catalog_repo.dart": [
  [
   "o_accept';\n\ncons",
   "o_accept,lat,lng';\n\ncons"
  ],
  [
   "id);\n\n  Future<L",
   "id);\n\n  /// الآيبان — جدول خاص لا يقرؤه إلا صاحب المتجر\n  Future<String?> iban(String nurseryId) async =>\n      (await _c.from('nursery_payout').select('iban').eq('nursery_id', nurseryId).maybeSingle())?['iban'] as String?;\n  Future<void> setIban(String nurseryId, String iban) =>\n      _c.from('nursery_payout').upsert({'nursery_id': nurseryId, 'iban': iban, 'updated_at': DateTime.now().toUtc().toIso8601String()});\n\n  Future<L"
  ]
 ]
}

def run(root):
    os.chdir(root)
    if 'nursery_payout' in open('lib/data/repositories/catalog_repo.dart', encoding='utf-8').read():
        print('002 already applied'); return
    for path, ops in EDITS.items():
        s = open(path, encoding='utf-8').read()
        for old, new in ops:
            assert s.count(old) == 1, (path, old[:60])
            s = s.replace(old, new)
        open(path, 'w', encoding='utf-8').write(s)
    print('✅ 002 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
