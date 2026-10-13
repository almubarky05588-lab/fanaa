import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

/// يفتح دفع ماي فاتورة في Safari الآمن داخل التطبيق (يدعم Apple Pay)،
/// ويُغلق تلقائيًا عندما تحوّل صفحة الرجوع (fanaa-15r.pages.dev/pay/...) إلى fenaa://pay/...
/// يرجع true لو وصل لرابط النجاح — التأكيد الفعلي يتم بالخادم بعدها
abstract final class PayWebViewScreen {
  static Future<bool?> open(BuildContext context, String url) async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: url,
        callbackUrlScheme: 'fenaa',
        // جلسة مستقلة: بدون نافذة «يريد استخدام موقع لتسجيل الدخول»
        options: const FlutterWebAuth2Options(preferEphemeral: true),
      );
      return Uri.parse(result).path.contains('done');
    } catch (_) {
      // أغلق العميل الصفحة — نتحقق من الخادم على أي حال
      return false;
    }
  }
}
