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
- `01_schema.sql` (tenants/societies, RBAC tables, domain tables)
- `02_views.sql` (society-scoped views)
- `03_seed.sql` (sample data with two societies)

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

## Multi-tenancy
- Each society is a tenant in table `societies`.
- All domain tables include `society_id` for strict scoping (e.g., `towers`, `flats`, `maintenance_bills`, `payments`, `bookings`, `complaints`, `visitors`, `polls`, `votes`, `feedback`, `incomes`, `expenses`).
- Use `society_id` filters in queries and APIs to isolate data per tenant.

## RBAC (Roles & Permissions)
- Roles are per-society in `roles` (e.g., Admin, Secretary, Resident, Committee Member, Security).
- Permissions are global in `permissions` with `module` and `action` (e.g., `complaints:update`).
- Role-permission mapping in `role_permissions`.
- Users join societies via `society_memberships`, and get roles through `society_user_roles`.

## Useful checks
```sql
-- List societies
SELECT * FROM societies ORDER BY name;

-- Current occupants in Green Meadows
SELECT * FROM v_current_occupancies WHERE society_name = 'Green Meadows';

-- Flat balances for a society
SELECT * FROM v_flat_balances WHERE society_name = 'Green Meadows' ORDER BY tower_name, flat_number;

-- Monthly income vs expense per society
SELECT * FROM v_monthly_financials WHERE society_name = 'Green Meadows';

-- Inspect role permissions for a society
SELECT r.name AS role, p.module, p.action
FROM roles r
JOIN role_permissions rp ON rp.role_id = r.id
JOIN permissions p ON p.id = rp.permission_id
WHERE r.society_id = (SELECT id FROM societies WHERE name='Green Meadows')
ORDER BY role, module, action;
```

## Reset database (dangerous)
```bash
docker compose down -v && docker compose up -d
```

Data is stored in the named volume `pgdata`. Removing it resets the database.
