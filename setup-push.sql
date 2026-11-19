-- Avisos push: pega en Supabase > SQL Editor > Run
create table public.push_subscriptions(endpoint text primary key, p256dh text not null, auth text not null, created_at timestamptz default now());
alter table public.push_subscriptions enable row level security;
create policy "admin push" on public.push_subscriptions for all to authenticated using(true) with check(true);
