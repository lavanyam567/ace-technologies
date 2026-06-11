create or replace function public.create_order_with_items(
  p_total_amount numeric,
  p_payment_method text,
  p_address_id uuid,
  p_items jsonb,
  p_payment_status text default 'pending',
  p_payment_reference text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_order_id uuid;
  v_item jsonb;
  v_product_id text;
  v_quantity int;
  v_price numeric;
  v_stock int;
  v_product_name text;
begin
  if v_user_id is null then
    raise exception 'Please sign in first.';
  end if;

  if p_items is null or jsonb_array_length(p_items) = 0 then
    raise exception 'Cannot create an order with an empty cart.';
  end if;

  insert into public.orders (
    user_id,
    address_id,
    total_amount,
    status,
    payment_method,
    payment_status,
    payment_reference
  )
  values (
    v_user_id,
    p_address_id,
    p_total_amount,
    'pending',
    p_payment_method,
    coalesce(p_payment_status, 'pending'),
    p_payment_reference
  )
  returning id into v_order_id;

  for v_item in select * from jsonb_array_elements(p_items)
  loop
    v_product_id := v_item ->> 'product_id';
    v_quantity := coalesce((v_item ->> 'quantity')::int, 1);
    v_price := coalesce((v_item ->> 'price')::numeric, 0);

    if v_product_id is null or v_quantity <= 0 then
      raise exception 'Invalid order item.';
    end if;

    select stock, name
      into v_stock, v_product_name
      from public.products
      where id = v_product_id
      for update;

    if not found then
      raise exception 'Product not found.';
    end if;

    if v_stock < v_quantity then
      raise exception '% has only % item(s) available. Please update your cart.',
        coalesce(v_product_name, 'Product'),
        v_stock;
    end if;

    insert into public.order_items (
      order_id,
      product_id,
      quantity,
      price
    )
    values (
      v_order_id,
      v_product_id,
      v_quantity,
      v_price
    );

    update public.products
      set stock = stock - v_quantity
      where id = v_product_id;
  end loop;

  return v_order_id;
end;
$$;

grant execute on function public.create_order_with_items(numeric, text, uuid, jsonb, text, text) to authenticated;
