import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fn_logo.dart';
import '../../core/widgets/fn_widgets.dart';
import '../../data/models/profile.dart';

/// 01 اختيار نوع الحساب
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});
  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  UserRole _role = UserRole.customer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _Hero(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(FnSpace.page, 24, FnSpace.page, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('نوع الحساب', style: FnText.label13.muted),
                  const SizedBox(height: 10),
                  _Option(
                    title: 'مستخدم',
                    subtitle: 'تصفّح المشاتل واطلب نباتاتك المفضلة',
                    icon: Icons.person_outline_rounded,
                    iconBg: FnColors.soft,
                    iconColor: FnColors.deep,
                    selected: _role == UserRole.customer,
                    onTap: () => setState(() => _role = UserRole.customer),
                  ),
                  const SizedBox(height: 12),
                  _Option(
                    title: 'صاحب متجر',
                    subtitle: 'اعرض منتجاتك وأدِر طلباتك بسهولة',
                    icon: Icons.storefront_outlined,
                    iconBg: const Color(0xFFF6E9E1),
                    iconColor: FnColors.clay,
                    selected: _role == UserRole.merchant,
                    onTap: () => setState(() => _role = UserRole.merchant),
                  ),
                  const Spacer(),
                  FnButton(
                    label: 'تأكيد',
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    onPressed: () => context.push('/auth/login', extra: _role),
                  ),
                  const SizedBox(height: 14),
                  const Center(child: _LangPill()),
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
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      height: 335 + top,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [FnColors.deep, FnColors.primary]),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(26), boxShadow: FnShadow.raised),
                    alignment: Alignment.center,
                    child: const FnLogoMark(size: 40, color: FnColors.primary, gradient: false),
                  ),
                  const SizedBox(height: 22),
                  Text('أهلًا بك في فناء', style: FnText.display28.onDark),
                  const SizedBox(height: 4),
                  Text('سوق النباتات الأول — اختر نوع حسابك للمتابعة', style: FnText.body15.soft),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double d, double o) => Container(
        width: d, height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: o)),
      );
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
            Container(width: 48, height: 48,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16)),
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

class _LangPill extends StatelessWidget {
  const _LangPill();
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.pill)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('العربية', style: FnText.label13),
          const SizedBox(width: 6),
          const Icon(Icons.language_rounded, size: 16, color: FnColors.deep),
        ]),
      );
}
