-- Verteilerplanung Schachenmann: Cloud einrichten (einmal im Supabase SQL Editor ausführen)
-- Legt an: Namen (people), Baustellen (sites), Speicher für Wärmepumpen-Schemas (wp) und alle Zugriffsregeln.
-- Kann gefahrlos mehrmals ausgeführt werden.

create table if not exists public.people (
  id text primary key,
  name text not null unique,
  admin boolean not null default false,
  auth_uid uuid unique references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.sites (
  id text primary key,
  owner text not null,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.people enable row level security;
alter table public.sites enable row level security;

grant select on public.people to anon, authenticated;
grant insert, update, delete on public.people to authenticated;
grant select, insert, update, delete on public.sites to authenticated;

-- Hilfsfunktionen: wer bin ich, bin ich Verwaltung
create or replace function public.my_person() returns text
language sql stable security definer set search_path = public as $$
  select id from public.people where auth_uid = auth.uid()
$$;
create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select admin from public.people where auth_uid = auth.uid()), false)
$$;

-- Erste Anmeldung: Konto mit dem Namen verbinden
create or replace function public.claim_person(p_id text) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.people set auth_uid = auth.uid()
   where id = p_id and auth_uid is null
     and lower(p_id || '@schachenmann-vp.ch') = lower(auth.jwt() ->> 'email');
  if not found then raise exception 'Name ist schon vergeben oder passt nicht'; end if;
end $$;

-- Verwaltung: Passwort zurücksetzen (Konto löschen, Person legt beim nächsten Anmelden ein neues Passwort fest)
create or replace function public.admin_reset(p_id text) returns void
language plpgsql security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then raise exception 'nur für die Verwaltung'; end if;
  delete from auth.users where id = (select auth_uid from public.people where id = p_id);
end $$;

grant execute on function public.my_person() to authenticated;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.claim_person(text) to authenticated;
grant execute on function public.admin_reset(text) to authenticated;

-- Regeln Namen: Liste sehen alle (für die Anmeldung), ändern nur die Verwaltung
drop policy if exists people_read on public.people;
drop policy if exists people_ins on public.people;
drop policy if exists people_upd on public.people;
drop policy if exists people_del on public.people;
create policy people_read on public.people for select to anon, authenticated using (true);
create policy people_ins on public.people for insert to authenticated with check (public.is_admin());
create policy people_upd on public.people for update to authenticated using (public.is_admin());
create policy people_del on public.people for delete to authenticated using (public.is_admin());

-- Regeln Baustellen: alle Angemeldeten sehen alles, ändern nur Ersteller und freigegebene Planer, löschen nur Ersteller
drop policy if exists sites_read on public.sites;
drop policy if exists sites_ins on public.sites;
drop policy if exists sites_upd on public.sites;
drop policy if exists sites_del on public.sites;
create policy sites_read on public.sites for select to authenticated using (public.my_person() is not null);
create policy sites_ins on public.sites for insert to authenticated with check (public.my_person() is not null);
create policy sites_upd on public.sites for update to authenticated
  using (owner = public.my_person() or (data -> 'editors') ? public.my_person())
  with check (public.my_person() is not null);
create policy sites_del on public.sites for delete to authenticated using (owner = public.my_person());

-- Speicher für Wärmepumpen-Schemas
insert into storage.buckets (id, name, public) values ('wp', 'wp', false) on conflict (id) do nothing;
drop policy if exists wp_read on storage.objects;
drop policy if exists wp_ins on storage.objects;
drop policy if exists wp_upd on storage.objects;
create policy wp_read on storage.objects for select to authenticated using (bucket_id = 'wp' and public.my_person() is not null);
create policy wp_ins on storage.objects for insert to authenticated with check (bucket_id = 'wp' and public.my_person() is not null);
create policy wp_upd on storage.objects for update to authenticated using (bucket_id = 'wp' and public.my_person() is not null);

-- Startnamen (Tobias Müller = Verwaltung)
insert into public.people (id, name, admin) values
  ('p-cihad-mekikli', 'Cihad Mekikli', false),
  ('p-marco-winkler', 'Marco Winkler', false),
  ('p-shajatan-kumar', 'Shajatan Kumar', false),
  ('p-mumin-jakupi', 'Mumin Jakupi', false),
  ('p-tobias-mueller', 'Tobias Müller', true),
  ('p-lionel-mazard', 'Lionel Mazard', false)
on conflict (id) do nothing;
