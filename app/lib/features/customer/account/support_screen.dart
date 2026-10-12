import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../core/i18n/i18n.dart';

/// الدعم والمساعدة
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  static const _faq = [
    ('كم يستغرق التوصيل؟', 'يعتمد على المشتل، ويظهر وقت التجهيز والتوصيل في صفحة كل متجر. أغلب الطلبات تصل خلال ساعة داخل نطاق المتجر.'),
    ('هل يمكنني إلغاء الطلب؟', 'نعم، يمكنك إلغاء الطلب من شاشة التتبع قبل أن يقبله المشتل. بعد القبول تواصل مع المشتل مباشرة.'),
    ('كيف أستخدم كوبون الخصم؟', 'أدخل الكود في خانة الكوبون داخل السلة واضغط «تطبيق»، وسيظهر الخصم في الإجمالي.'),
    ('ماذا لو وصلت النبتة تالفة؟', 'صوّر النبتة فور الاستلام وتواصل معنا خلال ٢٤ ساعة، وسنعمل مع المشتل على الاستبدال أو الاسترجاع.'),
    ('هل الأسعار شاملة الضريبة؟', 'نعم، جميع الأسعار شاملة ضريبة القيمة المضافة ١٥٪، وتصلك فاتورة ضريبية إلكترونية بعد التوصيل.'),
    ('كيف أسجّل مشتلي في فناء؟', 'من شاشة اختيار نوع الحساب اختر «صاحب متجر» وسجّل برقم جوالك، ثم أكمل بيانات مشتلك.'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: FnAppBar(title: tr('الدعم والمساعدة')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 24),
          children: [
            Row(children: [
              _Contact(icon: Icons.chat_outlined, label: tr('واتساب'),
                  onTap: () => launchUrl(Uri.parse('https://wa.me/${Env.supportWhatsapp}'), mode: LaunchMode.externalApplication)),
              const SizedBox(width: 10),
              _Contact(icon: Icons.call_outlined, label: tr('اتصال'), onTap: () => launchUrl(Uri.parse('tel:${Env.supportPhone}'))),
              const SizedBox(width: 10),
              _Contact(icon: Icons.mail_outline_rounded, label: tr('البريد'), onTap: () => launchUrl(Uri.parse('mailto:${Env.supportEmail}'))),
            ]),
            const SizedBox(height: 18),
            Text(tr('الأسئلة الشائعة'), style: FnText.label13.muted),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Column(children: [
                  for (var i = 0; i < _faq.length; i++) ...[
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      iconColor: FnColors.deep, collapsedIconColor: FnColors.faint,
                      title: Text(tr(_faq[i].$1), style: FnText.bodyStrong15),
                      expandedAlignment: AlignmentDirectional.centerStart,
                      children: [Text(tr(_faq[i].$2), style: FnText.body15.muted)],
                    ),
                    if (i < _faq.length - 1) const FnDivider(),
                  ],
                ]),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: FnColors.surface, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                FnListRow(title: tr('سياسة الخصوصية'), icon: Icons.privacy_tip_outlined, onTap: () => context.push('/legal/privacy')),
                const FnDivider(),
                FnListRow(title: tr('الشروط والأحكام'), icon: Icons.description_outlined, onTap: () => context.push('/legal/terms')),
              ]),
            ),
          ],
        ),
      );
}

class _Contact extends StatelessWidget {
  const _Contact({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
        child: FnCard(
          onTap: onTap, radius: 18,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: FnColors.soft, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: FnColors.deep, size: 20)),
            const SizedBox(height: 8),
            Text(label, style: FnText.label13),
          ]),
        ),
      );
}
