import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/format.dart';
import '../models/profile.dart';

/// حسابات التجربة — تدخل بالرمز 123456 بدون SMS (للاختبار ومراجعة Apple).
/// تُحذف قبل الإطلاق التجاري أو بعد ربط مزوّد SMS.
const _demoAccounts = {
  '+966500000001': 'demo.customer@fenaa.app',
  '+966500000002': 'demo.merchant@fenaa.app',
};

class AuthRepo {
  AuthRepo(this._c);
  final SupabaseClient _c;

  bool isDemo(String localPhone) => _demoAccounts.containsKey(Fmt.toE164(localPhone));

  /// يرسل OTP عبر SMS. الدور يُحفظ في metadata ويقرأه المحفّز عند إنشاء profile.
  Future<void> sendOtp(String localPhone, {required UserRole role}) async {
    if (isDemo(localPhone)) return; // حساب تجريبي — لا رسالة
    await _c.auth.signInWithOtp(phone: Fmt.toE164(localPhone), data: {'role': role.name});
  }

  Future<AuthResponse> verifyOtp(String localPhone, String token) {
    final e164 = Fmt.toE164(localPhone);
    final demoEmail = _demoAccounts[e164];
    if (demoEmail != null) {
      return _c.auth.signInWithPassword(email: demoEmail, password: token);
    }
    return _c.auth.verifyOTP(type: OtpType.sms, phone: e164, token: token);
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
