-- =====================================================================
-- فناء (Fenaa) — سوق المشاتل
-- 0001_schema.sql — الجداول والأنواع والفهارس
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists postgis;
create extension if not exists pg_trgm;

-- ---------------------------------------------------------------- ENUMS
create type user_role        as enum ('customer', 'merchant', 'courier', 'admin');
create type order_status     as enum ('pending', 'accepted', 'preparing', 'ready',
                                      'out_for_delivery', 'delivered', 'cancelled', 'rejected');
create type payment_status   as enum ('unpaid', 'authorized', 'paid', 'refunded', 'failed');
create type payment_method   as enum ('mada', 'apple_pay', 'credit_card', 'stc_pay', 'tabby', 'cod');
create type coupon_type      as enum ('percent', 'fixed');
create type wallet_txn_type  as enum ('order_credit', 'commission', 'payout', 'refund', 'adjustment');
create type payout_status    as enum ('requested', 'processing', 'paid', 'rejected');
create type delivery_status  as enum ('assigned', 'picked_up', 'arrived', 'delivered', 'failed');

-- ------------------------------------------------------------- PROFILES
create table profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  full_name     text,
  phone         text unique,
  role          user_role   not null default 'customer',
  avatar_url    text,
  locale        text        not null default 'ar',
  loyalty_points int        not null default 0,
  is_active     boolean     not null default true,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create table addresses (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references profiles(id) on delete cascade,
  label       text not null default 'المنزل',
  line        text not null,
  district    text,
  city        text not null,
  notes       text,
  location    geography(Point, 4326),
  is_default  boolean not null default false,
  created_at  timestamptz not null default now()
);
create index addresses_user_idx on addresses(user_id);

-- ------------------------------------------------------------ NURSERIES
create table nurseries (
  id                 uuid primary key default uuid_generate_v4(),
  owner_id           uuid not null references profiles(id) on delete restrict,
  name               text not null,
  slug               text unique not null,
  description        text,
  logo_url           text,
  cover_url          text,
  phone              text,
  tax_number         text,
  cr_number          text,
  city               text not null,
  district           text,
  address_line       text,
  location           geography(Point, 4326) not null,
  delivery_radius_km numeric(5,2)  not null default 8,
  delivery_fee       numeric(10,2) not null default 15,
  free_delivery_over numeric(10,2),
  min_order          numeric(10,2) not null default 0,
  prep_time_min      int           not null default 45,
  commission_rate    numeric(5,4)  not null default 0.10,
  auto_accept        boolean not null default false,
  is_open            boolean not null default true,
  on_vacation        boolean not null default false,
  is_verified        boolean not null default false,
  is_active          boolean not null default true,
  rating_avg         numeric(3,2) not null default 0,
  rating_count       int          not null default 0,
  created_at         timestamptz not null default now(),
  updated_at         timestamptz not null default now()
);
create index nurseries_location_idx on nurseries using gist(location);
create index nurseries_owner_idx    on nurseries(owner_id);
create index nurseries_name_trgm    on nurseries using gin(name gin_trgm_ops);

create table working_hours (
  id          uuid primary key default uuid_generate_v4(),
  nursery_id  uuid not null references nurseries(id) on delete cascade,
  weekday     smallint not null check (weekday between 0 and 6), -- 0=الأحد
  opens_at    time,
  closes_at   time,
  is_closed   boolean not null default false,
  unique (nursery_id, weekday)
);

-- ------------------------------------------------------------- CATALOG
create table categories (
  id        uuid primary key default uuid_generate_v4(),
  name_ar   text not null,
  name_en   text,
  slug      text unique not null,
  icon      text,
  sort      int not null default 0,
  is_active boolean not null default true
);

create table products (
  id           uuid primary key default uuid_generate_v4(),
  nursery_id   uuid not null references nurseries(id) on delete cascade,
  category_id  uuid references categories(id) on delete set null,
  name         text not null,
  description  text,
  images       text[] not null default '{}',
  base_price   numeric(10,2) not null check (base_price >= 0),
  stock        int not null default 0,
  sku          text,
  care_light   text,
  care_water   text,
  care_temp    text,
  is_available boolean not null default true,
  is_archived  boolean not null default false,
  sold_count   int not null default 0,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (nursery_id, sku)
);
create index products_nursery_idx  on products(nursery_id);
create index products_category_idx on products(category_id);
create index products_name_trgm    on products using gin(name gin_trgm_ops);

create table product_variants (
  id         uuid primary key default uuid_generate_v4(),
  product_id uuid not null references products(id) on delete cascade,
  name       text not null,                -- صغير / متوسط / كبير
  price      numeric(10,2) not null check (price >= 0),
  stock      int not null default 0,
  sku        text,
  sort       int not null default 0,
  is_active  boolean not null default true
);
create index variants_product_idx on product_variants(product_id);

create table favorites (
  user_id    uuid not null references profiles(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);

-- ---------------------------------------------------------------- CART
create table carts (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references profiles(id) on delete cascade,
  nursery_id uuid not null references nurseries(id) on delete cascade,
  updated_at timestamptz not null default now(),
  unique (user_id, nursery_id)
);

create table cart_items (
  id         uuid primary key default uuid_generate_v4(),
  cart_id    uuid not null references carts(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  variant_id uuid references product_variants(id) on delete set null,
  qty        int not null check (qty > 0),
  unique (cart_id, product_id, variant_id)
);

-- ------------------------------------------------------------- COUPONS
create table coupons (
  code         text primary key,
  nursery_id   uuid references nurseries(id) on delete cascade, -- null = عام
  type         coupon_type not null,
  value        numeric(10,2) not null check (value > 0),
  min_order    numeric(10,2) not null default 0,
  max_discount numeric(10,2),
  starts_at    timestamptz not null default now(),
  ends_at      timestamptz,
  usage_limit  int,
  used_count   int not null default 0,
  per_user_limit int not null default 1,
  is_active    boolean not null default true
);

create table coupon_redemptions (
  id         uuid primary key default uuid_generate_v4(),
  code       text not null references coupons(code) on delete cascade,
  user_id    uuid not null references profiles(id) on delete cascade,
  order_id   uuid,
  created_at timestamptz not null default now()
);

-- --------------------------------------------------------------- ORDERS
create table orders (
  id               uuid primary key default uuid_generate_v4(),
  order_number     bigint unique,                 -- يُولَّد بمحفّز
  user_id          uuid not null references profiles(id) on delete restrict,
  nursery_id       uuid not null references nurseries(id) on delete restrict,
  status           order_status   not null default 'pending',
  payment_status   payment_status not null default 'unpaid',
  payment_method   payment_method,
  address_snapshot jsonb not null,
  customer_note    text,
  scheduled_at     timestamptz,
  subtotal         numeric(10,2) not null default 0,
  delivery_fee     numeric(10,2) not null default 0,
  discount         numeric(10,2) not null default 0,
  total            numeric(10,2) not null default 0,   -- شامل الضريبة
  vat_rate         numeric(5,4)  not null default 0.15,
  vat_amount       numeric(10,2) not null default 0,   -- المتضمَّنة في total
  commission       numeric(10,2) not null default 0,
  net_payout       numeric(10,2) not null default 0,
  coupon_code      text references coupons(code) on delete set null,
  cancel_reason    text,
  placed_at        timestamptz not null default now(),
  accepted_at      timestamptz,
  ready_at         timestamptz,
  picked_up_at     timestamptz,
  delivered_at     timestamptz,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index orders_user_idx     on orders(user_id, placed_at desc);
create index orders_nursery_idx  on orders(nursery_id, status, placed_at desc);

create table order_items (
  id           uuid primary key default uuid_generate_v4(),
  order_id     uuid not null references orders(id) on delete cascade,
  product_id   uuid references products(id) on delete set null,
  variant_id   uuid references product_variants(id) on delete set null,
  name         text not null,          -- لقطة وقت الطلب
  variant_name text,
  unit_price   numeric(10,2) not null,
  qty          int not null check (qty > 0),
  line_total   numeric(10,2) not null
);
create index order_items_order_idx on order_items(order_id);

create table order_status_history (
  id         uuid primary key default uuid_generate_v4(),
  order_id   uuid not null references orders(id) on delete cascade,
  status     order_status not null,
  actor_id   uuid references profiles(id) on delete set null,
  note       text,
  created_at timestamptz not null default now()
);
create index osh_order_idx on order_status_history(order_id, created_at);

-- ------------------------------------------------------------ PAYMENTS
create table payments (
  id            uuid primary key default uuid_generate_v4(),
  order_id      uuid not null references orders(id) on delete cascade,
  provider      text not null,                -- moyasar / tap / tabby
  provider_ref  text,
  method        payment_method not null,
  amount        numeric(10,2) not null,
  status        payment_status not null default 'unpaid',
  raw           jsonb,
  created_at    timestamptz not null default now(),
  unique (provider, provider_ref)
);

create table invoices (
  id             uuid primary key default uuid_generate_v4(),
  order_id       uuid unique not null references orders(id) on delete cascade,
  invoice_number text unique not null,
  seller_name    text not null,
  seller_vat     text,
  issued_at      timestamptz not null default now(),
  vat_rate       numeric(5,4) not null default 0.15,
  vat_amount     numeric(10,2) not null,
  total          numeric(10,2) not null,
  zatca_qr       text,                        -- TLV base64
  pdf_url        text
);

-- ------------------------------------------------------------ DELIVERY
create table couriers (
  id         uuid primary key default uuid_generate_v4(),
  profile_id uuid unique references profiles(id) on delete cascade,
  name       text not null,
  phone      text not null,
  vehicle    text,
  rating_avg numeric(3,2) not null default 0,
  is_active  boolean not null default true
);

create table deliveries (
  id          uuid primary key default uuid_generate_v4(),
  order_id    uuid unique not null references orders(id) on delete cascade,
  courier_id  uuid references couriers(id) on delete set null,
  status      delivery_status not null default 'assigned',
  location    geography(Point, 4326),
  eta_minutes int,
  updated_at  timestamptz not null default now()
);

-- -------------------------------------------------------------- WALLET
create table wallets (
  nursery_id uuid primary key references nurseries(id) on delete cascade,
  balance    numeric(12,2) not null default 0,
  pending    numeric(12,2) not null default 0,
  updated_at timestamptz not null default now()
);

create table wallet_transactions (
  id            uuid primary key default uuid_generate_v4(),
  nursery_id    uuid not null references nurseries(id) on delete cascade,
  order_id      uuid references orders(id) on delete set null,
  type          wallet_txn_type not null,
  amount        numeric(12,2) not null,      -- موجب دائن / سالب مدين
  balance_after numeric(12,2) not null,
  note          text,
  created_at    timestamptz not null default now()
);
create index wallet_txn_idx on wallet_transactions(nursery_id, created_at desc);

create table payouts (
  id           uuid primary key default uuid_generate_v4(),
  nursery_id   uuid not null references nurseries(id) on delete cascade,
  amount       numeric(12,2) not null check (amount > 0),
  status       payout_status not null default 'requested',
  iban_last4   text,
  requested_at timestamptz not null default now(),
  paid_at      timestamptz,
  note         text
);

-- ------------------------------------------------------------- REVIEWS
create table reviews (
  id         uuid primary key default uuid_generate_v4(),
  order_id   uuid unique not null references orders(id) on delete cascade,
  user_id    uuid not null references profiles(id) on delete cascade,
  nursery_id uuid not null references nurseries(id) on delete cascade,
  rating     smallint not null check (rating between 1 and 5),
  comment    text,
  created_at timestamptz not null default now()
);
create index reviews_nursery_idx on reviews(nursery_id, created_at desc);

-- ------------------------------------------------------- NOTIFICATIONS
create table device_tokens (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references profiles(id) on delete cascade,
  token      text unique not null,
  platform   text not null,
  created_at timestamptz not null default now()
);

create table notifications (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references profiles(id) on delete cascade,
  title      text not null,
  body       text,
  data       jsonb,
  read_at    timestamptz,
  created_at timestamptz not null default now()
);
create index notifications_user_idx on notifications(user_id, created_at desc);
