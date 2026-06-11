create or replace function public.update_admin_order_status(
  p_order_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  updated_order public.orders%rowtype;
begin
  if not public.is_admin() then
    raise exception 'Admin access required.';
  end if;

  if p_status not in ('pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled') then
    raise exception 'Invalid order status: %', p_status;
  end if;

  update public.orders
  set
    status = p_status,
    updated_at = now()
  where id = p_order_id
  returning * into updated_order;

  if updated_order.id is null then
    raise exception 'Order not found.';
  end if;

  return to_jsonb(updated_order);
end;
$$;

grant execute on function public.update_admin_order_status(uuid, text) to authenticated;
