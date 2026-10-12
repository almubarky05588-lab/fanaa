import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/auth_repo.dart';
import 'data/repositories/order_repo.dart';

class FenaaApp extends ConsumerWidget {
  const FenaaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // عند تسجيل الدخول: ادمج سلة الزائر المحفوظة محليًا في سلة الحساب
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) async {
      final ev = next.valueOrNull?.event;
      if (ev == AuthChangeEvent.signedIn) {
        await ref.read(orderRepoProvider).mergeGuestCart();
        ref.invalidate(cartsProvider);
        ref.invalidate(profileProvider);
      } else if (ev == AuthChangeEvent.signedOut) {
        ref.invalidate(cartsProvider);
        ref.invalidate(profileProvider);
        ref.invalidate(myOrdersProvider);
      }
    });

    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: Env.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [Locale('ar', 'SA'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
