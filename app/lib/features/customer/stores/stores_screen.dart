import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/location/location.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../widgets/nursery_card.dart';
import '../../../core/i18n/i18n.dart';

enum _Filter { all, nearest, open, freeDelivery }

final _storesQuery = StateProvider<String>((_) => '');
final _storesFilter = StateProvider<_Filter>((_) => _Filter.all);

final _storesProvider = FutureProvider<List<Nursery>>((ref) async {
  final q = ref.watch(_storesQuery);
  final f = ref.watch(_storesFilter);
  final repo = ref.watch(catalogRepoProvider);
  List<Nursery> list;
  if (q.isEmpty) {
    final loc = await ref.watch(currentLocationProvider.future);
    list = await repo.nearby(lat: loc.lat, lng: loc.lng, radiusKm: 60);
    if (list.isEmpty) list = await repo.nurseries();
  } else {
    list = await repo.nurseries(query: q);
  }
  return switch (f) {
    _Filter.open => list.where((n) => n.isOpen).toList(),
    _Filter.freeDelivery => list.where((n) => n.freeDelivery).toList(),
    _Filter.nearest => [...list]..sort((a, b) => (a.distanceKm ?? 1e9).compareTo(b.distanceKm ?? 1e9)),
    _Filter.all => list,
  };
});

/// 04 المتاجر
class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(_storesProvider);
    final filter = ref.watch(_storesFilter);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 12, FnSpace.page, 0),
            child: Row(children: [
              Expanded(child: Text(tr('المتاجر'), style: FnText.title22)),
              FnIconButton(onTap: () => context.push('/map'), child: const Icon(Icons.map_outlined, size: 20, color: FnColors.deep)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 14, FnSpace.page, 0),
            child: TextField(
              onSubmitted: (v) => ref.read(_storesQuery.notifier).state = v.trim(),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: tr('ابحث عن مشتل أو مزرعة'),
                prefixIcon: const Icon(Icons.search_rounded, color: FnColors.faint),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 12, FnSpace.page, 8),
              children: [
                for (final (f, l) in [(_Filter.all, tr('الكل')), (_Filter.nearest, tr('الأقرب')), (_Filter.open, tr('مفتوح الآن')), (_Filter.freeDelivery, tr('توصيل مجاني'))])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FnChip(label: l, selected: filter == f, onTap: () => ref.read(_storesFilter.notifier).state = f),
                  ),
              ],
            ),
          ),
          Expanded(
            child: stores.when(
              loading: () => const FnLoading(),
              error: (_, __) => FnError(onRetry: () => ref.invalidate(_storesProvider)),
              data: (list) => list.isEmpty
                  ? FnEmpty(title: tr('لا توجد نتائج'), subtitle: tr('جرّب كلمة بحث أخرى أو غيّر الفلتر'), icon: Icons.storefront_outlined)
                  : RefreshIndicator(
                      color: FnColors.primary,
                      onRefresh: () async => ref.invalidate(_storesProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(FnSpace.page, 4, FnSpace.page, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => NurseryRowCard(n: list[i]),
                      ),
                    ),
            ),
          ),
        ]),
      ),
    );
  }
}
