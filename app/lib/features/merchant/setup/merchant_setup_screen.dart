import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/location/location.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/i18n/i18n.dart';

/// إنشاء المتجر — يظهر للتاجر الذي لا يملك مشتلًا بعد
class MerchantSetupScreen extends ConsumerStatefulWidget {
  const MerchantSetupScreen({super.key});
  @override
  ConsumerState<MerchantSetupScreen> createState() => _MerchantSetupScreenState();
}

class _MerchantSetupScreenState extends ConsumerState<MerchantSetupScreen> {
  final _name = TextEditingController();
  final _city = TextEditingController(text: tr('الرياض'));
  final _district = TextEditingController();
  final _phone = TextEditingController();
  final _vat = TextEditingController();
  final _cr = TextEditingController();
  bool _loading = false;

  String _slug(String s) {
    final base = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return '$base-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
  }

  Future<void> _create() async {
    if (_name.text.trim().length < 2 || _city.text.trim().isEmpty) {
      showFnSnack(context, tr('أدخل اسم المتجر والمدينة'), error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final c = ref.read(supabaseProvider);
      final loc = await ref.read(currentLocationProvider.future);
      await c.from('nurseries').insert({
        'owner_id': c.auth.currentUser!.id,
        'name': _name.text.trim(),
        'slug': _slug(_name.text),
        'city': _city.text.trim(),
        'district': _district.text.trim().isEmpty ? null : _district.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'tax_number': _vat.text.trim().isEmpty ? null : _vat.text.trim(),
        'cr_number': _cr.text.trim().isEmpty ? null : _cr.text.trim(),
        'location': 'POINT(${loc.lng} ${loc.lat})',
      });
      ref.invalidate(myNurseryProvider);
      if (mounted) context.go('/m/dashboard');
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(FnSpace.page, 24, FnSpace.page, 24),
            children: [
              Container(width: 74, height: 74, decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(26)),
                  child: const Center(child: FnLogoMark(size: 42, color: FnColors.lime, gradient: false))),
              const SizedBox(height: 18),
              Text(tr('أنشئ متجرك على فناء'), style: FnText.display28),
              Text(tr('بيانات أساسية تقدر تعدّلها لاحقًا من الإعدادات'), style: FnText.body15.muted),
              const SizedBox(height: 22),
              for (final (l, c, h) in [
                (tr('اسم المتجر'), _name, tr('مثال: مشتل الروضة')),
                (tr('المدينة'), _city, tr('الرياض')),
                (tr('الحي'), _district, tr('حي الروضة')),
                (tr('رقم التواصل'), _phone, '05X XXX XXXX'),
                (tr('الرقم الضريبي (اختياري)'), _vat, '3XXXXXXXXXXXXX3'),
                (tr('السجل التجاري (اختياري)'), _cr, '10XXXXXXXX'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l, style: FnText.label13.muted),
                    const SizedBox(height: 6),
                    TextField(controller: c, decoration: InputDecoration(hintText: h)),
                  ]),
                ),
              Row(children: [
                const Icon(Icons.my_location_rounded, size: 14, color: FnColors.primary),
                const SizedBox(width: 6),
                Expanded(child: Text(tr('سيُحفظ موقع المتجر من موقعك الحالي'), style: FnText.caption11.muted)),
              ]),
              const SizedBox(height: 22),
              FnButton(label: tr('إنشاء المتجر'), loading: _loading, onPressed: _create),
            ],
          ),
        ),
      );
}
