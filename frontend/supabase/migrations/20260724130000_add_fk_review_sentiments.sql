-- Add foreign key constraint to review_sentiments referencing reviews
alter table public.review_sentiments
  drop constraint if exists review_sentiments_review_id_fkey,
  add constraint review_sentiments_review_id_fkey
    foreign key (review_id)
    references public.reviews(id)
    on delete cascade;
