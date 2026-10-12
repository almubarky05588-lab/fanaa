import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/auth_repo.dart';
import '../../features/auth/account_type_screen.dart';
import '../../features/auth/otp_screen.dart';
import '../../features/auth/phone_login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/common/placeholder_screen.dart';
import '../../features/customer/shell/customer_shell.dart';
import '../../features/merchant/shell/merchant_shell.dart';
import '../supabase/supabase_client.dart';

class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Stream<dynamic> s) { _sub = s.listen((_) => notifyListeners()); }
  late final StreamSubscription _sub;
  @override
  void dispose() { _sub.cancel(); super.dispose(); }
}

final _rootKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(supabaseProvider).auth;
  final notifier = _AuthNotifier(auth.onAuthStateChange);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      final inAuth = loc.startsWith('/auth');
      if (!loggedIn) return (inAuth) ? null : '/auth/type';
      if (inAuth) return '/splash';
      if (loc == '/splash') return null;
      final p = ref.read(profileProvider).valueOrNull;
      if (p == null) return null;
      final merchantArea = loc.startsWith('/m/');
      if (p.isMerchant && !merchantArea) return '/m/dashboard';
      if (!p.isMerchant && merchantArea) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

      // ------------------------------------------------------------ المصادقة
      GoRoute(path: '/auth/type', builder: (_, __) => const AccountTypeScreen()),
      GoRoute(
        path: '/auth/login',
        builder: (_, s) => PhoneLoginScreen(role: (s.extra as UserRole?) ?? UserRole.customer),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (_, s) {
          final e = (s.extra as Map?) ?? const {};
          return OtpScreen(phone: e['phone'] as String? ?? '', role: (e['role'] as UserRole?) ?? UserRole.customer);
        },
      ),

      // -------------------------------------------------------------- العميل
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => CustomerShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const PlaceholderScreen('الرئيسية', showBack: false))]),
          StatefulShellBranch(routes: [GoRoute(path: '/stores', builder: (_, __) => const PlaceholderScreen('المتاجر', showBack: false))]),
          StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (_, __) => const PlaceholderScreen('السلة', showBack: false))]),
          StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (_, __) => const PlaceholderScreen('طلباتي', showBack: false))]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (_, __) => const PlaceholderScreen('المزيد', showBack: false))]),
        ],
      ),
      GoRoute(path: '/map', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('الخريطة')),
      GoRoute(path: '/store/:id', parentNavigatorKey: _rootKey, builder: (_, s) => PlaceholderScreen('المتجر ${s.pathParameters['id']}')),
      GoRoute(path: '/product/:id', parentNavigatorKey: _rootKey, builder: (_, s) => PlaceholderScreen('المنتج ${s.pathParameters['id']}')),
      GoRoute(path: '/checkout/:nurseryId', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('إتمام الطلب')),
      GoRoute(path: '/payment', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('الدفع')),
      GoRoute(path: '/payment/card', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('بيانات البطاقة')),
      GoRoute(path: '/payment/success/:orderId', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('نجاح الدفع')),
      GoRoute(path: '/order/:id', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('تتبع الطلب')),
      GoRoute(path: '/invoice/:orderId', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('الفاتورة')),
      GoRoute(path: '/account', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('حسابي')),
      GoRoute(path: '/addresses', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('العناوين')),

      // -------------------------------------------------------------- التاجر
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MerchantShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/m/dashboard', builder: (_, __) => const PlaceholderScreen('لوحة التاجر', showBack: false))]),
          StatefulShellBranch(routes: [GoRoute(path: '/m/orders', builder: (_, __) => const PlaceholderScreen('الطلبات الواردة', showBack: false))]),
          StatefulShellBranch(routes: [GoRoute(path: '/m/products', builder: (_, __) => const PlaceholderScreen('المنتجات', showBack: false))]),
          StatefulShellBranch(routes: [GoRoute(path: '/m/wallet', builder: (_, __) => const PlaceholderScreen('المحفظة', showBack: false))]),
          StatefulShellBranch(routes: [GoRoute(path: '/m/settings', builder: (_, __) => const PlaceholderScreen('إعدادات المتجر', showBack: false))]),
        ],
      ),
      GoRoute(path: '/m/order/:id', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('تفاصيل الطلب')),
      GoRoute(path: '/m/products/new', parentNavigatorKey: _rootKey, builder: (_, __) => const PlaceholderScreen('إضافة منتج')),
    ],
  );
});
