import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fn_widgets.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/auth_repo.dart';

/// 02 تسجيل دخول المستخدم / 14 دخول صاحب المتجر — نفس الشاشة بأيقونة وعنوان مختلفين
class PhoneLoginScreen extends ConsumerStatefulWidget {
  const PhoneLoginScreen({super.key, required this.role});
  final UserRole role;
  @override
  ConsumerState<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends ConsumerState<PhoneLoginScreen> {
  final _phone = TextEditingController();
  bool _loading = false;

  bool get _valid {
    final d = _phone.text.replaceAll(RegExp(r'[^0-9]'), '');
    return (d.length == 9 && d.startsWith('5')) || (d.length == 10 && d.startsWith('05'));
  }

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await ref.read(authRepoProvider).sendOtp(_phone.text, role: widget.role);
      if (!mounted) return;
      context.push('/auth/otp', extra: {'phone': _phone.text, 'role': widget.role});
    } catch (e) {
      if (mounted) showFnSnack(context, 'تعذّر إرسال الرمز، تحقّق من الرقم', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchant = widget.role == UserRole.merchant;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FnSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: FnBackButton(onTap: () => context.pop())),
              const SizedBox(height: 36),
              Container(
                width: 74, height: 74,
                decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(26)),
                child: Icon(merchant ? Icons.storefront_outlined : Icons.person_outline_rounded, size: 34, color: FnColors.deep),
              ),
              const SizedBox(height: 22),
              Text(merchant ? 'تسجيل الدخول كصاحب متجر' : 'تسجيل الدخول كمستخدم', style: FnText.display28),
              const SizedBox(height: 4),
              Text('أدخل رقم جوالك وسنرسل لك رمز تحقق للمتابعة', style: FnText.body15.muted),
              const SizedBox(height: 30),
              Text('رقم الجوال', style: FnText.label13),
              const SizedBox(height: 8),
              PhoneField(controller: _phone, onChanged: (_) => setState(() {}), onSubmitted: _valid ? (_) => _send() : null),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: FnColors.faint),
                const SizedBox(width: 6),
                Text('سنرسل رمز التحقق عبر رسالة نصية', style: FnText.caption11.faint),
              ]),
              const Spacer(),
              FnButton(label: 'تسجيل الدخول', loading: _loading, onPressed: _valid ? _send : null),
              const SizedBox(height: 14),
              Center(
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'ليس لديك حساب؟ ', style: FnText.label13.muted),
                  TextSpan(text: 'سجّل الآن', style: FnText.label13.primary),
                ])),
              ),
              const SizedBox(height: 10),
              const Center(child: LangPill()),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// حقل الجوال: شريحة [علم +966] على اليسار والرقم بجانبها مباشرة (LTR)
class PhoneField extends StatelessWidget {
  const PhoneField({super.key, required this.controller, this.onChanged, this.onSubmitted});
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(FnRadius.field)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(children: [
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: FnColors.bgBase, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(3),
                    child: SvgPicture.asset('assets/brand/flag_sa.svg', width: 24, height: 16, fit: BoxFit.cover)),
                const SizedBox(width: 8),
                Text('+966', style: FnText.label13),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.left,
                style: FnText.body15,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: InputDecoration(
                  hintText: '5X XXX XXXX',
                  hintStyle: FnText.body15.faint,
                  filled: false, isDense: true, border: InputBorder.none, enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none, contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ]),
        ),
      );
}

class LangPill extends StatelessWidget {
  const LangPill({super.key});
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
