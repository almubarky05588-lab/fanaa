import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/repositories/auth_repo.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fn_logo.dart';

/// شاشة البداية — تنتظر البروفايل ثم توجّه حسب الدور
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(profileProvider, (_, next) {
      next.whenData((p) {
        if (!context.mounted) return;
        if (p == null) {
          context.go('/auth/type');
        } else {
          context.go(p.isMerchant ? '/m/dashboard' : '/home');
        }
      });
    });
    return const Scaffold(
      backgroundColor: FnColors.deep,
      body: Center(child: FnLogoLockup(markSize: 56, markColor: FnColors.lime)),
    );
  }
}
