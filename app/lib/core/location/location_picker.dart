import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../i18n/i18n.dart';
import '../theme/tokens.dart';
import '../widgets/fn_widgets.dart';
import 'location.dart';

/// الموقع الذي اختاره المستخدم على الخريطة + ما أمكن معرفته عنه (الحي/المدينة/الشارع)
class PickedPlace {
  const PickedPlace({required this.lat, required this.lng, this.district, this.city, this.street});
  final double lat, lng;
  final String? district, city, street;

  /// «الشارع، الحي، المدينة» بما هو متاح
  String get summary => [street, district, city].where((e) => (e ?? '').isNotEmpty).join(tr('، '));
}

/// يفتح الخريطة ليختار المستخدم الموقع بنفسه — يرجع null لو رجع بدون تأكيد
Future<PickedPlace?> pickLocation(BuildContext context, {double? lat, double? lng, required String title}) =>
    Navigator.of(context, rootNavigator: true).push<PickedPlace>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => LocationPickerScreen(title: title, lat: lat, lng: lng),
    ));

class LocationPickerScreen extends ConsumerStatefulWidget {
  const LocationPickerScreen({super.key, required this.title, this.lat, this.lng});
  final String title;
  final double? lat, lng;
  @override
  ConsumerState<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  GoogleMapController? _map;
  late LatLng _target = widget.lat != null && widget.lng != null
      ? LatLng(widget.lat!, widget.lng!)
      : LatLng(kFallbackLocation.lat, kFallbackLocation.lng);
  PickedPlace? _place;
  bool _moving = false;
  bool _locating = false;
  int _lookup = 0;

  @override
  void initState() {
    super.initState();
    // بدون موقع سابق: نبدأ من موقع الجوال (لو سمح) — والمستخدم يحرّك الخريطة كما يريد
    if (widget.lat == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToMe(animate: false));
    } else {
      _resolve();
    }
  }

  Future<void> _goToMe({bool animate = true}) async {
    setState(() => _locating = true);
    ref.invalidate(currentLocationProvider);
    final me = await ref.read(currentLocationProvider.future);
    if (!mounted) return;
    setState(() => _locating = false);
    _target = LatLng(me.lat, me.lng);
    final u = CameraUpdate.newLatLngZoom(_target, 16);
    animate ? await _map?.animateCamera(u) : await _map?.moveCamera(u);
    _resolve();
  }

  /// يعرف الحي والمدينة من موضع الدبوس (من خدمة الجهاز نفسه، بدون مفتاح)
  Future<void> _resolve() async {
    final id = ++_lookup;
    final t = _target;
    PickedPlace p = PickedPlace(lat: t.latitude, lng: t.longitude);
    try {
      await setLocaleIdentifier(AppLang.isEn ? 'en_US' : 'ar_SA');
      final marks = await placemarkFromCoordinates(t.latitude, t.longitude);
      if (marks.isNotEmpty) {
        final m = marks.first;
        String? clean(String? s) => (s ?? '').trim().isEmpty ? null : s!.trim();
        p = PickedPlace(
          lat: t.latitude, lng: t.longitude,
          district: clean(m.subLocality),
          city: clean(m.locality) ?? clean(m.administrativeArea),
          street: clean(m.thoroughfare) ?? clean(m.street),
        );
      }
    } catch (_) {/* بدون اتصال: نكتفي بالإحداثيات */}
    if (mounted && id == _lookup) setState(() => _place = p);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: _target, zoom: widget.lat != null ? 16 : 12.5),
          onMapCreated: (c) => _map = c,
          onCameraMoveStarted: () => setState(() => _moving = true),
          onCameraMove: (p) => _target = p.target,
          onCameraIdle: () {
            setState(() => _moving = false);
            _resolve();
          },
          myLocationEnabled: true, myLocationButtonEnabled: false,
          zoomControlsEnabled: false, mapToolbarEnabled: false, compassEnabled: false,
        ),
        // الدبوس ثابت في الوسط — المستخدم يحرّك الخريطة تحته
        IgnorePointer(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 46),
              child: AnimatedSlide(
                offset: Offset(0, _moving ? -0.12 : 0),
                duration: const Duration(milliseconds: 150),
                child: const Icon(Icons.location_on_rounded, size: 52, color: FnColors.deep,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3))]),
              ),
            ),
          ),
        ),
        // الرأس
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FnSpace.page, vertical: 8),
            child: Row(children: [
              FnBackButton(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(16), boxShadow: FnShadow.card),
                  child: Text(widget.title, style: FnText.bodyStrong15, maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
            ]),
          ),
        ),
        // زر موقعي
        PositionedDirectional(
          end: FnSpace.page, bottom: 200 + bottom,
          child: FnIconButton(
            shadow: true, radius: 16, size: 48,
            onTap: _locating ? null : _goToMe,
            child: _locating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: FnColors.primary))
                : const Icon(Icons.my_location_rounded, color: FnColors.deep, size: 22),
          ),
        ),
        // البطاقة السفلية
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(FnSpace.page, 18, FnSpace.page, 14 + bottom),
            decoration: BoxDecoration(
              color: FnColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: FnShadow.card,
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('حرّك الخريطة حتى يكون الدبوس على الموقع بالضبط'), style: FnText.caption11.muted),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.place_outlined, color: FnColors.deep, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _moving || _place == null
                        ? tr('جارٍ تحديد العنوان…')
                        : (_place!.summary.isEmpty ? tr('موقع محدد على الخريطة') : _place!.summary),
                    style: FnText.bodyStrong15, maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              FnButton(
                label: tr('تأكيد الموقع'),
                onPressed: _moving ? null : () => Navigator.pop(context, _place ?? PickedPlace(lat: _target.latitude, lng: _target.longitude)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
