import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final user = ref.read(supabaseProvider).auth.currentUser;
    String target;
    if (user == null) {
      target = (await AppPrefs.roleChoice()) == 'customer' ? '/home' : '/auth/type';
    } else {
      ref.invalidate(profileProvider);
      final p = await ref.read(profileProvider.future);
      target = p == null ? '/auth/type' : (p.isMerchant ? '/m/dashboard' : '/home');
    }
    if (mounted) context.go(target);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: FnColors.deep,
        body: Center(child: FnLogoLockup(markSize: 56, markColor: FnColors.lime)),
      );
}
