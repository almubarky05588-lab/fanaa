import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/coupon.dart';

class CouponRepo {
  CouponRepo(this._c);
  final SupabaseClient _c;

  Future<List<Coupon>> list(String nurseryId) async {
    final rows = await _c.from('coupons').select().eq('nursery_id', nurseryId).order('starts_at', ascending: false);
    return rows.map((e) => Coupon.fromJson(e)).toList();
  }

  Future<void> create({
    required String nurseryId,
    required String code,
    required String type,
    required double value,
    double minOrder = 0,
    double? maxDiscount,
    int? usageLimit,
    int perUserLimit = 1,
    DateTime? endsAt,
  }) =>
      _c.from('coupons').insert({
        'code': code,
        'nursery_id': nurseryId,
        'type': type,
        'value': value,
        'min_order': minOrder,
        'max_discount': maxDiscount,
        'usage_limit': usageLimit,
        'per_user_limit': perUserLimit,
        'ends_at': endsAt?.toUtc().toIso8601String(),
      });

  Future<void> setActive(String code, bool v) => _c.from('coupons').update({'is_active': v}).eq('code', code);

  Future<void> delete(String code) => _c.from('coupons').delete().eq('code', code);

  Future<CouponCheck> validate({required String nurseryId, required String code, required double subtotal}) async {
    final r = await _c.rpc('validate_coupon', params: {'p_nursery_id': nurseryId, 'p_code': code, 'p_subtotal': subtotal});
    return CouponCheck.fromJson(Map<String, dynamic>.from(r as Map), nurseryId);
  }
}

final couponRepoProvider = Provider((ref) => CouponRepo(ref.watch(supabaseProvider)));
final merchantCouponsProvider =
    FutureProvider.family<List<Coupon>, String>((ref, nid) => ref.watch(couponRepoProvider).list(nid));
