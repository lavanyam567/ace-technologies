alter table public.orders
add column if not exists payment_status text not null default 'pending',
add column if not exists payment_reference text;
