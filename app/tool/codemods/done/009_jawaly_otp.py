"""Codemod 009: رمز التحقق عبر فورجوالي (دوال الخادم otp-send / otp-verify) بدل رسائل Supabase."""
import sys, os

NEW_OTP = '''  /// يرسل رمزًا من ٤ أرقام عبر فورجوالي (دالة الخادم otp-send)
  Future<void> sendOtp(String localPhone, {required UserRole role}) async {
    if (isDemo(localPhone)) return; // حساب تجريبي — لا رسالة
    await _call('otp-send', {'phone': Fmt.toE164(localPhone)});
  }

  /// يتحقق من الرمز (دالة الخادم otp-verify) ويفتح الجلسة. الدور يُستخدم فقط عند إنشاء حساب جديد
  Future<AuthResponse> verifyOtp(String localPhone, String token, {UserRole role = UserRole.customer}) async {
    final e164 = Fmt.toE164(localPhone);
    final demoEmail = _demoAccounts[e164];
    if (demoEmail != null) {
      return _c.auth.signInWithPassword(email: demoEmail, password: token);
    }
    final data = await _call('otp-verify', {'phone': e164, 'code': token, 'role': role.name});
    return _c.auth.setSession(data['refresh_token'] as String);
  }

  Future<Map<String, dynamic>> _call(String fn, Map<String, dynamic> body) async {
    try {
      final r = await _c.functions.invoke(fn, body: body);
      return Map<String, dynamic>.from(r.data as Map);
    } on FunctionException catch (e) {
      final d = e.details;
      throw OtpException(d is Map && d['error'] is String ? d['error'] as String : 'حدث خطأ غير متوقع');
    }
  }
'''

def run(root):
    os.chdir(root)
    p = 'lib/data/repositories/auth_repo.dart'
    s = open(p, encoding='utf-8').read()
    if 'otp-verify' in s:
        print('009 already applied'); return
    i = s.index('  /// يرسل OTP عبر SMS.')
    j = s.index('  Future<Profile?> myProfile() async {')
    s = s[:i] + NEW_OTP + '\n' + s[j:]
    s = s.replace("/// حسابات التجربة — تدخل بالرمز 123456 بدون SMS", "/// حسابات التجربة — تدخل بالرمز 1234 بدون رسالة")
    s = s.rstrip() + '''

/// خطأ من خدمة الرمز برسالة جاهزة للعرض
class OtpException implements Exception {
  OtpException(this.message);
  final String message;
  @override
  String toString() => message;
}
'''
    open(p, 'w', encoding='utf-8').write(s)

    p = 'lib/features/auth/phone_login_screen.dart'
    s = open(p, encoding='utf-8').read()
    old = "      if (mounted) showFnSnack(context, tr('تعذّر إرسال الرمز، تحقّق من الرقم'), error: true);"
    assert s.count(old) == 1
    s = s.replace(old, "      if (mounted) showFnSnack(context, e is OtpException ? tr(e.message) : tr('تعذّر إرسال الرمز، تحقّق من الرقم'), error: true);")
    open(p, 'w', encoding='utf-8').write(s)

    p = 'lib/features/auth/otp_screen.dart'
    s = open(p, encoding='utf-8').read()
    for old, new in [
        ("verifyOtp(widget.phone, EnglishDigitsFormatter.convert(_code));",
         "verifyOtp(widget.phone, EnglishDigitsFormatter.convert(_code), role: widget.role);"),
        ("    } catch (_) {\n      if (mounted) showFnSnack(context, tr('الرمز غير صحيح أو انتهت صلاحيته'), error: true);",
         "    } catch (e) {\n      if (mounted) showFnSnack(context, e is OtpException ? tr(e.message) : tr('الرمز غير صحيح أو انتهت صلاحيته'), error: true);"),
        ("    } catch (_) {\n      if (mounted) showFnSnack(context, tr('تعذّر الإرسال'), error: true);",
         "    } catch (e) {\n      if (mounted) showFnSnack(context, e is OtpException ? tr(e.message) : tr('تعذّر الإرسال'), error: true);"),
    ]:
        assert s.count(old) == 1, old[:50]
        s = s.replace(old, new)
    open(p, 'w', encoding='utf-8').write(s)

    p = 'lib/core/i18n/en.dart'
    s = open(p, encoding='utf-8').read()
    add = {
        'رقم الجوال غير صحيح': 'Invalid mobile number',
        'خدمة الرسائل غير مهيّأة': 'SMS service is not configured',
        'انتظر قليلًا قبل طلب رمز جديد': 'Please wait a moment before requesting a new code',
        'تجاوزت عدد المحاولات، حاول بعد ساعة': 'Too many attempts — try again in an hour',
        'تعذّر حفظ الرمز': 'Could not save the code',
        'تعذّر إرسال الرسالة': 'Could not send the SMS',
        'محاولات كثيرة — اطلب رمزًا جديدًا': 'Too many attempts — request a new code',
        'تعذّر تسجيل الدخول، حاول مجددًا': 'Could not sign in — please try again',
    }
    lines = ''.join(f"  '{k}': '{v}',\n" for k, v in add.items() if f"  '{k}':" not in s)
    s = s.replace("\n};\n", "\n" + lines.rstrip('\n') + "\n};\n")
    open(p, 'w', encoding='utf-8').write(s)
    print('✅ 009 applied')

if __name__ == '__main__':
    run(sys.argv[1] if len(sys.argv) > 1 else '.')
