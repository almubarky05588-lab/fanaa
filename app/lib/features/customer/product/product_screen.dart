import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../data/repositories/order_repo.dart';
import '../../common/guest_login_prompt.dart';

/// 08 صفحة المنتج
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  ProductVariant? _variant;
  int _qty = 1;
  bool _adding = false;
  int _img = 0;

  Future<void> _add(Product p) async {
    setState(() => _adding = true);
    try {
      await ref.read(orderRepoProvider).addToCart(nurseryId: p.nurseryId, productId: p.id, variantId: _variant?.id, qty: _qty);
      ref.invalidate(cartsProvider);
      if (!mounted) return;
      showFnSnack(context, 'أُضيف إلى السلة');
      context.pop();
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _toggleFav(String id, bool now) async {
    // المفضلة مرتبطة بالحساب — الزائر يُطلب منه التسجيل
    if (ref.read(currentUserProvider) == null) {
      await askToLogin(context, reason: 'احفظ نباتاتك المفضلة في حسابك وارجع لها متى ما شئت', from: '/product/$id');
      return;
    }
    await ref.read(catalogRepoProvider).toggleFavorite(id, !now);
    ref.invalidate(favoriteIdsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productProvider(widget.id));
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>{};
    return Scaffold(
      body: async.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(productProvider(widget.id))),
        data: (p) {
          if (p == null) return const FnEmpty(title: 'المنتج غير متاح');
          _variant ??= p.variants.isEmpty ? null : p.variants.firstWhere((v) => v.stock > 0, orElse: () => p.variants.first);
          final price = _variant?.price ?? p.basePrice;
          final fav = favs.contains(p.id);
          final top = MediaQuery.paddingOf(context).top;
          return Stack(children: [
            CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 332 + top,
                  child: Stack(children: [
                    Positioned.fill(child: Container(color: FnColors.soft)),
                    Positioned(left: -70, top: 180 + top, child: _blob(240, FnColors.lime.withValues(alpha: .35))),
                    Positioned(right: -40, top: -40, child: _blob(160, Colors.white.withValues(alpha: .45))),
                    if (p.images.isNotEmpty)
                      Positioned.fill(
                        child: PageView.builder(
                          itemCount: p.images.length,
                          onPageChanged: (i) => setState(() => _img = i),
                          itemBuilder: (_, i) => FnImage(url: p.images[i], radius: 0, bg: Colors.transparent),
                        ),
                      )
                    else
                      Positioned.fill(top: top + 60, child: const Center(child: FnLogoMark(size: 200, color: FnColors.primary, gradient: false))),
                    if (p.images.length > 1)
                      Positioned(
                        bottom: 44, left: 0, right: 0,
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          for (var i = 0; i < p.images.length; i++)
                            AnimatedContainer(duration: const Duration(milliseconds: 160), margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _img ? 18 : 6, height: 6,
                                decoration: BoxDecoration(color: i == _img ? FnColors.deep : FnColors.surface, borderRadius: BorderRadius.circular(3))),
                        ]),
                      ),
                  ]),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: Container(
                    decoration: const BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.vertical(top: Radius.circular(FnRadius.sheet))),
                    padding: const EdgeInsets.fromLTRB(FnSpace.page, 24, FnSpace.page, 140),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: FnText.title22),
                          GestureDetector(
                            onTap: p.nursery == null ? null : () => context.push('/store/${p.nurseryId}'),
                            child: Text('${p.nursery?.name ?? ''} • ${p.nursery?.ratingAvg.toStringAsFixed(1) ?? '0'} ★', style: FnText.caption11.muted),
                          ),
                        ])),
                        Text(Fmt.moneyShort(price), style: FnText.title22.deep),
                      ]),
                      if (p.variants.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text('الحجم', style: FnText.heading18),
                        const SizedBox(height: 10),
                        Wrap(spacing: 10, runSpacing: 10, children: [
                          for (final v in p.variants)
                            _SizeChip(
                              label: '${v.name} — ${Fmt.moneyShort(v.price)}',
                              selected: _variant?.id == v.id,
                              disabled: v.stock <= 0 || !v.isActive,
                              onTap: () => setState(() => _variant = v),
                            ),
                        ]),
                      ],
                      if (p.careLight != null || p.careWater != null || p.careTemp != null) ...[
                        const SizedBox(height: 18),
                        Text('العناية', style: FnText.heading18),
                        const SizedBox(height: 10),
                        Row(children: [
                          _Care('الإضاءة', p.careLight ?? '—', Icons.wb_sunny_outlined),
                          const SizedBox(width: 10),
                          _Care('الري', p.careWater ?? '—', Icons.water_drop_outlined),
                          const SizedBox(width: 10),
                          _Care('الحرارة', p.careTemp ?? '—', Icons.thermostat_outlined),
                        ]),
                      ],
                      if (p.description != null && p.description!.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text('الوصف', style: FnText.heading18),
                        const SizedBox(height: 8),
                        Text(p.description!, style: FnText.body15.muted),
                      ],
                    ]),
                  ),
                ),
              ),
            ]),
            Positioned(
              top: top + 12, right: FnSpace.page, left: FnSpace.page,
              child: Row(children: [
                const FnBackButton(),
                const Spacer(),
                FnIconButton(
                  onTap: () => _toggleFav(p.id, fav),
                  child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 21, color: FnColors.clay),
                ),
              ]),
            ),
          ]);
        },
      ),
      bottomNavigationBar: async.valueOrNull == null
          ? null
          : FnBottomBar(
              child: Row(children: [
                FnStepper(value: _qty, min: 1, onChanged: (v) => setState(() => _qty = v)),
                const SizedBox(width: 14),
                Expanded(
                  child: FnButton(
                    label: 'أضف للسلة — ${Fmt.moneyShort((_variant?.price ?? async.value!.basePrice) * _qty)}',
                    loading: _adding,
                    onPressed: async.value!.inStock ? () => _add(async.value!) : null,
                  ),
                ),
              ]),
            ),
    );
  }

  Widget _blob(double d, Color c) => Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: c));
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label, required this.selected, required this.onTap, this.disabled = false});
  final String label;
  final bool selected, disabled;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? .45 : 1,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? FnColors.deep : FnColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: selected ? null : Border.all(color: FnColors.border),
            ),
            child: Text(label, style: selected ? FnText.label13.onDark : FnText.label13),
          ),
        ),
      );
}

class _Care extends StatelessWidget {
  const _Care(this.title, this.value, this.icon);
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Icon(icon, size: 18, color: FnColors.primary),
            const SizedBox(height: 4),
            Text(title, style: FnText.caption11.muted),
            Text(value, style: FnText.label13, textAlign: TextAlign.center, maxLines: 2),
          ]),
        ),
      );
}
