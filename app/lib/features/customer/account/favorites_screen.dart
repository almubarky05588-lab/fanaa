import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../widgets/nursery_card.dart';
import '../widgets/product_card.dart';
import '../../../core/i18n/i18n.dart';

/// المفضلة — المنتجات والمتاجر المحفوظة
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});
  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  bool _stores = false;

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(favoriteProductsProvider);
    final stores = ref.watch(favoriteNurseriesProvider);
    return Scaffold(
      appBar: FnAppBar(title: tr('المفضلة')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(FnSpace.page, 4, FnSpace.page, 12),
          child: Row(children: [
            FnChip(label: tr('المنتجات ({0})', [products.valueOrNull?.length ?? 0]), selected: !_stores, onTap: () => setState(() => _stores = false)),
            const SizedBox(width: 8),
            FnChip(label: tr('المتاجر ({0})', [stores.valueOrNull?.length ?? 0]), selected: _stores, onTap: () => setState(() => _stores = true)),
          ]),
        ),
        Expanded(
          child: RefreshIndicator(
            color: FnColors.primary,
            onRefresh: () async {
              ref.invalidate(favoriteProductsProvider);
              ref.invalidate(favoriteNurseriesProvider);
            },
            child: _stores
                ? stores.when(
                    loading: () => const FnLoading(),
                    error: (_, __) => FnError(onRetry: () => ref.invalidate(favoriteNurseriesProvider)),
                    data: (list) => list.isEmpty
                        ? ListView(children: [SizedBox(height: 80),
                            FnEmpty(title: tr('لا توجد متاجر مفضلة'), subtitle: tr('اضغط ♡ في صفحة أي متجر لحفظه هنا'), icon: Icons.storefront_outlined)])
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(FnSpace.page, 0, FnSpace.page, 24),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => NurseryRowCard(n: list[i]),
                          ),
                  )
                : products.when(
                    loading: () => const FnLoading(),
                    error: (_, __) => FnError(onRetry: () => ref.invalidate(favoriteProductsProvider)),
                    data: (list) => list.isEmpty
                        ? ListView(children: [SizedBox(height: 80),
                            FnEmpty(title: tr('لا توجد منتجات مفضلة'), subtitle: tr('اضغط ♡ في صفحة أي منتج لحفظه هنا'), icon: Icons.favorite_border_rounded)])
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(FnSpace.page, 0, FnSpace.page, 24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: .70),
                            itemCount: list.length,
                            itemBuilder: (_, i) => ProductCard(p: list[i], onAdd: () => context.push('/product/${list[i].id}')),
                          ),
                  ),
          ),
        ),
      ]),
    );
  }
}
