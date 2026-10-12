import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fn_logo.dart';
import '../../core/widgets/fn_widgets.dart';
import '../../data/local/guest_cart.dart';
import '../../data/models/profile.dart';
import 'phone_login_screen.dart' show LangPill;
import '../../core/i18n/i18n.dart';

/// 01 اختيار نوع الحساب
/// المستخدم يدخل مباشرة كزائر (التسجيل عند الشراء)، وصاحب المتجر يسجّل أولًا.
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});
  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  UserRole _role = UserRole.customer;

  Future<void> _confirm() async {
    await AppPrefs.setRoleChoice(_role.name);
    if (!mounted) return;
    if (_role == UserRole.customer) {
      context.go('/home');
    } else {
      context.push('/auth/login', extra: UserRole.merchant);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _Hero(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 24, FnSpace.page, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('نوع الحساب'), style: FnText.label13.muted),
                  const SizedBox(height: 10),
                  _Option(
                    title: tr('مستخدم'),
                    subtitle: tr('تصفّح المشاتل واطلب نباتاتك المفضلة'),
                    icon: Icons.person_outline_rounded,
                    iconBg: FnColors.soft,
                    iconColor: FnColors.deep,
                    selected: _role == UserRole.customer,
                    onTap: () => setState(() => _role = UserRole.customer),
                  ),
                  const SizedBox(height: 12),
                  _Option(
                    title: tr('صاحب متجر'),
                    subtitle: tr('اعرض منتجاتك وأدِر طلباتك بسهولة'),
                    icon: Icons.storefront_outlined,
                    iconBg: const Color(0xFFF6E9E1),
                    iconColor: FnColors.clay,
                    selected: _role == UserRole.merchant,
                    onTap: () => setState(() => _role = UserRole.merchant),
                  ),
                  const Spacer(),
                  // arrow_forward ينقلبه Flutter في العربية فيشير لليسار ← (للأمام)
                  FnButton(label: tr('تأكيد'), icon: const Icon(Icons.arrow_forward_rounded, size: 18), onPressed: _confirm),
                  const SizedBox(height: 14),
                  const Center(child: LangPill()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      height: 335 + top,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [FnColors.deep, FnColors.primary]),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(FnRadius.sheet)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -40, top: 80, child: _circle(220, .10)),
          Positioned(right: -60, top: -20, child: _circle(180, .08)),
          Positioned(right: -16, bottom: 20, child: Opacity(opacity: .12, child: const FnLogoMark(size: 150, color: Colors.white, gradient: false))),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: top + 56, left: 24, right: 24),
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(26), boxShadow: FnShadow.raised),
                  alignment: Alignment.center,
                  child: const FnLogoMark(size: 40, color: FnColors.primary, gradient: false),
                ),
                const SizedBox(height: 22),
                Text(tr('أهلًا بك في فناء'), style: FnText.display28.onDark),
                const SizedBox(height: 4),
                Text(tr('سوق النباتات الأول — اختر نوع حسابك للمتابعة'), style: FnText.body15.soft),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double d, double o) =>
      Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: o)));
}

class _Option extends StatelessWidget {
  const _Option({required this.title, required this.subtitle, required this.icon, required this.iconBg,
      required this.iconColor, required this.selected, required this.onTap});
  final String title, subtitle;
  final IconData icon;
  final Color iconBg, iconColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: FnColors.surface,
            borderRadius: BorderRadius.circular(FnRadius.card),
            border: Border.all(color: selected ? FnColors.primary : Colors.transparent, width: 1.5),
          ),
          child: Row(children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: iconColor, size: 24)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: FnText.bodyStrong15),
              Text(subtitle, style: FnText.caption11.muted),
            ])),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? FnColors.primary : FnColors.bgBase,
                border: Border.all(color: selected ? FnColors.primary : FnColors.border, width: 1.5),
              ),
              child: selected ? const Icon(Icons.check_rounded, size: 15, color: Colors.white) : null,
            ),
          ]),
        ),
      );
}
