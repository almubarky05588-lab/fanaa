import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/location/location.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../core/i18n/i18n.dart';

final _mapNurseriesProvider = FutureProvider<List<Nursery>>((ref) async {
  final loc = await ref.watch(currentLocationProvider.future);
  return ref.watch(catalogRepoProvider).nearby(lat: loc.lat, lng: loc.lng, radiusKm: 40);
});

/// 07 الخريطة
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _ctrl;
  Nursery? _sel;
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final loc = ref.watch(currentLocationProvider).valueOrNull ?? kFallbackLocation;
    final all = ref.watch(_mapNurseriesProvider).valueOrNull ?? const <Nursery>[];
    final list = switch (_filter) {
      'open' => all.where((n) => n.isOpen).toList(),
      'free' => all.where((n) => n.freeDelivery).toList(),
      _ => all,
    };
    _sel ??= list.isEmpty ? null : list.first;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: LatLng(loc.lat, loc.lng), zoom: 12.5),
          onMapCreated: (c) => _ctrl = c,
          myLocationEnabled: true, myLocationButtonEnabled: false, zoomControlsEnabled: false, mapToolbarEnabled: false,
          markers: {
            for (final n in list.where((n) => n.lat != null))
              Marker(
                markerId: MarkerId(n.id),
                position: LatLng(n.lat!, n.lng!),
                icon: BitmapDescriptor.defaultMarkerWithHue(n.id == _sel?.id ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueCyan),
                infoWindow: InfoWindow(title: n.name),
                onTap: () => setState(() => _sel = n),
              ),
          },
        ),
        Positioned(
          top: top + 10, left: FnSpace.page, right: FnSpace.page,
          child: Column(children: [
            Row(children: [
              const FnBackButton(size: 52),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.go('/stores'),
                  child: Container(
                    height: 52, padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(26), boxShadow: FnShadow.card),
                    child: Row(children: [
                      const Icon(Icons.search_rounded, size: 20, color: FnColors.muted),
                      const SizedBox(width: 10),
                      Text(tr('ابحث عن مشتل قريب'), style: FnText.body15.muted),
                    ]),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 38,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                for (final (k, l) in [('all', tr('الكل')), ('near', tr('الأقرب')), ('open', tr('مفتوح الآن')), ('free', tr('توصيل مجاني'))])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: FnChip(label: l, shadow: true, selected: _filter == k,
                        onTap: () => setState(() { _filter = k; _sel = null; })),
                  ),
              ]),
            ),
          ]),
        ),
        if (_sel != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _Sheet(
              n: _sel!,
              onLocate: () => _ctrl?.animateCamera(CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng))),
            ),
          ),
      ]),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.n, required this.onLocate});
  final Nursery n;
  final VoidCallback onLocate;
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: FnSpace.page, bottom: 14),
          child: FnIconButton(size: 52, shadow: true, onTap: onLocate, child: const Icon(Icons.my_location_rounded, color: FnColors.primary)),
        ),
        Container(
          decoration: const BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(FnRadius.sheet))),
          padding: const EdgeInsets.fromLTRB(FnSpace.page, 12, FnSpace.page, 20),
          child: SafeArea(
            top: false,
            child: Column(children: [
              Container(width: 44, height: 5, decoration: BoxDecoration(color: FnColors.border, borderRadius: BorderRadius.circular(3))),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(n.name, style: FnText.title22),
                  Text([n.location, if (n.distanceKm != null) Fmt.km(n.distanceKm!)].join(' • '), style: FnText.caption11.muted),
                ])),
                FnBadge(n.isOpen ? tr('مفتوح الآن') : tr('مغلق')),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                _s('${n.ratingAvg.toStringAsFixed(1)} ★', tr('التقييم')),
                _s(Fmt.minutes(n.prepTimeMin), tr('وقت التوصيل')),
                _s(n.freeDelivery ? tr('مجاني') : Fmt.moneyShort(n.deliveryFee), tr('التوصيل')),
                _s('${n.ratingCount}', tr('المراجعات')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: FnButton(label: tr('عرض المتجر'), height: 54, onPressed: () => context.push('/store/${n.id}'))),
                const SizedBox(width: 12),
                Expanded(child: FnGhostButton(
                  label: tr('الاتجاهات'),
                  onPressed: n.lat == null ? null : () => launchUrl(
                      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${n.lat},${n.lng}'), mode: LaunchMode.externalApplication),
                )),
              ]),
            ]),
          ),
        ),
      ]);

  Widget _s(String v, String l) => Column(children: [Text(v, style: FnText.bodyStrong15), Text(l, style: FnText.caption11.muted)]);
}
