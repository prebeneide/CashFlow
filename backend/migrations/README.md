# Database Migrations

SQL-migrasjoner for CashFlow database schema.

## Kjøre migrasjoner i Supabase

### Metode 1: Via Supabase Dashboard

1. Gå til Supabase Dashboard → SQL Editor
2. Åpne filen `001_initial_schema.sql`
3. Kopier hele innholdet
4. Lim inn i SQL Editor
5. Klikk "Run"

### Metode 2: Via Supabase CLI

```bash
supabase db push
```

## Migrasjoner

- `001_initial_schema.sql` - Initial database schema med alle tabeller, indexes og RLS policies

## Tabeller

- `users` - Brukerprofiler
- `company_profiles` - Bedriftsprofiler
- `documents` - Bilag/dokumenter
- `transactions` - Transaksjoner
- `decision_objects` - Beslutningsobjekter
- `journal_entries` - Journalposter
- `audit_logs` - Audit logger

## Row Level Security (RLS)

Alle tabeller har RLS aktivert med policies som sikrer at brukere kun kan se og endre sine egne data.

