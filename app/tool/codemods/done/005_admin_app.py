"""Codemod 005: لوحة الأدمن في التطبيق — موافقة المتاجر، الحظر، الأقسام والبنرات من القاعدة، والإشعارات."""
import sys, os
EDITS = {
 "lib/core/i18n/en.dart": [
  [
   "dashboard',\n};\n",
   "dashboard',\n  'قراءة الكل': 'Mark all read',\n  'لا توجد إشعارات': 'No notifications',\n  'تحديثات طلباتك والعروض تظهر هنا': 'Order updates and offers appear here',\n  'ألغى العميل الطلب': 'Customer cancelled the order',\n  '{0} • طلب #{1}': '{0} • Order #{1}',\n  'تم إيقاف حسابك': 'Your account is suspended',\n  'لا يمكنك استخدام فناء حاليًا. إذا تعتقد أن هذا خطأ تواصل مع الدعم.': 'You can\\'t use Fenaa right now. If you think this is a mistake, contact support.',\n  'متجرك قيد المراجعة': 'Your store is under review',\n  'جهّز منتجاتك الآن — يظهر متجرك للعملاء بعد موافقة الإدارة': 'Set up your products now — your store goes live once approved',\n  'حسابك موقوف — تواصل مع الدعم': 'Your account is suspended — contact support',\n};\n"
  ]
 ],
 "lib/core/router/app_router.dart": [
  [
   "]!)),\n\n     ",
   "]!)),\n      top('/notifications', (_) => const NotificationsScreen()),\n      top('/blocked', (_) => const BlockedScreen()),\n\n     "
  ],
  [
   "= null) retu",
   "= null) return null;\n      // حساب موقوف من الإدارة: شاشة الإيقاف فقط (والدعم)\n      if (!p.isActive) return (loc == '/blocked' || loc == '/support') ? null : '/blocked';\n      if (loc == '/blocked') return '/splash';\n      if (loc == '/notifications') retu"
  ],
  [
   "port 'auth_r",
   "port '../../features/common/blocked_screen.dart';\nimport '../../features/common/notifications_screen.dart';\nimport 'auth_r"
  ]
 ],
 "lib/data/models/catalog.dart": [
  [
   "['icon']);\n}",
   "['icon'],\n      displayMode: j['display_mode'] ?? 'icon', imageUrl: j['image_url'], bgColor: j['bg_color']);\n}"
  ],
  [
   "\n      Category(",
   " Category(\n      "
  ],
  [
   "s.icon});\n  ",
   "s.icon,\n      this.displayMode = 'icon', this.imageUrl, this.bgColor});\n  "
  ],
  [
   "on;\n  const ",
   "on;\n  /// طريقة العرض التي يختارها الأدمن: icon | image | text\n  final String displayMode;\n  final String? imageUrl;\n  final String? bgColor;\n  const "
  ],
  [
   "alse,\n      );\n\n  String",
   "alse,\n        isApproved: j['is_approved'] ?? true,\n      );\n\n  String"
  ],
  [
   "= false,\n  }",
   "= false,\n    this.isApproved = true,\n  }"
  ],
  [
   "tion;\n\n  con",
   "tion;\n  final bool isApproved;\n\n  con"
  ]
 ],
 "lib/data/models/profile.dart": [
  [
   "] ?? 0,\n    ",
   "] ?? 0,\n        isActive: j['is_active'] ?? true,\n    "
  ],
  [
   "ts = 0,\n  })",
   "ts = 0,\n    this.isActive = true,\n  })"
  ],
  [
   "ints;\n\n  con",
   "ints;\n  /// false = أوقفته الإدارة\n  final bool isActive;\n\n  con"
  ]
 ],
 "lib/data/repositories/catalog_repo.dart": [
  [
   "at,lng';\n\nco",
   "at,lng,is_approved';\n\nco"
  ]
 ],
 "lib/features/customer/home/home_screen.dart": [
  [
   ");\n}\n\nclass _CategoryTile extends StatelessWidget {\n  const _CategoryTile({required this.c, required this.index});\n  final Category c;\n  final int index;\n  static const _bgs = [FnColors.soft, Color(0xFFF6E9E1), Color(0xFFE6EEF6), Color(0xFFEFE8F4), Color(0xFFF7F0DE)];\n  static const _fgs = [FnColors.deep, FnColors.clay, FnColors.sky, FnColors.plum, FnColors.star];\n  static const _icons = [Icons.local_florist_outlined, Icons.park_outlined, Icons.water_drop_outlined, Icons.yard_outlined, Icons.handyman_outlined];\n  @override\n  Widget build(BuildContext context) => GestureDetector(\n        onTap: () => context.push('/stores?category=${c.id}'),\n        child: SizedBox(\n          width: 72,\n          child: Column(children: [\n            Container(width: 64, height: 64,\n                decoration: BoxDecoration(color: _bgs[index % 5], borderRadius: BorderRadius.circular(20)),\n                child: Icon(_icons[index % 5], color: _fgs[index % 5], size: 26)),\n            const SizedBox(height: 6),\n            Text(tr(c.nameAr), style: FnText.caption11, maxLines: 1, overflow: TextOverflow.ellipsis),\n          ]),\n        ),\n      );\n}\n",
   ",\n    );\n  }\n}\n"
  ],
  [
   "child: Text(tr('تسوّق الآن'), style: FnText.label13.deep),\n",
   "  child: Text(tr(cta), style: FnText.label13.deep),\n  "
  ],
  [
   "rtical: 8),\n            ",
   "rtical: 8),\n              "
  ],
  [
   "      Container(\n      ",
   "      if (b?.linkType != 'none' && cta.isNotEmpty)\n                Container(\n        "
  ],
  [
   "Text(tr('خصم ٢٠٪ على أول طلب من فناء'), style: FnText.caption11.soft",
   "if (b == null || (b!.subtitle ?? '').isNotEmpty)\n                Text(b == null ? tr('خصم ٢٠٪ على أول طلب من فناء') : tr(b!.subtitle!), style: FnText.caption11.soft, maxLines: 2"
  ],
  [
   "tr('هناك نبتة لكل شخص'), style: FnText.heading18.onDark",
   "b == null ? tr('هناك نبتة لكل شخص') : tr(b!.title), style: FnText.heading18.onDark, maxLines: 2, overflow: TextOverflow.ellipsis"
  ],
  [
   "alse)),\n    ",
   "alse)),\n          ],\n    "
  ],
  [
   "      Positioned(left: 18, ",
   "        PositionedDirectional(end: 18, "
  ],
  [
   " 160,\n      ",
   " 160,\n        "
  ],
  [
   "Stack(children: [\n      ",
   "Stack(fit: StackFit.expand, children: [\n          if (hasImage) ...[\n            // صورة البنر (يُفضّل 1200×450) مع تظليل خفيف ليبقى النص مقروءًا\n            FnImage(url: b!.imageUrl, radius: 0),\n            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(\n                begin: AlignmentDirectional.centerStart, end: AlignmentDirectional.centerEnd,\n                colors: [Color(0xB30C3E2A), Color(0x000C3E2A)]))),\n          ] else ...[\n        "
  ],
  [
   "=> GestureDetector(\n      onTap:",
   "{\n    final hasImage = (b?.imageUrl ?? '').isNotEmpty;\n    final cta = b?.ctaLabel ?? tr('تسوّق الآن');\n    return GestureDetector(\n      onTap: onTap ??"
  ],
  [
   "anner();\n  @o",
   "anner({this.b, this.onTap});\n  final AppBanner? b;\n  final VoidCallback? onTap;\n  @o"
  ],
  [
   " }\n}\n\nclass ",
   " }\n}\n\n/// بنرات الرئيسية من لوحة التحكم — أكثر من بنر يصير شرائح تتقلّب، وبدونها يظهر البنر الافتراضي\nclass _Banners extends ConsumerStatefulWidget {\n  const _Banners();\n  @override\n  ConsumerState<_Banners> createState() => _BannersState();\n}\n\nclass _BannersState extends ConsumerState<_Banners> {\n  final _page = PageController(viewportFraction: .92);\n  int _index = 0;\n\n  void _open(AppBanner b) {\n    final v = b.linkValue ?? '';\n    switch (b.linkType) {\n      case 'store' when v.isNotEmpty:\n        context.push('/store/$v');\n      case 'category' when v.isNotEmpty:\n        context.push('/stores?category=$v');\n      case 'url' when v.isNotEmpty:\n        launchUrl(Uri.parse(v), mode: LaunchMode.externalApplication);\n      case 'none':\n        break;\n      default:\n        context.go('/stores');\n    }\n  }\n\n  @override\n  void dispose() {\n    _page.dispose();\n    super.dispose();\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final list = ref.watch(bannersProvider).valueOrNull ?? const <AppBanner>[];\n    if (list.isEmpty) {\n      return const Padding(padding: EdgeInsets.symmetric(horizontal: FnSpace.page), child: _PromoBanner());\n    }\n    if (list.length == 1) {\n      return Padding(padding: const EdgeInsets.symmetric(horizontal: FnSpace.page), child: _PromoBanner(b: list.first, onTap: () => _open(list.first)));\n    }\n    return Column(children: [\n      SizedBox(\n        height: 150,\n        child: PageView.builder(\n          controller: _page,\n          itemCount: list.length,\n          onPageChanged: (i) => setState(() => _index = i),\n          itemBuilder: (_, i) => Padding(\n            padding: const EdgeInsets.symmetric(horizontal: 5),\n            child: _PromoBanner(b: list[i], onTap: () => _open(list[i])),\n          ),\n        ),\n      ),\n      const SizedBox(height: 8),\n      Row(mainAxisAlignment: MainAxisAlignment.center, children: [\n        for (var i = 0; i < list.length; i++)\n          AnimatedContainer(\n            duration: const Duration(milliseconds: 200),\n            margin: const EdgeInsets.symmetric(horizontal: 3),\n            width: i == _index ? 18 : 6, height: 6,\n            decoration: BoxDecoration(color: i == _index ? FnColors.primary : FnColors.border, borderRadius: BorderRadius.circular(3)),\n          ),\n      ]),\n    ]);\n  }\n}\n\nclass "
  ],
  [
   "i) => _Catego",
   "i) => Catego"
  ],
  [
   "fromLTRB(FnSpace.page, 16, FnSpace.page, 0), child: _PromoBanner",
   "only(top: 16), child: _Banners"
  ],
  [
   "FnIconButton(onTap: () {}, child: const Icon(Icons.notifications_none_rounded, size: 21, color: FnColors.ink)",
   "const NotificationBell("
  ],
  [
   "ate(popularProductsProvider);\n      ",
   "ate(popularProductsProvider);\n          ref.invalidate(bannersProvider);\n          ref.invalidate(notificationsProvider);\n      "
  ],
  [
   "yStore;\nimpo",
   "yStore;\nimport '../../../data/repositories/content_repo.dart';\nimport '../../common/notifications_screen.dart' show NotificationBell;\nimport '../widgets/category_tile.dart';\nimpo"
  ],
  [
   "o_router.dar",
   "o_router.dart';\nimport 'package:url_launcher/url_launcher.dar"
  ]
 ],
 "lib/features/merchant/dashboard/merchant_dashboard_screen.dart": [
  [
   "FnIconButton(radius: 16, onTap: () {}, child: const Icon(Icons.notifications_none_rounded, size: 20, color: FnColors.ink)),\n            ])",
   "const NotificationBell(radius: 16),\n            ]),\n            if (!n.isApproved) ...[\n              const SizedBox(height: 12),\n              Container(\n                padding: const EdgeInsets.all(14),\n                decoration: BoxDecoration(color: const Color(0xFFF7F0DE), borderRadius: BorderRadius.circular(16)),\n                child: Row(children: [\n                  const Icon(Icons.hourglass_top_rounded, color: FnColors.star, size: 22),\n                  const SizedBox(width: 10),\n                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [\n                    Text(tr('متجرك قيد المراجعة'), style: FnText.bodyStrong15),\n                    Text(tr('جهّز منتجاتك الآن — يظهر متجرك للعملاء بعد موافقة الإدارة'), style: FnText.caption11.muted),\n                  ])),\n                ]),\n              ),\n            ]"
  ],
  [
   ".dart';\n\nfin",
   ".dart';\nimport '../../common/notifications_screen.dart' show NotificationBell;\n\nfin"
  ]
 ]
}

def run(root):
    os.chdir(root)
    if 'NotificationBell' in open('lib/features/customer/home/home_screen.dart', encoding='utf-8').read():
        print('005 already applied'); return
    for path, ops in EDITS.items():
        s = open(path, encoding='utf-8').read()
        for old, new in ops:
            assert s.count(old) == 1, (path, old[:60])
            s = s.replace(old, new)
        open(path, 'w', encoding='utf-8').write(s)
    print('✅ 005 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
