-- InMo: pega TODO esto en Supabase > SQL Editor > Run
create extension if not exists pgcrypto;
create table public.properties(
 id uuid primary key default gen_random_uuid(),
 title text not null, category text not null,
 operation text not null check(operation in('venta','alquiler')),
 price numeric not null, currency text default 'USD',
 province text not null, municipality text not null, address text, description text,
 bedrooms int default 0, bathrooms int default 0, area numeric default 0, condition text, extras text,
 photos text[] default '{}', owner_name text, owner_phone text, owner_whatsapp text, preferred_contact text,
 status text not null default 'pending' check(status in('pending','approved','rejected','sold','rented')),
 views int not null default 0, created_at timestamptz default now());
create table public.publish_links(
 token text primary key, expires_at timestamptz not null,
 status text not null default 'active' check(status in('active','used','disabled')),
 used_at timestamptz, property_id uuid, created_at timestamptz default now());
create table public.settings(key text primary key, value jsonb not null);
insert into public.settings values('subscriptions','{"enabled":false,"plans":[{"name":"Básico","price":5,"limit":3},{"name":"Pro","price":15,"limit":15}]}');
alter table public.properties enable row level security;
alter table public.publish_links enable row level security;
alter table public.settings enable row level security;
create policy "publico ve aprobadas" on public.properties for select using(status in('approved','sold','rented'));
create policy "admin propiedades" on public.properties for all to authenticated using(true) with check(true);
create policy "admin enlaces" on public.publish_links for all to authenticated using(true) with check(true);
create policy "ajustes lectura" on public.settings for select using(true);
create policy "admin ajustes" on public.settings for all to authenticated using(true) with check(true);
create function public.link_active(t text) returns boolean language sql security definer set search_path=public as
$$ select exists(select 1 from publish_links where token=t and status='active' and expires_at>now()) $$;
create function public.check_link(t text) returns text language sql security definer set search_path=public as
$$ select coalesce((select case when status='disabled' then 'disabled' when status='used' then 'used' when expires_at<=now() then 'expired' else 'ok' end from publish_links where token=t),'invalid') $$;
create function public.submit_property(t text,d jsonb) returns uuid language plpgsql security definer set search_path=public as $$
declare pid uuid:=gen_random_uuid();
begin
 update publish_links set status='used',used_at=now(),property_id=pid where token=t and status='active' and expires_at>now();
 if not found then raise exception 'link_invalid'; end if;
 insert into properties(id,title,category,operation,price,currency,province,municipality,address,description,bedrooms,bathrooms,area,condition,extras,photos,owner_name,owner_phone,owner_whatsapp,preferred_contact)
 values(pid,left(d->>'title',150),d->>'category',d->>'operation',(d->>'price')::numeric,coalesce(d->>'currency','USD'),d->>'province',d->>'municipality',d->>'address',d->>'description',coalesce((d->>'bedrooms')::int,0),coalesce((d->>'bathrooms')::int,0),coalesce((d->>'area')::numeric,0),d->>'condition',d->>'extras',coalesce(array(select jsonb_array_elements_text(d->'photos')),'{}'),d->>'owner_name',d->>'owner_phone',d->>'owner_whatsapp',d->>'preferred_contact');
 return pid;
end $$;
create function public.add_view(pid uuid) returns void language sql security definer set search_path=public as
$$ update properties set views=views+1 where id=pid and status in('approved','sold','rented') $$;
insert into storage.buckets(id,name,public) values('photos','photos',true) on conflict do nothing;
create policy "fotos lectura" on storage.objects for select using(bucket_id='photos');
create policy "fotos subir con enlace" on storage.objects for insert to anon,authenticated with check(bucket_id='photos' and public.link_active((storage.foldername(name))[1]));
create policy "fotos admin" on storage.objects for all to authenticated using(bucket_id='photos') with check(bucket_id='photos');
alter publication supabase_realtime add table public.properties;
