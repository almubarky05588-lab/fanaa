import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// يحفظ الوجهة التي يرجع لها المستخدم بعد تسجيل الدخول
abstract final class AuthRedirect {
  static String? pending;
  static String? take() {
    final t = pending;
    pending = null;
    return t;
  }
}

/// يفتح شاشة الدخول ويعود لـ [from] بعد التحقق
void goLogin(BuildContext context, {String? from}) {
  AuthRedirect.pending = from;
  context.push('/auth/login');
}

/// المسارات التي تتطلب تسجيل دخول العميل (الباقي متاح للزائر)
bool customerRouteNeedsAuth(String loc) =>
    loc.startsWith('/checkout') ||
    loc.startsWith('/payment') ||
    loc.startsWith('/order/') ||
    loc.startsWith('/invoice/') ||
    loc == '/account' ||
    loc == '/addresses';
