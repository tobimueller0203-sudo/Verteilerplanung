-- Verteilerplanung: Tabelle für hinterlegte Bauteile (einmal im Supabase SQL Editor ausführen, kann mehrmals laufen)
create table if not exists public.parts (
  id text primary key,
  kind text not null,
  hst text,
  lf text,
  typ text,
  enr text not null,
  net numeric,
  bru numeric,
  created_by text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.parts enable row level security;
grant select, insert, update, delete on public.parts to authenticated;
drop policy if exists parts_read on public.parts;
drop policy if exists parts_ins on public.parts;
drop policy if exists parts_upd on public.parts;
drop policy if exists parts_del on public.parts;
-- alle Angemeldeten sehen und erfassen Bauteile; ändern und löschen nur die Verwaltung
create policy parts_read on public.parts for select to authenticated using (public.my_person() is not null);
create policy parts_ins on public.parts for insert to authenticated with check (public.my_person() is not null and created_by = public.my_person());
create policy parts_upd on public.parts for update to authenticated using (public.is_admin());
create policy parts_del on public.parts for delete to authenticated using (public.is_admin());
