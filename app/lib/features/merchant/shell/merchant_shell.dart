import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/fn_bottom_nav.dart';

const merchantTabs = [
  FnNavItem('الرئيسية', Icons.home_outlined, Icons.home_rounded),
  FnNavItem('الطلبات', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded),
  FnNavItem('المنتجات', Icons.grid_view_outlined, Icons.grid_view_rounded),
  FnNavItem('المحفظة', Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded),
  FnNavItem('الإعدادات', Icons.settings_outlined, Icons.settings_rounded),
];

class MerchantShell extends StatelessWidget {
  const MerchantShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: FnBottomNav(items: merchantTabs, shell: shell),
      );
}
