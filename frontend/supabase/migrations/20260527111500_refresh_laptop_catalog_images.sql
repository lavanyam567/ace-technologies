-- Refresh laptop catalog images so all laptop cards have usable laptop photos.

update public.products
set
  image_url = laptop_images.image_url,
  additional_images = laptop_images.additional_images,
  updated_at = now()
from (
  values
    (
      'lap_001',
      'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=900&q=85',
      array[
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=900&q=85',
        'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=900&q=85'
      ]::text[]
    ),
    (
      'lap_002',
      'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=900&q=85',
      array[
        'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=900&q=85',
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=900&q=85'
      ]::text[]
    ),
    (
      'lap_003',
      'https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=900&q=85',
      array[
        'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?w=900&q=85',
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=900&q=85'
      ]::text[]
    ),
    (
      'challenger_laptop_dell_inspiron_3505',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f69a215b3703191b04644/Frame%204%20-%202021-03-15T193359.773.png',
      array[
        'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f69a215b3703191b04644/Frame%204%20-%202021-03-15T193359.773.png'
      ]::text[]
    ),
    (
      'challenger_laptop_lenovo_v15_i3',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f76ae15b3703191b0479a/Frame%204%20-%202021-03-15T203026.053.png',
      array[
        'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f76ae15b3703191b0479a/Frame%204%20-%202021-03-15T203026.053.png'
      ]::text[]
    ),
    (
      'challenger_laptop_dell_inspiron_5502',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f6bb615b3703191b0468f/Frame%204%20-%202021-03-15T194138.712.png',
      array[
        'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f6bb615b3703191b0468f/Frame%204%20-%202021-03-15T194138.712.png'
      ]::text[]
    ),
    (
      'gbs_asus_laptop_sales_service',
      'https://admin.gbssystems.com/public/storage/banner/28/main_banner/69c27853a7e26Asus.jpg%20(2).jpeg',
      array[
        'https://admin.gbssystems.com/public/storage/banner/28/main_banner/69c27853a7e26Asus.jpg%20(2).jpeg',
        'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=900&q=85'
      ]::text[]
    ),
    (
      'gbs_lenovo_laptop_sales_repair',
      'https://admin.gbssystems.com/public/storage/banner/31/main_banner/69c278ce6a651Lenovo.jpg%20(2).jpeg',
      array[
        'https://admin.gbssystems.com/public/storage/banner/31/main_banner/69c278ce6a651Lenovo.jpg%20(2).jpeg',
        'https://images.unsplash.com/photo-1588872657578-7efd1f1555ed?w=900&q=85'
      ]::text[]
    ),
    (
      'gbs_dell_laptop_sales_service',
      'https://admin.gbssystems.com/public/storage/banner/36/main_banner/69c278dce8815Dell.jpg%20(2).jpeg',
      array[
        'https://admin.gbssystems.com/public/storage/banner/36/main_banner/69c278dce8815Dell.jpg%20(2).jpeg',
        'https://images.unsplash.com/photo-1593642632559-0c6d3fc62b89?w=900&q=85'
      ]::text[]
    ),
    (
      'gbs_hp_laptop_sales_repair',
      'https://admin.gbssystems.com/public/storage/banner/39/main_banner/69c278e90046fHp.jpg%20(2).jpeg',
      array[
        'https://admin.gbssystems.com/public/storage/banner/39/main_banner/69c278e90046fHp.jpg%20(2).jpeg',
        'https://images.unsplash.com/photo-1541807084-5c52b6b3adef?w=900&q=85'
      ]::text[]
    ),
    (
      'gbs_acer_laptop_sales_service',
      'https://admin.gbssystems.com/public/storage/banner/41/main_banner/69c278f75fbd8Acer.jpg%20(2).jpeg',
      array[
        'https://admin.gbssystems.com/public/storage/banner/41/main_banner/69c278f75fbd8Acer.jpg%20(2).jpeg',
        'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=900&q=85'
      ]::text[]
    )
) as laptop_images(id, image_url, additional_images)
where products.id = laptop_images.id;
