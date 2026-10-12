enum UserRole { customer, merchant, courier, admin }

UserRole roleFrom(String? s) =>
    UserRole.values.firstWhere((r) => r.name == s, orElse: () => UserRole.customer);

class Profile {
  final String id;
  final String? fullName;
  final String? phone;
  final UserRole role;
  final String? avatarUrl;
  final int loyaltyPoints;

  const Profile({
    required this.id,
    this.fullName,
    this.phone,
    required this.role,
    this.avatarUrl,
    this.loyaltyPoints = 0,
  });

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
        id: j['id'],
        fullName: j['full_name'],
        phone: j['phone'],
        role: roleFrom(j['role']),
        avatarUrl: j['avatar_url'],
        loyaltyPoints: j['loyalty_points'] ?? 0,
      );

  bool get isMerchant => role == UserRole.merchant;
}

class Address {
  final String id;
  final String label;
  final String line;
  final String? district;
  final String city;
  final String? notes;
  final double? lat;
  final double? lng;
  final bool isDefault;

  const Address({
    required this.id,
    required this.label,
    required this.line,
    this.district,
    required this.city,
    this.notes,
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'],
        label: j['label'] ?? 'المنزل',
        line: j['line'] ?? '',
        district: j['district'],
        city: j['city'] ?? '',
        notes: j['notes'],
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        isDefault: j['is_default'] ?? false,
      );

  String get full => [district, city].where((e) => (e ?? '').isNotEmpty).join('، ');
}
