# Society/Flat Management Database

PostgreSQL schema, views, and seed data for the Society/Flat Management System.

## Prerequisites
- Docker and Docker Compose v2

## Start the database
```bash
docker compose up -d
```

This starts:
- Postgres 16 on port 5432
- Adminer UI on port 8080

On first startup, the init scripts under `db/init` run automatically:
- `01_schema.sql` (tables, enums, constraints)
- `02_views.sql` (useful views)
- `03_seed.sql` (sample data)

## Connect
- Adminer (browser): `http://localhost:8080`
  - System: PostgreSQL
  - Server: `postgres` (service name on the Docker network)
  - Username: `society_admin`
  - Password: `society_pass`
  - Database: `society_db`

- psql (host):
```bash
psql "postgresql://society_admin:society_pass@localhost:5432/society_db"
```

- psql (via container):
```bash
docker compose exec -T postgres psql -U society_admin -d society_db -c "SELECT 1;"
```

## Useful checks
```sql
-- Current occupants per flat
SELECT * FROM v_current_occupancies;

-- Flat balances (billed vs paid)
SELECT * FROM v_flat_balances;

-- Monthly income vs expense
SELECT * FROM v_monthly_financials;
```

## Reset database (dangerous)
```bash
docker compose down -v && docker compose up -d
```

Data is stored in the named volume `pgdata`. Removing it resets the database.
