import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/shop_mode.dart';
import '../../../core/widgets/fn_bottom_nav.dart';

const customerTabs = [
  FnNavItem('الرئيسية', Icons.home_outlined, Icons.home_rounded),
  FnNavItem('المتاجر', Icons.storefront_outlined, Icons.storefront_rounded),
  FnNavItem('السلة', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded),
  FnNavItem('طلباتي', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  FnNavItem('المزيد', Icons.grid_view_outlined, Icons.grid_view_rounded),
];

/// العودة من وضع «تسوّق كعميل» إلى لوحة التاجر
void backToMyStore(BuildContext context) {
  ShopMode.active.value = false;
  context.go('/m/dashboard');
}

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context) => Scaffold(
        body: shell,
        bottomNavigationBar: FnBottomNav(items: customerTabs, shell: shell),
      );
}
