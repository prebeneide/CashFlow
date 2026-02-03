# CashFlow Backend

NestJS backend API for CashFlow regnskapssystem.

## Teknologi

- NestJS
- TypeScript
- Supabase (Database & Auth)
- PostgreSQL

## Struktur

Backend er organisert i moduler:
- `app` - Hovedmodul og health checks
- `supabase` - Supabase-integrasjon og database-tilgang

## Kjøre lokalt

```bash
npm install
npm run start:dev
```

Serveren starter på http://localhost:3000

## Environment Variables

Prosjektet bruker følgende environment variables (definert i `.env`):

- `PORT` - Server port (default: 3000)
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous key
- `SUPABASE_SERVICE_ROLE_KEY` - Supabase service role key
- `DATABASE_URL` - PostgreSQL connection string
- `JWT_SECRET` - Secret for JWT tokens
- `OPENAI_API_KEY` - API key for intelligent dokumentanalyse

## API Endpoints

- `GET /` - API welcome message
- `GET /health` - Health check
- `GET /supabase/test` - Test Supabase-tilkobling

## Build

```bash
npm run build
npm run start:prod
```
