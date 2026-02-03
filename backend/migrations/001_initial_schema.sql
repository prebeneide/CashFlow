-- CashFlow Database Schema
-- Initial migration

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT UNIQUE NOT NULL,
  preferred_language VARCHAR(5) DEFAULT 'en',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Company profiles
CREATE TABLE IF NOT EXISTS public.company_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  organization_number TEXT,
  industry TEXT,
  vat_registered BOOLEAN DEFAULT false,
  default_settings JSONB DEFAULT '{}',
  learned_patterns JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Documents (bilag)
CREATE TABLE IF NOT EXISTS public.documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.company_profiles(id) ON DELETE CASCADE,
  file_path TEXT NOT NULL,
  file_type TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Transactions
CREATE TABLE IF NOT EXISTS public.transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.company_profiles(id) ON DELETE CASCADE,
  document_id UUID REFERENCES public.documents(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'NEW' CHECK (status IN ('NEW', 'NEEDS_INFO', 'NEEDS_USER_CHOICE', 'READY_TO_BOOK', 'BOOKED')),
  ai_analysis JSONB DEFAULT '{}',
  user_choices JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  booked_at TIMESTAMP WITH TIME ZONE
);

-- Decision objects
CREATE TABLE IF NOT EXISTS public.decision_objects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
  kind TEXT NOT NULL,
  label TEXT NOT NULL,
  options JSONB NOT NULL,
  resolved_choice_id TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Journal entries
CREATE TABLE IF NOT EXISTS public.journal_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID NOT NULL REFERENCES public.company_profiles(id) ON DELETE CASCADE,
  transaction_id UUID NOT NULL REFERENCES public.transactions(id) ON DELETE CASCADE,
  lines JSONB NOT NULL,
  status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'BOOKED')),
  booked_date DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Audit logs
CREATE TABLE IF NOT EXISTS public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id UUID REFERENCES public.company_profiles(id) ON DELETE SET NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  changes JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_transactions_company_status ON public.transactions(company_id, status);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON public.transactions(status);
CREATE INDEX IF NOT EXISTS idx_documents_company ON public.documents(company_id);
CREATE INDEX IF NOT EXISTS idx_decision_objects_transaction ON public.decision_objects(transaction_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_company ON public.audit_logs(company_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON public.audit_logs(created_at DESC);

-- Row Level Security (RLS) policies
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.company_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.decision_objects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own data
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- RLS Policy: Users can only see their own company profiles
CREATE POLICY "Users can view own companies"
  ON public.company_profiles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own companies"
  ON public.company_profiles FOR ALL
  USING (auth.uid() = user_id);

-- RLS Policy: Users can only see documents for their companies
CREATE POLICY "Users can view own company documents"
  ON public.documents FOR SELECT
  USING (
    company_id IN (
      SELECT id FROM public.company_profiles WHERE user_id = auth.uid()
    )
  );

-- RLS Policy: Users can only see transactions for their companies
CREATE POLICY "Users can view own company transactions"
  ON public.transactions FOR SELECT
  USING (
    company_id IN (
      SELECT id FROM public.company_profiles WHERE user_id = auth.uid()
    )
  );

-- RLS Policy: Users can only see decision objects for their transactions
CREATE POLICY "Users can view own decision objects"
  ON public.decision_objects FOR SELECT
  USING (
    transaction_id IN (
      SELECT t.id FROM public.transactions t
      JOIN public.company_profiles cp ON t.company_id = cp.id
      WHERE cp.user_id = auth.uid()
    )
  );

-- RLS Policy: Users can only see journal entries for their companies
CREATE POLICY "Users can view own journal entries"
  ON public.journal_entries FOR SELECT
  USING (
    company_id IN (
      SELECT id FROM public.company_profiles WHERE user_id = auth.uid()
    )
  );

-- RLS Policy: Users can only see audit logs for their companies
CREATE POLICY "Users can view own audit logs"
  ON public.audit_logs FOR SELECT
  USING (
    company_id IN (
      SELECT id FROM public.company_profiles WHERE user_id = auth.uid()
    )
  );

