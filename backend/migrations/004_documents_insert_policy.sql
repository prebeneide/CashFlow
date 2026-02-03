-- Allow users to insert documents and transactions for their own companies
-- These policies allow authenticated users to create document and transaction entries
-- for companies they own.

-- RLS is already enabled on public.documents and public.transactions in 001_initial_schema.sql
-- Here we add INSERT policies that allow users to create documents and transactions
-- for their own companies.

-- Slett eksisterende policies hvis de finnes (for å unngå konflikter)
DROP POLICY IF EXISTS "Users can insert documents for own companies" ON public.documents;
DROP POLICY IF EXISTS "Users can insert transactions for own companies" ON public.transactions;

-- Policy for documents
CREATE POLICY "Users can insert documents for own companies"
  ON public.documents FOR INSERT
  WITH CHECK (
    company_id IN (
      SELECT id FROM public.company_profiles WHERE user_id = auth.uid()
    )
  );

-- Policy for transactions
CREATE POLICY "Users can insert transactions for own companies"
  ON public.transactions FOR INSERT
  WITH CHECK (
    company_id IN (
      SELECT id FROM public.company_profiles WHERE user_id = auth.uid()
    )
  );

