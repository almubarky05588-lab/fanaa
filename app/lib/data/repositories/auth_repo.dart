import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/format.dart';
import '../models/profile.dart';

/// حسابات التجربة — تدخل بالرمز 1234 بدون رسالة (للاختبار ومراجعة Apple).
/// تُحذف قبل الإطلاق التجاري أو بعد ربط مزوّد SMS.
const _demoAccounts = {
  '+966500000001': 'demo.customer@fenaa.app',   // عميل
  '+966500000002': 'demo.merchant@fenaa.app',   // مشتل الروضة
  '+966500000003': 'demo.merchant2@fenaa.app',  // مشتل الياسمين
};

class AuthRepo {
  AuthRepo(this._c);
  final SupabaseClient _c;

  bool isDemo(String localPhone) => _demoAccounts.containsKey(Fmt.toE164(localPhone));

  /// يرسل رمزًا من ٤ أرقام عبر فورجوالي (دالة الخادم otp-send)
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

  Future<Profile?> myProfile() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return null;
    final j = await _c.from('profiles').select().eq('id', uid).maybeSingle();
    return j == null ? null : Profile.fromJson(j);
  }

  Future<void> updateName(String name) async {
    final uid = _c.auth.currentUser!.id;
    await _c.from('profiles').update({'full_name': name}).eq('id', uid);
  }

  Future<void> signOut() => _c.auth.signOut();
}

final authRepoProvider = Provider((ref) => AuthRepo(ref.watch(supabaseProvider)));

/// البروفايل الحالي — يُعاد تحميله عند تغيّر حالة المصادقة.
final profileProvider = FutureProvider<Profile?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepoProvider).myProfile();
});

/// خطأ من خدمة الرمز برسالة جاهزة للعرض
class OtpException implements Exception {
  OtpException(this.message);
  final String message;
  @override
  String toString() => message;
}
