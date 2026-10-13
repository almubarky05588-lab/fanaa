import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../core/widgets/store_logo.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../data/repositories/order_repo.dart';
import '../widgets/product_card.dart';
import '../../../core/i18n/i18n.dart';
import '../widgets/nursery_card.dart' show nurseryDistanceKm;

/// 05 صفحة المتجر
class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> {
  String? _cat;

  Future<void> _quickAdd(Product p) async {
    if (p.variants.length > 1) { context.push('/product/${p.id}'); return; }
    try {
      await ref.read(orderRepoProvider).addToCart(
          nurseryId: p.nurseryId, productId: p.id, variantId: p.variants.isEmpty ? null : p.variants.first.id);
      ref.invalidate(cartsProvider);
      if (mounted) showFnSnack(context, tr('أُضيف {0} إلى السلة', [p.name]));
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nursery = ref.watch(nurseryProvider(widget.id));
    final products = ref.watch(nurseryProductsProvider(widget.id));
    final carts = ref.watch(cartsProvider).valueOrNull ?? const [];
    final myCart = carts.where((c) => c.nurseryId == widget.id).firstOrNull;

    return Scaffold(
      body: nursery.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(nurseryProvider(widget.id))),
        data: (n) {
          if (n == null) return FnEmpty(title: tr('المتجر غير متاح'));
          final list = products.valueOrNull ?? const <Product>[];
          final cats = <String, String>{};
          for (final p in list) { if (p.categoryId != null && p.categoryName != null) cats[p.categoryId!] = tr(p.categoryName!); }
          final shown = _cat == null ? list : list.where((p) => p.categoryId == _cat).toList();
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _Header(n: n)),
            if (n.description != null && n.description!.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(FnSpace.page, 0, FnSpace.page, 16),
                  child: Text(n.description!, style: FnText.body15.muted),
                ),
              ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: FnSpace.page),
                  children: [
                    Padding(padding: const EdgeInsetsDirectional.only(end: 8),
                        child: FnChip(label: tr('الكل'), selected: _cat == null, onTap: () => setState(() => _cat = null))),
                    for (final e in cats.entries)
                      Padding(padding: const EdgeInsetsDirectional.only(end: 8),
                          child: FnChip(label: e.value, selected: _cat == e.key, onTap: () => setState(() => _cat = e.key))),
                  ],
                ),
              ),
            ),
            if (products.isLoading)
              const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40), child: FnLoading()))
            else if (shown.isEmpty)
              SliverToBoxAdapter(child: FnEmpty(title: tr('لا توجد منتجات في هذا القسم')))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(FnSpace.page, 12, FnSpace.page, 120),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .70),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => ProductCard(p: shown[i], onAdd: () => _quickAdd(shown[i])),
                ),
              ),
          ]);
        },
      ),
      bottomNavigationBar: myCart == null
          ? null
          : FnBottomBar(
              child: FnButton(
                label: tr('عرض السلة • {0} منتج • {1}', [myCart.count, Fmt.moneyShort(myCart.subtotal)]),
                onPressed: () => context.push('/cart?nursery=${widget.id}'),
              ),
            ),
    );
  }
}

/// رأس صفحة المتجر: غلاف قصير + بطاقة معلومات تتداخل معه + شعار المتجر
class _Header extends ConsumerWidget {
  const _Header({required this.n});
  final Nursery n;
  static const _coverH = 150.0;
  static const _overlap = 44.0;

  Future<void> _toggleFav(BuildContext context, WidgetRef ref, bool now) async {
    if (ref.read(currentUserProvider) == null) {
      goLogin(context, from: '/store/${n.id}');
      return;
    }
    try {
      await ref.read(catalogRepoProvider).toggleFavoriteNursery(n.id, !now);
      ref.invalidate(favoriteNurseryIdsProvider);
      ref.invalidate(favoriteNurseriesProvider);
      if (context.mounted) showFnSnack(context, now ? tr('أُزيل من المفضلة') : tr('أُضيف {0} إلى المفضلة', [n.name]));
    } catch (e) {
      if (context.mounted) showFnSnack(context, fnErrorText(e), error: true);
    }
  }

  void _share() {
    final link = 'https://fanaa-15r.pages.dev/store/${n.id}';
    Share.share(tr('تسوّق من {0} على تطبيق فناء 🌿\n{1}', [n.name, link]), subject: n.name);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = MediaQuery.paddingOf(context).top;
    final fav = (ref.watch(favoriteNurseryIdsProvider).valueOrNull ?? const <String>{}).contains(n.id);
    final coverH = _coverH + top;
    return Stack(children: [
      // الغلاف
      Positioned(
        top: 0, left: 0, right: 0, height: coverH,
        child: n.coverUrl != null
            ? FnImage(url: n.coverUrl, radius: 0)
            : Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [FnColors.primary, FnColors.deep]),
                ),
                child: Stack(children: [
                  Positioned(left: 24, bottom: _overlap + 6,
                      child: FnLogoMark(size: 72, color: Colors.white.withValues(alpha: .14), gradient: false)),
                  Positioned(left: 110, top: top + 26,
                      child: FnLogoMark(size: 34, color: Colors.white.withValues(alpha: .10), gradient: false)),
                ]),
              ),
      ),
      // البطاقة تبدأ داخل الغلاف بمقدار التداخل وتُرسم فوقه
      Column(children: [
        SizedBox(height: coverH - _overlap),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: FnSpace.page),
          child: _InfoCard(n: n),
        ),
        const SizedBox(height: 16),
      ]),
      // أزرار الأعلى
      Positioned(
        top: top + 10, right: FnSpace.page, left: FnSpace.page,
        child: Row(children: [
          const FnBackButton(),
          const Spacer(),
          FnIconButton(onTap: _share, child: const Icon(Icons.share_outlined, size: 19, color: FnColors.ink)),
          const SizedBox(width: 8),
          FnIconButton(
            onTap: () => _toggleFav(context, ref, fav),
            child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20, color: FnColors.clay),
          ),
        ]),
      ),
    ]);
  }
}

class _InfoCard extends ConsumerWidget {
  const _InfoCard({required this.n});
  final Nursery n;
  @override
  Widget build(BuildContext context, WidgetRef ref) => FnCard(
        shadow: true,
        radius: 24,
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            StoreLogo(url: n.logoUrl, size: 56, radius: 18),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.name, style: FnText.heading18, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text([n.location, if (nurseryDistanceKm(ref, n) != null) tr('يبعد {0}', [Fmt.km(nurseryDistanceKm(ref, n)!)])].join(' • '),
                  style: FnText.caption11.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            FnBadge(n.isOpen ? tr('مفتوح الآن') : tr('مغلق'), bg: n.isOpen ? FnColors.soft : FnColors.bgBase, fg: n.isOpen ? FnColors.deep : FnColors.muted),
          ]),
          const SizedBox(height: 14),
          const FnDivider(),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Stat('${n.ratingAvg.toStringAsFixed(1)} ★', tr('التقييم ({0})', [n.ratingCount]))),
            Expanded(child: _Stat(Fmt.minutes(n.prepTimeMin), tr('وقت التوصيل'))),
            Expanded(child: _Stat(n.freeDelivery ? tr('مجاني') : Fmt.moneyShort(n.deliveryFee), tr('التوصيل'))),
            Expanded(child: _Stat(n.minOrder == 0 ? '—' : Fmt.moneyShort(n.minOrder), tr('الحد الأدنى'))),
          ]),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.v, this.l);
  final String v, l;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(v, style: FnText.bodyStrong15, maxLines: 1),
        const SizedBox(height: 2),
        Text(l, style: FnText.caption11.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]);
}
