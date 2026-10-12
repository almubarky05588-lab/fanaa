import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// عنصر في سلة الزائر (بدون تسجيل) — يُحفظ محليًا على الجهاز
class GuestCartEntry {
  const GuestCartEntry({required this.nurseryId, required this.productId, this.variantId, required this.qty});
  final String nurseryId;
  final String productId;
  final String? variantId;
  final int qty;

  String get key => '$productId|${variantId ?? ''}';

  GuestCartEntry withQty(int q) => GuestCartEntry(nurseryId: nurseryId, productId: productId, variantId: variantId, qty: q);

  Map<String, dynamic> toJson() => {'n': nurseryId, 'p': productId, 'v': variantId, 'q': qty};
  factory GuestCartEntry.fromJson(Map<String, dynamic> j) =>
      GuestCartEntry(nurseryId: j['n'], productId: j['p'], variantId: j['v'], qty: j['q']);
}

abstract final class GuestCart {
  static const _k = 'fenaa.guest_cart.v1';

  static Future<List<GuestCartEntry>> load() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString(_k);
    if (s == null || s.isEmpty) return [];
    try {
      return (jsonDecode(s) as List).map((e) => GuestCartEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _save(List<GuestCartEntry> l) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k, jsonEncode(l.map((e) => e.toJson()).toList()));
  }

  static Future<void> add({required String nurseryId, required String productId, String? variantId, int qty = 1}) async {
    final l = await load();
    final key = '$productId|${variantId ?? ''}';
    final i = l.indexWhere((e) => e.key == key);
    if (i >= 0) {
      l[i] = l[i].withQty(l[i].qty + qty);
    } else {
      l.add(GuestCartEntry(nurseryId: nurseryId, productId: productId, variantId: variantId, qty: qty));
    }
    await _save(l);
  }

  static Future<void> setQty(String key, int qty) async {
    final l = await load();
    final i = l.indexWhere((e) => e.key == key);
    if (i < 0) return;
    if (qty <= 0) {
      l.removeAt(i);
    } else {
      l[i] = l[i].withQty(qty);
    }
    await _save(l);
  }

  static Future<void> clearNursery(String nurseryId) async {
    final l = await load();
    l.removeWhere((e) => e.nurseryId == nurseryId);
    await _save(l);
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_k);
  }
}

/// تفضيلات بسيطة للتطبيق
abstract final class AppPrefs {
  static const _role = 'fenaa.role_choice';

  /// 'customer' | 'merchant' | null (لم يختر بعد)
  static Future<String?> roleChoice() async => (await SharedPreferences.getInstance()).getString(_role);
  static Future<void> setRoleChoice(String v) async => (await SharedPreferences.getInstance()).setString(_role, v);
  static Future<void> clearRoleChoice() async => (await SharedPreferences.getInstance()).remove(_role);
}
