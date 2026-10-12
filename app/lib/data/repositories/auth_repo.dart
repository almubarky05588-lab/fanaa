import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/utils/format.dart';
import '../models/profile.dart';

class AuthRepo {
  AuthRepo(this._c);
  final SupabaseClient _c;

  /// يرسل OTP عبر SMS. الدور يُحفظ في metadata ويقرأه المحفّز عند إنشاء profile.
  Future<void> sendOtp(String localPhone, {required UserRole role}) => _c.auth.signInWithOtp(
        phone: Fmt.toE164(localPhone),
        data: {'role': role.name},
      );

  Future<AuthResponse> verifyOtp(String localPhone, String token) => _c.auth.verifyOTP(
        type: OtpType.sms,
        phone: Fmt.toE164(localPhone),
        token: token,
      );

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
