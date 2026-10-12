import 'package:intl/intl.dart';

/// تنسيقات العرض — الأرقام الغربية (0-9) حسب قرار التصميم، والعملة ر.س.
abstract final class Fmt {
  static final _money = NumberFormat('#,##0.00', 'en');
  static final _int = NumberFormat('#,##0', 'en');

  static String money(num v) => '${_money.format(v)} ر.س';
  static String moneyShort(num v) =>
      v == v.roundToDouble() ? '${_int.format(v)} ر.س' : money(v);

  static String km(double v) => '${v.toStringAsFixed(1)} كم';
  static String minutes(int m) => '$m د';

  /// +966 5X XXX XXXX
  static String phone(String p) {
    var d = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('966')) d = d.substring(3);
    d = d.replaceFirst(RegExp(r'^0+'), '');
    if (d.length == 9) {
      return '+966 ${d.substring(0, 2)} ${d.substring(2, 5)} ${d.substring(5)}';
    }
    return p;
  }

  /// يحوّل الإدخال المحلي 5xxxxxxxx (أو 05xxxxxxxx) إلى E.164 (+9665xxxxxxxx)
  static String toE164(String input) {
    var d = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('00')) d = d.substring(2);
    if (d.startsWith('0')) d = d.substring(1);
    if (!d.startsWith('966')) d = '966$d';
    return '+$d';
  }

  static String date(DateTime d) => DateFormat('d MMMM yyyy', 'ar').format(d);
  static String time(DateTime d) => DateFormat('h:mm a', 'ar').format(d);
  static String dateTime(DateTime d) => '${date(d)} — ${time(d)}';

  static String timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return 'منذ ${diff.inDays} يوم';
  }
}
