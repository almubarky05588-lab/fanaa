import 'package:flutter/foundation.dart';

/// وضع «تسوّق كعميل» لصاحب المتجر — يسمح له بدخول واجهة العميل والشراء من المتاجر الأخرى.
abstract final class ShopMode {
  static final ValueNotifier<bool> active = ValueNotifier(false);
}
