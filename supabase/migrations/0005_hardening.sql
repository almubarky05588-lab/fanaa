-- =====================================================================
-- فناء (Fenaa) — 0005_hardening.sql — معالجة تنبيهات أمان Supabase
-- =====================================================================

-- search_path ثابت للدوال
alter function public.set_updated_at() set search_path = public;
alter function public.set_order_number() set search_path = public;
alter function public.nearby_nurseries(double precision, double precision, double precision) set search_path = public;
alter function public.tlv_field(int, text) set search_path = public;
alter function public.zatca_qr(text, text, timestamptz, numeric, numeric) set search_path = public;

-- دوال المحفّزات لا تُستدعى عبر الـAPI
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.on_order_delivered() from public, anon, authenticated;
revoke execute on function public.recompute_nursery_rating() from public, anon, authenticated;

-- دوال الأعمال للمستخدمين المسجّلين فقط
revoke execute on function public.place_order(uuid, uuid, payment_method, text, text, timestamptz) from public, anon;
revoke execute on function public.update_order_status(uuid, order_status, text) from public, anon;
revoke execute on function public.request_payout(uuid, numeric, text) from public, anon;
grant execute on function public.place_order(uuid, uuid, payment_method, text, text, timestamptz) to authenticated;
grant execute on function public.update_order_status(uuid, order_status, text) to authenticated;
grant execute on function public.request_payout(uuid, numeric, text) to authenticated;

-- دوال المساعدة في السياسات
revoke execute on function public.auth_role() from public, anon;
revoke execute on function public.can_see_order(uuid) from public, anon;
grant execute on function public.auth_role() to authenticated;
grant execute on function public.can_see_order(uuid) to authenticated;
grant execute on function public.is_nursery_owner(uuid) to authenticated, anon;

-- جدول PostGIS المرجعي: لا يُعرض للعامة
revoke all on table public.spatial_ref_sys from anon, authenticated;
