import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../data/models/order.dart';
import '../../../data/repositories/order_repo.dart';
import '../checkout/checkout_state.dart';
import '../../../core/i18n/i18n.dart';

final orderProvider = FutureProvider.family<Order?, String>((ref, id) => ref.watch(orderRepoProvider).order(id));

/// 11b نجاح الدفع / تأكيد الطلب
class PaymentSuccessScreen extends ConsumerWidget {
  const PaymentSuccessScreen({super.key, required this.orderId});
  final String orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = ref.watch(orderProvider(orderId)).valueOrNull;
    final method = o?.paymentMethod;
    final methodTitle = PayMethod.values.where((m) => m.db == method).firstOrNull?.title ?? '—';
    final paid = o?.paymentStatus == 'paid';
    return Scaffold(
      backgroundColor: FnColors.deep,
      body: Stack(children: [
        Positioned(left: -90, top: -110, child: _c(320)),
        Positioned(right: -80, top: 120, child: _c(220)),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: FnSpace.page),
            child: Column(children: [
              const Spacer(),
              Container(
                width: 108, height: 108,
                decoration: BoxDecoration(color: FnColors.lime, shape: BoxShape.circle, boxShadow: FnShadow.raised),
                child: const Icon(Icons.check_rounded, size: 56, color: FnColors.deep),
              ),
              const SizedBox(height: 18),
              Text(method == 'cod' || !paid ? tr('تم تأكيد طلبك') : tr('تم الدفع بنجاح'), style: FnText.display28.onDark),
              const SizedBox(height: 6),
              Text(tr('استلم المشتل طلبك وسيبدأ التجهيز خلال دقائق'), style: FnText.body15.soft, textAlign: TextAlign.center),
              const SizedBox(height: 22),
              FnCard(
                radius: 22,
                padding: const EdgeInsets.all(18),
                child: Column(children: [
                  FnKV(tr('رقم الطلب'), o == null ? '—' : '#${o.orderNumber}'),
                  FnKV(tr('المشتل'), o?.nursery?.name ?? '—'),
                  FnKV(tr('طريقة الدفع'), methodTitle),
                  FnKV(tr('الوصول المتوقع'), tr('٤٥ دقيقة')),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: FnDivider()),
                  FnKV(paid ? tr('المدفوع') : tr('المستحق'), o == null ? '—' : Fmt.money(o.total), strong: true),
                ]),
              ),
              const Spacer(),
              FnButton(label: tr('تتبّع الطلب'), color: FnColors.lime, textColor: FnColors.deep, onPressed: () => context.go('/order/$orderId')),
              const SizedBox(height: 10),
              FnGhostButton(label: tr('العودة للرئيسية'), borderColor: FnColors.primary, textColor: FnColors.surface, height: 58,
                  onPressed: () => context.go('/home')),
              const SizedBox(height: 12),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _c(double d) => Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, color: FnColors.primary.withValues(alpha: .32)));
}
