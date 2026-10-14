import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/models/coupon.dart';
import '../../../data/repositories/coupon_repo.dart';
import '../dashboard/merchant_dashboard_screen.dart';
import '../../../core/i18n/i18n.dart';
import '../../auth/phone_login_screen.dart' show EnglishDigitsFormatter;

/// الكوبونات والعروض — لصاحب المتجر
class MerchantCouponsScreen extends ConsumerWidget {
  const MerchantCouponsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WithMyNursery(builder: (n) => _Coupons(n: n));
}

class _Coupons extends ConsumerWidget {
  const _Coupons({required this.n});
  final Nursery n;

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CouponForm(nurseryId: n.id),
    );
    if (saved == true) ref.invalidate(merchantCouponsProvider(n.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(merchantCouponsProvider(n.id));
    return Scaffold(
      appBar: FnAppBar(
        title: tr('الكوبونات'),
        action: GestureDetector(
          onTap: () => _add(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(14)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(tr('كوبون جديد'), style: FnText.label13.onDark),
              const SizedBox(width: 6),
              const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            ]),
          ),
        ),
      ),
      body: async.when(
        loading: () => const FnLoading(),
        error: (_, __) => FnError(onRetry: () => ref.invalidate(merchantCouponsProvider(n.id))),
        data: (list) => list.isEmpty
            ? FnEmpty(
                title: tr('لا توجد كوبونات بعد'),
                subtitle: tr('أنشئ كوبون خصم وشاركه مع عملائك لزيادة مبيعاتك'),
                icon: Icons.local_offer_outlined,
                action: SizedBox(width: 180, child: FnButton(label: tr('كوبون جديد'), height: 50, onPressed: () => _add(context, ref))),
              )
            : RefreshIndicator(
                color: FnColors.primary,
                onRefresh: () async => ref.invalidate(merchantCouponsProvider(n.id)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _CouponCard(c: list[i], nurseryId: n.id),
                ),
              ),
      ),
    );
  }
}

class _CouponCard extends ConsumerWidget {
  const _CouponCard({required this.c, required this.nurseryId});
  final Coupon c;
  final String nurseryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dead = c.expired || c.exhausted;
    final status = c.expired ? tr('منتهي') : (c.exhausted ? tr('اكتملت الاستخدامات') : (c.isActive ? tr('فعّال') : tr('موقوف')));
    final valueLabel = c.isPercent ? '${c.value.toStringAsFixed(0)}%' : Fmt.moneyShort(c.value);
    final details = [
      if (c.minOrder > 0) tr('حد أدنى {0}', [Fmt.moneyShort(c.minOrder)]),
      if (c.isPercent && c.maxDiscount != null) tr('حتى {0}', [Fmt.moneyShort(c.maxDiscount!)]),
      tr('استُخدم {0}{1}', [c.usedCount, c.usageLimit != null ? tr(' من {0}', [c.usageLimit]) : '']),
      if (c.endsAt != null) tr('ينتهي {0}', [Fmt.date(c.endsAt!)]),
    ].join(' • ');

    return FnCard(
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: dead ? FnColors.bgBase : FnColors.soft, borderRadius: BorderRadius.circular(18)),
          alignment: Alignment.center,
          child: Text(valueLabel, style: FnText.heading18.copyWith(color: dead ? FnColors.faint : FnColors.deep)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Directionality(textDirection: TextDirection.ltr,
                child: Text(c.code, style: FnText.bodyStrong15.copyWith(letterSpacing: 1.2))),
            const SizedBox(width: 8),
            FnBadge(status,
                bg: c.isActive && !dead ? FnColors.soft : FnColors.bgBase,
                fg: c.isActive && !dead ? FnColors.deep : FnColors.muted),
          ]),
          const SizedBox(height: 4),
          Text(details, style: FnText.caption11.muted),
        ])),
        Column(children: [
          FnSwitch(
            value: c.isActive,
            onChanged: dead
                ? null
                : (v) async {
                    await ref.read(couponRepoProvider).setActive(c.code, v);
                    ref.invalidate(merchantCouponsProvider(nurseryId));
                  },
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (d) => AlertDialog(
                  title: Text(tr('حذف الكوبون {0}؟', [c.code]), style: FnText.heading18),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(d, false), child: Text(tr('إلغاء'), style: FnText.label13.muted)),
                    TextButton(onPressed: () => Navigator.pop(d, true), child: Text(tr('حذف'), style: FnText.label13.clay)),
                  ],
                ),
              );
              if (ok != true) return;
              await ref.read(couponRepoProvider).delete(c.code);
              ref.invalidate(merchantCouponsProvider(nurseryId));
            },
            child: const Icon(Icons.delete_outline_rounded, size: 20, color: FnColors.faint),
          ),
        ]),
      ]),
    );
  }
}

class _CouponForm extends ConsumerStatefulWidget {
  const _CouponForm({required this.nurseryId});
  final String nurseryId;
  @override
  ConsumerState<_CouponForm> createState() => _CouponFormState();
}

class _CouponFormState extends ConsumerState<_CouponForm> {
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _min = TextEditingController(text: '0');
  final _max = TextEditingController();
  final _limit = TextEditingController();
  final _perUser = TextEditingController(text: '1');
  String _type = 'percent';
  DateTime? _endsAt;
  bool _saving = false;

  Future<void> _save() async {
    final code = _code.text.trim().toUpperCase();
    final value = double.tryParse(_value.text);
    if (code.length < 3 || value == null || value <= 0) {
      showFnSnack(context, tr('أدخل الكود (٣ أحرف على الأقل) وقيمة الخصم'), error: true);
      return;
    }
    if (_type == 'percent' && value > 100) {
      showFnSnack(context, tr('النسبة لا تتجاوز ١٠٠٪'), error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(couponRepoProvider).create(
            nurseryId: widget.nurseryId,
            code: code,
            type: _type,
            value: value,
            minOrder: double.tryParse(_min.text) ?? 0,
            maxDiscount: _type == 'percent' ? double.tryParse(_max.text) : null,
            usageLimit: int.tryParse(_limit.text),
            perUserLimit: int.tryParse(_perUser.text) ?? 1,
            endsAt: _endsAt,
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      final s = e.toString();
      if (mounted) {
        showFnSnack(context, s.contains('duplicate') || s.contains('23505') ? tr('هذا الكود مستخدم، اختر كودًا آخر') : fnErrorText(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _f(String label, TextEditingController c, String hint, {bool number = true, String? suffix, bool code = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: FnText.label13.muted),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            textCapitalization: code ? TextCapitalization.characters : TextCapitalization.none,
            textDirection: code || number ? TextDirection.ltr : null,
            inputFormatters: code
                ? [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(16)]
                : (number ? [const EnglishDigitsFormatter(), FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] : null),
            decoration: InputDecoration(hintText: hint, suffixText: suffix, fillColor: FnColors.bgBase),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: FnColors.border, borderRadius: BorderRadius.circular(3)))),
            const SizedBox(height: 14),
            Text(tr('كوبون جديد'), style: FnText.heading18),
            const SizedBox(height: 14),
            _f(tr('الكود'), _code, 'SPRING20', number: false, code: true),
            Text(tr('نوع الخصم'), style: FnText.label13.muted),
            const SizedBox(height: 6),
            Row(children: [
              FnChip(label: tr('نسبة ٪'), selected: _type == 'percent', onTap: () => setState(() => _type = 'percent')),
              const SizedBox(width: 8),
              FnChip(label: tr('مبلغ ثابت'), selected: _type == 'fixed', onTap: () => setState(() => _type = 'fixed')),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _f(tr('قيمة الخصم'), _value, _type == 'percent' ? '10' : '15', suffix: _type == 'percent' ? '%' : tr('ر.س'))),
              const SizedBox(width: 12),
              Expanded(child: _f(tr('الحد الأدنى للطلب'), _min, '0', suffix: tr('ر.س'))),
            ]),
            if (_type == 'percent') _f(tr('أقصى خصم (اختياري)'), _max, tr('بدون حد'), suffix: tr('ر.س')),
            Row(children: [
              Expanded(child: _f(tr('عدد الاستخدامات (اختياري)'), _limit, tr('بدون حد'))),
              const SizedBox(width: 12),
              Expanded(child: _f(tr('لكل عميل'), _perUser, '1', suffix: tr('مرة'))),
            ]),
            Text(tr('تاريخ الانتهاء'), style: FnText.label13.muted),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: _endsAt ?? DateTime.now().add(const Duration(days: 30)),
                );
                if (d != null) setState(() => _endsAt = DateTime(d.year, d.month, d.day, 23, 59));
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(FnRadius.field)),
                child: Row(children: [
                  Expanded(child: Text(_endsAt == null ? tr('بدون تاريخ انتهاء') : Fmt.date(_endsAt!),
                      style: _endsAt == null ? FnText.body15.faint : FnText.body15)),
                  if (_endsAt != null)
                    GestureDetector(onTap: () => setState(() => _endsAt = null),
                        child: const Icon(Icons.close_rounded, size: 18, color: FnColors.faint))
                  else
                    const Icon(Icons.calendar_month_outlined, size: 18, color: FnColors.faint),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            FnButton(label: tr('حفظ الكوبون'), loading: _saving, onPressed: _save),
          ]),
        ),
      );
}
