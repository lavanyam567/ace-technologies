create extension if not exists "pgcrypto";

drop table if exists public.reviews cascade;
drop table if exists public.service_bookings cascade;
drop table if exists public.bookings cascade;
drop table if exists public.order_items cascade;
drop table if exists public.orders cascade;
drop table if exists public.wishlist_items cascade;
drop table if exists public.wishlist cascade;
drop table if exists public.cart_items cascade;
drop table if exists public.cart cascade;
drop table if exists public.addresses cascade;
drop table if exists public.products cascade;
drop table if exists public.services cascade;
drop table if exists public.categories cascade;
drop table if exists public.profiles cascade;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null default 'customer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id text primary key,
  name text not null,
  brand text not null default '',
  description text not null default '',
  price numeric(12,2) not null default 0,
  original_price numeric(12,2),
  rating numeric(3,2) not null default 4.5,
  image_url text not null default '',
  additional_images text[] not null default '{}',
  stock int not null default 0,
  discount int not null default 0,
  category text not null references public.categories(name) on update cascade,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.services (
  id text primary key,
  title text not null,
  description text not null default '',
  price numeric(12,2),
  image_url text not null default '',
  additional_images text[] not null default '{}',
  features text[] not null default '{}',
  duration text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.addresses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  phone text not null,
  address_line1 text not null,
  address_line2 text,
  city text not null,
  state text not null,
  pincode text not null,
  label text,
  type text,
  is_default boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.cart_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  quantity int not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, product_id)
);

create table if not exists public.wishlist_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, product_id)
);

create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  address_id uuid references public.addresses(id) on delete set null,
  total_amount numeric(12,2) not null default 0,
  status text not null default 'pending',
  payment_method text,
  tracking_number text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id text not null references public.products(id),
  quantity int not null default 1 check (quantity > 0),
  price numeric(12,2) not null default 0
);

create table if not exists public.service_bookings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  service_id text not null references public.services(id),
  address_id uuid references public.addresses(id) on delete set null,
  customer_name text not null,
  customer_phone text not null,
  customer_email text not null,
  booking_date date not null,
  time_slot text not null,
  status text not null default 'pending',
  notes text,
  total_price numeric(12,2),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now(),
  unique (user_id, product_id)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_products_updated_at on public.products;
create trigger set_products_updated_at before update on public.products
for each row execute function public.set_updated_at();

drop trigger if exists set_services_updated_at on public.services;
create trigger set_services_updated_at before update on public.services
for each row execute function public.set_updated_at();

drop trigger if exists set_addresses_updated_at on public.addresses;
create trigger set_addresses_updated_at before update on public.addresses
for each row execute function public.set_updated_at();

drop trigger if exists set_cart_items_updated_at on public.cart_items;
create trigger set_cart_items_updated_at before update on public.cart_items
for each row execute function public.set_updated_at();

drop trigger if exists set_orders_updated_at on public.orders;
create trigger set_orders_updated_at before update on public.orders
for each row execute function public.set_updated_at();

drop trigger if exists set_service_bookings_updated_at on public.service_bookings;
create trigger set_service_bookings_updated_at before update on public.service_bookings
for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.products enable row level security;
alter table public.services enable row level security;
alter table public.addresses enable row level security;
alter table public.cart_items enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.service_bookings enable row level security;
alter table public.reviews enable row level security;

drop policy if exists "Public categories are readable" on public.categories;
create policy "Public categories are readable" on public.categories for select using (true);

drop policy if exists "Public products are readable" on public.products;
create policy "Public products are readable" on public.products for select using (is_active = true);

drop policy if exists "Public services are readable" on public.services;
create policy "Public services are readable" on public.services for select using (is_active = true);

drop policy if exists "Users can manage own profile" on public.profiles;
create policy "Users can manage own profile" on public.profiles for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "Users can manage own addresses" on public.addresses;
create policy "Users can manage own addresses" on public.addresses for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users can manage own cart" on public.cart_items;
create policy "Users can manage own cart" on public.cart_items for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users can manage own wishlist" on public.wishlist_items;
create policy "Users can manage own wishlist" on public.wishlist_items for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users can manage own orders" on public.orders;
create policy "Users can manage own orders" on public.orders for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Users can read own order items" on public.order_items;
create policy "Users can read own order items" on public.order_items for select using (
  exists (select 1 from public.orders where orders.id = order_items.order_id and orders.user_id = auth.uid())
);

drop policy if exists "Users can create own order items" on public.order_items;
create policy "Users can create own order items" on public.order_items for insert with check (
  exists (select 1 from public.orders where orders.id = order_items.order_id and orders.user_id = auth.uid())
);

drop policy if exists "Users can manage own bookings" on public.service_bookings;
create policy "Users can manage own bookings" on public.service_bookings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "Reviews are readable" on public.reviews;
create policy "Reviews are readable" on public.reviews for select using (true);

drop policy if exists "Users can manage own reviews" on public.reviews;
create policy "Users can manage own reviews" on public.reviews for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

insert into public.categories (name, sort_order) values
  ('Processors', 10), ('Laptops', 20), ('Networking', 30), ('Printers', 40),
  ('CCTV Cameras', 50), ('Fire Alarms', 60), ('Door Access', 70), ('RAM', 80),
  ('Hard Disk', 90), ('Keyboard', 100), ('Mouse', 110), ('Monitor', 120),
  ('Pendrive', 130), ('TV', 140), ('DVR', 150), ('NVR', 160), ('Projector', 170),
  ('Cables (3+1)', 180), ('Telephoning Solutions', 190), ('Access Point', 200)
on conflict (name) do nothing;

insert into public.services (id, title, description, price, image_url, features) values
  ('svc_001', 'CCTV Installation', 'Professional CCTV camera installation for homes, offices, warehouses, and commercial spaces.', 2999, 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800&q=80', array['HD & 4K Camera Options','24/7 Monitoring','Remote Access','Motion Detection','Cloud Storage']),
  ('svc_002', 'Networking Solutions', 'End-to-end LAN/WAN setup, structured cabling, Wi-Fi configuration, and network troubleshooting.', 4999, 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80', array['Enterprise WiFi','Network Security','Firewall Setup','VPN Configuration','24/7 Support']),
  ('svc_003', 'Server Installation', 'Rack server setup, NAS configuration, and data center management for businesses of all sizes.', 7999, 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&q=80', array['Server Setup','Configuration','Regular Maintenance','Backup Solutions','Performance Tuning']),
  ('svc_004', 'IT AMC Services', 'Annual Maintenance Contract covering laptops, desktops, printers, and networking equipment.', null, 'https://images.unsplash.com/photo-1581092335397-9583eb92d232?w=800&q=80', array['Hardware Maintenance','On-site Support','Remote Assistance','Hardware Repair','Annual Contracts']),
  ('svc_005', 'Access Control Systems', 'Biometric, RFID, and keypad access control installation for secured entry management.', 3499, 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80', array['Biometric Systems','RFID Installation','Keypad Setup','Access Logs','Multi-level Security']),
  ('svc_006', 'Firewall & Cybersecurity', 'Network firewall configuration, VPN setup, and cybersecurity audits to protect your business data.', null, 'https://images.unsplash.com/photo-1563986768609-322da13575f3?w=800&q=80', array['Firewall Setup','VPN Configuration','Security Audit','Threat Detection','Data Protection']),
  ('svc_007', 'On-Site IT Support', 'Professional IT support for troubleshooting, repair, software installation, and system optimization.', 2499, 'https://images.unsplash.com/photo-1531482615713-2afd69097998?w=800&q=80', array['Technical Support','Hardware Repair','Software Setup','System Optimization','Quick Response']),
  ('svc_008', 'Wi-Fi Installation', 'Professional Wi-Fi network design and installation with coverage and security configuration.', 3999, 'https://images.unsplash.com/photo-1606904825846-647eb07f5be2?w=800&q=80', array['Network Design','Installation','Configuration','Signal Optimization','Security Setup'])
on conflict (id) do update set
  title = excluded.title,
  description = excluded.description,
  price = excluded.price,
  image_url = excluded.image_url,
  features = excluded.features;

insert into public.products (id, name, brand, price, original_price, rating, image_url, stock, discount, category) values
  ('proc_001', 'Intel Core i9-13900K', 'Intel', 42999, 49999, 4.8, 'https://images.unsplash.com/photo-1591799264318-7e6ef8ddb7ea?w=600&q=80', 12, 14, 'Processors'),
  ('lap_001', 'HP EliteBook 840 G10', 'HP', 89999, 104999, 4.7, 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=600&q=80', 8, 14, 'Laptops'),
  ('net_001', 'Cisco Catalyst 2960 Switch', 'Cisco', 34999, 41999, 4.8, 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=600&q=80', 15, 17, 'Networking'),
  ('prt_001', 'HP LaserJet Pro M404dn', 'HP', 24999, 29999, 4.6, 'https://images.unsplash.com/photo-1612198188060-c7c2a3b66eae?w=600&q=80', 10, 17, 'Printers'),
  ('cam_001', 'Hikvision 4MP IP Camera', 'Hikvision', 4999, 6500, 4.5, 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=600&q=80', 25, 23, 'CCTV Cameras'),
  ('ram_001', 'Kingston 16GB DDR4 3200MHz', 'Kingston', 3299, 4000, 4.7, 'https://images.unsplash.com/photo-1562976540-1502c2145186?w=600&q=80', 30, 18, 'RAM')
on conflict (id) do update set
  name = excluded.name,
  brand = excluded.brand,
  price = excluded.price,
  original_price = excluded.original_price,
  rating = excluded.rating,
  image_url = excluded.image_url,
  stock = excluded.stock,
  discount = excluded.discount,
  category = excluded.category;
