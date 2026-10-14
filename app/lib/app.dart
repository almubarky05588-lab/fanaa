import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/env.dart';
import 'core/i18n/i18n.dart';
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
    // تغيير اللغة يعيد بناء التطبيق كاملًا (المفتاح) مع الحفاظ على الشاشة الحالية في الموجّه
    return ValueListenableBuilder<String>(
      valueListenable: AppLang.code,
      builder: (context, lang, _) {
        final en = lang == 'en';
        return MaterialApp.router(
          key: ValueKey(lang),
          title: en ? 'Fenaa' : Env.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          routerConfig: router,
          locale: en ? const Locale('en') : const Locale('ar', 'SA'),
          supportedLocales: const [Locale('ar', 'SA'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) => GestureDetector(
            // الضغط خارج خانات الكتابة ينزّل الكيبورد
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: Directionality(
              textDirection: en ? TextDirection.ltr : TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
