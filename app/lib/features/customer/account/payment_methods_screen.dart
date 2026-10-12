import 'package:flutter/material.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';

/// طرق الدفع المتاحة — البطاقات المحفوظة تُضاف بعد ربط بوابة الدفع
class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  static const _methods = [
    (Icons.apple, 'Apple Pay', 'ادفع بلمسة من جوالك'),
    (Icons.credit_card_rounded, 'مدى', 'بطاقات مدى السعودية'),
    (Icons.credit_card_outlined, 'بطاقة ائتمانية', 'فيزا وماستركارد'),
    (Icons.phone_iphone_rounded, 'STC Pay', 'المحفظة الرقمية'),
    (Icons.calendar_month_outlined, 'تابي', 'قسّمها على ٤ دفعات بدون فوائد'),
    (Icons.payments_outlined, 'الدفع عند الاستلام', 'نقدًا أو بالشبكة عند التوصيل'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const FnAppBar(title: 'طرق الدفع'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
          children: [
            Text('البطاقات المحفوظة', style: FnText.label13.muted),
            const SizedBox(height: 8),
            FnCard(
              child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.lock_outline_rounded, color: FnColors.deep, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Text('تُحفظ بطاقتك بأمان عند أول دفع لتستخدمها لاحقًا بضغطة واحدة',
                    style: FnText.caption11.muted)),
              ]),
            ),
            const SizedBox(height: 18),
            Text('طرق الدفع المتاحة', style: FnText.label13.muted),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                for (var i = 0; i < _methods.length; i++) ...[
                  FnListRow(
                    title: _methods[i].$2, subtitle: _methods[i].$3, icon: _methods[i].$1,
                    trailing: const Icon(Icons.check_circle_rounded, size: 18, color: FnColors.primary),
                  ),
                  if (i < _methods.length - 1) const FnDivider(),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.verified_user_outlined, size: 14, color: FnColors.faint),
              const SizedBox(width: 6),
              Text('مدفوعات مشفّرة ومتوافقة مع معايير PCI', style: FnText.caption11.faint),
            ]),
          ],
        ),
      );
}
