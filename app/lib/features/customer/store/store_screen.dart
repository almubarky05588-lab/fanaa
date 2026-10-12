import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../data/repositories/order_repo.dart';
import '../widgets/product_card.dart';

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
      if (mounted) showFnSnack(context, 'أُضيف ${p.name} إلى السلة');
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
          if (n == null) return const FnEmpty(title: 'المتجر غير متاح');
          final list = products.valueOrNull ?? const <Product>[];
          final cats = <String, String>{};
          for (final p in list) { if (p.categoryId != null && p.categoryName != null) cats[p.categoryId!] = p.categoryName!; }
          final shown = _cat == null ? list : list.where((p) => p.categoryId == _cat).toList();
          return CustomScrollView(slivers: [
            SliverToBoxAdapter(child: _Cover(n: n)),
            SliverToBoxAdapter(
              child: Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: FnSpace.page),
                  child: _InfoCard(n: n),
                ),
              ),
            ),
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
                        child: FnChip(label: 'الكل', selected: _cat == null, onTap: () => setState(() => _cat = null))),
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
              const SliverToBoxAdapter(child: FnEmpty(title: 'لا توجد منتجات في هذا القسم'))
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
                label: 'عرض السلة • ${myCart.count} منتج • ${Fmt.moneyShort(myCart.subtotal)}',
                onPressed: () => context.push('/cart?nursery=${widget.id}'),
              ),
            ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.n});
  final Nursery n;
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: 230 + top,
      child: Stack(fit: StackFit.expand, children: [
        if (n.coverUrl != null)
          FnImage(url: n.coverUrl, radius: 0)
        else
          Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [FnColors.primary, FnColors.deep])),
            child: Stack(children: [
              Positioned(left: 30, top: top + 30, child: FnLogoMark(size: 168, color: Colors.white.withValues(alpha: .9), gradient: false)),
            ]),
          ),
        Positioned(
          top: top + 12, right: FnSpace.page, left: FnSpace.page,
          child: Row(children: [
            const FnBackButton(),
            const Spacer(),
            FnIconButton(onTap: () {}, child: const Icon(Icons.share_outlined, size: 19, color: FnColors.ink)),
            const SizedBox(width: 8),
            FnIconButton(onTap: () {}, child: const Icon(Icons.favorite_border_rounded, size: 20, color: FnColors.clay)),
          ]),
        ),
      ]),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.n});
  final Nursery n;
  @override
  Widget build(BuildContext context) => FnCard(
        shadow: true,
        radius: 24,
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n.name, style: FnText.title22),
              Text(n.location, style: FnText.caption11.muted),
            ])),
            FnBadge(n.isOpen ? 'مفتوح الآن' : 'مغلق', bg: n.isOpen ? FnColors.soft : FnColors.bgBase, fg: n.isOpen ? FnColors.deep : FnColors.muted),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _Stat('${n.ratingAvg.toStringAsFixed(1)} ★', 'التقييم (${n.ratingCount})'),
            _Stat(Fmt.minutes(n.prepTimeMin), 'وقت التوصيل'),
            _Stat(n.freeDelivery ? 'مجاني' : Fmt.moneyShort(n.deliveryFee), 'التوصيل'),
            _Stat(n.minOrder == 0 ? '—' : Fmt.moneyShort(n.minOrder), 'الحد الأدنى'),
          ]),
        ]),
      );
}

class _Stat extends StatelessWidget {
  const _Stat(this.v, this.l);
  final String v, l;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(v, style: FnText.bodyStrong15),
        Text(l, style: FnText.caption11.muted),
      ]);
}
