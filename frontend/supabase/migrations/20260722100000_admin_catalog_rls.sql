-- Policies for products
drop policy if exists "Admins can manage products" on public.products;
create policy "Admins can manage products"
on public.products
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admins can select all products" on public.products;
create policy "Admins can select all products"
on public.products
for select
using (public.is_admin());

-- Policies for services
drop policy if exists "Admins can manage services" on public.services;
create policy "Admins can manage services"
on public.services
for all
using (public.is_admin())
with check (public.is_admin());

drop policy if exists "Admins can select all services" on public.services;
create policy "Admins can select all services"
on public.services
for select
using (public.is_admin());

-- Policies for categories
drop policy if exists "Admins can manage categories" on public.categories;
create policy "Admins can manage categories"
on public.categories
for all
using (public.is_admin())
with check (public.is_admin());
