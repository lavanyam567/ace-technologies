create table if not exists public.recently_viewed_products (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  viewed_at timestamptz not null default now(),
  unique (user_id, product_id)
);

create table if not exists public.compare_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, product_id)
);

alter table public.recently_viewed_products enable row level security;
alter table public.compare_items enable row level security;

drop policy if exists "Users can manage own recently viewed products" on public.recently_viewed_products;
create policy "Users can manage own recently viewed products"
on public.recently_viewed_products
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users can manage own compare items" on public.compare_items;
create policy "Users can manage own compare items"
on public.compare_items
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
