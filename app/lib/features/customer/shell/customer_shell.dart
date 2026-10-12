import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/shop_mode.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_bottom_nav.dart';
import '../../../data/repositories/auth_repo.dart';

const customerTabs = [
  FnNavItem('الرئيسية', Icons.home_outlined, Icons.home_rounded),
  FnNavItem('المتاجر', Icons.storefront_outlined, Icons.storefront_rounded),
  FnNavItem('السلة', Icons.shopping_bag_outlined, Icons.shopping_bag_rounded),
  FnNavItem('طلباتي', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
  FnNavItem('المزيد', Icons.grid_view_outlined, Icons.grid_view_rounded),
];

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.shell});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final merchant = ref.watch(profileProvider).valueOrNull?.isMerchant == true;
    return Scaffold(
      body: shell,
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        if (merchant) const _BackToStoreBar(),
        FnBottomNav(items: customerTabs, shell: shell),
      ]),
    );
  }
}

/// شريط يظهر لصاحب المتجر أثناء تسوّقه كعميل
class _BackToStoreBar extends StatelessWidget {
  const _BackToStoreBar();
  @override
  Widget build(BuildContext context) => Material(
        color: FnColors.deep,
        child: InkWell(
          onTap: () {
            ShopMode.active.value = false;
            context.go('/m/dashboard');
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FnSpace.page, vertical: 10),
            child: Row(children: [
              const Icon(Icons.shopping_bag_outlined, size: 16, color: FnColors.lime),
              const SizedBox(width: 8),
              Expanded(child: Text('أنت تتسوّق كعميل', style: FnText.label13.onDark)),
              Text('العودة لمتجري', style: FnText.label13.lime),
            ]),
          ),
        ),
      );
}
