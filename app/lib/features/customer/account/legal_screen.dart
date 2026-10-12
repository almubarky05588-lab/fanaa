import 'package:flutter/material.dart';
import '../../../core/config/env.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/fn_widgets.dart';
import '../../../core/i18n/i18n.dart';

/// سياسة الخصوصية والشروط — نص مبدئي يُراجَع قانونيًا قبل الإطلاق
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.kind});
  final String kind; // privacy | terms

  @override
  Widget build(BuildContext context) {
    final privacy = kind == 'privacy';
    final sections = privacy ? _privacy : _terms;
    return Scaffold(
      appBar: FnAppBar(title: privacy ? tr('سياسة الخصوصية') : tr('الشروط والأحكام')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(FnSpace.page, 6, FnSpace.page, 32),
        children: [
          Text(tr('آخر تحديث: أكتوبر ٢٠٢٦'), style: FnText.caption11.faint),
          const SizedBox(height: 12),
          for (final s in sections) ...[
            Text(tr(s.$1), style: FnText.heading18),
            const SizedBox(height: 6),
            Text(tr(s.$2), style: FnText.body15.muted.copyWith(height: 1.8)),
            const SizedBox(height: 18),
          ],
          Text(tr('للتواصل: {0}', [Env.supportEmail]), style: FnText.label13.primary),
        ],
      ),
    );
  }

  static const _privacy = [
    ('البيانات التي نجمعها', 'رقم الجوال للتسجيل والتحقق، والاسم، وعناوين التوصيل التي تحفظها، وموقعك الجغرافي عند السماح بذلك لعرض المشاتل القريبة، وتفاصيل طلباتك.'),
    ('كيف نستخدمها', 'لتنفيذ طلباتك وتوصيلها، وإصدار الفواتير الضريبية، والتواصل معك بخصوص طلباتك، وتحسين خدماتنا. لا نبيع بياناتك لأي طرف.'),
    ('مشاركة البيانات', 'نشارك مع المشتل الذي تطلب منه الاسم ورقم الجوال وعنوان التوصيل فقط لتنفيذ الطلب. تتم معالجة الدفع عبر مزوّد دفع مرخّص، ولا نحفظ بيانات بطاقتك على خوادمنا.'),
    ('حماية البيانات', 'تُحفظ البيانات في خوادم مشفّرة، والوصول إليها مقيّد بصلاحيات صارمة.'),
    ('حقوقك', 'يمكنك تعديل بياناتك من حسابك، وطلب حذف حسابك وبياناتك بالتواصل معنا.'),
  ];

  static const _terms = [
    ('عن فناء', 'فناء منصة تربط العملاء بالمشاتل ومتاجر النباتات. المشتل هو البائع والمسؤول عن جودة المنتج وتجهيزه وتوصيله.'),
    ('الطلبات والأسعار', 'الأسعار يحددها كل مشتل وتشمل ضريبة القيمة المضافة. يحق للمشتل قبول الطلب أو رفضه، وفي حال الرفض بعد الدفع يُسترد المبلغ كاملًا.'),
    ('الإلغاء والاسترجاع', 'يمكن إلغاء الطلب قبل قبول المشتل له. في حال وصول منتج تالف يُبلَّغ عنه خلال ٢٤ ساعة من الاستلام مع صورة توضيحية.'),
    ('الكوبونات', 'لكل كوبون شروطه (الحد الأدنى، مدة الصلاحية، عدد مرات الاستخدام)، ولا يمكن استبداله نقدًا.'),
    ('أصحاب المتاجر', 'يلتزم صاحب المتجر بصحة بيانات منتجاته وأسعاره، وتُخصم عمولة المنصة المتفق عليها من كل طلب مكتمل.'),
  ];
}
