-- Verteilerplanung: Produktkatalog in der Cloud (einmal im Supabase SQL Editor ausführen, kann mehrmals laufen)
-- Die App füllt die Tabelle selbst, sobald sich die Verwaltung (Tobias Müller) anmeldet.
create table if not exists public.catalog (
  key text primary key,
  grp text,
  nr text,
  art text,
  lf text,
  net numeric,
  bru numeric,
  src text not null default 'code',
  updated_by text,
  updated_at timestamptz not null default now()
);
alter table public.catalog enable row level security;
grant select, insert, update, delete on public.catalog to authenticated;
drop policy if exists catalog_read on public.catalog;
drop policy if exists catalog_ins on public.catalog;
drop policy if exists catalog_upd on public.catalog;
drop policy if exists catalog_del on public.catalog;
-- alle Angemeldeten lesen; anlegen, ändern, löschen nur die Verwaltung
create policy catalog_read on public.catalog for select to authenticated using (public.my_person() is not null);
create policy catalog_ins on public.catalog for insert to authenticated with check (public.is_admin());
create policy catalog_upd on public.catalog for update to authenticated using (public.is_admin());
create policy catalog_del on public.catalog for delete to authenticated using (public.is_admin());
