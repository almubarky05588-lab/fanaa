-- =====================================================================
-- فناء (Fenaa) — 0002_rls.sql — سياسات الصلاحيات على مستوى الصفوف
-- =====================================================================

-- ------------------------------------------------------------- HELPERS
create or replace function auth_role() returns user_role
language sql stable security definer set search_path = public as $$
  select role from profiles where id = auth.uid()
$$;

create or replace function is_nursery_owner(nid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from nurseries where id = nid and owner_id = auth.uid())
$$;

create or replace function can_see_order(oid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from orders o
    where o.id = oid
      and (o.user_id = auth.uid() or is_nursery_owner(o.nursery_id)
           or exists (select 1 from deliveries d join couriers c on c.id = d.courier_id
                      where d.order_id = o.id and c.profile_id = auth.uid()))
  )
$$;

-- ---------------------------------------------------------- ENABLE RLS
alter table profiles             enable row level security;
alter table addresses            enable row level security;
alter table nurseries            enable row level security;
alter table working_hours        enable row level security;
alter table categories           enable row level security;
alter table products             enable row level security;
alter table product_variants     enable row level security;
alter table favorites            enable row level security;
alter table carts                enable row level security;
alter table cart_items           enable row level security;
alter table coupons              enable row level security;
alter table coupon_redemptions   enable row level security;
alter table orders               enable row level security;
alter table order_items          enable row level security;
alter table order_status_history enable row level security;
alter table payments             enable row level security;
alter table invoices             enable row level security;
alter table couriers             enable row level security;
alter table deliveries           enable row level security;
alter table wallets              enable row level security;
alter table wallet_transactions  enable row level security;
alter table payouts              enable row level security;
alter table reviews              enable row level security;
alter table device_tokens        enable row level security;
alter table notifications        enable row level security;

-- ------------------------------------------------------------ PROFILES
create policy profiles_select_own on profiles for select using (id = auth.uid());
create policy profiles_update_own on profiles for update using (id = auth.uid())
  with check (id = auth.uid() and role = (select role from profiles where id = auth.uid()));

-- ----------------------------------------------------------- ADDRESSES
create policy addresses_all_own on addresses for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ----------------------------------------------------------- NURSERIES
create policy nurseries_select_public on nurseries for select
  using (is_active or owner_id = auth.uid());
create policy nurseries_insert_owner on nurseries for insert
  with check (owner_id = auth.uid() and auth_role() = 'merchant');
create policy nurseries_update_owner on nurseries for update
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());

create policy working_hours_select on working_hours for select using (true);
create policy working_hours_write on working_hours for all
  using (is_nursery_owner(nursery_id)) with check (is_nursery_owner(nursery_id));

-- ------------------------------------------------------------- CATALOG
create policy categories_select on categories for select using (is_active);

create policy products_select on products for select
  using ((not is_archived and is_available) or is_nursery_owner(nursery_id));
create policy products_write on products for all
  using (is_nursery_owner(nursery_id)) with check (is_nursery_owner(nursery_id));

create policy variants_select on product_variants for select
  using (exists (select 1 from products p where p.id = product_id
                 and ((not p.is_archived) or is_nursery_owner(p.nursery_id))));
create policy variants_write on product_variants for all
  using (exists (select 1 from products p where p.id = product_id and is_nursery_owner(p.nursery_id)))
  with check (exists (select 1 from products p where p.id = product_id and is_nursery_owner(p.nursery_id)));

create policy favorites_all_own on favorites for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------- CART
create policy carts_all_own on carts for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy cart_items_all_own on cart_items for all
  using (exists (select 1 from carts c where c.id = cart_id and c.user_id = auth.uid()))
  with check (exists (select 1 from carts c where c.id = cart_id and c.user_id = auth.uid()));

-- ------------------------------------------------------------- COUPONS
create policy coupons_select_active on coupons for select
  using (is_active and (ends_at is null or ends_at > now()) or is_nursery_owner(nursery_id));
create policy coupons_write_owner on coupons for all
  using (nursery_id is not null and is_nursery_owner(nursery_id))
  with check (nursery_id is not null and is_nursery_owner(nursery_id));
create policy coupon_redemptions_select_own on coupon_redemptions for select
  using (user_id = auth.uid());

-- --------------------------------------------------------------- ORDERS
-- الكتابة في الطلبات تتم فقط عبر دوال security definer (0003)
create policy orders_select on orders for select using (can_see_order(id));
create policy order_items_select on order_items for select using (can_see_order(order_id));
create policy osh_select on order_status_history for select using (can_see_order(order_id));
create policy payments_select on payments for select using (can_see_order(order_id));
create policy invoices_select on invoices for select using (can_see_order(order_id));

-- ------------------------------------------------------------ DELIVERY
create policy couriers_select on couriers for select using (true);
create policy couriers_update_self on couriers for update
  using (profile_id = auth.uid()) with check (profile_id = auth.uid());
create policy deliveries_select on deliveries for select using (can_see_order(order_id));
create policy deliveries_update_courier on deliveries for update
  using (exists (select 1 from couriers c where c.id = courier_id and c.profile_id = auth.uid()))
  with check (exists (select 1 from couriers c where c.id = courier_id and c.profile_id = auth.uid()));

-- -------------------------------------------------------------- WALLET
create policy wallets_select_owner on wallets for select using (is_nursery_owner(nursery_id));
create policy wallet_txn_select_owner on wallet_transactions for select using (is_nursery_owner(nursery_id));
create policy payouts_select_owner on payouts for select using (is_nursery_owner(nursery_id));
create policy payouts_insert_owner on payouts for insert with check (is_nursery_owner(nursery_id));

-- ------------------------------------------------------------- REVIEWS
create policy reviews_select on reviews for select using (true);
create policy reviews_insert_customer on reviews for insert
  with check (user_id = auth.uid() and exists (
    select 1 from orders o where o.id = order_id and o.user_id = auth.uid() and o.status = 'delivered'));

-- ------------------------------------------------------- NOTIFICATIONS
create policy device_tokens_all_own on device_tokens for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy notifications_select_own on notifications for select using (user_id = auth.uid());
create policy notifications_update_own on notifications for update
  using (user_id = auth.uid()) with check (user_id = auth.uid());
