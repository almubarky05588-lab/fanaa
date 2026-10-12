class Coupon {
  const Coupon({
    required this.code,
    this.nurseryId,
    required this.type,
    required this.value,
    this.minOrder = 0,
    this.maxDiscount,
    required this.startsAt,
    this.endsAt,
    this.usageLimit,
    this.usedCount = 0,
    this.perUserLimit = 1,
    this.isActive = true,
  });

  final String code;
  final String? nurseryId;
  final String type; // percent | fixed
  final double value;
  final double minOrder;
  final double? maxDiscount;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int? usageLimit;
  final int usedCount;
  final int perUserLimit;
  final bool isActive;

  bool get isPercent => type == 'percent';
  bool get expired => endsAt != null && endsAt!.isBefore(DateTime.now());
  bool get exhausted => usageLimit != null && usedCount >= usageLimit!;

  factory Coupon.fromJson(Map<String, dynamic> j) => Coupon(
        code: j['code'],
        nurseryId: j['nursery_id'],
        type: j['type'],
        value: (j['value'] as num).toDouble(),
        minOrder: (j['min_order'] as num?)?.toDouble() ?? 0,
        maxDiscount: (j['max_discount'] as num?)?.toDouble(),
        startsAt: DateTime.parse(j['starts_at']).toLocal(),
        endsAt: j['ends_at'] == null ? null : DateTime.parse(j['ends_at']).toLocal(),
        usageLimit: j['usage_limit'],
        usedCount: j['used_count'] ?? 0,
        perUserLimit: j['per_user_limit'] ?? 1,
        isActive: j['is_active'] ?? true,
      );
}

/// نتيجة معاينة الكوبون في السلة
class CouponCheck {
  const CouponCheck({required this.ok, this.code, this.discount = 0, required this.message, this.nurseryId});
  final bool ok;
  final String? code;
  final double discount;
  final String message;
  final String? nurseryId;

  factory CouponCheck.fromJson(Map<String, dynamic> j, String nurseryId) => CouponCheck(
        ok: j['ok'] == true,
        code: j['code'],
        discount: (j['discount'] as num?)?.toDouble() ?? 0,
        message: j['message'] ?? '',
        nurseryId: nurseryId,
      );
}
