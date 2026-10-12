-- =====================================================================
-- فناء (Fenaa) — 0003_functions.sql — منطق الأعمال والمحفّزات
-- =====================================================================

-- ---------------------------------------------------------- updated_at
create or replace function set_updated_at() returns trigger language plpgsql as $$
begin new.updated_at := now(); return new; end $$;

create trigger t_profiles_upd  before update on profiles  for each row execute function set_updated_at();
create trigger t_nurseries_upd before update on nurseries for each row execute function set_updated_at();
create trigger t_products_upd  before update on products  for each row execute function set_updated_at();
create trigger t_orders_upd    before update on orders    for each row execute function set_updated_at();
create trigger t_carts_upd     before update on carts     for each row execute function set_updated_at();

-- ----------------------------------------------- profile عند التسجيل
create or replace function handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, phone, full_name, role)
  values (new.id, new.phone,
          coalesce(new.raw_user_meta_data->>'full_name', ''),
          coalesce((new.raw_user_meta_data->>'role')::user_role, 'customer'))
  on conflict (id) do nothing;
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
for each row execute function handle_new_user();

-- ------------------------------------------------------- رقم الطلب
create sequence if not exists order_number_seq start 12001;

create or replace function set_order_number() returns trigger language plpgsql as $$
begin
  if new.order_number is null then new.order_number := nextval('order_number_seq'); end if;
  return new;
end $$;
create trigger t_orders_number before insert on orders for each row execute function set_order_number();

-- -------------------------------------------- المشاتل القريبة (خريطة)
create or replace function nearby_nurseries(p_lat double precision, p_lng double precision,
                                            p_radius_km double precision default 15)
returns table (
  id uuid, name text, slug text, logo_url text, cover_url text, city text, district text,
  rating_avg numeric, rating_count int, delivery_fee numeric, free_delivery_over numeric,
  prep_time_min int, is_open boolean, lat double precision, lng double precision, distance_km double precision)
language sql stable as $$
  select n.id, n.name, n.slug, n.logo_url, n.cover_url, n.city, n.district,
         n.rating_avg, n.rating_count, n.delivery_fee, n.free_delivery_over, n.prep_time_min,
         (n.is_open and not n.on_vacation) as is_open,
         st_y(n.location::geometry) as lat, st_x(n.location::geometry) as lng,
         st_distance(n.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography) / 1000 as distance_km
  from nurseries n
  where n.is_active
    and st_dwithin(n.location, st_setsrid(st_makepoint(p_lng, p_lat), 4326)::geography, p_radius_km * 1000)
  order by distance_km
$$;

-- --------------------------------------------- QR فاتورة الزكاة (TLV)
create or replace function tlv_field(tag int, val text) returns bytea language sql immutable as $$
  select decode(lpad(to_hex(tag), 2, '0'), 'hex')
      || decode(lpad(to_hex(octet_length(convert_to(val, 'UTF8'))), 2, '0'), 'hex')
      || convert_to(val, 'UTF8')
$$;

create or replace function zatca_qr(p_seller text, p_vat text, p_ts timestamptz,
                                    p_total numeric, p_vat_amt numeric) returns text
language sql immutable as $$
  select replace(encode(
    tlv_field(1, p_seller)
    || tlv_field(2, coalesce(p_vat, ''))
    || tlv_field(3, to_char(p_ts at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'))
    || tlv_field(4, to_char(p_total,   'FM999999990.00'))
    || tlv_field(5, to_char(p_vat_amt, 'FM999999990.00')), 'base64'), E'\n', '')
$$;

-- ------------------------------------------------- إتمام الطلب (RPC)
create or replace function place_order(
  p_nursery_id uuid, p_address_id uuid, p_payment_method payment_method,
  p_coupon text default null, p_note text default null, p_scheduled_at timestamptz default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid();
  v_cart carts%rowtype; v_n nurseries%rowtype; v_addr addresses%rowtype; v_c coupons%rowtype;
  v_subtotal numeric := 0; v_delivery numeric := 0; v_discount numeric := 0; v_merchant_disc numeric := 0;
  v_total numeric; v_vat numeric; v_comm numeric; v_payout numeric; v_used int;
  v_order_id uuid; v_order_no bigint; r record;
begin
  if v_uid is null then raise exception 'unauthenticated'; end if;

  select * into v_n from nurseries where id = p_nursery_id and is_active;
  if not found then raise exception 'المشتل غير متاح'; end if;
  if not v_n.is_open or v_n.on_vacation then raise exception 'المشتل مغلق حاليًا'; end if;

  select * into v_addr from addresses where id = p_address_id and user_id = v_uid;
  if not found then raise exception 'العنوان غير موجود'; end if;

  select * into v_cart from carts where user_id = v_uid and nursery_id = p_nursery_id;
  if not found then raise exception 'السلة فارغة'; end if;

  for r in
    select ci.qty, p.id as product_id, p.name, p.is_available, p.is_archived, p.stock as pstock,
           v.id as variant_id, v.stock as vstock, v.is_active as vactive,
           coalesce(v.price, p.base_price) as unit_price
    from cart_items ci
    join products p on p.id = ci.product_id
    left join product_variants v on v.id = ci.variant_id
    where ci.cart_id = v_cart.id
  loop
    if r.is_archived or not r.is_available then raise exception 'المنتج % غير متاح', r.name; end if;
    if r.variant_id is not null and (not r.vactive or r.vstock < r.qty) then raise exception 'الكمية غير متوفرة: %', r.name; end if;
    if r.variant_id is null and r.pstock < r.qty then raise exception 'الكمية غير متوفرة: %', r.name; end if;
    v_subtotal := v_subtotal + r.unit_price * r.qty;
  end loop;

  if v_subtotal = 0 then raise exception 'السلة فارغة'; end if;
  if v_subtotal < v_n.min_order then raise exception 'الحد الأدنى للطلب % ر.س', v_n.min_order; end if;

  v_delivery := case when v_n.free_delivery_over is not null and v_subtotal >= v_n.free_delivery_over
                     then 0 else v_n.delivery_fee end;

  if p_coupon is not null and length(trim(p_coupon)) > 0 then
    select * into v_c from coupons
    where code = upper(trim(p_coupon)) and is_active
      and starts_at <= now() and (ends_at is null or ends_at > now())
      and (nursery_id is null or nursery_id = p_nursery_id);
    if not found then raise exception 'الكوبون غير صالح'; end if;
    if v_subtotal < v_c.min_order then raise exception 'الكوبون يتطلب حدًا أدنى % ر.س', v_c.min_order; end if;
    if v_c.usage_limit is not null and v_c.used_count >= v_c.usage_limit then raise exception 'انتهت استخدامات الكوبون'; end if;
    select count(*) into v_used from coupon_redemptions where code = v_c.code and user_id = v_uid;
    if v_used >= v_c.per_user_limit then raise exception 'استخدمت هذا الكوبون من قبل'; end if;
    v_discount := case v_c.type when 'percent' then round(v_subtotal * v_c.value / 100, 2) else v_c.value end;
    if v_c.max_discount is not null then v_discount := least(v_discount, v_c.max_discount); end if;
    v_discount := least(v_discount, v_subtotal);
    if v_c.nursery_id is not null then v_merchant_disc := v_discount; end if;
  end if;

  v_total  := greatest(v_subtotal + v_delivery - v_discount, 0);
  v_vat    := round(v_total - v_total / 1.15, 2);
  v_comm   := round(v_subtotal * v_n.commission_rate, 2);
  v_payout := v_subtotal + v_delivery - v_comm - v_merchant_disc;

  insert into orders (user_id, nursery_id, payment_method, address_snapshot, customer_note, scheduled_at,
                      subtotal, delivery_fee, discount, total, vat_rate, vat_amount, commission, net_payout, coupon_code)
  values (v_uid, p_nursery_id, p_payment_method,
          (to_jsonb(v_addr) - 'location') || jsonb_build_object('lat', st_y(v_addr.location::geometry),
                                                                 'lng', st_x(v_addr.location::geometry)),
          p_note, p_scheduled_at, v_subtotal, v_delivery, v_discount, v_total, 0.15, v_vat, v_comm, v_payout,
          case when v_c.code is null then null else v_c.code end)
  returning id, order_number into v_order_id, v_order_no;

  insert into order_items (order_id, product_id, variant_id, name, variant_name, unit_price, qty, line_total)
  select v_order_id, p.id, v.id, p.name, v.name, coalesce(v.price, p.base_price), ci.qty,
         coalesce(v.price, p.base_price) * ci.qty
  from cart_items ci
  join products p on p.id = ci.product_id
  left join product_variants v on v.id = ci.variant_id
  where ci.cart_id = v_cart.id;

  update product_variants v set stock = v.stock - ci.qty
    from cart_items ci where ci.cart_id = v_cart.id and ci.variant_id = v.id;
  update products p set stock = p.stock - ci.qty
    from cart_items ci where ci.cart_id = v_cart.id and ci.variant_id is null and ci.product_id = p.id;

  insert into order_status_history (order_id, status, actor_id) values (v_order_id, 'pending', v_uid);

  if v_c.code is not null then
    insert into coupon_redemptions (code, user_id, order_id) values (v_c.code, v_uid, v_order_id);
    update coupons set used_count = used_count + 1 where code = v_c.code;
  end if;

  delete from carts where id = v_cart.id;

  if v_n.auto_accept then
    update orders set status = 'accepted', accepted_at = now() where id = v_order_id;
    insert into order_status_history (order_id, status, note) values (v_order_id, 'accepted', 'قبول تلقائي');
  end if;

  insert into notifications (user_id, title, body, data)
  values (v_n.owner_id, 'طلب جديد', 'طلب #' || v_order_no || ' بقيمة ' || v_total || ' ر.س',
          jsonb_build_object('order_id', v_order_id));

  return v_order_id;
end $$;

-- ------------------------------------------------- تحديث حالة الطلب
create or replace function update_order_status(p_order_id uuid, p_status order_status, p_note text default null)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := auth.uid(); o orders%rowtype;
  v_owner boolean; v_courier boolean; v_customer boolean;
begin
  select * into o from orders where id = p_order_id for update;
  if not found then raise exception 'الطلب غير موجود'; end if;

  v_owner    := is_nursery_owner(o.nursery_id);
  v_customer := o.user_id = v_uid;
  v_courier  := exists (select 1 from deliveries d join couriers c on c.id = d.courier_id
                        where d.order_id = o.id and c.profile_id = v_uid);

  if p_status in ('accepted','preparing','ready','rejected') and not v_owner then raise exception 'غير مصرح'; end if;
  if p_status in ('out_for_delivery','delivered') and not (v_owner or v_courier) then raise exception 'غير مصرح'; end if;
  if p_status = 'cancelled' and not (v_customer and o.status = 'pending') then raise exception 'لا يمكن إلغاء الطلب في هذه المرحلة'; end if;

  if not (
       (o.status = 'pending'          and p_status in ('accepted','rejected','cancelled'))
    or (o.status = 'accepted'         and p_status in ('preparing','ready','rejected'))
    or (o.status = 'preparing'        and p_status = 'ready')
    or (o.status = 'ready'            and p_status = 'out_for_delivery')
    or (o.status = 'out_for_delivery' and p_status = 'delivered')
  ) then raise exception 'انتقال غير صالح من % إلى %', o.status, p_status; end if;

  update orders set
    status        = p_status,
    accepted_at   = case when p_status = 'accepted'         then now() else accepted_at end,
    ready_at      = case when p_status = 'ready'            then now() else ready_at end,
    picked_up_at  = case when p_status = 'out_for_delivery' then now() else picked_up_at end,
    delivered_at  = case when p_status = 'delivered'        then now() else delivered_at end,
    cancel_reason = case when p_status in ('cancelled','rejected') then p_note else cancel_reason end
  where id = p_order_id;

  insert into order_status_history (order_id, status, actor_id, note) values (p_order_id, p_status, v_uid, p_note);

  insert into notifications (user_id, title, body, data) values (o.user_id,
    case p_status
      when 'accepted'         then 'تم قبول طلبك'
      when 'preparing'        then 'المشتل يجهّز طلبك'
      when 'ready'            then 'طلبك جاهز'
      when 'out_for_delivery' then 'طلبك في الطريق'
      when 'delivered'        then 'تم توصيل طلبك'
      when 'rejected'         then 'تم رفض الطلب'
      else 'تحديث على طلبك' end,
    'طلب #' || o.order_number, jsonb_build_object('order_id', p_order_id, 'status', p_status));

  if p_status in ('cancelled','rejected') then
    update product_variants v set stock = v.stock + oi.qty
      from order_items oi where oi.order_id = p_order_id and oi.variant_id = v.id;
    update products p set stock = p.stock + oi.qty
      from order_items oi where oi.order_id = p_order_id and oi.variant_id is null and oi.product_id = p.id;
  end if;
end $$;

-- ------------------------------------ عند التوصيل: فاتورة + محفظة
create or replace function on_order_delivered() returns trigger
language plpgsql security definer set search_path = public as $$
declare n nurseries%rowtype; v_bal numeric;
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered' then
    select * into n from nurseries where id = new.nursery_id;

    insert into invoices (order_id, invoice_number, seller_name, seller_vat, issued_at,
                          vat_rate, vat_amount, total, zatca_qr)
    values (new.id, 'INV-' || new.order_number, n.name, n.tax_number, now(),
            new.vat_rate, new.vat_amount, new.total,
            zatca_qr(n.name, n.tax_number, now(), new.total, new.vat_amount))
    on conflict (order_id) do nothing;

    insert into wallets (nursery_id) values (new.nursery_id) on conflict do nothing;
    update wallets set balance = balance + new.net_payout, updated_at = now()
      where nursery_id = new.nursery_id returning balance into v_bal;
    insert into wallet_transactions (nursery_id, order_id, type, amount, balance_after, note)
    values (new.nursery_id, new.id, 'order_credit', new.net_payout, v_bal, 'صافي طلب #' || new.order_number);

    update products p set sold_count = p.sold_count + oi.qty
      from order_items oi where oi.order_id = new.id and oi.product_id = p.id;

    if new.payment_method = 'cod' then
      update orders set payment_status = 'paid' where id = new.id;
    end if;
  end if;
  return new;
end $$;

create trigger t_order_delivered after update of status on orders
for each row execute function on_order_delivered();

-- --------------------------------------------------- تقييم المشتل
create or replace function recompute_nursery_rating() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update nurseries set rating_avg = s.avg_r, rating_count = s.cnt
  from (select round(avg(rating), 2) as avg_r, count(*) as cnt from reviews where nursery_id = new.nursery_id) s
  where id = new.nursery_id;
  return new;
end $$;

create trigger t_reviews_rating after insert on reviews
for each row execute function recompute_nursery_rating();

-- ------------------------------------- تأكيد الدفع (من الويبهوك فقط)
create or replace function mark_order_paid(p_order_id uuid, p_provider text, p_ref text,
                                           p_method payment_method, p_amount numeric, p_raw jsonb default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into payments (order_id, provider, provider_ref, method, amount, status, raw)
  values (p_order_id, p_provider, p_ref, p_method, p_amount, 'paid', p_raw)
  on conflict (provider, provider_ref) do update set status = 'paid', raw = excluded.raw;
  update orders set payment_status = 'paid', payment_method = p_method where id = p_order_id;
end $$;

revoke execute on function mark_order_paid(uuid, text, text, payment_method, numeric, jsonb) from public, anon, authenticated;

-- ------------------------------------------------------ طلب سحب
create or replace function request_payout(p_nursery_id uuid, p_amount numeric, p_iban_last4 text)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_bal numeric; v_id uuid;
begin
  if not is_nursery_owner(p_nursery_id) then raise exception 'غير مصرح'; end if;
  select balance into v_bal from wallets where nursery_id = p_nursery_id for update;
  if coalesce(v_bal, 0) < p_amount then raise exception 'الرصيد غير كافٍ'; end if;
  update wallets set balance = balance - p_amount, pending = pending + p_amount where nursery_id = p_nursery_id;
  insert into payouts (nursery_id, amount, iban_last4) values (p_nursery_id, p_amount, p_iban_last4) returning id into v_id;
  insert into wallet_transactions (nursery_id, type, amount, balance_after, note)
  values (p_nursery_id, 'payout', -p_amount, v_bal - p_amount, 'طلب سحب');
  return v_id;
end $$;
