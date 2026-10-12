import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../dashboard/merchant_dashboard_screen.dart';
import '../../../core/i18n/i18n.dart';

final merchantProductsProvider = FutureProvider.family<List<Product>, String>(
    (ref, nid) => ref.watch(catalogRepoProvider).merchantProducts(nid));

/// 18 إدارة المنتجات
class MerchantProductsScreen extends ConsumerWidget {
  const MerchantProductsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WithMyNursery(builder: (n) => _Products(n: n));
}

enum _F { all, available, out, hidden }

class _Products extends ConsumerStatefulWidget {
  const _Products({required this.n});
  final Nursery n;
  @override
  ConsumerState<_Products> createState() => _ProductsState();
}

class _ProductsState extends ConsumerState<_Products> {
  _F _f = _F.all;
  String _q = '';

  int _stock(Product p) => p.variants.isEmpty ? p.stock : p.variants.fold(0, (s, v) => s + v.stock);

  bool _match(Product p) {
    if (_q.isNotEmpty && !p.name.contains(_q)) return false;
    return switch (_f) {
      _F.all => true,
      _F.available => p.isAvailable && _stock(p) > 0,
      _F.out => _stock(p) <= 0,
      _F.hidden => !p.isAvailable,
    };
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(merchantProductsProvider(widget.n.id));
    final all = async.valueOrNull ?? const <Product>[];
    final shown = all.where(_match).toList();
    int c(_F f) { final p = _f; _f = f; final r = all.where(_match).length; _f = p; return r; }

    return Scaffold(
      appBar: FnAppBar(
        title: tr('المنتجات'), showBack: false,
        action: GestureDetector(
          onTap: () async {
            await context.push('/m/products/new');
            ref.invalidate(merchantProductsProvider(widget.n.id));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(tr('إضافة'), style: FnText.label13.onDark),
              const SizedBox(width: 6),
              const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ]),
          ),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 0),
          child: TextField(
            onChanged: (v) => setState(() => _q = v.trim()),
            decoration: InputDecoration(hintText: tr('ابحث في منتجاتك'), prefixIcon: Icon(Icons.search_rounded, color: FnColors.faint)),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 10, FnSpace.page, 6),
            children: [
              for (final (f, l) in [(_F.all, tr('الكل')), (_F.available, tr('متوفر')), (_F.out, tr('نفد')), (_F.hidden, tr('مخفي'))])
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: FnChip(small: true, label: '$l ${c(f)}', selected: _f == f, onTap: () => setState(() => _f = f)),
                ),
            ],
          ),
        ),
        Expanded(
          child: async.isLoading && all.isEmpty
              ? const FnLoading()
              : shown.isEmpty
                  ? FnEmpty(
                      title: all.isEmpty ? tr('أضف أول منتج') : tr('لا توجد منتجات'), icon: Icons.local_florist_outlined,
                      action: all.isEmpty ? SizedBox(width: 180, child: FnButton(label: tr('إضافة منتج'), height: 50, onPressed: () => context.push('/m/products/new'))) : null,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(FnSpace.page, 4, FnSpace.page, 24),
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final p = shown[i];
                        final st = _stock(p);
                        return FnCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(children: [
                            FnImage(url: p.cover, size: 52, radius: 16),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, style: FnText.bodyStrong15),
                              const SizedBox(height: 4),
                              Row(children: [
                                Flexible(child: Text('${p.categoryName ?? tr('بدون قسم')} • ${Fmt.moneyShort(p.fromPrice)}', style: FnText.caption11.muted,
                                    overflow: TextOverflow.ellipsis)),
                                const SizedBox(width: 8),
                                st > 0
                                    ? FnBadge(tr('متوفر {0}', [st]))
                                    : FnBadge(tr('نفد المخزون'), bg: FnColors.clay, fg: Colors.white),
                              ]),
                            ])),
                            FnSwitch(
                              value: p.isAvailable,
                              onChanged: (v) async {
                                await ref.read(catalogRepoProvider).setAvailability(p.id, v);
                                ref.invalidate(merchantProductsProvider(widget.n.id));
                              },
                            ),
                          ]),
                        );
                      },
                    ),
        ),
      ]),
    );
  }
}
