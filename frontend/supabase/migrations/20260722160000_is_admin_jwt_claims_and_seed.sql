-- Redefine is_admin function to use JWT claims fallback for immediate/robust check
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'admin'
  )
  or exists (
    select 1
    from public.users
    where id = auth.uid()
      and role = 'admin'
  )
  or coalesce((auth.jwt() -> 'user_metadata' ->> 'role') = 'admin', false)
  or coalesce((auth.jwt() ->> 'email') = 'lava052005@gmail.com', false);
$$;

-- Grant execute to authenticated users
grant execute on function public.is_admin() to authenticated;

-- Ensure kaveyae7@gmail.com has customer role in public.profiles and public.users tables
update public.profiles
set role = 'customer'
where id in (select id from auth.users where email = 'kaveyae7@gmail.com');

update public.users
set role = 'customer'
where email = 'kaveyae7@gmail.com';

-- Ensure lava052005@gmail.com has admin role in public.profiles and public.users tables
update public.profiles
set role = 'admin'
where id in (select id from auth.users where email = 'lava052005@gmail.com');

update public.users
set role = 'admin'
where email = 'lava052005@gmail.com';
