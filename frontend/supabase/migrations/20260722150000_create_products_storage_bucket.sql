-- Ensure the products storage bucket exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public access to read the products bucket
CREATE POLICY "Public Access" ON storage.objects
  FOR SELECT USING (bucket_id = 'products');

-- Allow authenticated/public uploads to the products bucket (for catalog builders)
CREATE POLICY "Upload Access" ON storage.objects
  FOR INSERT WITH CHECK (bucket_id = 'products');
