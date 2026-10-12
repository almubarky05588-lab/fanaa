import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/catalog.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../dashboard/merchant_dashboard_screen.dart';

/// 21 إعدادات المتجر
class MerchantSettingsScreen extends ConsumerWidget {
  const MerchantSettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => WithMyNursery(builder: (n) => _Settings(n: n));
}

class _Settings extends ConsumerStatefulWidget {
  const _Settings({required this.n});
  final Nursery n;
  @override
  ConsumerState<_Settings> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<_Settings> {
  late bool _auto = widget.n.autoAccept;
  late bool _vacation = widget.n.onVacation;
  bool _notif = true;

  Future<void> _update(Map<String, dynamic> data) async {
    try {
      await ref.read(catalogRepoProvider).updateNursery(widget.n.id, data);
      ref.invalidate(myNurseryProvider);
    } catch (e) {
      if (mounted) showFnSnack(context, fnErrorText(e), error: true);
    }
  }

  Future<void> _editNumber(String title, String field, num? current, {String suffix = 'ر.س'}) async {
    final c = TextEditingController(text: current?.toString() ?? '');
    final v = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: FnText.heading18),
          const SizedBox(height: 12),
          TextField(controller: c, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(suffixText: suffix, fillColor: FnColors.bgBase)),
          const SizedBox(height: 16),
          FnButton(label: 'حفظ', onPressed: () => Navigator.pop(ctx, c.text.trim())),
        ]),
      ),
    );
    if (v == null) return;
    await _update({field: v.isEmpty ? null : double.tryParse(v)});
  }

  @override
  Widget build(BuildContext context) {
    final n = ref.watch(myNurseryProvider).valueOrNull ?? widget.n;
    return Scaffold(
      appBar: const FnAppBar(title: 'إعدادات المتجر', showBack: false),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
        children: [
          FnCard(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(16)),
                  child: const Center(child: FnLogoMark(size: 30, color: FnColors.lime, gradient: false))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.name, style: FnText.bodyStrong15),
                Text('تعديل الاسم والشعار والوصف', style: FnText.caption11.muted),
              ])),
              const Icon(Icons.chevron_left_rounded, color: FnColors.faint),
            ]),
          ),
          const SizedBox(height: 8),
          _label('التوصيل والرسوم'),
          _Group(children: [
            FnListRow(title: 'نطاق التوصيل', value: Fmt.km(n.deliveryRadiusKm),
                onTap: () => _editNumber('نطاق التوصيل', 'delivery_radius_km', n.deliveryRadiusKm, suffix: 'كم')),
            FnListRow(title: 'رسوم التوصيل', value: Fmt.moneyShort(n.deliveryFee),
                onTap: () => _editNumber('رسوم التوصيل', 'delivery_fee', n.deliveryFee)),
            FnListRow(title: 'توصيل مجاني فوق', value: n.freeDeliveryOver == null ? '—' : Fmt.moneyShort(n.freeDeliveryOver!),
                onTap: () => _editNumber('توصيل مجاني فوق', 'free_delivery_over', n.freeDeliveryOver)),
            FnListRow(title: 'الحد الأدنى للطلب', value: Fmt.moneyShort(n.minOrder),
                onTap: () => _editNumber('الحد الأدنى للطلب', 'min_order', n.minOrder)),
            FnListRow(title: 'وقت التجهيز', value: Fmt.minutes(n.prepTimeMin),
                onTap: () => _editNumber('وقت التجهيز', 'prep_time_min', n.prepTimeMin, suffix: 'دقيقة')),
          ]),
          const SizedBox(height: 8),
          _label('التشغيل'),
          _Group(children: [
            _Toggle('قبول الطلبات تلقائيًا', 'بدون تأكيد يدوي', _auto, (v) { setState(() => _auto = v); _update({'auto_accept': v}); }),
            _Toggle('إشعارات الطلبات الجديدة', 'صوت + تنبيه', _notif, (v) => setState(() => _notif = v)),
            _Toggle('الإجازة المؤقتة', 'إيقاف استقبال الطلبات', _vacation, (v) { setState(() => _vacation = v); _update({'on_vacation': v}); }),
          ]),
          const SizedBox(height: 14),
          _Group(children: [
            FnListRow(
              title: 'تسجيل الخروج', titleStyle: FnText.bodyStrong15.clay, icon: Icons.logout_rounded, iconColor: FnColors.clay,
              trailing: const SizedBox.shrink(),
              onTap: () async {
                await ref.read(authRepoProvider).signOut();
                if (context.mounted) context.go('/auth/type');
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(top: 6, bottom: 8), child: Text(t, style: FnText.label13.muted));
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.t, this.s, this.v, this.on);
  final String t, s;
  final bool v;
  final ValueChanged<bool> on;
  @override
  Widget build(BuildContext context) => FnListRow(title: t, subtitle: s, trailing: FnSwitch(value: v, onChanged: on));
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[children[i], if (i < children.length - 1) const FnDivider()],
        ]),
      );
}
