-- إحداثيات المتجر كأعمدة مقروءة (للمسافة وتعديل الموقع على الخريطة)
alter table public.nurseries
  add column if not exists lat double precision generated always as (st_y(location::geometry)) stored,
  add column if not exists lng double precision generated always as (st_x(location::geometry)) stored;

-- الآيبان: جدول خاص لا يقرؤه إلا صاحب المتجر (بيانات المتاجر العامة مقروءة للجميع)
create table if not exists public.nursery_payout (
  nursery_id uuid primary key references public.nurseries(id) on delete cascade,
  iban       text not null check (iban ~ '^SA[0-9]{22}$'),
  updated_at timestamptz not null default now()
);
alter table public.nursery_payout enable row level security;

create policy nursery_payout_owner on public.nursery_payout
  for all to authenticated
  using (exists (select 1 from public.nurseries n where n.id = nursery_id and n.owner_id = auth.uid()))
  with check (exists (select 1 from public.nurseries n where n.id = nursery_id and n.owner_id = auth.uid()));
