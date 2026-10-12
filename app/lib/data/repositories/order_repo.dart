import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../local/guest_cart.dart';
import '../models/catalog.dart';
import '../models/order.dart';
import '../models/profile.dart';

const _orderCols = 'id,order_number,user_id,nursery_id,status,payment_status,payment_method,address_snapshot,'
    'customer_note,subtotal,delivery_fee,discount,total,vat_amount,commission,net_payout,placed_at,accepted_at,'
    'ready_at,picked_up_at,delivered_at,order_items(name,variant_name,unit_price,qty,line_total,product_id)';

const _cartNurseryCols = 'id,name,slug,logo_url,delivery_fee,free_delivery_over,min_order,prep_time_min,city,district,'
    'rating_avg,rating_count,is_open';

const _cartProductCols = 'id,nursery_id,name,images,base_price,stock,is_available,is_archived';

class OrderRepo {
  OrderRepo(this._c);
  final SupabaseClient _c;

  bool get _guest => _c.auth.currentUser == null;

  // ---------------------------------------------------------------- السلة
  /// سلات المستخدم — من الخادم للمسجّل، ومن الجهاز للزائر
  Future<List<Cart>> carts() async {
    if (_guest) return _guestCarts();
    final uid = _c.auth.currentUser!.id;
    final rows = await _c.from('carts')
        .select('id,nursery_id,nurseries($_cartNurseryCols),'
            'cart_items(id,cart_id,qty,products($_cartProductCols),product_variants(id,name,price,stock,is_active))')
        .eq('user_id', uid).order('updated_at', ascending: false);
    return rows
        .map((j) => Cart(
              id: j['id'],
              nurseryId: j['nursery_id'],
              nursery: j['nurseries'] is Map ? Nursery.fromJson(Map<String, dynamic>.from(j['nurseries'])) : null,
              items: ((j['cart_items'] as List?) ?? const []).map((e) => CartItem.fromJson(e)).toList(),
            ))
        .where((c) => c.items.isNotEmpty)
        .toList();
  }

  Future<List<Cart>> _guestCarts() async {
    final entries = await GuestCart.load();
    if (entries.isEmpty) return const [];
    final ids = entries.map((e) => e.productId).toSet().toList();
    final rows = await _c.from('products')
        .select('$_cartProductCols,product_variants(id,name,price,stock,is_active,sort),nurseries($_cartNurseryCols)')
        .inFilter('id', ids);
    final byId = {for (final r in rows) r['id'] as String: r};
    final groups = <String, List<CartItem>>{};
    final nurseries = <String, Nursery>{};
    for (final e in entries) {
      final r = byId[e.productId];
      if (r == null) continue;
      final p = Product.fromJson(r);
      final v = e.variantId == null ? null : p.variants.where((x) => x.id == e.variantId).firstOrNull;
      if (p.nursery != null) nurseries[p.nurseryId] = p.nursery!;
      (groups[p.nurseryId] ??= []).add(CartItem(id: e.key, cartId: 'guest:${p.nurseryId}', product: p, variant: v, qty: e.qty));
    }
    return [
      for (final g in groups.entries)
        Cart(id: 'guest:${g.key}', nurseryId: g.key, nursery: nurseries[g.key], items: g.value),
    ];
  }

  Future<void> addToCart({required String nurseryId, required String productId, String? variantId, int qty = 1}) async {
    if (_guest) {
      await GuestCart.add(nurseryId: nurseryId, productId: productId, variantId: variantId, qty: qty);
      return;
    }
    final uid = _c.auth.currentUser!.id;
    final cart = await _c.from('carts').upsert({'user_id': uid, 'nursery_id': nurseryId},
        onConflict: 'user_id,nursery_id').select('id').single();
    var q = _c.from('cart_items').select('id,qty').eq('cart_id', cart['id']).eq('product_id', productId);
    q = variantId == null ? q.isFilter('variant_id', null) : q.eq('variant_id', variantId);
    final existing = await q.maybeSingle();
    if (existing != null) {
      await _c.from('cart_items').update({'qty': existing['qty'] + qty}).eq('id', existing['id']);
    } else {
      await _c.from('cart_items').insert({'cart_id': cart['id'], 'product_id': productId, 'variant_id': variantId, 'qty': qty});
    }
  }

  Future<void> setQty(String itemId, int qty) async {
    if (_guest) return GuestCart.setQty(itemId, qty);
    if (qty <= 0) {
      await _c.from('cart_items').delete().eq('id', itemId);
    } else {
      await _c.from('cart_items').update({'qty': qty}).eq('id', itemId);
    }
  }

  Future<void> clearCart(String cartId) async {
    if (cartId.startsWith('guest:')) return GuestCart.clearNursery(cartId.substring(6));
    await _c.from('carts').delete().eq('id', cartId);
  }

  /// ينقل سلة الزائر إلى سلة الحساب بعد تسجيل الدخول
  Future<void> mergeGuestCart() async {
    if (_guest) return;
    final entries = await GuestCart.load();
    if (entries.isEmpty) return;
    for (final e in entries) {
      try {
        await addToCart(nurseryId: e.nurseryId, productId: e.productId, variantId: e.variantId, qty: e.qty);
      } catch (_) {/* منتج لم يعد متاحًا — يُتجاهل */}
    }
    await GuestCart.clear();
  }

  // ------------------------------------------------------------- العناوين
  Future<List<Address>> addresses() async {
    if (_guest) return const [];
    final rows = await _c.from('addresses')
        .select('id,label,line,district,city,notes,is_default,created_at')
        .order('is_default', ascending: false).order('created_at');
    return rows.map((e) => Address.fromJson(e)).toList();
  }

  Future<Address> addAddress({required String label, required String line, String? district, required String city,
      String? notes, double? lat, double? lng, bool isDefault = false}) async {
    final uid = _c.auth.currentUser!.id;
    if (isDefault) await _c.from('addresses').update({'is_default': false}).eq('user_id', uid);
    final j = await _c.from('addresses').insert({
      'user_id': uid, 'label': label, 'line': line, 'district': district, 'city': city, 'notes': notes,
      'is_default': isDefault,
      if (lat != null && lng != null) 'location': 'POINT($lng $lat)',
    }).select('id,label,line,district,city,notes,is_default').single();
    return Address.fromJson(j);
  }

  Future<void> setDefaultAddress(String id) async {
    final uid = _c.auth.currentUser!.id;
    await _c.from('addresses').update({'is_default': false}).eq('user_id', uid);
    await _c.from('addresses').update({'is_default': true}).eq('id', id);
  }

  // -------------------------------------------------------------- الطلبات
  Future<String> placeOrder({required String nurseryId, required String addressId, required String paymentMethod,
      String? coupon, String? note, DateTime? scheduledAt}) async {
    final id = await _c.rpc('place_order', params: {
      'p_nursery_id': nurseryId,
      'p_address_id': addressId,
      'p_payment_method': paymentMethod,
      'p_coupon': coupon,
      'p_note': note,
      'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
    });
    return id as String;
  }

  /// ينشئ رابط دفع ماي فاتورة للطلب (null = الطلب مدفوع أصلًا)
  Future<String?> createPayment(String orderId) async =>
      (await _invokeFn('payment-create', {'order_id': orderId}))['url'] as String?;

  /// يسأل الخادم: هل تأكّد الدفع من ماي فاتورة؟
  Future<bool> verifyPayment(String orderId) async =>
      (await _invokeFn('payment-verify', {'order_id': orderId}))['paid'] == true;

  Future<Map<String, dynamic>> _invokeFn(String fn, Map<String, dynamic> body) async {
    try {
      final r = await _c.functions.invoke(fn, body: body);
      return Map<String, dynamic>.from(r.data as Map);
    } on FunctionException catch (e) {
      final d = e.details;
      throw PaymentException(d is Map && d['error'] is String ? d['error'] as String : 'حدث خطأ غير متوقع');
    }
  }

  Future<List<Order>> myOrders() async {
    if (_guest) return const [];
    final uid = _c.auth.currentUser!.id;
    final rows = await _c.from('orders').select('$_orderCols,nurseries(id,name,slug,logo_url,city,district)')
        .eq('user_id', uid).order('placed_at', ascending: false);
    return rows.map((e) => Order.fromJson(e)).toList();
  }

  Future<Order?> order(String id) async {
    final j = await _c.from('orders')
        .select('$_orderCols,nurseries(id,name,slug,logo_url,city,district,phone,prep_time_min),profiles(full_name,phone)')
        .eq('id', id).maybeSingle();
    return j == null ? null : Order.fromJson(j);
  }

  Stream<Order?> watchOrder(String id) =>
      _c.from('orders').stream(primaryKey: ['id']).eq('id', id).asyncMap((rows) => rows.isEmpty ? null : order(id));

  Future<void> updateStatus(String orderId, OrderStatus s, {String? note}) =>
      _c.rpc('update_order_status', params: {'p_order_id': orderId, 'p_status': s.db, 'p_note': note});

  Future<Invoice?> invoice(String orderId) async {
    final j = await _c.from('invoices').select().eq('order_id', orderId).maybeSingle();
    return j == null ? null : Invoice.fromJson(j);
  }

  Future<void> addReview({required String orderId, required String nurseryId, required int rating, String? comment}) =>
      _c.from('reviews').insert({'order_id': orderId, 'nursery_id': nurseryId, 'user_id': _c.auth.currentUser!.id,
          'rating': rating, 'comment': comment});

  // ------------------------------------------------------------- التاجر
  Future<List<Order>> merchantOrders(String nurseryId, {List<OrderStatus>? statuses}) async {
    var q = _c.from('orders').select('$_orderCols,profiles(full_name,phone)').eq('nursery_id', nurseryId);
    if (statuses != null && statuses.isNotEmpty) q = q.inFilter('status', statuses.map((s) => s.db).toList());
    final rows = await q.order('placed_at', ascending: false);
    return rows.map((e) => Order.fromJson(e)).toList();
  }

  Stream<List<Map<String, dynamic>>> watchMerchantOrders(String nurseryId) =>
      _c.from('orders').stream(primaryKey: ['id']).eq('nursery_id', nurseryId).order('placed_at', ascending: false);

  Future<Map<String, dynamic>> merchantStats(String nurseryId) async {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final rows = await _c.from('orders').select('status,total,placed_at').eq('nursery_id', nurseryId)
        .gte('placed_at', today.subtract(const Duration(days: 7)).toUtc().toIso8601String());
    double todaySales = 0;
    int newCount = 0, preparing = 0;
    final daily = List<double>.filled(7, 0);
    for (final r in rows) {
      final s = r['status'] as String;
      final t = (r['total'] as num).toDouble();
      final d = DateTime.parse(r['placed_at']).toLocal();
      if (s == 'pending') newCount++;
      if (s == 'accepted' || s == 'preparing') preparing++;
      if (s != 'cancelled' && s != 'rejected') {
        if (!d.isBefore(start)) todaySales += t;
        final idx = 6 - start.difference(DateTime(d.year, d.month, d.day)).inDays;
        if (idx >= 0 && idx < 7) daily[idx] += t;
      }
    }
    return {'todaySales': todaySales, 'newCount': newCount, 'preparing': preparing, 'daily': daily};
  }

  Future<Map<String, dynamic>> wallet(String nurseryId) async {
    final w = await _c.from('wallets').select().eq('nursery_id', nurseryId).maybeSingle();
    final tx = await _c.from('wallet_transactions').select().eq('nursery_id', nurseryId)
        .order('created_at', ascending: false).limit(30);
    return {
      'balance': (w?['balance'] as num?)?.toDouble() ?? 0,
      'pending': (w?['pending'] as num?)?.toDouble() ?? 0,
      'transactions': tx.map((e) => WalletTxn.fromJson(e)).toList(),
    };
  }

  Future<void> requestPayout(String nurseryId, double amount, String ibanLast4) =>
      _c.rpc('request_payout', params: {'p_nursery_id': nurseryId, 'p_amount': amount, 'p_iban_last4': ibanLast4});
}

final orderRepoProvider = Provider((ref) => OrderRepo(ref.watch(supabaseProvider)));
final cartsProvider = FutureProvider((ref) {
  ref.watch(authStateProvider);
  return ref.watch(orderRepoProvider).carts();
});
final addressesProvider = FutureProvider((ref) {
  ref.watch(authStateProvider);
  return ref.watch(orderRepoProvider).addresses();
});
final myOrdersProvider = FutureProvider((ref) {
  ref.watch(authStateProvider);
  return ref.watch(orderRepoProvider).myOrders();
});

/// خطأ من خدمة الدفع برسالة جاهزة للعرض
class PaymentException implements Exception {
  PaymentException(this.message);
  final String message;
  @override
  String toString() => message;
}
