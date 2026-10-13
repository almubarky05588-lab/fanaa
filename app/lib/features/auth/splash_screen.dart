import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fn_logo.dart';
import '../../data/local/guest_cart.dart';
import '../../data/repositories/auth_repo.dart';

/// شاشة البداية — توجّه حسب: مسجّل (حسب الدور) / زائر اختار "مستخدم" / أول مرة
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final auth = ref.read(supabaseProvider).auth;
    String target = '/auth/type';
    try {
      if (auth.currentUser == null) {
        target = (await AppPrefs.roleChoice()) == 'customer' ? '/home' : '/auth/type';
      } else {
        ref.invalidate(profileProvider);
        final p = await ref.read(profileProvider.future).timeout(const Duration(seconds: 8));
        target = p == null ? '/auth/type' : (p.isMerchant ? '/m/dashboard' : '/home');
      }
    } on AuthException {
      // الجلسة انتهت ولا يمكن تجديدها — دخول من جديد
      await auth.signOut().catchError((_) {});
      target = '/auth/type';
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST301' || e.message.toLowerCase().contains('jwt')) {
        await auth.signOut().catchError((_) {});
        target = '/auth/type';
      } else {
        target = '/home';
      }
    } catch (_) {
      // بطء أو انقطاع: نكمل بدل التعليق (الشاشات تعيد المحاولة بنفسها)
      target = '/home';
    }
    if (mounted) context.go(target);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: FnColors.deep,
        body: Center(child: FnLogoLockup(markSize: 56, markColor: FnColors.lime)),
      );
}
