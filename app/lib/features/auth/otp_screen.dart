import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../core/router/auth_redirect.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/fn_widgets.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/auth_repo.dart';
import 'phone_login_screen.dart' show EnglishDigitsFormatter;
import '../../core/i18n/i18n.dart';

/// طول رمز التحقق — 4 أرقام (يُضبط بنفس القيمة في إعدادات SMS في Supabase)
const kOtpLength = 4;

/// 02b / 14b — رمز التحقق
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, required this.role});
  final String phone;
  final UserRole role;
  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  String _code = '';
  bool _loading = false;
  int _seconds = 45;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = 45);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) { t.cancel(); return; }
      setState(() => _seconds--);
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  Future<void> _verify() async {
    if (_code.length < kOtpLength || _loading) return;
    setState(() => _loading = true);
    try {
      await ref.read(authRepoProvider).verifyOtp(widget.phone, EnglishDigitsFormatter.convert(_code), role: widget.role);
      ref.invalidate(profileProvider);
      // الموجّه ينقل المستخدم تلقائيًا للوجهة المحفوظة؛ هذا احتياط فقط
      if (mounted) context.go(AuthRedirect.take() ?? '/splash');
    } catch (e) {
      if (mounted) showFnSnack(context, e is OtpException ? tr(e.message) : tr('الرمز غير صحيح أو انتهت صلاحيته'), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authRepoProvider).sendOtp(widget.phone, role: widget.role);
      _startTimer();
      if (mounted) showFnSnack(context, tr('تم إرسال رمز جديد'));
    } catch (e) {
      if (mounted) showFnSnack(context, e is OtpException ? tr(e.message) : tr('تعذّر الإرسال'), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchant = widget.role == UserRole.merchant;
    final mm = (_seconds ~/ 60).toString();
    final ss = (_seconds % 60).toString().padLeft(2, '0');
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FnSpace.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Align(alignment: AlignmentDirectional.centerStart, child: FnBackButton(onTap: () => context.pop())),
              const SizedBox(height: 28),
              Container(
                width: 74, height: 74,
                decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(26)),
                child: Icon(merchant ? Icons.storefront_outlined : Icons.person_outline_rounded, size: 34, color: FnColors.deep),
              ),
              const SizedBox(height: 22),
              Text(tr('أدخل رمز التحقق'), style: FnText.display28),
              const SizedBox(height: 8),
              Text(tr('أرسلنا رمزًا مكوّنًا من {0} أرقام إلى', [kOtpLength]), style: FnText.body15.muted),
              const SizedBox(height: 4),
              Row(children: [
                Directionality(textDirection: TextDirection.ltr, child: Text(Fmt.phone(widget.phone), style: FnText.bodyStrong15)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(12)),
                    child: Text(tr('تغيير'), style: FnText.caption11.primary),
                  ),
                ),
              ]),
              const SizedBox(height: 30),
              Directionality(
                textDirection: TextDirection.ltr,
                child: PinCodeTextField(
                  appContext: context,
                  length: kOtpLength,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [EnglishDigitsFormatter()],
                  autoFocus: true,
                  animationType: AnimationType.scale,
                  cursorColor: FnColors.deep,
                  textStyle: FnText.title22,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(16),
                    fieldHeight: 68, fieldWidth: 64, borderWidth: 1,
                    activeFillColor: FnColors.surface, inactiveFillColor: FnColors.surface, selectedFillColor: FnColors.surface,
                    activeColor: FnColors.deep, inactiveColor: FnColors.border, selectedColor: FnColors.primary,
                  ),
                  enableActiveFill: true,
                  onChanged: (v) => setState(() => _code = EnglishDigitsFormatter.convert(v)),
                  onCompleted: (_) => _verify(),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: _seconds > 0
                    ? Text.rich(TextSpan(children: [
                        TextSpan(text: tr('إعادة إرسال الرمز خلال '), style: FnText.body15.muted),
                        TextSpan(text: '$mm:$ss', style: FnText.label13.deep),
                      ]))
                    : GestureDetector(onTap: _resend, child: Text(tr('إعادة إرسال الرمز'), style: FnText.label13.primary)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: FnColors.deep),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tr('لا تشارك الرمز مع أحد، فريق فناء لن يطلبه منك'), style: FnText.caption11.deep)),
                ]),
              ),
              const Spacer(),
              FnButton(label: tr('تأكيد'), loading: _loading, onPressed: _code.length == kOtpLength ? _verify : null, height: 60),
              const SizedBox(height: 12),
              Center(child: Text(tr('لم يصلك الرمز؟ جرّب الاتصال الصوتي'), style: FnText.caption11.muted)),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
