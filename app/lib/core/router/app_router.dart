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
import '../../features/customer/account/account_screen.dart';
import '../../features/customer/account/addresses_screen.dart';
import '../../features/customer/cart/cart_screen.dart';
import '../../features/customer/checkout/checkout_screen.dart';
import '../../features/customer/checkout/checkout_state.dart';
import '../../features/customer/home/home_screen.dart';
import '../../features/customer/map/map_screen.dart';
import '../../features/customer/orders/invoice_screen.dart';
import '../../features/customer/orders/my_orders_screen.dart';
import '../../features/customer/orders/tracking_screen.dart';
import '../../features/customer/payment/card_details_screen.dart';
import '../../features/customer/payment/payment_screen.dart';
import '../../features/customer/payment/payment_success_screen.dart';
import '../../features/customer/product/product_screen.dart';
import '../../features/customer/shell/customer_shell.dart';
import '../../features/customer/store/store_screen.dart';
import '../../features/customer/stores/stores_screen.dart';
import '../../features/merchant/dashboard/merchant_dashboard_screen.dart';
import '../../features/merchant/orders/merchant_order_detail_screen.dart';
import '../../features/merchant/orders/merchant_orders_screen.dart';
import '../../features/merchant/products/add_product_screen.dart';
import '../../features/merchant/products/merchant_products_screen.dart';
import '../../features/merchant/settings/merchant_settings_screen.dart';
import '../../features/merchant/setup/merchant_setup_screen.dart';
import '../../features/merchant/shell/merchant_shell.dart';
import '../../features/merchant/wallet/merchant_wallet_screen.dart';
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

  GoRoute top(String path, Widget Function(GoRouterState s) b) =>
      GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (_, s) => b(s));

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final loc = state.matchedLocation;
      final inAuth = loc.startsWith('/auth');
      if (!loggedIn) return inAuth ? null : '/auth/type';
      if (inAuth) return '/splash';
      if (loc == '/splash') return null;
      final p = ref.read(profileProvider).valueOrNull;
      if (p == null) return null;
      final merchantArea = loc.startsWith('/m/');
      // الفاتورة مشتركة بين الطرفين
      if (loc.startsWith('/invoice/')) return null;
      if (p.isMerchant && !merchantArea) return '/m/dashboard';
      if (!p.isMerchant && merchantArea) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),

      // ------------------------------------------------------------ المصادقة
      GoRoute(path: '/auth/type', builder: (_, __) => const AccountTypeScreen()),
      GoRoute(path: '/auth/login', builder: (_, s) => PhoneLoginScreen(role: (s.extra as UserRole?) ?? UserRole.customer)),
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
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, __) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/stores', builder: (_, __) => const StoresScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/cart', builder: (_, s) => CartScreen(isTab: true, nurseryId: s.uri.queryParameters['nursery']))]),
          StatefulShellBranch(routes: [GoRoute(path: '/orders', builder: (_, __) => const MyOrdersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/more', builder: (_, __) => const AccountScreen())]),
        ],
      ),
      top('/map', (_) => const MapScreen()),
      top('/store/:id', (s) => StoreScreen(id: s.pathParameters['id']!)),
      top('/product/:id', (s) => ProductScreen(id: s.pathParameters['id']!)),
      top('/checkout/:nurseryId', (s) => CheckoutScreen(nurseryId: s.pathParameters['nurseryId']!)),
      top('/payment', (_) => const PaymentScreen()),
      top('/payment/card', (s) => CardDetailsScreen(method: (s.extra as PayMethod?) ?? PayMethod.mada)),
      top('/payment/success/:orderId', (s) => PaymentSuccessScreen(orderId: s.pathParameters['orderId']!)),
      top('/order/:id', (s) => TrackingScreen(orderId: s.pathParameters['id']!)),
      top('/invoice/:orderId', (s) => InvoiceScreen(orderId: s.pathParameters['orderId']!)),
      top('/account', (_) => const AccountScreen(isTab: false)),
      top('/addresses', (s) => AddressesScreen(openAdd: s.uri.queryParameters['add'] == '1')),

      // -------------------------------------------------------------- التاجر
      top('/m/setup', (_) => const MerchantSetupScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MerchantShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/m/dashboard', builder: (_, __) => const MerchantDashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/m/orders', builder: (_, __) => const MerchantOrdersScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/m/products', builder: (_, __) => const MerchantProductsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/m/wallet', builder: (_, __) => const MerchantWalletScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/m/settings', builder: (_, __) => const MerchantSettingsScreen())]),
        ],
      ),
      top('/m/order/:id', (s) => MerchantOrderDetailScreen(id: s.pathParameters['id']!)),
      top('/m/products/new', (_) => const AddProductScreen()),
    ],
  );
});
