-- Refresh accurate source images for products imported from Challenger BuildYourPC
-- and GBS Systems. Keeps image_url and additional_images aligned.

update public.products
set
  image_url = image_data.image_url,
  additional_images = array[image_data.image_url],
  updated_at = now()
from (
  values
    (
      'challenger_pc_nova_3200g',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/69f4b7832c36890368b138db/3500.png'
    ),
    (
      'challenger_pc_comet_3400g',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/69f4b7cb2c36890368b1394d/3500.png'
    ),
    (
      'challenger_pc_flint_5500gt',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/69f4b7de2c36890368b13973/4500.png'
    ),
    (
      'challenger_pc_drift_5500_rtx3050',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/69f4b5ff2c36890368b1354b/5950.png'
    ),
    (
      'challenger_pc_forge_i5_rtx3050',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/69f4b6302c36890368b13609/5950.png'
    ),
    (
      'challenger_pc_blaze_5600_rtx5060',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/69f4b6772c36890368b136ed/6950.png'
    ),
    (
      'challenger_laptop_dell_inspiron_3505',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f69a215b3703191b04644/Frame%204%20-%202021-03-15T193359.773.png'
    ),
    (
      'challenger_laptop_lenovo_v15_i3',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f76ae15b3703191b0479a/Frame%204%20-%202021-03-15T203026.053.png'
    ),
    (
      'challenger_laptop_dell_inspiron_5502',
      'https://challenger-computers.s3.ap-south-1.amazonaws.com/604f6bb615b3703191b0468f/Frame%204%20-%202021-03-15T194138.712.png'
    ),
    (
      'gbs_asus_laptop_sales_service',
      'https://admin.gbssystems.com/public/storage/banner/28/main_banner/69c27853a7e26Asus.jpg%20(2).jpeg'
    ),
    (
      'gbs_lenovo_laptop_sales_repair',
      'https://admin.gbssystems.com/public/storage/banner/31/main_banner/69c278ce6a651Lenovo.jpg%20(2).jpeg'
    ),
    (
      'gbs_dell_laptop_sales_service',
      'https://admin.gbssystems.com/public/storage/banner/36/main_banner/69c278dce8815Dell.jpg%20(2).jpeg'
    ),
    (
      'gbs_hp_laptop_sales_repair',
      'https://admin.gbssystems.com/public/storage/banner/39/main_banner/69c278e90046fHp.jpg%20(2).jpeg'
    ),
    (
      'gbs_acer_laptop_sales_service',
      'https://admin.gbssystems.com/public/storage/banner/41/main_banner/69c278f75fbd8Acer.jpg%20(2).jpeg'
    )
) as image_data(id, image_url)
where products.id = image_data.id;
