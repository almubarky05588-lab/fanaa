import 'package:flutter/material.dart';
import '../../core/router/auth_redirect.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fn_widgets.dart';
import '../../core/i18n/i18n.dart';

/// بطاقة دعوة الزائر لتسجيل الدخول — تظهر في الأقسام المرتبطة بالحساب
class GuestLoginPrompt extends StatelessWidget {
  const GuestLoginPrompt({super.key, required this.title, required this.subtitle, this.from, this.icon = Icons.person_outline_rounded});
  final String title, subtitle;
  final String? from;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FnEmpty(
        title: title,
        subtitle: subtitle,
        icon: icon,
        action: SizedBox(width: 200, child: FnButton(label: tr('تسجيل الدخول'), height: 50, onPressed: () => goLogin(context, from: from))),
      );
}

/// يعرض نافذة سفلية تطلب التسجيل قبل إجراء يتطلب حسابًا (المفضلة مثلًا)
Future<void> askToLogin(BuildContext context, {required String reason, String? from}) => showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: FnColors.border, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 18),
            Container(width: 60, height: 60, decoration: const BoxDecoration(color: FnColors.soft, shape: BoxShape.circle),
                child: const Icon(Icons.lock_outline_rounded, color: FnColors.deep, size: 26)),
            const SizedBox(height: 12),
            Text(tr('سجّل دخولك للمتابعة'), style: FnText.heading18),
            const SizedBox(height: 4),
            Text(reason, style: FnText.body15.muted, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FnButton(label: tr('تسجيل الدخول برقم الجوال'), onPressed: () { Navigator.pop(ctx); goLogin(context, from: from); }),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('لاحقًا'), style: FnText.label13.muted)),
          ]),
        ),
      ),
    );
