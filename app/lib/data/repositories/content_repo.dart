import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/i18n/i18n.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/order.dart';

/// بنر الرئيسية — يديره الأدمن من لوحة التحكم
class AppBanner {
  const AppBanner({required this.id, required this.title, this.subtitle, this.imageUrl, this.ctaLabel,
      this.linkType = 'stores', this.linkValue});
  final String id, title, linkType;
  final String? subtitle, imageUrl, ctaLabel, linkValue;
  factory AppBanner.fromJson(Map<String, dynamic> j) => AppBanner(
        id: j['id'], title: j['title'], subtitle: j['subtitle'], imageUrl: j['image_url'],
        ctaLabel: j['cta_label'], linkType: j['link_type'] ?? 'stores', linkValue: j['link_value'],
      );
}

/// إشعار داخل التطبيق (طلب جديد، تغيّر حالة الطلب، إعلان من الإدارة)
class AppNotification {
  const AppNotification({required this.id, required this.title, this.body, this.data = const {}, this.readAt, required this.createdAt});
  final String id, title;
  final String? body;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime createdAt;
  bool get isRead => readAt != null;
  String get kind => data['kind'] as String? ?? 'broadcast';
  String? get orderId => data['order_id'] as String?;

  /// النص حسب لغة التطبيق — إشعارات الطلبات تُبنى من نوعها، والإعلانات تظهر كما كتبها الأدمن
  String get displayTitle => switch (kind) {
        'new_order' => tr('طلب جديد'),
        'order_cancelled' => tr('ألغى العميل الطلب'),
        'order_status' => orderStatusFrom(data['status'] as String? ?? '').labelAr,
        _ => title,
      };
  String get displayBody => switch (kind) {
        'new_order' || 'order_cancelled' => tr('طلب #{0}', [data['order_number']]),
        'order_status' => tr('{0} • طلب #{1}', [data['nursery'] ?? '', data['order_number']]),
        _ => body ?? '',
      };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'], title: j['title'] ?? '', body: j['body'],
        data: Map<String, dynamic>.from(j['data'] ?? const {}),
        readAt: j['read_at'] == null ? null : DateTime.parse(j['read_at']).toLocal(),
        createdAt: DateTime.parse(j['created_at']).toLocal(),
      );
}

class ContentRepo {
  ContentRepo(this._c);
  final SupabaseClient _c;

  Future<List<AppBanner>> banners() async {
    final rows = await _c.from('banners').select().order('sort');
    return rows.map((e) => AppBanner.fromJson(e)).toList();
  }

  Future<List<AppNotification>> notifications() async {
    if (_c.auth.currentUser == null) return const [];
    final rows = await _c.from('notifications').select().order('created_at', ascending: false).limit(100);
    return rows.map((e) => AppNotification.fromJson(e)).toList();
  }

  Future<void> markRead(String id) =>
      _c.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);

  Future<void> markAllRead() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return;
    await _c.from('notifications').update({'read_at': DateTime.now().toUtc().toIso8601String()})
        .eq('user_id', uid).isFilter('read_at', null);
  }
}

final contentRepoProvider = Provider((ref) => ContentRepo(ref.watch(supabaseProvider)));
final bannersProvider = FutureProvider((ref) => ref.watch(contentRepoProvider).banners());
final notificationsProvider = FutureProvider((ref) {
  ref.watch(authStateProvider);
  return ref.watch(contentRepoProvider).notifications();
});
final unreadCountProvider = Provider<int>((ref) =>
    (ref.watch(notificationsProvider).valueOrNull ?? const []).where((n) => !n.isRead).length);
