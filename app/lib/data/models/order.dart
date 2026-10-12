import 'catalog.dart';
import '../../core/i18n/i18n.dart';

class CartItem {
  final String id;
  final String cartId;
  final Product product;
  final ProductVariant? variant;
  final int qty;

  const CartItem({required this.id, required this.cartId, required this.product, this.variant, required this.qty});

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        id: j['id'],
        cartId: j['cart_id'],
        product: Product.fromJson(Map<String, dynamic>.from(j['products'])),
        variant: j['product_variants'] is Map
            ? ProductVariant.fromJson(Map<String, dynamic>.from(j['product_variants']))
            : null,
        qty: j['qty'],
      );

  double get unitPrice => variant?.price ?? product.basePrice;
  double get lineTotal => unitPrice * qty;
}

class Cart {
  final String id;
  final String nurseryId;
  final Nursery? nursery;
  final List<CartItem> items;
  const Cart({required this.id, required this.nurseryId, this.nursery, required this.items});

  int get count => items.fold(0, (s, i) => s + i.qty);
  double get subtotal => items.fold(0, (s, i) => s + i.lineTotal);
  bool get isEmpty => items.isEmpty;
}

enum OrderStatus { pending, accepted, preparing, ready, outForDelivery, delivered, cancelled, rejected }

OrderStatus orderStatusFrom(String s) => switch (s) {
      'accepted' => OrderStatus.accepted,
      'preparing' => OrderStatus.preparing,
      'ready' => OrderStatus.ready,
      'out_for_delivery' => OrderStatus.outForDelivery,
      'delivered' => OrderStatus.delivered,
      'cancelled' => OrderStatus.cancelled,
      'rejected' => OrderStatus.rejected,
      _ => OrderStatus.pending,
    };

extension OrderStatusX on OrderStatus {
  String get db => switch (this) {
        OrderStatus.outForDelivery => 'out_for_delivery',
        _ => name,
      };

  String get labelAr => switch (this) {
        OrderStatus.pending => tr('جديد'),
        OrderStatus.accepted => tr('تم القبول'),
        OrderStatus.preparing => tr('قيد التجهيز'),
        OrderStatus.ready => tr('جاهز'),
        OrderStatus.outForDelivery => tr('في الطريق'),
        OrderStatus.delivered => tr('تم التوصيل'),
        OrderStatus.cancelled => tr('ملغي'),
        OrderStatus.rejected => tr('مرفوض'),
      };

  /// ترتيب المرحلة في الخط الزمني (0..3)
  int get step => switch (this) {
        OrderStatus.pending => 0,
        OrderStatus.accepted || OrderStatus.preparing || OrderStatus.ready => 1,
        OrderStatus.outForDelivery => 2,
        OrderStatus.delivered => 3,
        _ => -1,
      };

  bool get isTerminal =>
      this == OrderStatus.delivered || this == OrderStatus.cancelled || this == OrderStatus.rejected;
}

class OrderItem {
  final String name;
  final String? variantName;
  final double unitPrice;
  final int qty;
  final double lineTotal;
  final String? productId;
  const OrderItem({required this.name, this.variantName, required this.unitPrice, required this.qty, required this.lineTotal, this.productId});
  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        name: j['name'],
        variantName: j['variant_name'],
        unitPrice: (j['unit_price'] as num).toDouble(),
        qty: j['qty'],
        lineTotal: (j['line_total'] as num).toDouble(),
        productId: j['product_id'],
      );
}

class Order {
  final String id;
  final int orderNumber;
  final String userId;
  final String nurseryId;
  final OrderStatus status;
  final String paymentStatus;
  final String? paymentMethod;
  final Map<String, dynamic> address;
  final String? note;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final double vatAmount;
  final double commission;
  final double netPayout;
  final DateTime placedAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final Nursery? nursery;
  final String? customerName;
  final String? customerPhone;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.nurseryId,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    required this.address,
    this.note,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.vatAmount,
    required this.commission,
    required this.netPayout,
    required this.placedAt,
    this.acceptedAt,
    this.readyAt,
    this.pickedUpAt,
    this.deliveredAt,
    this.items = const [],
    this.nursery,
    this.customerName,
    this.customerPhone,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'],
        orderNumber: j['order_number'] ?? 0,
        userId: j['user_id'],
        nurseryId: j['nursery_id'],
        status: orderStatusFrom(j['status']),
        paymentStatus: j['payment_status'] ?? 'unpaid',
        paymentMethod: j['payment_method'],
        address: Map<String, dynamic>.from(j['address_snapshot'] ?? {}),
        note: j['customer_note'],
        subtotal: (j['subtotal'] as num).toDouble(),
        deliveryFee: (j['delivery_fee'] as num).toDouble(),
        discount: (j['discount'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
        vatAmount: (j['vat_amount'] as num).toDouble(),
        commission: (j['commission'] as num?)?.toDouble() ?? 0,
        netPayout: (j['net_payout'] as num?)?.toDouble() ?? 0,
        placedAt: DateTime.parse(j['placed_at']).toLocal(),
        acceptedAt: j['accepted_at'] == null ? null : DateTime.parse(j['accepted_at']).toLocal(),
        readyAt: j['ready_at'] == null ? null : DateTime.parse(j['ready_at']).toLocal(),
        pickedUpAt: j['picked_up_at'] == null ? null : DateTime.parse(j['picked_up_at']).toLocal(),
        deliveredAt: j['delivered_at'] == null ? null : DateTime.parse(j['delivered_at']).toLocal(),
        items: ((j['order_items'] as List?) ?? const []).map((e) => OrderItem.fromJson(e)).toList(),
        nursery: j['nurseries'] is Map ? Nursery.fromJson(Map<String, dynamic>.from(j['nurseries'])) : null,
        customerName: j['profiles'] is Map ? j['profiles']['full_name'] : null,
        customerPhone: j['profiles'] is Map ? j['profiles']['phone'] : null,
      );

  int get itemCount => items.fold(0, (s, i) => s + i.qty);
  String get addressLine => [address['line'], address['district'], address['city']]
      .where((e) => (e ?? '').toString().isNotEmpty)
      .join(tr('، '));
}

class Invoice {
  final String invoiceNumber;
  final String sellerName;
  final String? sellerVat;
  final DateTime issuedAt;
  final double vatAmount;
  final double total;
  final String? zatcaQr;
  const Invoice({required this.invoiceNumber, required this.sellerName, this.sellerVat, required this.issuedAt, required this.vatAmount, required this.total, this.zatcaQr});
  factory Invoice.fromJson(Map<String, dynamic> j) => Invoice(
        invoiceNumber: j['invoice_number'],
        sellerName: j['seller_name'],
        sellerVat: j['seller_vat'],
        issuedAt: DateTime.parse(j['issued_at']).toLocal(),
        vatAmount: (j['vat_amount'] as num).toDouble(),
        total: (j['total'] as num).toDouble(),
        zatcaQr: j['zatca_qr'],
      );
}

class WalletTxn {
  final String type;
  final double amount;
  final String? note;
  final DateTime createdAt;
  const WalletTxn({required this.type, required this.amount, this.note, required this.createdAt});
  factory WalletTxn.fromJson(Map<String, dynamic> j) => WalletTxn(
        type: j['type'],
        amount: (j['amount'] as num).toDouble(),
        note: j['note'],
        createdAt: DateTime.parse(j['created_at']).toLocal(),
      );
}
