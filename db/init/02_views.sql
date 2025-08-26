BEGIN;

-- Current active occupancies per flat
CREATE OR REPLACE VIEW v_current_occupancies AS
SELECT
	t.id AS tower_id,
	t.name AS tower_name,
	f.id AS flat_id,
	f.number AS flat_number,
	o.occupant_kind,
	o.move_in_date,
	u.id AS resident_user_id,
	u.full_name AS resident_name
FROM flat_occupancies o
JOIN flats f ON f.id = o.flat_id
JOIN towers t ON t.id = f.tower_id
LEFT JOIN users u ON u.id = o.resident_user_id
WHERE o.move_out_date IS NULL;

-- Flat balances = total billed - total paid (successful)
CREATE OR REPLACE VIEW v_flat_balances AS
WITH billed AS (
	SELECT flat_id, SUM(amount_due + penalty_amount) AS total_billed
	FROM maintenance_bills
	GROUP BY flat_id
), paid AS (
	SELECT flat_id, SUM(amount) AS total_paid
	FROM payments
	WHERE status = 'success'
	GROUP BY flat_id
)
SELECT
	t.name AS tower_name,
	f.id AS flat_id,
	f.number AS flat_number,
	COALESCE(b.total_billed, 0) AS total_billed,
	COALESCE(p.total_paid, 0) AS total_paid,
	COALESCE(b.total_billed, 0) - COALESCE(p.total_paid, 0) AS balance
FROM flats f
JOIN towers t ON t.id = f.tower_id
LEFT JOIN billed b ON b.flat_id = f.id
LEFT JOIN paid p ON p.flat_id = f.id
ORDER BY t.name, f.number;

-- Monthly income vs expense aggregation (includes successful maintenance payments as income)
CREATE OR REPLACE VIEW v_monthly_financials AS
WITH payments_m AS (
	SELECT date_trunc('month', paid_at) AS month_start, SUM(amount)::NUMERIC(12,2) AS total
	FROM payments
	WHERE status = 'success'
	GROUP BY 1
), incomes_m AS (
	SELECT date_trunc('month', entry_date::timestamp) AS month_start, SUM(amount)::NUMERIC(12,2) AS total
	FROM incomes
	GROUP BY 1
), expenses_m AS (
	SELECT date_trunc('month', entry_date::timestamp) AS month_start, SUM(amount)::NUMERIC(12,2) AS total
	FROM expenses
	GROUP BY 1
), combined_income AS (
	SELECT month_start, SUM(total)::NUMERIC(12,2) AS total_income
	FROM (
		SELECT * FROM payments_m
		UNION ALL
		SELECT * FROM incomes_m
	) s
	GROUP BY month_start
)
SELECT
	EXTRACT(YEAR FROM COALESCE(ci.month_start, e.month_start))::INT AS year,
	EXTRACT(MONTH FROM COALESCE(ci.month_start, e.month_start))::INT AS month,
	COALESCE(ci.total_income, 0)::NUMERIC(12,2) AS total_income,
	COALESCE(e.total, 0)::NUMERIC(12,2) AS total_expense,
	(COALESCE(ci.total_income, 0) - COALESCE(e.total, 0))::NUMERIC(12,2) AS net
FROM combined_income ci
FULL OUTER JOIN expenses_m e ON e.month_start = ci.month_start
ORDER BY year, month;

COMMIT;