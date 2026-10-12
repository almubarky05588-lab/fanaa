"""Codemod 004: المسافة في كل القوائم وصفحة المتجر، موقع العميل والاتجاهات للتاجر، وإزالة البار الأخضر."""
import sys, os
EDITS = {
 "lib/core/i18n/en.dart": [
  [
   "s updated',\n};\n",
   "s updated',\n  'يبعد {0}': '{0} away',\n  'للمندوب: {0}': 'For courier: {0}',\n  'الاتجاهات إلى العميل': 'Directions to customer',\n  'متجري': 'My store',\n  'العودة للوحة متجري': 'Back to my store dashboard',\n};\n"
  ]
 ],
 "lib/core/location/location.dart": [
  [
   "t, lng;\n}\n\n/",
   "t, lng;\n}\n\n/// المسافة بالكيلومتر بين نقطتين (هافرساين)\ndouble kmBetween(double lat1, double lng1, double lat2, double lng2) {\n  const r = 6371.0;\n  double rad(double d) => d * math.pi / 180;\n  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);\n  final a = math.pow(math.sin(dLat / 2), 2) + math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);\n  return 2 * r * math.asin(math.sqrt(a.toDouble()));\n}\n\n/"
  ],
  [
   "import 'package:fl",
   "import 'dart:math' as math;\nimport 'package:fl"
  ]
 ],
 "lib/features/customer/account/account_screen.dart": [
  [
   " ),\n        const SizedB",
   " ),\n        if (myStore != null) ...[\n          const SizedBox(height: 10),\n          FnCard(\n            padding: const EdgeInsets.all(4),\n            child: FnListRow(title: tr('العودة للوحة متجري'), subtitle: myStore.name, icon: Icons.storefront_rounded,\n                onTap: () => backToMyStore(context)),\n          ),\n        ],\n        const SizedB"
  ],
  [
   ".dart';\n\n///",
   ".dart';\nimport '../shell/customer_shell.dart' show backToMyStore;\n\n///"
  ]
 ],
 "lib/features/customer/home/home_screen.dart": [
  [
   "   ])),\n    ",
   "   ])),\n                  if (profile?.isMerchant == true) ...[\n                    GestureDetector(\n                      onTap: () => backToMyStore(context),\n                      child: Container(\n                        height: 44,\n                        padding: const EdgeInsets.symmetric(horizontal: 12),\n                        decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(22)),\n                        child: Row(mainAxisSize: MainAxisSize.min, children: [\n                          const Icon(Icons.storefront_rounded, size: 18, color: FnColors.deep),\n                          const SizedBox(width: 6),\n                          Text(tr('متجري'), style: FnText.label13.deep),\n                        ]),\n                      ),\n                    ),\n                    const SizedBox(width: 8),\n                  ],\n    "
  ],
  [
   "r_repo.dart';\nimport '..",
   "r_repo.dart';\nimport '../shell/customer_shell.dart' show backToMyStore;\nimport '.."
  ]
 ],
 "lib/features/customer/shell/customer_shell.dart": [
  [
   "]),\n    );\n  }\n}\n\n/// شريط يظهر لصاحب المتجر أثناء تسوّقه كعميل\nclass _BackToStoreBar extends StatelessWidget {\n  const _BackToStoreBar();\n  @override\n  Widget build(BuildContext context) => Material(\n        color: FnColors.deep,\n        child: InkWell(\n          onTap: () {\n            ShopMode.active.value = false;\n            context.go('/m/dashboard');\n          },\n          child: Padding(\n            padding: const EdgeInsets.symmetric(horizontal: FnSpace.page, vertical: 10),\n            child: Row(children: [\n              const Icon(Icons.shopping_bag_outlined, size: 16, color: FnColors.lime),\n              const SizedBox(width: 8),\n              Expanded(child: Text(tr('أنت تتسوّق كعميل'), style: FnText.label13.onDark)),\n              Text(tr('العودة لمتجري'), style: FnText.label13.lime),\n            ]),\n          ),\n        ),\n      ",
   ""
  ],
  [
   ", WidgetRef ref) {\n    final merchant = ref.watch(profileProvider).valueOrNull?.isMerchant == true;\n    return Scaffold(\n      body: shell,\n      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [\n        if (merchant) const _BackToStoreBar(),\n       ",
   ") => Scaffold(\n        body: shell,\n        bottomNavigationBar:"
  ],
  [
   "class CustomerShell extends Consumer",
   "/// العودة من وضع «تسوّق كعميل» إلى لوحة التاجر\nvoid backToMyStore(BuildContext context) {\n  ShopMode.active.value = false;\n  context.go('/m/dashboard');\n}\n\nclass CustomerShell extends Stateless"
  ],
  [
   "theme/tokens.dart';\nimport '../../../core/widgets/fn_bottom_nav.dart';\nimport '../../../data/repositories/auth_repo.dart';\nimport '../../../core/i18n/i18n",
   "widgets/fn_bottom_nav"
  ],
  [
   ".dart';\nimport 'package:flutter_riverpod/flutter_riverpod",
   ""
  ]
 ],
 "lib/features/customer/store/store_screen.dart": [
  [
   " Text(n.location, style",
   " Text([n.location, if (nurseryDistanceKm(ref, n) != null) tr('يبعد {0}', [Fmt.km(nurseryDistanceKm(ref, n)!)])].join(' • '),\n                  style"
  ],
  [
   "ontext) => F",
   "ontext, WidgetRef ref) => F"
  ],
  [
   "ard extends StatelessWidget {\n  c",
   "ard extends ConsumerWidget {\n  c"
  ],
  [
   ".dart';\n\n///",
   ".dart';\nimport '../widgets/nursery_card.dart' show nurseryDistanceKm;\n\n///"
  ]
 ],
 "lib/features/customer/widgets/nursery_card.dart": [
  [
   "     ]),\n      );\n}\n",
   "     ]),\n      );\n  }\n}\n"
  ],
  [
   ", if (n.distanceKm != null) Fmt.km(n.distanceKm!)].joi",
   ", if (km != null) Fmt.km(km)].joi"
  ],
  [
   "ontext) => FnCar",
   "ontext, WidgetRef ref) {\n    final km = nurseryDistanceKm(ref, n);\n    return FnCar"
  ],
  [
   "ryRowCard extends StatelessWidget {\n  const N",
   "ryRowCard extends ConsumerWidget {\n  const N"
  ],
  [
   "   );\n}\n\n///",
   "   );\n  }\n}\n\n///"
  ],
  [
   "n.distanceKm != null) Fmt.km(n.distanceKm!",
   "km != null) Fmt.km(km"
  ],
  [
   "ontext) => Gestu",
   "ontext, WidgetRef ref) {\n    final km = nurseryDistanceKm(ref, n);\n    return Gestu"
  ],
  [
   "tends StatelessWidget",
   "tends ConsumerWidget"
  ],
  [
   "\n\n/// بطاقة ",
   "\n\n/// المسافة من موقع العميل الفعلي للمتجر — من الخادم إن وُجدت، وإلا تُحسب من الإحداثيات.\n/// لا تُعرض لو رفض العميل إذن الموقع (حتى لا نعرض مسافة من موقع افتراضي)\ndouble? nurseryDistanceKm(WidgetRef ref, Nursery n) {\n  final me = ref.watch(currentLocationProvider).valueOrNull;\n  if (me == null || identical(me, kFallbackLocation)) return null;\n  if (n.distanceKm != null) return n.distanceKm;\n  if (n.lat == null || n.lng == null) return null;\n  return kmBetween(me.lat, me.lng, n.lat!, n.lng!);\n}\n\n/// بطاقة "
  ],
  [
   "go_router/go_router",
   "flutter_riverpod/flutter_riverpod.dart';\nimport 'package:go_router/go_router.dart';\nimport '../../../core/location/location"
  ]
 ],
 "lib/features/merchant/orders/merchant_order_detail_screen.dart": [
  [
   "   );\n  }\n}\n",
   "   );\n  }\n}\n\n/// موقع العميل على الخريطة + زر الاتجاهات (يفتح خرائط قوقل، وإلا خرائط أبل)\nclass _DeliveryMap extends StatelessWidget {\n  const _DeliveryMap({required this.lat, required this.lng});\n  final double lat, lng;\n\n  Future<void> _directions() async {\n    final google = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');\n    if (await canLaunchUrl(google)) {\n      await launchUrl(google);\n    } else {\n      await launchUrl(Uri.parse('https://maps.apple.com/?daddr=$lat,$lng&dirflg=d'), mode: LaunchMode.externalApplication);\n    }\n  }\n\n  @override\n  Widget build(BuildContext context) {\n    final pos = LatLng(lat, lng);\n    return FnCard(\n      padding: EdgeInsets.zero,\n      child: Column(children: [\n        ClipRRect(\n          borderRadius: const BorderRadius.vertical(top: Radius.circular(FnRadius.card)),\n          child: SizedBox(\n            height: 160,\n            child: IgnorePointer(\n              child: GoogleMap(\n                initialCameraPosition: CameraPosition(target: pos, zoom: 15.5),\n                markers: {Marker(markerId: const MarkerId('customer'), position: pos)},\n                zoomControlsEnabled: false, mapToolbarEnabled: false, myLocationButtonEnabled: false,\n                scrollGesturesEnabled: false, zoomGesturesEnabled: false, rotateGesturesEnabled: false, tiltGesturesEnabled: false,\n              ),\n            ),\n          ),\n        ),\n        Padding(\n          padding: const EdgeInsets.all(10),\n          child: FnButton(label: tr('الاتجاهات إلى العميل'), icon: Icons.directions_rounded, height: 48, onPressed: _directions),\n        ),\n      ]),\n    );\n  }\n}\n"
  ],
  [
   "    ),\n                ]),\n              ),\n              const SizedBox(height: 12)",
   "    ),\n                ]),\n              ),\n              if (o.address['lat'] is num && o.address['lng'] is num) ...[\n                const SizedBox(height: 12),\n                _DeliveryMap(lat: (o.address['lat'] as num).toDouble(), lng: (o.address['lng'] as num).toDouble()),\n              ],\n              const SizedBox(height: 12)"
  ],
  [
   "f ((o.note ?",
   "f ((o.address['notes'] ?? '').toString().isNotEmpty)\n                      Text(tr('للمندوب: {0}', [o.address['notes']]), style: FnText.caption11.muted),\n                    if ((o.note ?"
  ],
  [
   "go_router.da",
   "go_router.dart';\nimport 'package:google_maps_flutter/google_maps_flutter.da"
  ]
 ]
}

def run(root):
    os.chdir(root)
    if 'backToMyStore' in open('lib/features/customer/shell/customer_shell.dart', encoding='utf-8').read():
        print('004 already applied'); return
    for path, ops in EDITS.items():
        s = open(path, encoding='utf-8').read()
        for old, new in ops:
            assert s.count(old) == 1, (path, old[:60])
            s = s.replace(old, new)
        open(path, 'w', encoding='utf-8').write(s)
    print('✅ 004 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
