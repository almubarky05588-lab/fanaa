import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/catalog.dart';

const nurseryCols = 'id,name,slug,description,logo_url,cover_url,city,district,rating_avg,rating_count,'
    'delivery_fee,free_delivery_over,min_order,prep_time_min,is_open,on_vacation,owner_id,phone,tax_number,'
    'delivery_radius_km,auto_accept,lat,lng';

const productCols = 'id,nursery_id,category_id,name,description,images,base_price,stock,care_light,care_water,'
    'care_temp,is_available,sold_count,product_variants(id,name,price,stock,is_active,sort)';

class CatalogRepo {
  CatalogRepo(this._c);
  final SupabaseClient _c;

  Future<List<Nursery>> nearby({required double lat, required double lng, double radiusKm = 25}) async {
    final rows = await _c.rpc('nearby_nurseries', params: {'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm});
    return (rows as List).map((e) => Nursery.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Nursery>> nurseries({String? query, int limit = 40}) async {
    var q = _c.from('nurseries').select(nurseryCols).eq('is_active', true);
    if (query != null && query.isNotEmpty) q = q.ilike('name', '%$query%');
    final rows = await q.order('rating_avg', ascending: false).limit(limit);
    return rows.map((e) => Nursery.fromJson(e)).toList();
  }

  Future<Nursery?> nursery(String id) async {
    final j = await _c.from('nurseries').select(nurseryCols).eq('id', id).maybeSingle();
    return j == null ? null : Nursery.fromJson(j);
  }

  Future<Nursery?> myNursery() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return null;
    final j = await _c.from('nurseries').select(nurseryCols).eq('owner_id', uid).maybeSingle();
    return j == null ? null : Nursery.fromJson(j);
  }

  Future<List<Category>> categories() async {
    final rows = await _c.from('categories').select().eq('is_active', true).order('sort');
    return rows.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Product>> products({String? nurseryId, String? categoryId, String? query, int limit = 40}) async {
    var q = _c.from('products').select('$productCols,categories(name_ar),nurseries(id,name,slug)').eq('is_archived', false).eq('is_available', true);
    if (nurseryId != null) q = q.eq('nursery_id', nurseryId);
    if (categoryId != null) q = q.eq('category_id', categoryId);
    if (query != null && query.isNotEmpty) q = q.ilike('name', '%$query%');
    final rows = await q.order('sold_count', ascending: false).limit(limit);
    return rows.map((e) => Product.fromJson(e)).toList();
  }

  Future<Product?> product(String id) async {
    final j = await _c.from('products').select('$productCols,categories(name_ar),nurseries($nurseryCols)').eq('id', id).maybeSingle();
    return j == null ? null : Product.fromJson(j);
  }

  Future<Set<String>> favoriteIds() async {
    if (_c.auth.currentUser == null) return {};
    final rows = await _c.from('favorites').select('product_id');
    return rows.map((e) => e['product_id'] as String).toSet();
  }

  Future<void> toggleFavorite(String productId, bool fav) async {
    final uid = _c.auth.currentUser!.id;
    if (fav) {
      await _c.from('favorites').upsert({'user_id': uid, 'product_id': productId});
    } else {
      await _c.from('favorites').delete().match({'user_id': uid, 'product_id': productId});
    }
  }

  // ---- المتاجر المفضلة
  Future<Set<String>> favoriteNurseryIds() async {
    if (_c.auth.currentUser == null) return {};
    final rows = await _c.from('favorite_nurseries').select('nursery_id');
    return rows.map((e) => e['nursery_id'] as String).toSet();
  }

  Future<void> toggleFavoriteNursery(String nurseryId, bool fav) async {
    final uid = _c.auth.currentUser!.id;
    if (fav) {
      await _c.from('favorite_nurseries').upsert({'user_id': uid, 'nursery_id': nurseryId});
    } else {
      await _c.from('favorite_nurseries').delete().match({'user_id': uid, 'nursery_id': nurseryId});
    }
  }

  Future<List<Product>> favoriteProducts() async {
    if (_c.auth.currentUser == null) return [];
    final rows = await _c.from('favorites')
        .select('products($productCols,categories(name_ar),nurseries(id,name,slug))')
        .order('created_at', ascending: false);
    return rows.where((e) => e['products'] != null).map((e) => Product.fromJson(Map<String, dynamic>.from(e['products']))).toList();
  }

  Future<List<Nursery>> favoriteNurseries() async {
    if (_c.auth.currentUser == null) return [];
    final rows = await _c.from('favorite_nurseries').select('nurseries($nurseryCols)').order('created_at', ascending: false);
    return rows.where((e) => e['nurseries'] != null).map((e) => Nursery.fromJson(Map<String, dynamic>.from(e['nurseries']))).toList();
  }

  /// تقييمات متجر — للتاجر
  Future<List<Map<String, dynamic>>> nurseryReviews(String nurseryId) async => List<Map<String, dynamic>>.from(
      await _c.from('reviews').select('id,rating,comment,created_at,profiles(full_name)')
          .eq('nursery_id', nurseryId).order('created_at', ascending: false).limit(100));

  // ---- التاجر
  Future<List<Product>> merchantProducts(String nurseryId) async {
    final rows = await _c.from('products').select('$productCols,categories(name_ar)')
        .eq('nursery_id', nurseryId).eq('is_archived', false).order('created_at', ascending: false);
    return rows.map((e) => Product.fromJson(e)).toList();
  }

  Future<void> setAvailability(String productId, bool v) => _c.from('products').update({'is_available': v}).eq('id', productId);

  Future<String> createProduct(Map<String, dynamic> data, List<Map<String, dynamic>> variants) async {
    final p = await _c.from('products').insert(data).select('id').single();
    if (variants.isNotEmpty) {
      await _c.from('product_variants').insert(variants.map((v) => {...v, 'product_id': p['id']}).toList());
    }
    return p['id'];
  }

  Future<String> uploadProductImage(String nurseryId, String fileName, Uint8List bytes) async {
    final key = '$nurseryId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _c.storage.from('products').uploadBinary(key, bytes, fileOptions: const FileOptions(upsert: true));
    return _c.storage.from('products').getPublicUrl(key);
  }

  /// شعار/غلاف المتجر — مسار يبدأ بمعرّف المتجر (تسمح به سياسة التخزين للمالك فقط)
  Future<String> uploadNurseryImage(String nurseryId, String kind, Uint8List bytes) async {
    final key = '$nurseryId/${kind}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _c.storage.from('nurseries').uploadBinary(key, bytes,
        fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
    return _c.storage.from('nurseries').getPublicUrl(key);
  }

  Future<void> updateNursery(String id, Map<String, dynamic> data) => _c.from('nurseries').update(data).eq('id', id);

  /// الآيبان — جدول خاص لا يقرؤه إلا صاحب المتجر
  Future<String?> iban(String nurseryId) async =>
      (await _c.from('nursery_payout').select('iban').eq('nursery_id', nurseryId).maybeSingle())?['iban'] as String?;
  Future<void> setIban(String nurseryId, String iban) =>
      _c.from('nursery_payout').upsert({'nursery_id': nurseryId, 'iban': iban, 'updated_at': DateTime.now().toUtc().toIso8601String()});

  Future<List<Map<String, dynamic>>> workingHours(String nurseryId) async =>
      List<Map<String, dynamic>>.from(await _c.from('working_hours').select().eq('nursery_id', nurseryId).order('weekday'));
}

final catalogRepoProvider = Provider((ref) => CatalogRepo(ref.watch(supabaseProvider)));
final categoriesProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).categories());
final topNurseriesProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).nurseries(limit: 10));
final favoriteIdsProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).favoriteIds());
final myNurseryProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).myNursery());
final nurseryProvider = FutureProvider.family<Nursery?, String>((ref, id) => ref.watch(catalogRepoProvider).nursery(id));
final productProvider = FutureProvider.family<Product?, String>((ref, id) => ref.watch(catalogRepoProvider).product(id));
final nurseryProductsProvider =
    FutureProvider.family<List<Product>, String>((ref, id) => ref.watch(catalogRepoProvider).products(nurseryId: id, limit: 100));
final popularProductsProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).products(limit: 10));
final favoriteNurseryIdsProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).favoriteNurseryIds());
final favoriteProductsProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).favoriteProducts());
final favoriteNurseriesProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).favoriteNurseries());
final nurseryReviewsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) => ref.watch(catalogRepoProvider).nurseryReviews(id));
