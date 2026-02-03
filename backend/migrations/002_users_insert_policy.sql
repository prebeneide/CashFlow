-- Allow authenticated users to insert their own row into public.users
-- This fixes foreign key errors when creating company_profiles for
-- existing auth.users that don't yet have a public.users entry.

-- RLS is already enabled on public.users in 001_initial_schema.sql
-- Here we just add an INSERT policy that mirrors the SELECT/UPDATE ones.

CREATE POLICY "Users can insert own profile"
  ON public.users FOR INSERT
  WITH CHECK (auth.uid() = id);


