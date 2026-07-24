-- SQL Migration: Remove API Test Laptop and Clean Laptop Product Names
-- Replaces "Sales & Service" suffixes to keep product catalog clean of service details.

DELETE FROM public.products 
WHERE name = 'API Test Laptop' OR id = 'api_test';

-- Update laptop names and descriptions to keep them purely product-focused
UPDATE public.products
SET name = 'Asus Laptop', description = 'High-performance Asus laptop for home and business use.'
WHERE id = 'gbs_asus_laptop_sales_service';

UPDATE public.products
SET name = 'Lenovo Laptop', description = 'Reliable Lenovo ThinkPad laptop for professionals.'
WHERE id = 'gbs_lenovo_laptop_sales_repair';

UPDATE public.products
SET name = 'Dell Laptop', description = 'Powerful Dell Latitude laptop for multitasking and everyday use.'
WHERE id = 'gbs_dell_laptop_sales_service';

UPDATE public.products
SET name = 'HP Laptop', description = 'HP laptop featuring micro-edge display and backlit keyboard.'
WHERE id = 'gbs_hp_laptop_sales_repair';

UPDATE public.products
SET name = 'Acer Laptop', description = 'Acer laptop with dynamic display and long battery life.'
WHERE id = 'gbs_acer_laptop_sales_service';
