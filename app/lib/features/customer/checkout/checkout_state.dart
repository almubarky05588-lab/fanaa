import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/profile.dart';

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
        PayMethod.mada => 'مدى',
        PayMethod.creditCard => 'بطاقة ائتمانية',
        PayMethod.stcPay => 'STC Pay',
        PayMethod.tabby => 'تابي',
        PayMethod.cod => 'الدفع عند الاستلام',
      };
  String get subtitle => switch (this) {
        PayMethod.applePay => 'الدفع بلمسة واحدة',
        PayMethod.mada => 'بطاقة مدى البنكية',
        PayMethod.creditCard => 'فيزا / ماستركارد',
        PayMethod.stcPay => 'محفظة إلكترونية',
        PayMethod.tabby => '٤ دفعات بدون فوائد',
        PayMethod.cod => 'نقدًا أو شبكة',
      };
  bool get needsCard => this == PayMethod.mada || this == PayMethod.creditCard;
}
