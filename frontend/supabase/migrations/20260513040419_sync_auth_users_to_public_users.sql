create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  email text unique not null,
  full_name text,
  role text not null default 'customer',
  created_at timestamptz not null default now()
);

alter table public.users enable row level security;

drop policy if exists "Users can read own public user row" on public.users;
create policy "Users can read own public user row"
on public.users
for select
using (auth.uid() = id);

drop policy if exists "Users can update own public user row" on public.users;
create policy "Users can update own public user row"
on public.users
for update
using (auth.uid() = id)
with check (auth.uid() = id);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''))
  on conflict (id) do update set
    full_name = coalesce(excluded.full_name, public.profiles.full_name);

  insert into public.users (id, email, full_name, role, created_at)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    'customer',
    new.created_at
  )
  on conflict (id) do update set
    email = excluded.email,
    full_name = coalesce(excluded.full_name, public.users.full_name),
    role = coalesce(public.users.role, excluded.role);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

insert into public.users (id, email, full_name, role, created_at)
select
  id,
  email,
  coalesce(raw_user_meta_data ->> 'full_name', ''),
  'customer',
  created_at
from auth.users
where email is not null
on conflict (id) do update set
  email = excluded.email,
  full_name = coalesce(excluded.full_name, public.users.full_name);

insert into public.profiles (id, full_name, created_at)
select
  id,
  coalesce(raw_user_meta_data ->> 'full_name', ''),
  created_at
from auth.users
on conflict (id) do update set
  full_name = coalesce(excluded.full_name, public.profiles.full_name);
