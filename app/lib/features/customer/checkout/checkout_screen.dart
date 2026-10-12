import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/order_repo.dart';
import 'checkout_state.dart';
import '../../../core/i18n/i18n.dart';

/// 10 إتمام الطلب
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.nurseryId});
  final String nurseryId;
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _note = TextEditingController();
  bool _now = true;

  Future<void> _pickSchedule() async {
    final d = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 7)),
        initialDate: DateTime.now());
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 17, minute: 0));
    if (t == null) return;
    final at = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    final draft = ref.read(checkoutDraftProvider);
    if (draft != null) ref.read(checkoutDraftProvider.notifier).state = draft.copyWith(scheduledAt: at);
    setState(() => _now = false);
  }

  Future<void> _pickAddress(List<Address> list) async {
    final picked = await showModalBottomSheet<Address>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 44, height: 5, decoration: BoxDecoration(color: FnColors.border, borderRadius: BorderRadius.circular(3))),
          Padding(padding: const EdgeInsets.all(16), child: Text(tr('اختر عنوان التوصيل'), style: FnText.heading18)),
          for (final a in list)
            FnListRow(title: a.label, subtitle: tr('{0}، {1}', [a.line, a.full]), icon: Icons.location_on_outlined, showChevron: false, onTap: () => Navigator.pop(context, a)),
          FnListRow(title: tr('إضافة عنوان جديد'), icon: Icons.add_location_alt_outlined, iconColor: FnColors.primary,
              onTap: () { Navigator.pop(context); context.push('/addresses?add=1'); }),
          const SizedBox(height: 12),
        ]),
      ),
    );
    if (picked != null) {
      final draft = ref.read(checkoutDraftProvider);
      if (draft != null) ref.read(checkoutDraftProvider.notifier).state = draft.copyWith(address: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(checkoutDraftProvider);
    final addrs = ref.watch(addressesProvider);
    if (draft == null) return Scaffold(body: FnEmpty(title: tr('لا يوجد طلب قيد الإعداد')));

    final list = addrs.valueOrNull ?? const <Address>[];
    final addr = draft.address ?? (list.isEmpty ? null : list.firstWhere((a) => a.isDefault, orElse: () => list.first));
    if (draft.address == null && addr != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(checkoutDraftProvider.notifier).state = draft.copyWith(address: addr));
    }

    return Scaffold(
      appBar: FnAppBar(title: tr('إتمام الطلب')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
        children: [
          const _Steps(current: 1),
          const SizedBox(height: 16),
          _label(tr('عنوان التوصيل')),
          FnCard(
            padding: const EdgeInsets.all(14), radius: 18,
            onTap: () => list.isEmpty ? context.push('/addresses?add=1') : _pickAddress(list),
            child: Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.location_on_outlined, color: FnColors.deep, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: addr == null
                  ? Text(tr('أضف عنوان التوصيل'), style: FnText.bodyStrong15.primary)
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(addr.label, style: FnText.bodyStrong15),
                      Text(tr('{0}، {1}', [addr.line, addr.full]), style: FnText.caption11.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
              Text(addr == null ? tr('إضافة') : tr('تغيير'), style: FnText.label13.primary),
            ]),
          ),
          const SizedBox(height: 14),
          _label(tr('وقت التوصيل')),
          Row(children: [
            Expanded(child: _TimeOpt(
              title: tr('الآن'), subtitle: tr('خلال ٤٥ دقيقة'), selected: _now,
              onTap: () { setState(() => _now = true); ref.read(checkoutDraftProvider.notifier).state = draft.copyWith(clearSchedule: true); },
            )),
            const SizedBox(width: 10),
            Expanded(child: _TimeOpt(
              title: tr('جدولة لاحقًا'),
              subtitle: draft.scheduledAt == null ? tr('اختر اليوم والوقت') : Fmt.dateTime(draft.scheduledAt!),
              selected: !_now, onTap: _pickSchedule,
            )),
          ]),
          const SizedBox(height: 14),
          _label(tr('ملاحظة للمشتل')),
          TextField(controller: _note, maxLines: 2, decoration: InputDecoration(hintText: tr('مثال: اتركها عند الباب'))),
          const SizedBox(height: 14),
          FnCard(
            child: Column(children: [
              FnKV(tr('مجموع المنتجات'), Fmt.money(draft.subtotal)),
              FnKV(tr('التوصيل'), draft.delivery == 0 ? tr('مجاني') : Fmt.money(draft.delivery)),
              if (draft.discount > 0)
                FnKV(tr('خصم الكوبون {0}', [draft.coupon ?? '']), '− ${Fmt.money(draft.discount)}', valueColor: FnColors.primary),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: FnDivider()),
              FnKV(tr('الإجمالي'), Fmt.money(draft.total), strong: true),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: FnBottomBar(
        child: Row(children: [
          Expanded(
            child: FnButton(
              label: tr('المتابعة للدفع'),
              onPressed: addr == null
                  ? null
                  : () {
                      ref.read(checkoutDraftProvider.notifier).state =
                          ref.read(checkoutDraftProvider)!.copyWith(note: _note.text.trim().isEmpty ? null : _note.text.trim());
                      context.push('/payment');
                    },
            ),
          ),
          const SizedBox(width: 14),
          Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(tr('الإجمالي'), style: FnText.caption11.muted),
            Text(Fmt.moneyShort(draft.total), style: FnText.heading18),
          ]),
        ]),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t, style: FnText.label13.muted));
}

class _Steps extends StatelessWidget {
  const _Steps({required this.current});
  final int current;
  @override
  Widget build(BuildContext context) {
    const labels = ['السلة', 'التفاصيل', 'الدفع'];
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < 3; i++) ...[
        Container(
          height: 30, padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center,
          decoration: BoxDecoration(
            color: i < current ? FnColors.soft : (i == current ? FnColors.deep : FnColors.surface),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(tr(labels[i]), style: FnText.caption11.copyWith(
              color: i < current ? FnColors.deep : (i == current ? FnColors.surface : FnColors.muted))),
        ),
        if (i < 2) const SizedBox(width: 8),
      ],
    ]);
  }
}

class _TimeOpt extends StatelessWidget {
  const _TimeOpt({required this.title, required this.subtitle, required this.selected, required this.onTap});
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? FnColors.deep : FnColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: selected ? null : Border.all(color: FnColors.border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: selected ? FnText.bodyStrong15.onDark : FnText.bodyStrong15),
            Text(subtitle, style: selected ? FnText.caption11.lime : FnText.caption11.muted, maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      );
}
