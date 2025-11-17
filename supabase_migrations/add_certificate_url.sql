-- Add certificate_url column to users table
-- This column stores the Supabase storage URL for supplier SSM certificates

-- Add the column if it doesn't exist
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS certificate_url TEXT;

-- Add a comment to document the column
COMMENT ON COLUMN public.users.certificate_url IS 'URL to the supplier SSM (Companies Commission of Malaysia) registration certificate stored in Supabase storage';

-- Optional: Create an index for faster queries when filtering by certificate existence
CREATE INDEX IF NOT EXISTS idx_users_certificate_url 
ON public.users(certificate_url) 
WHERE certificate_url IS NOT NULL;
