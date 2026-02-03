# Supabase Storage Setup

## Metode 1: Via Supabase Dashboard (Enklest)

1. Gå til Supabase Dashboard → **Storage**
2. Klikk **"New bucket"**
3. Fyll inn:
   - **Name**: `documents`
   - **Public bucket**: **Av** (ikke huk av - filer skal være private)
   - **File size limit**: `50 MB` (valgfritt)
   - **Allowed MIME types**: `image/jpeg, image/png, image/gif, image/webp, image/heic, application/pdf` (valgfritt)
4. Klikk **"Create bucket"**

5. Gå til **Storage** → **Policies** for `documents` bucket
6. Klikk **"New Policy"** og velg **"For full customization"**
7. Lim inn følgende policies (én om gangen):

### Policy 1: Upload (INSERT)
```sql
CREATE POLICY "Users can upload to own folder"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'documents' AND
  name LIKE auth.uid()::text || '/%'
);
```

### Policy 2: View (SELECT)
```sql
CREATE POLICY "Users can view own files"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'documents' AND
  name LIKE auth.uid()::text || '/%'
);
```

### Policy 3: Delete (DELETE)
```sql
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'documents' AND
  name LIKE auth.uid()::text || '/%'
);
```

## Metode 2: Via SQL Editor (Raskest)

1. Gå til Supabase Dashboard → **SQL Editor**
2. Åpne filen `003_storage_setup.sql`
3. Kopier hele innholdet
4. Lim inn i SQL Editor
5. Klikk **"Run"**

Dette setter opp både bucket-en og alle nødvendige RLS policies automatisk.

## Hva gjør dette?

- Oppretter en `documents` bucket for å lagre kvitteringer og dokumenter
- Setter opp Row Level Security (RLS) policies som sikrer at:
  - Brukere kun kan laste opp filer til sin egen mappe (basert på company_id)
  - Brukere kun kan se sine egne filer
  - Brukere kun kan slette sine egne filer
- Begrenser filstørrelse til 50 MB
- Tillater kun bilder og PDF-filer

## Teste oppsettet

Etter at bucket-en er opprettet, kan du teste opplastingen i appen:
1. Gå til Dashboard
2. Klikk "Last opp kvittering"
3. Velg en fil eller ta bilde
4. Last opp

Hvis alt fungerer, vil filen bli lagret i Supabase Storage og en transaksjon vil bli opprettet i databasen.

