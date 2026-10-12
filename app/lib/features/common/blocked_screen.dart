import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/i18n.dart';
import '../../core/router/shop_mode.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fn_widgets.dart';
import '../../data/repositories/auth_repo.dart';

/// يظهر لمن أوقفت الإدارة حسابه
class BlockedScreen extends ConsumerWidget {
  const BlockedScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(FnSpace.page),
            child: Column(children: [
              const Spacer(),
              Container(
                width: 84, height: 84,
                decoration: BoxDecoration(color: const Color(0xFFF6E9E1), borderRadius: BorderRadius.circular(28)),
                child: const Icon(Icons.block_rounded, size: 40, color: FnColors.clay),
              ),
              const SizedBox(height: 18),
              Text(tr('تم إيقاف حسابك'), style: FnText.title22, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(tr('لا يمكنك استخدام فناء حاليًا. إذا تعتقد أن هذا خطأ تواصل مع الدعم.'),
                  style: FnText.body15.muted, textAlign: TextAlign.center),
              const Spacer(),
              FnButton(label: tr('الدعم والمساعدة'), onPressed: () => context.push('/support')),
              const SizedBox(height: 10),
              FnButton(
                label: tr('تسجيل الخروج'), color: FnColors.bgBase, textColor: FnColors.ink,
                onPressed: () async {
                  ShopMode.active.value = false;
                  await ref.read(authRepoProvider).signOut();
                  if (context.mounted) context.go('/auth/type');
                },
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
      );
}
