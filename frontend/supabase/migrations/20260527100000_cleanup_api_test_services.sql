with test_services as (
  select
    id,
    row_number() over (order by created_at, id) as rn
  from public.services
  where lower(title) = 'api test installation'
     or lower(description) like '%rest validation%'
     or features && array['Endpoint insert', 'RLS validation']
)
update public.services as services
set
  title = case ((test_services.rn - 1) % 4)
    when 0 then 'CCTV Camera Installation'
    when 1 then 'Biometric Access Installation'
    when 2 then 'Network Cabling Installation'
    else 'Video Door Phone Installation'
  end,
  description = case ((test_services.rn - 1) % 4)
    when 0 then 'Professional CCTV camera installation for homes, offices, shops, and commercial sites.'
    when 1 then 'Biometric, RFID, and keypad access control setup for secure entry management.'
    when 2 then 'Structured LAN cabling, router placement, and Wi-Fi access point installation.'
    else 'Video door phone setup with camera, indoor monitor, wiring, and handover support.'
  end,
  price = case ((test_services.rn - 1) % 4)
    when 0 then 2999
    when 1 then 3499
    when 2 then 2499
    else 1999
  end,
  image_url = case ((test_services.rn - 1) % 4)
    when 0 then 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=800&q=80'
    when 1 then 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=800&q=80'
    when 2 then 'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=800&q=80'
    else 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=800&q=80'
  end,
  features = case ((test_services.rn - 1) % 4)
    when 0 then array['Site Survey', 'Camera Mounting', 'DVR/NVR Setup', 'Mobile View Setup']
    when 1 then array['Biometric Setup', 'RFID Configuration', 'Access Logs', 'User Training']
    when 2 then array['LAN Cabling', 'Router Setup', 'Access Point Setup', 'Signal Testing']
    else array['Indoor Monitor Setup', 'Outdoor Camera Setup', 'Wiring', 'Usage Demo']
  end
from test_services
where services.id = test_services.id;
