-- Add image_urls column to posts table
ALTER TABLE posts 
ADD COLUMN image_urls TEXT[] DEFAULT '{}';

-- Create storage bucket for post images
INSERT INTO storage.buckets (id, name, public) 
VALUES ('post_images', 'post_images', true);

-- Allow public access to post images
CREATE POLICY "Post images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'post_images');

-- Allow authenticated users to upload images
CREATE POLICY "Users can upload post images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'post_images' 
  AND auth.role() = 'authenticated'
);

-- Allow users to delete their own images
CREATE POLICY "Users can delete their own post images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'post_images'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Create function to handle image uploads
CREATE OR REPLACE FUNCTION handle_post_image_upload(
  bucket_name text,
  file_path text,
  file_data bytea
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_path text;
BEGIN
  -- Generate unique file path using UUID
  new_path := auth.uid()::text || '/' || gen_random_uuid()::text || '/' || file_path;
  
  -- Insert file into storage
  INSERT INTO storage.objects (
    bucket_id,
    name,
    owner,
    size,
    metadata,
    created_at
  ) VALUES (
    bucket_name,
    new_path,
    auth.uid(),
    octet_length(file_data),
    jsonb_build_object(
      'mimetype', CASE 
        WHEN file_path ~* '\.png$' THEN 'image/png'
        WHEN file_path ~* '\.(jpg|jpeg)$' THEN 'image/jpeg'
        ELSE 'application/octet-stream'
      END,
      'size', octet_length(file_data)::text
    ),
    NOW()
  );
  
  RETURN new_path;
END;
$$;
