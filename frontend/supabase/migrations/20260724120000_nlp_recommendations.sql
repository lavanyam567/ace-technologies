-- ============================================================
-- NLP Recommendations & Feedback Analysis Migration
-- Ace Technologies
-- ============================================================

-- 1. user_activity table: tracks product views, cart adds, purchases
create table if not exists public.user_activity (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  product_id  text not null references public.products(id) on delete cascade,
  action_type text not null check (action_type in ('view', 'cart', 'purchase')),
  created_at  timestamptz not null default now()
);

create index if not exists idx_user_activity_user_id     on public.user_activity(user_id);
create index if not exists idx_user_activity_product_id  on public.user_activity(product_id);
create index if not exists idx_user_activity_action_type on public.user_activity(action_type);

-- RLS for user_activity
alter table public.user_activity enable row level security;

drop policy if exists "Users insert own activity"  on public.user_activity;
drop policy if exists "Users view own activity"    on public.user_activity;

create policy "Users insert own activity"
  on public.user_activity for insert
  with check (auth.uid() = user_id);

create policy "Users view own activity"
  on public.user_activity for select
  using (auth.uid() = user_id);

-- 2. review_sentiments table: NLP analysis results per review
create table if not exists public.review_sentiments (
  id           uuid primary key default gen_random_uuid(),
  review_id    uuid not null,
  product_id   text not null references public.products(id) on delete cascade,
  sentiment    text not null check (sentiment in ('positive', 'neutral', 'negative')),
  score        numeric(4,3) not null default 0.5,
  keywords     text[] not null default '{}',
  processed_at timestamptz not null default now(),
  unique(review_id)
);

create index if not exists idx_review_sentiments_product_id on public.review_sentiments(product_id);
create index if not exists idx_review_sentiments_sentiment  on public.review_sentiments(sentiment);

-- RLS for review_sentiments
alter table public.review_sentiments enable row level security;

drop policy if exists "Anyone can view sentiments"        on public.review_sentiments;
drop policy if exists "Authenticated can insert sentiment" on public.review_sentiments;

create policy "Anyone can view sentiments"
  on public.review_sentiments for select
  using (true);

create policy "Authenticated can insert sentiment"
  on public.review_sentiments for insert
  with check (auth.uid() is not null);

-- Allow upsert from edge function (service role bypasses RLS anyway)
drop policy if exists "Authenticated can upsert sentiment" on public.review_sentiments;
create policy "Authenticated can upsert sentiment"
  on public.review_sentiments for update
  using (auth.uid() is not null);

-- ============================================================
-- 3. RPC: Collaborative Filtering Recommendations
-- Returns up to 10 products that co-activity users interacted with
-- ============================================================
create or replace function public.get_recommendations_for_user(p_user_id uuid)
returns setof public.products
language sql security definer
stable
as $$
  select distinct p.*
  from public.products p
  inner join public.user_activity ua on ua.product_id = p.id
  where ua.user_id in (
    -- Find other users who interacted with same products as p_user_id
    select distinct ua2.user_id
    from public.user_activity ua2
    where ua2.product_id in (
      select product_id
      from public.user_activity
      where user_id = p_user_id
    )
    and ua2.user_id != p_user_id
  )
  -- Exclude products this user already interacted with
  and p.id not in (
    select product_id
    from public.user_activity
    where user_id = p_user_id
  )
  and p.is_active = true
  order by p.rating desc
  limit 10;
$$;

-- ============================================================
-- 4. RPC: Content-Based Similar Products (same category)
-- ============================================================
create or replace function public.get_similar_products(p_product_id text)
returns setof public.products
language sql security definer
stable
as $$
  select p.*
  from public.products p
  where p.category = (
    select category from public.products where id = p_product_id
  )
  and p.id != p_product_id
  and p.is_active = true
  order by p.rating desc, p.discount desc
  limit 8;
$$;

-- ============================================================
-- 5. RPC: Sentiment Summary for a single product
-- ============================================================
create or replace function public.get_product_sentiment_summary(p_product_id text)
returns table (
  positive_count bigint,
  neutral_count  bigint,
  negative_count bigint,
  average_score  numeric,
  top_keywords   text[]
)
language sql security definer
stable
as $$
  select
    count(*) filter (where sentiment = 'positive')        as positive_count,
    count(*) filter (where sentiment = 'neutral')         as neutral_count,
    count(*) filter (where sentiment = 'negative')        as negative_count,
    coalesce(avg(score), 0.5)                             as average_score,
    array_agg(distinct kw)
      filter (where kw is not null and kw != '')          as top_keywords
  from public.review_sentiments rs
  cross join lateral unnest(rs.keywords) as kw
  where product_id = p_product_id;
$$;

-- ============================================================
-- 6. RPC: Admin — overall sentiment summary across all products
-- ============================================================
create or replace function public.get_all_sentiments_summary()
returns table (
  product_id     text,
  product_name   text,
  positive_count bigint,
  neutral_count  bigint,
  negative_count bigint,
  average_score  numeric
)
language sql security definer
stable
as $$
  select
    rs.product_id,
    p.name                                                as product_name,
    count(*) filter (where rs.sentiment = 'positive')   as positive_count,
    count(*) filter (where rs.sentiment = 'neutral')    as neutral_count,
    count(*) filter (where rs.sentiment = 'negative')   as negative_count,
    coalesce(avg(rs.score), 0.5)                        as average_score
  from public.review_sentiments rs
  inner join public.products p on p.id = rs.product_id
  group by rs.product_id, p.name
  order by (count(*) filter (where rs.sentiment = 'negative')) desc;
$$;
