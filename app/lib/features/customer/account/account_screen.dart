import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/auth_redirect.dart';
import '../../../core/router/shop_mode.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_logo.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/local/guest_cart.dart';
import '../../../data/repositories/auth_repo.dart';
import '../../../data/repositories/catalog_repo.dart';
import '../../../data/repositories/coupon_repo.dart';
import '../../../data/repositories/order_repo.dart';

/// 06 المزيد / 13 حسابي
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key, this.isTab = true});
  final bool isTab;
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

/// اختيار اللغة — الإنجليزية تُفعَّل في التحديث القادم
void showLanguageSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: FnColors.border, borderRadius: BorderRadius.circular(3))),
            Padding(padding: const EdgeInsets.all(14), child: Text('اللغة', style: FnText.heading18)),
            FnListRow(title: 'العربية', trailing: const Icon(Icons.check_circle_rounded, color: FnColors.primary, size: 20),
                onTap: () => Navigator.pop(ctx)),
            const FnDivider(),
            FnListRow(title: 'English', titleStyle: FnText.body15.faint,
                trailing: const FnBadge('قريبًا', bg: FnColors.bgBase, fg: FnColors.muted)),
          ]),
        ),
      ),
    );

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
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: FnAppBar(title: 'حسابي', showBack: !widget.isTab),
      body: user == null ? _guest(context) : _member(context),
    );
  }

  // ---------------------------------------------------------------- الزائر
  Widget _guest(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: FnColors.deep, borderRadius: BorderRadius.circular(22)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 54, height: 54, decoration: BoxDecoration(color: FnColors.lime, borderRadius: BorderRadius.circular(18)),
                    child: const Center(child: FnLogoMark(size: 32, color: FnColors.deep, gradient: false))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('أهلًا بك في فناء', style: FnText.heading18.onDark),
                  Text('سجّل دخولك لحفظ طلباتك وعناوينك', style: FnText.caption11.soft),
                ])),
              ]),
              const SizedBox(height: 14),
              FnButton(label: 'تسجيل الدخول برقم الجوال', height: 50, color: FnColors.lime, textColor: FnColors.deep,
                  onPressed: () => goLogin(context, from: '/more')),
            ]),
          ),
          const SizedBox(height: 10),
          _Group(children: [
            FnListRow(title: 'اللغة', icon: Icons.language_rounded, value: 'العربية', showChevron: false,
                onTap: () => showLanguageSheet(context)),
            FnListRow(title: 'الدعم والمساعدة', icon: Icons.help_outline_rounded, onTap: () => context.push('/support')),
            FnListRow(
              title: 'هل أنت صاحب متجر؟', subtitle: 'سجّل مشتلك وابدأ البيع', icon: Icons.storefront_outlined, iconColor: FnColors.clay,
              onTap: () async {
                await AppPrefs.clearRoleChoice();
                if (context.mounted) context.go('/auth/type');
              },
            ),
          ]),
        ],
      );

  // ---------------------------------------------------------------- المسجّل
  Widget _member(BuildContext context) {
    final p = ref.watch(profileProvider).valueOrNull;
    final orders = ref.watch(myOrdersProvider).valueOrNull ?? const [];
    final favs = ref.watch(favoriteIdsProvider).valueOrNull ?? const <String>{};
    final addrs = ref.watch(addressesProvider).valueOrNull ?? const [];
    final favStores = ref.watch(favoriteNurseryIdsProvider).valueOrNull ?? const <String>{};
    final coupons = ref.watch(myRedemptionsProvider).valueOrNull ?? const [];
    final myStore = p?.isMerchant == true ? ref.watch(myNurseryProvider).valueOrNull : null;
    return ListView(
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
              if (myStore != null) Text('صاحب ${myStore.name}', style: FnText.caption11.lime),
              Directionality(textDirection: TextDirection.ltr, child: Text(p?.phone == null ? '' : Fmt.phone(p!.phone!), style: FnText.caption11.soft)),
            ])),
            GestureDetector(
              onTap: () => _editName(p?.fullName),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: FnColors.primary, borderRadius: BorderRadius.circular(13)),
                child: Text(myStore != null ? 'تعديل اسمك' : 'تعديل', style: FnText.caption11.onDark),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _Stat('${orders.length}', 'الطلبات', onTap: () => context.go('/orders')),
          const SizedBox(width: 10),
          _Stat('${p?.loyaltyPoints ?? 0}', 'نقاط الولاء'),
          const SizedBox(width: 10),
          _Stat('${coupons.length}', 'الكوبونات', onTap: () => context.push('/my-coupons')),
        ]),
        const SizedBox(height: 10),
        _Group(children: [
          FnListRow(title: 'طلباتي', icon: Icons.shopping_bag_outlined, value: '${orders.length}', onTap: () => context.go('/orders')),
          FnListRow(title: 'العناوين المحفوظة', icon: Icons.location_on_outlined, value: '${addrs.length}', onTap: () => context.push('/addresses')),
          FnListRow(title: 'طرق الدفع', icon: Icons.credit_card_rounded, onTap: () => context.push('/pay-methods')),
          FnListRow(title: 'المفضلة', icon: Icons.favorite_border_rounded, value: '${favs.length + favStores.length}',
              onTap: () => context.push('/favorites')),
        ]),
        const SizedBox(height: 10),
        _Group(children: [
          FnListRow(title: 'الإشعارات', icon: Icons.notifications_none_rounded,
              trailing: FnSwitch(value: _notif, onChanged: (v) => setState(() => _notif = v))),
          FnListRow(title: 'اللغة', icon: Icons.language_rounded, value: 'العربية', showChevron: false,
              onTap: () => showLanguageSheet(context)),
          FnListRow(title: 'الدعم والمساعدة', icon: Icons.help_outline_rounded, onTap: () => context.push('/support')),
          FnListRow(
            title: 'تسجيل الخروج', titleStyle: FnText.bodyStrong15.clay, icon: Icons.logout_rounded, iconColor: FnColors.clay,
            trailing: const SizedBox.shrink(),
            onTap: () async {
              ShopMode.active.value = false;
              await ref.read(authRepoProvider).signOut();
              if (context.mounted) context.go('/home'); // يبقى يتصفّح كزائر
            },
          ),
        ]),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.v, this.l, {this.onTap});
  final String v, l;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: FnCard(
          onTap: onTap, radius: 16,
          padding: const EdgeInsets.symmetric(vertical: 10),
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
