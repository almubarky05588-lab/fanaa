import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/profile.dart';
import '../../../core/i18n/i18n.dart';

/// مسوّدة الطلب بين شاشة إتمام الطلب وشاشة الدفع
class CheckoutDraft {
  const CheckoutDraft({
    required this.nurseryId,
    required this.nurseryName,
    this.address,
    this.scheduledAt,
    this.note,
    this.coupon,
    this.subtotal = 0,
    this.delivery = 0,
    this.discount = 0,
  });
  final String nurseryId;
  final String nurseryName;
  final Address? address;
  final DateTime? scheduledAt;
  final String? note;
  final String? coupon;
  final double subtotal, delivery, discount;
  double get total => (subtotal + delivery - discount).clamp(0, double.infinity).toDouble();

  CheckoutDraft copyWith({Address? address, DateTime? scheduledAt, bool clearSchedule = false, String? note, String? coupon,
          double? subtotal, double? delivery, double? discount}) =>
      CheckoutDraft(
        nurseryId: nurseryId,
        nurseryName: nurseryName,
        address: address ?? this.address,
        scheduledAt: clearSchedule ? null : (scheduledAt ?? this.scheduledAt),
        note: note ?? this.note,
        coupon: coupon ?? this.coupon,
        subtotal: subtotal ?? this.subtotal,
        delivery: delivery ?? this.delivery,
        discount: discount ?? this.discount,
      );
}

final checkoutDraftProvider = StateProvider<CheckoutDraft?>((_) => null);

/// طرق الدفع بنفس ترتيب التصميم (11 بوابة الدفع)
enum PayMethod { applePay, mada, creditCard, stcPay, tabby, cod }

/// الطرق الظاهرة للعميل (البطاقة البنكية تشمل مدى وفيزا وماستركارد)
final kShownPayMethods = <PayMethod>[
  if (defaultTargetPlatform == TargetPlatform.iOS) PayMethod.applePay, // Apple Pay على iPhone فقط
  PayMethod.mada, PayMethod.stcPay, PayMethod.cod,
];

extension PayMethodX on PayMethod {
  String get db => switch (this) {
        PayMethod.applePay => 'apple_pay',
        PayMethod.mada => 'mada',
        PayMethod.creditCard => 'credit_card',
        PayMethod.stcPay => 'stc_pay',
        PayMethod.tabby => 'tabby',
        PayMethod.cod => 'cod',
      };
  String get title => switch (this) {
        PayMethod.applePay => 'Apple Pay',
        PayMethod.mada => tr('بطاقة بنكية'),
        PayMethod.creditCard => tr('بطاقة ائتمانية'),
        PayMethod.stcPay => 'STC Pay',
        PayMethod.tabby => tr('تابي'),
        PayMethod.cod => tr('الدفع عند الاستلام'),
      };
  String get subtitle => switch (this) {
        PayMethod.applePay => tr('الدفع بلمسة واحدة'),
        PayMethod.mada => tr('مدى • فيزا • ماستركارد'),
        PayMethod.creditCard => tr('فيزا / ماستركارد'),
        PayMethod.stcPay => tr('محفظة إلكترونية'),
        PayMethod.tabby => tr('٤ دفعات بدون فوائد'),
        PayMethod.cod => tr('نقدًا أو شبكة'),
      };
  bool get needsCard => this == PayMethod.mada || this == PayMethod.creditCard;
}
