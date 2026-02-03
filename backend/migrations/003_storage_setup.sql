-- Supabase Storage Setup for CashFlow
-- Dette setter opp documents-bucket for kvitteringer og dokumenter

-- Opprett storage bucket for dokumenter
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'documents',
  'documents',
  false, -- Private bucket (brukere kan bare se sine egne filer)
  52428800, -- 50 MB filstørrelsesgrense
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Slett eksisterende policies hvis de finnes (for å unngå konflikter)
DROP POLICY IF EXISTS "Users can upload to own folder" ON storage.objects;
DROP POLICY IF EXISTS "Users can view own files" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own files" ON storage.objects;

-- RLS Policy: Brukere kan laste opp filer til sin egen mappe
-- Filstien må være på formatet: {user_id}/{timestamp}-{filename}
-- Bruker starts_with for å sjekke at filstien starter med bruker-ID (mer pålitelig)
CREATE POLICY "Users can upload to own folder"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'documents' AND
  name LIKE auth.uid()::text || '/%'
);

-- RLS Policy: Brukere kan se sine egne filer
CREATE POLICY "Users can view own files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documents' AND
  name LIKE auth.uid()::text || '/%'
);

-- RLS Policy: Brukere kan slette sine egne filer
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'documents' AND
  name LIKE auth.uid()::text || '/%'
);

