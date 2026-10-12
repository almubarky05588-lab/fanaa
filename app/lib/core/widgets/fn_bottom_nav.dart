import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/tokens.dart';

class FnNavItem {
  const FnNavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// شريط تنقّل سفلي مطابق للتصميم: أبيض، التبويب النشط داخل مربع أخضر فاتح 44×30
class FnBottomNav extends StatelessWidget {
  const FnBottomNav({super.key, required this.items, required this.shell});
  final List<FnNavItem> items;
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: FnColors.surface,
          boxShadow: [BoxShadow(color: Color(0x0F0B2E20), blurRadius: 12, offset: Offset(0, -3))],
        ),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < items.length; i++)
                _Tab(item: items[i], active: shell.currentIndex == i,
                    onTap: () => shell.goBranch(i, initialLocation: i == shell.currentIndex)),
            ],
          ),
        ),
      );
}

class _Tab extends StatelessWidget {
  const _Tab({required this.item, required this.active, required this.onTap});
  final FnNavItem item;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 64,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: active ? 44 : 30, height: 30,
              decoration: BoxDecoration(color: active ? FnColors.soft : Colors.transparent, borderRadius: BorderRadius.circular(12)),
              child: Icon(active ? item.activeIcon : item.icon, size: 20, color: active ? FnColors.deep : FnColors.faint),
            ),
            const SizedBox(height: 4),
            Text(item.label, style: active ? FnText.caption11.deep : FnText.caption11.muted),
          ]),
        ),
      );
}
