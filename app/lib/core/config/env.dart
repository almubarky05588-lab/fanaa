/// إعدادات البيئة — تُمرَّر عبر --dart-define في الإنتاج،
/// والقيم الافتراضية هنا للتطوير فقط (المفتاح publishable عام بطبيعته).
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kzeawenrpvkfmeslxylz.supabase.co',
  );

  static const supabaseKey = String.fromEnvironment(
    'SUPABASE_KEY',
    defaultValue: 'sb_publishable_XT_5L19jAeOu-jOa6Ag61A_Sv1MgoSX',
  );

  /// مفتاح خرائط قوقل — يُضبط لكل منصة في AndroidManifest و AppDelegate،
  /// وهنا فقط لاستدعاءات Places/Geocoding إن وُجدت.
  static const mapsKey = String.fromEnvironment('MAPS_KEY', defaultValue: '');

  // بيانات الدعم — تُحدَّث ببيانات العميل الفعلية قبل الإطلاق
  static const supportWhatsapp = '966500000000';
  static const supportPhone = '0500000000';
  static const supportEmail = 'support@fenaa.sa';

  static const appName = 'فناء';
  static const vatRate = 0.15;
  static const currency = 'ر.س';
}
