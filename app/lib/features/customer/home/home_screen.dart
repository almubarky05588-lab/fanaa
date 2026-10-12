import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/location/location.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/order_repo.dart';
import '../shell/customer_shell.dart' show backToMyStore;
import '../../../data/repositories/content_repo.dart';
import '../../common/notifications_screen.dart' show NotificationBell;
import '../widgets/category_tile.dart';
import '../widgets/nursery_card.dart';
import '../widgets/product_card.dart';
import '../../../core/i18n/i18n.dart';

final _nearbyProvider = FutureProvider<List<Nursery>>((ref) async {
  final loc = await ref.watch(currentLocationProvider.future);
  final repo = ref.watch(catalogRepoProvider);
  final near = await repo.nearby(lat: loc.lat, lng: loc.lng);
  return near.isNotEmpty ? near : repo.nurseries(limit: 10);
});

/// 03 الرئيسية
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).valueOrNull;
    final nearby = ref.watch(_nearbyProvider);
    final cats = ref.watch(categoriesProvider);
    final popular = ref.watch(popularProductsProvider);
    final addrs = ref.watch(addressesProvider).valueOrNull ?? const <Address>[];
    final addr = addrs.where((a) => a.isDefault).firstOrNull ?? addrs.firstOrNull;
    final addrText = addr == null
        ? tr('التوصيل إلى موقعك الحالي')
        : tr('التوصيل إلى {0}', [[addr.label, addr.district].whereType<String>().where((s) => s.isNotEmpty).join(' — ')]);

    return Scaffold(
      body: RefreshIndicator(
        color: FnColors.primary,
        onRefresh: () async {
          ref.invalidate(_nearbyProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(popularProductsProvider);
          ref.invalidate(bannersProvider);
          ref.invalidate(notificationsProvider);
        },
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(FnSpace.page, 12, FnSpace.page, 0),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr('مرحبًا {0} 👋', [profile?.fullName?.isNotEmpty == true ? profile!.fullName!.split(' ').first : tr('بك')]), style: FnText.title22),
                    // العنوان الافتراضي — الضغط يفتح العناوين لاختيار غيره
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/addresses'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: FnColors.primary),
                          const SizedBox(width: 4),
                          Flexible(child: Text(addrText, style: FnText.caption11.muted, maxLines: 1, overflow: TextOverflow.ellipsis)),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: FnColors.faint),
                        ]),
                      ),
                    ),
                  ])),
                  if (profile?.isMerchant == true) ...[
                    GestureDetector(
                      onTap: () => backToMyStore(context),
                      child: Container(
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(22)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.storefront_rounded, size: 18, color: FnColors.deep),
                          const SizedBox(width: 6),
                          Text(tr('متجري'), style: FnText.label13.deep),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FnIconButton(onTap: () => context.push('/map'), child: const Icon(Icons.map_outlined, size: 20, color: FnColors.deep)),
                  const SizedBox(width: 8),
                  const NotificationBell(),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 16, FnSpace.page, 0),
              child: GestureDetector(
                onTap: () => context.go('/stores'),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    const Icon(Icons.search_rounded, size: 20, color: FnColors.faint),
                    const SizedBox(width: 10),
                    Expanded(child: Text(tr('ابحث عن مشتل، نبتة أو منتج'), style: FnText.body15.faint)),
                    Container(width: 34, height: 34,
                        decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(11)),
                        child: const Icon(Icons.tune_rounded, size: 18, color: Colors.white)),
                  ]),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.only(top: 16), child: _Banners())),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 24, FnSpace.page, 12),
              child: FnSectionTitle(tr('المتاجر القريبة منك'), action: tr('عرض الكل'), onAction: () => context.go('/stores')),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 170,
              child: nearby.when(
                loading: () => const FnLoading(),
                error: (_, __) => FnError(onRetry: () => ref.invalidate(_nearbyProvider)),
                data: (list) => list.isEmpty
                    ? Center(child: Text(tr('لا توجد مشاتل قريبة حاليًا'), style: FnText.body15.muted))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: FnSpace.page),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => NurseryTileCard(n: list[i]),
                      ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 24, FnSpace.page, 12),
              child: FnSectionTitle(tr('الأقسام')),
            ),
          ),
          SliverToBoxAdapter(
            child: cats.maybeWhen(
              data: (list) => SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: FnSpace.page),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => CategoryTile(c: list[i], index: i),
                ),
              ),
              orElse: () => const SizedBox(height: 96),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 24, FnSpace.page, 12),
              child: FnSectionTitle(tr('الأكثر طلبًا')),
            ),
          ),
          popular.maybeWhen(
            data: (list) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 0, FnSpace.page, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .70),
                itemCount: list.length,
                itemBuilder: (_, i) => ProductCard(p: list[i]),
              ),
            ),
            orElse: () => const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ),
        ]),
      ),
    );
  }
}

/// بنرات الرئيسية من لوحة التحكم — أكثر من بنر يصير شرائح تتقلّب، وبدونها يظهر البنر الافتراضي
class _Banners extends ConsumerStatefulWidget {
  const _Banners();
  @override
  ConsumerState<_Banners> createState() => _BannersState();
}

class _BannersState extends ConsumerState<_Banners> {
  final _page = PageController(viewportFraction: .92);
  int _index = 0;

  void _open(AppBanner b) {
    final v = b.linkValue ?? '';
    switch (b.linkType) {
      case 'store' when v.isNotEmpty:
        context.push('/store/$v');
      case 'category' when v.isNotEmpty:
        context.push('/stores?category=$v');
      case 'url' when v.isNotEmpty:
        launchUrl(Uri.parse(v), mode: LaunchMode.externalApplication);
      case 'none':
        break;
      default:
        context.go('/stores');
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(bannersProvider).valueOrNull ?? const <AppBanner>[];
    if (list.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(horizontal: FnSpace.page), child: _PromoBanner());
    }
    if (list.length == 1) {
      return Padding(padding: const EdgeInsets.symmetric(horizontal: FnSpace.page), child: _PromoBanner(b: list.first, onTap: () => _open(list.first)));
    }
    return Column(children: [
      SizedBox(
        height: 150,
        child: PageView.builder(
          controller: _page,
          itemCount: list.length,
          onPageChanged: (i) => setState(() => _index = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: _PromoBanner(b: list[i], onTap: () => _open(list[i])),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < list.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == _index ? 18 : 6, height: 6,
            decoration: BoxDecoration(color: i == _index ? FnColors.primary : FnColors.border, borderRadius: BorderRadius.circular(3)),
          ),
      ]),
    ]);
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({this.b, this.onTap});
  final AppBanner? b;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final hasImage = (b?.imageUrl ?? '').isNotEmpty;
    final cta = b?.ctaLabel ?? tr('تسوّق الآن');
    return GestureDetector(
      onTap: onTap ?? () => context.go('/stores'),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [FnColors.primary, FnColors.deep]),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(fit: StackFit.expand, children: [
          if (hasImage) ...[
            // صورة البنر (يُفضّل 1200×450) مع تظليل خفيف ليبقى النص مقروءًا
            FnImage(url: b!.imageUrl, radius: 0),
            const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
                begin: AlignmentDirectional.centerStart, end: AlignmentDirectional.centerEnd,
                colors: [Color(0xB30C3E2A), Color(0x000C3E2A)]))),
          ] else ...[
            Positioned(left: -30, bottom: -40, child: Container(width: 160, height: 160,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)))),
            PositionedDirectional(end: 18, top: 22, child: FnLogoMark(size: 104, color: Colors.white.withValues(alpha: .9), gradient: false)),
          ],
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b == null ? tr('هناك نبتة لكل شخص') : tr(b!.title), style: FnText.heading18.onDark, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              if (b == null || (b!.subtitle ?? '').isNotEmpty)
                Text(b == null ? tr('خصم ٢٠٪ على أول طلب من فناء') : tr(b!.subtitle!), style: FnText.caption11.soft, maxLines: 2),
              const Spacer(),
              if (b?.linkType != 'none' && cta.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.pill)),
                  child: Text(tr(cta), style: FnText.label13.deep),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
