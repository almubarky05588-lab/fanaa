import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/location/location.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/order_repo.dart';
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
                  FnIconButton(onTap: () => context.push('/map'), child: const Icon(Icons.map_outlined, size: 20, color: FnColors.deep)),
                  const SizedBox(width: 8),
                  FnIconButton(onTap: () {}, child: const Icon(Icons.notifications_none_rounded, size: 21, color: FnColors.ink)),
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
          const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.fromLTRB(FnSpace.page, 16, FnSpace.page, 0), child: _PromoBanner())),
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
                  itemBuilder: (_, i) => _CategoryTile(c: list[i], index: i),
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

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();
  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: () => context.go('/stores'),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [FnColors.primary, FnColors.deep]),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned(left: -30, bottom: -40, child: Container(width: 160, height: 160,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .08)))),
          Positioned(left: 18, top: 22, child: FnLogoMark(size: 104, color: Colors.white.withValues(alpha: .9), gradient: false)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('هناك نبتة لكل شخص'), style: FnText.heading18.onDark),
              const SizedBox(height: 2),
              Text(tr('خصم ٢٠٪ على أول طلب من فناء'), style: FnText.caption11.soft),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.pill)),
                child: Text(tr('تسوّق الآن'), style: FnText.label13.deep),
              ),
            ]),
          ),
        ]),
      ));
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.c, required this.index});
  final Category c;
  final int index;
  static const _bgs = [FnColors.soft, Color(0xFFF6E9E1), Color(0xFFE6EEF6), Color(0xFFEFE8F4), Color(0xFFF7F0DE)];
  static const _fgs = [FnColors.deep, FnColors.clay, FnColors.sky, FnColors.plum, FnColors.star];
  static const _icons = [Icons.local_florist_outlined, Icons.park_outlined, Icons.water_drop_outlined, Icons.yard_outlined, Icons.handyman_outlined];
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => context.push('/stores?category=${c.id}'),
        child: SizedBox(
          width: 72,
          child: Column(children: [
            Container(width: 64, height: 64,
                decoration: BoxDecoration(color: _bgs[index % 5], borderRadius: BorderRadius.circular(20)),
                child: Icon(_icons[index % 5], color: _fgs[index % 5], size: 26)),
            const SizedBox(height: 6),
            Text(tr(c.nameAr), style: FnText.caption11, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}
