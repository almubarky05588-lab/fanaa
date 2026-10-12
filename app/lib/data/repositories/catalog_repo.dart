import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase/supabase_client.dart';
import '../models/catalog.dart';

const _nurseryCols = 'id,name,slug,description,logo_url,cover_url,city,district,rating_avg,rating_count,'
    'delivery_fee,free_delivery_over,min_order,prep_time_min,is_open,on_vacation,owner_id,phone,tax_number,'
    'delivery_radius_km,auto_accept';

const _productCols = 'id,nursery_id,category_id,name,description,images,base_price,stock,care_light,care_water,'
    'care_temp,is_available,sold_count,product_variants(id,name,price,stock,is_active,sort)';

class CatalogRepo {
  CatalogRepo(this._c);
  final SupabaseClient _c;

  Future<List<Nursery>> nearby({required double lat, required double lng, double radiusKm = 15}) async {
    final rows = await _c.rpc('nearby_nurseries', params: {'p_lat': lat, 'p_lng': lng, 'p_radius_km': radiusKm});
    return (rows as List).map((e) => Nursery.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<Nursery>> topRated({int limit = 10}) async {
    final rows = await _c.from('nurseries').select(_nurseryCols).eq('is_active', true)
        .order('rating_avg', ascending: false).limit(limit);
    return rows.map((e) => Nursery.fromJson(e)).toList();
  }

  Future<List<Nursery>> search(String q) async {
    final rows = await _c.from('nurseries').select(_nurseryCols).eq('is_active', true)
        .ilike('name', '%$q%').limit(30);
    return rows.map((e) => Nursery.fromJson(e)).toList();
  }

  Future<Nursery?> nursery(String id) async {
    final j = await _c.from('nurseries').select(_nurseryCols).eq('id', id).maybeSingle();
    return j == null ? null : Nursery.fromJson(j);
  }

  Future<Nursery?> myNursery() async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return null;
    final j = await _c.from('nurseries').select(_nurseryCols).eq('owner_id', uid).maybeSingle();
    return j == null ? null : Nursery.fromJson(j);
  }

  Future<List<Category>> categories() async {
    final rows = await _c.from('categories').select().eq('is_active', true).order('sort');
    return rows.map((e) => Category.fromJson(e)).toList();
  }

  Future<List<Product>> products({String? nurseryId, String? categoryId, String? query, int limit = 40}) async {
    var q = _c.from('products').select('$_productCols,categories(name_ar)').eq('is_archived', false);
    if (nurseryId != null) q = q.eq('nursery_id', nurseryId);
    if (categoryId != null) q = q.eq('category_id', categoryId);
    if (query != null && query.isNotEmpty) q = q.ilike('name', '%$query%');
    final rows = await q.order('sold_count', ascending: false).limit(limit);
    return rows.map((e) => Product.fromJson(e)).toList();
  }

  Future<Product?> product(String id) async {
    final j = await _c.from('products').select('$_productCols,categories(name_ar),nurseries($_nurseryCols)')
        .eq('id', id).maybeSingle();
    return j == null ? null : Product.fromJson(j);
  }

  // ---- المفضلة
  Future<Set<String>> favoriteIds() async {
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

  // ---- التاجر: إدارة المنتجات
  Future<List<Product>> merchantProducts(String nurseryId) async {
    final rows = await _c.from('products').select('$_productCols,categories(name_ar)')
        .eq('nursery_id', nurseryId).eq('is_archived', false).order('created_at', ascending: false);
    return rows.map((e) => Product.fromJson(e)).toList();
  }

  Future<void> setAvailability(String productId, bool v) =>
      _c.from('products').update({'is_available': v}).eq('id', productId);

  Future<String> createProduct(Map<String, dynamic> data, List<Map<String, dynamic>> variants) async {
    final p = await _c.from('products').insert(data).select('id').single();
    if (variants.isNotEmpty) {
      await _c.from('product_variants').insert(variants.map((v) => {...v, 'product_id': p['id']}).toList());
    }
    return p['id'];
  }

  Future<String> uploadProductImage(String nurseryId, String path, List<int> bytes) async {
    final key = '$nurseryId/${DateTime.now().millisecondsSinceEpoch}_${path.split('/').last}';
    await _c.storage.from('products').uploadBinary(key, Uint8List.fromList(bytes));
    return _c.storage.from('products').getPublicUrl(key);
  }

  Future<void> updateNursery(String id, Map<String, dynamic> data) =>
      _c.from('nurseries').update(data).eq('id', id);
}

final catalogRepoProvider = Provider((ref) => CatalogRepo(ref.watch(supabaseProvider)));
final categoriesProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).categories());
final topNurseriesProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).topRated());
final favoriteIdsProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).favoriteIds());
final myNurseryProvider = FutureProvider((ref) => ref.watch(catalogRepoProvider).myNursery());
