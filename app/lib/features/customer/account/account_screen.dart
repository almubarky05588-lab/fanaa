import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../data/repositories/order_repo.dart';

/// 06 المزيد / 13 حسابي
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, this.isTab = true});
  final bool isTab;
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _notif = true;

  Future<void> _editName(String? current) async {
    final c = TextEditingController(text: current);
    final v = await showModalBottomSheet<String>(
      context: context, isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.viewInsetsOf(ctx).bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('تعديل الاسم', style: FnText.heading18),
          const SizedBox(height: 12),
          TextField(controller: c, autofocus: true, decoration: const InputDecoration(hintText: 'الاسم الكامل', fillColor: FnColors.bgBase)),
          const SizedBox(height: 16),
          FnButton(label: 'حفظ', onPressed: () => Navigator.pop(ctx, c.text.trim())),
        ]),
      ),
    );
    if (v == null || v.isEmpty) return;
    await ref.read(authRepoProvider).updateName(v);
    ref.invalidate(profileProvider);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(profileProvider).valueOrNull;
    final orders = ref.watch(myOrdersProvider).valueOrNull ?? const [];
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>{};
    final addrs = ref.watch(addressesProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: FnAppBar(title: 'حسابي', showBack: !widget.isTab),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(22)),
            child: Row(children: [
              Container(width: 54, height: 54, decoration: BoxDecoration(color: FnColors.lime, borderRadius: BorderRadius.circular(18)),
                  child: const Center(child: FnLogoMark(size: 32, color: FnColors.deep, gradient: false))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p?.fullName?.isNotEmpty == true ? p!.fullName! : 'أضف اسمك', style: FnText.heading18.onDark),
                Directionality(textDirection: TextDirection.ltr, child: Text(p?.phone == null ? '' : Fmt.phone(p!.phone!), style: FnText.caption11.soft)),
              ])),
              GestureDetector(
                onTap: () => _editName(p?.fullName),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: FnColors.primary, borderRadius: BorderRadius.circular(13)),
                  child: Text('تعديل', style: FnText.caption11.onDark),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          Row(children: [
            _Stat('${orders.length}', 'الطلبات'),
            const SizedBox(width: 10),
            _Stat('${p?.loyaltyPoints ?? 0}', 'نقاط الولاء'),
            const SizedBox(width: 10),
            const _Stat('0', 'الكوبونات'),
          ]),
          const SizedBox(height: 10),
          _Group(children: [
            FnListRow(title: 'طلباتي', icon: Icons.shopping_bag_outlined, value: '${orders.length}', onTap: () => context.go('/orders')),
            FnListRow(title: 'العناوين المحفوظة', icon: Icons.location_on_outlined, value: '${addrs.length}', onTap: () => context.push('/addresses')),
            FnListRow(title: 'طرق الدفع', icon: Icons.credit_card_rounded, onTap: () => showFnSnack(context, 'تُحفظ البطاقات عند أول دفع')),
            FnListRow(title: 'المفضلة', icon: Icons.favorite_border_rounded, value: '${favs.length}', onTap: () {}),
          ]),
          const SizedBox(height: 10),
          _Group(children: [
            FnListRow(title: 'الإشعارات', icon: Icons.notifications_none_rounded,
                trailing: FnSwitch(value: _notif, onChanged: (v) => setState(() => _notif = v))),
            FnListRow(title: 'اللغة', icon: Icons.language_rounded, value: 'العربية'),
            FnListRow(title: 'الدعم والمساعدة', icon: Icons.help_outline_rounded),
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
}

class _Stat extends StatelessWidget {
  const _Stat(this.v, this.l);
  final String v, l;
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(16)),
          child: Column(children: [Text(v, style: FnText.heading18), Text(l, style: FnText.caption11.muted)]),
        ),
      );
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
