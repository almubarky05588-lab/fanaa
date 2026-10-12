import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/location/location_picker.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/i18n/i18n.dart';

/// مدن المملكة المتاحة للاختيار
const kSaudiCities = [
  'الرياض', 'جدة', 'مكة المكرمة', 'المدينة المنورة', 'الدمام', 'الخبر', 'الظهران', 'الأحساء', 'الجبيل',
  'الطائف', 'تبوك', 'بريدة', 'عنيزة', 'حائل', 'أبها', 'خميس مشيط', 'جازان', 'نجران', 'الباحة', 'ينبع', 'عرعر', 'سكاكا',
];

/// يتحقق من آيبان سعودي: SA + 22 رقم
String? normalizeIban(String raw) {
  final s = raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
  final digits = s.startsWith('SA') ? s.substring(2) : s;
  return RegExp(r'^[0-9]{22}$').hasMatch(digits) ? 'SA$digits' : null;
}

/// إنشاء المتجر — يظهر للتاجر الذي لا يملك مشتلًا بعد
class MerchantSetupScreen extends ConsumerStatefulWidget {
  const MerchantSetupScreen({super.key});
  @override
  ConsumerState<MerchantSetupScreen> createState() => _MerchantSetupScreenState();
}

class _MerchantSetupScreenState extends ConsumerState<MerchantSetupScreen> {
  final _name = TextEditingController();
  final _iban = TextEditingController();
  String _city = kSaudiCities.first;
  PickedPlace? _place;
  bool _loading = false;

  String _slug(String s) {
    final base = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return '$base-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
  }

  Future<void> _pickPlace() async {
    final p = await pickLocation(context, title: tr('حدّد موقع متجرك'), lat: _place?.lat, lng: _place?.lng);
    if (p != null) setState(() => _place = p);
  }

  Future<void> _create() async {
    final iban = normalizeIban(_iban.text);
    if (_name.text.trim().length < 2) {
      showFnSnack(context, tr('أدخل اسم المتجر'), error: true);
      return;
    }
    if (iban == null) {
      showFnSnack(context, tr('الآيبان غير صحيح — SA ثم 22 رقمًا'), error: true);
      return;
    }
    if (_place == null) {
      showFnSnack(context, tr('حدّد موقع متجرك على الخريطة'), error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final c = ref.read(supabaseProvider);
      final user = c.auth.currentUser!;
      final row = await c.from('nurseries').insert({
        'owner_id': user.id,
        'name': _name.text.trim(),
        'slug': _slug(_name.text),
        'city': _city,
        'district': _place!.district,
        'phone': (user.phone ?? '').isEmpty ? null : '+${user.phone!.replaceAll('+', '')}',
        'location': 'POINT(${_place!.lng} ${_place!.lat})',
      }).select('id').single();
      await c.from('nursery_payout').insert({'nursery_id': row['id'], 'iban': iban});
      ref.invalidate(myNurseryProvider);
      if (mounted) context.go('/m/dashboard');
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: FnText.label13.muted));

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

              _label(tr('اسم المتجر')),
              TextField(controller: _name, decoration: InputDecoration(hintText: tr('مثال: مشتل الروضة'))),
              const SizedBox(height: 14),

              _label(tr('المدينة')),
              DropdownButtonFormField<String>(
                value: _city,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: FnColors.faint),
                decoration: const InputDecoration(),
                items: [for (final c in kSaudiCities) DropdownMenuItem(value: c, child: Text(tr(c), style: FnText.body15))],
                onChanged: (v) => setState(() => _city = v ?? _city),
              ),
              const SizedBox(height: 14),

              _label(tr('الآيبان (لتحويل أرباحك)')),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextField(
                  controller: _iban,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(22)],
                  decoration: const InputDecoration(prefixText: 'SA  ', hintText: '00 0000 0000 0000 0000 0000'),
                ),
              ),
              const SizedBox(height: 14),

              _label(tr('موقع المتجر')),
              FnCard(
                onTap: _pickPlace,
                padding: const EdgeInsets.all(12),
                border: true,
                borderColor: _place == null ? FnColors.border : FnColors.primary,
                child: Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
                    child: Icon(_place == null ? Icons.add_location_alt_outlined : Icons.place_rounded, color: FnColors.deep),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_place == null ? tr('حدّد موقع متجرك على الخريطة') : tr('تم تحديد الموقع'), style: FnText.bodyStrong15),
                      Text(
                        _place == null ? tr('ليظهر للعملاء القريبين وتُحسب المسافة') : (_place!.summary.isEmpty ? tr('اضغط للتعديل') : _place!.summary),
                        style: FnText.caption11.muted, maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                    ]),
                  ),
                  Icon(_place == null ? Icons.chevron_right_rounded : Icons.edit_outlined, color: FnColors.faint, size: 20),
                ]),
              ),
              const SizedBox(height: 26),
              FnButton(label: tr('إنشاء المتجر'), loading: _loading, onPressed: _create),
            ],
          ),
        ),
      );
}
