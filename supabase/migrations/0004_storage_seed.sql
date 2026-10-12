-- =====================================================================
-- فناء (Fenaa) — 0004_storage_seed.sql — التخزين + الأقسام + التحديث اللحظي
-- =====================================================================

-- ----------------------------------------------- صور المنتجات (عامة للقراءة)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('products', 'products', true, 5242880, array['image/jpeg','image/png','image/webp','image/heic'])
on conflict (id) do nothing;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('nurseries', 'nurseries', true, 5242880, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

-- التاجر يرفع فقط داخل مجلد مشتله: products/<nursery_id>/...
create policy products_read on storage.objects for select using (bucket_id in ('products','nurseries'));

create policy products_write_owner on storage.objects for insert to authenticated
  with check (bucket_id in ('products','nurseries')
              and is_nursery_owner(((storage.foldername(name))[1])::uuid));

create policy products_update_owner on storage.objects for update to authenticated
  using (bucket_id in ('products','nurseries') and is_nursery_owner(((storage.foldername(name))[1])::uuid));

create policy products_delete_owner on storage.objects for delete to authenticated
  using (bucket_id in ('products','nurseries') and is_nursery_owner(((storage.foldername(name))[1])::uuid));

-- --------------------------------------------------------------- الأقسام
insert into categories (name_ar, name_en, slug, icon, sort) values
  ('نباتات داخلية', 'Indoor plants',  'indoor',    'local_florist', 1),
  ('نباتات خارجية', 'Outdoor plants', 'outdoor',   'park',          2),
  ('أشجار ونخيل',   'Trees & palms',  'trees',     'forest',        3),
  ('ورود وزهور',   'Flowers',        'flowers',   'filter_vintage',4),
  ('صبّار وعصاريات','Cacti & succulents','cacti',  'grass',         5),
  ('بذور وشتلات',  'Seeds & seedlings','seeds',  'spa',           6),
  ('أسمدة وتربة',  'Fertilizer & soil','soil',   'compost',       7),
  ('أدوات العناية', 'Garden tools',   'tools',     'handyman',      8),
  ('أصاصيص',         'Pots',           'pots',      'inventory_2',   9)
on conflict (slug) do nothing;

-- ---------------------------------------------- التحديث اللحظي للطلبات والتوصيل
alter publication supabase_realtime add table orders;
alter publication supabase_realtime add table deliveries;
alter publication supabase_realtime add table notifications;
