import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/i18n.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/fn_widgets.dart';
import '../../data/repositories/auth_repo.dart';
import '../../data/repositories/content_repo.dart';

/// جرس الإشعارات بنقطة لغير المقروء — يُستخدم في رأس العميل والتاجر
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.radius});
  final double? radius;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Stack(clipBehavior: Clip.none, children: [
      FnIconButton(
        radius: radius,
        onTap: () => context.push('/notifications'),
        child: const Icon(Icons.notifications_none_rounded, size: 21, color: FnColors.ink),
      ),
      if (unread > 0)
        PositionedDirectional(
          top: 6, end: 6,
          child: Container(
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(color: FnColors.clay, borderRadius: BorderRadius.circular(8)),
            child: Center(child: Text(unread > 9 ? '9+' : '$unread', style: FnText.caption11.onDark.copyWith(fontSize: 9, height: 1.6))),
          ),
        ),
    ]);
  }
}

/// قائمة الإشعارات
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(AppNotification n) => switch (n.kind) {
        'new_order' => Icons.shopping_bag_outlined,
        'order_cancelled' => Icons.cancel_outlined,
        'order_status' => Icons.local_shipping_outlined,
        _ => Icons.campaign_outlined,
      };

  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    if (!n.isRead) {
      await ref.read(contentRepoProvider).markRead(n.id);
      ref.invalidate(notificationsProvider);
    }
    final id = n.orderId;
    if (id == null || !context.mounted) return;
    final merchant = ref.read(profileProvider).valueOrNull?.isMerchant == true && n.data['role'] == 'merchant';
    context.push(merchant ? '/m/order/$id' : '/order/$id');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    final hasUnread = ref.watch(unreadCountProvider) > 0;
    return Scaffold(
      appBar: FnAppBar(
        title: tr('الإشعارات'),
        action: hasUnread
            ? TextButton(
                onPressed: () async {
                  await ref.read(contentRepoProvider).markAllRead();
                  ref.invalidate(notificationsProvider);
                },
                child: Text(tr('قراءة الكل'), style: FnText.label13.primary),
              )
            : null,
      ),
      body: RefreshIndicator(
        color: FnColors.primary,
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: list.when(
          loading: () => const FnLoading(),
          error: (_, __) => FnError(onRetry: () => ref.invalidate(notificationsProvider)),
          data: (items) => items.isEmpty
              ? ListView(children: [
                  const SizedBox(height: 120),
                  FnEmpty(title: tr('لا توجد إشعارات'), subtitle: tr('تحديثات طلباتك والعروض تظهر هنا'), icon: Icons.notifications_none_rounded),
                ])
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(FnSpace.page, 8, FnSpace.page, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final n = items[i];
                    return FnCard(
                      onTap: () => _open(context, ref, n),
                      padding: const EdgeInsets.all(12),
                      color: n.isRead ? FnColors.surface : FnColors.soft,
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: n.isRead ? FnColors.bgBase : FnColors.surface, borderRadius: BorderRadius.circular(14)),
                          child: Icon(_icon(n), size: 20, color: FnColors.deep),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(n.displayTitle, style: FnText.bodyStrong15),
                          if (n.displayBody.isNotEmpty) Text(n.displayBody, style: FnText.caption11.muted),
                          const SizedBox(height: 2),
                          Text(Fmt.timeAgo(n.createdAt), style: FnText.caption11.faint),
                        ])),
                        if (!n.isRead)
                          Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 6),
                              decoration: const BoxDecoration(color: FnColors.clay, shape: BoxShape.circle)),
                      ]),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
