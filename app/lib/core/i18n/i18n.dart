import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'en.dart';

/// لغة التطبيق الحالية — تُحفظ على الجهاز، وتغييرها يعيد بناء التطبيق كاملًا
abstract final class AppLang {
  static final ValueNotifier<String> code = ValueNotifier('ar');
  static const _key = 'fenaa.lang';

  static bool get isEn => code.value == 'en';

  static Future<void> load() async {
    final v = (await SharedPreferences.getInstance()).getString(_key);
    if (v == 'ar' || v == 'en') code.value = v!;
  }

  static Future<void> set(String v) async {
    code.value = v;
    await (await SharedPreferences.getInstance()).setString(_key, v);
  }
}

/// يترجم النص العربي حسب لغة التطبيق. القيم المتغيرة تُمرَّر بالترتيب وتحل محل {0} و {1} …
String tr(String ar, [List<Object?> args = const []]) {
  var s = AppLang.isEn ? (kEn[ar] ?? ar) : ar;
  for (var i = 0; i < args.length; i++) {
    s = s.replaceAll('{$i}', '${args[i] ?? ''}');
  }
  return s;
}
