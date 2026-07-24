-- ============================================================
-- Search-Intent Recommendations Migration
-- Ace Technologies
-- ============================================================

-- 1. search_history table: records every submitted search query
create table if not exists public.search_history (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users(id) on delete cascade,
  query        text not null,
  result_count int  not null default 0,
  created_at   timestamptz not null default now()
);

create index if not exists idx_search_history_user_id    on public.search_history(user_id);
create index if not exists idx_search_history_created_at on public.search_history(created_at);

-- RLS for search_history — users only touch their own rows
alter table public.search_history enable row level security;

drop policy if exists "Users insert own searches" on public.search_history;
drop policy if exists "Users view own searches"   on public.search_history;

create policy "Users insert own searches"
  on public.search_history for insert
  with check (auth.uid() = user_id);

create policy "Users view own searches"
  on public.search_history for select
  using (auth.uid() = user_id);

-- ============================================================
-- 2. RPC: Search-Intent Recommendations
-- Recommends products matching the tokens of a user's recent
-- searches, ranked by how many search tokens they match.
-- ============================================================
create or replace function public.get_search_based_recommendations(
  p_user_id uuid,
  p_limit   int default 10
)
returns setof public.products
language sql security definer
stable
as $$
  with recent_queries as (
    -- Last 10 distinct queries (lower-cased) from the past 30 days
    select q
    from (
      select lower(query) as q, max(created_at) as last_seen
      from public.search_history
      where user_id = p_user_id
        and created_at >= now() - interval '30 days'
      group by lower(query)
      order by last_seen desc
      limit 10
    ) recent
  ),
  tokens as (
    -- Split each query into tokens of length >= 3
    select distinct token
    from recent_queries
    cross join lateral regexp_split_to_table(q, '\s+') as token
    where length(token) >= 3
  ),
  matched as (
    select p.id, count(*) as match_count
    from public.products p
    inner join tokens t
      on p.name ilike '%' || t.token || '%'
      or p.brand ilike '%' || t.token || '%'
      or p.category ilike '%' || t.token || '%'
    where p.is_active = true
      -- Exclude products the user already carted or purchased
      and p.id not in (
        select product_id
        from public.user_activity
        where user_id = p_user_id
          and action_type in ('cart', 'purchase')
      )
    group by p.id
  )
  select p.*
  from public.products p
  inner join matched m on m.id = p.id
  order by m.match_count desc, p.rating desc nulls last
  limit p_limit;
$$;
