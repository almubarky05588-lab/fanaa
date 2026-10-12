class Nursery {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? coverUrl;
  final String city;
  final String? district;
  final double ratingAvg;
  final int ratingCount;
  final double deliveryFee;
  final double? freeDeliveryOver;
  final double minOrder;
  final int prepTimeMin;
  final bool isOpen;
  final double? lat;
  final double? lng;
  final double? distanceKm;
  final String? ownerId;
  final String? phone;
  final String? taxNumber;
  final double deliveryRadiusKm;
  final bool autoAccept;
  final bool onVacation;
  final bool isApproved;

  const Nursery({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.coverUrl,
    required this.city,
    this.district,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.deliveryFee = 15,
    this.freeDeliveryOver,
    this.minOrder = 0,
    this.prepTimeMin = 45,
    this.isOpen = true,
    this.lat,
    this.lng,
    this.distanceKm,
    this.ownerId,
    this.phone,
    this.taxNumber,
    this.deliveryRadiusKm = 8,
    this.autoAccept = false,
    this.onVacation = false,
    this.isApproved = true,
  });

  factory Nursery.fromJson(Map<String, dynamic> j) => Nursery(
        id: j['id'],
        name: j['name'] ?? '',
        slug: j['slug'] ?? '',
        description: j['description'],
        logoUrl: j['logo_url'],
        coverUrl: j['cover_url'],
        city: j['city'] ?? '',
        district: j['district'],
        ratingAvg: (j['rating_avg'] as num?)?.toDouble() ?? 0,
        ratingCount: j['rating_count'] ?? 0,
        deliveryFee: (j['delivery_fee'] as num?)?.toDouble() ?? 15,
        freeDeliveryOver: (j['free_delivery_over'] as num?)?.toDouble(),
        minOrder: (j['min_order'] as num?)?.toDouble() ?? 0,
        prepTimeMin: j['prep_time_min'] ?? 45,
        isOpen: j['is_open'] ?? true,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        distanceKm: (j['distance_km'] as num?)?.toDouble(),
        ownerId: j['owner_id'],
        phone: j['phone'],
        taxNumber: j['tax_number'],
        deliveryRadiusKm: (j['delivery_radius_km'] as num?)?.toDouble() ?? 8,
        autoAccept: j['auto_accept'] ?? false,
        onVacation: j['on_vacation'] ?? false,
        isApproved: j['is_approved'] ?? true,
      );

  String get location => [district, city].where((e) => (e ?? '').isNotEmpty).join(' — ');
  bool get freeDelivery => deliveryFee == 0;
}

class Category {
  final String id;
  final String nameAr;
  final String slug;
  final String? icon;
  /// طريقة العرض التي يختارها الأدمن: icon | image | text
  final String displayMode;
  final String? imageUrl;
  final String? bgColor;
  const Category({required this.id, required this.nameAr, required this.slug, this.icon,
      this.displayMode = 'icon', this.imageUrl, this.bgColor});
  factory Category.fromJson(Map<String, dynamic> j) => Category(
      id: j['id'], nameAr: j['name_ar'], slug: j['slug'], icon: j['icon'],
      displayMode: j['display_mode'] ?? 'icon', imageUrl: j['image_url'], bgColor: j['bg_color']);
}

class ProductVariant {
  final String id;
  final String name;
  final double price;
  final int stock;
  final bool isActive;
  const ProductVariant({required this.id, required this.name, required this.price, this.stock = 0, this.isActive = true});
  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
        id: j['id'],
        name: j['name'],
        price: (j['price'] as num).toDouble(),
        stock: j['stock'] ?? 0,
        isActive: j['is_active'] ?? true,
      );
}

class Product {
  final String id;
  final String nurseryId;
  final String? categoryId;
  final String name;
  final String? description;
  final List<String> images;
  final double basePrice;
  final int stock;
  final String? careLight;
  final String? careWater;
  final String? careTemp;
  final bool isAvailable;
  final int soldCount;
  final List<ProductVariant> variants;
  final Nursery? nursery;
  final String? categoryName;

  const Product({
    required this.id,
    required this.nurseryId,
    this.categoryId,
    required this.name,
    this.description,
    this.images = const [],
    required this.basePrice,
    this.stock = 0,
    this.careLight,
    this.careWater,
    this.careTemp,
    this.isAvailable = true,
    this.soldCount = 0,
    this.variants = const [],
    this.nursery,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'],
        nurseryId: j['nursery_id'],
        categoryId: j['category_id'],
        name: j['name'] ?? '',
        description: j['description'],
        images: (j['images'] as List?)?.cast<String>() ?? const [],
        basePrice: (j['base_price'] as num).toDouble(),
        stock: j['stock'] ?? 0,
        careLight: j['care_light'],
        careWater: j['care_water'],
        careTemp: j['care_temp'],
        isAvailable: j['is_available'] ?? true,
        soldCount: j['sold_count'] ?? 0,
        variants: ((j['product_variants'] as List?) ?? const [])
            .map((v) => ProductVariant.fromJson(v))
            .toList()
          ..sort((a, b) => a.price.compareTo(b.price)),
        nursery: j['nurseries'] is Map ? Nursery.fromJson(Map<String, dynamic>.from(j['nurseries'])) : null,
        categoryName: j['categories'] is Map ? j['categories']['name_ar'] : null,
      );

  String? get cover => images.isEmpty ? null : images.first;
  double get fromPrice => variants.isEmpty ? basePrice : variants.first.price;
  bool get inStock => variants.isEmpty ? stock > 0 : variants.any((v) => v.stock > 0 && v.isActive);
}
