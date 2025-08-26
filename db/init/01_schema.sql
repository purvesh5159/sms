BEGIN;

-- Enums
CREATE TYPE user_role AS ENUM ('admin', 'resident', 'security');
CREATE TYPE complaint_status AS ENUM ('open', 'in_progress', 'closed');
CREATE TYPE payment_status AS ENUM ('pending', 'success', 'failed', 'refunded');
CREATE TYPE bill_status AS ENUM ('unpaid', 'paid', 'partial', 'overdue');
CREATE TYPE booking_status AS ENUM ('pending', 'approved', 'rejected', 'cancelled');
CREATE TYPE visitor_status AS ENUM ('expected', 'checked_in', 'checked_out', 'denied');
CREATE TYPE poll_type AS ENUM ('yes_no', 'multiple_choice');
CREATE TYPE occupant_type AS ENUM ('owner', 'tenant');

-- Utility function for updated_at
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
	NEW.updated_at = now();
	RETURN NEW;
END;
$$;

-- Users
CREATE TABLE IF NOT EXISTS users (
	id BIGSERIAL PRIMARY KEY,
	full_name VARCHAR(200) NOT NULL,
	email VARCHAR(320) NOT NULL UNIQUE,
	phone VARCHAR(20) UNIQUE,
	role user_role NOT NULL DEFAULT 'resident',
	password_hash TEXT NOT NULL,
	profile_image_url TEXT,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Towers
CREATE TABLE IF NOT EXISTS towers (
	id BIGSERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL UNIQUE,
	address TEXT,
	num_floors INTEGER,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_towers_updated_at BEFORE UPDATE ON towers FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Flats
CREATE TABLE IF NOT EXISTS flats (
	id BIGSERIAL PRIMARY KEY,
	tower_id BIGINT NOT NULL REFERENCES towers(id) ON DELETE CASCADE,
	number VARCHAR(20) NOT NULL,
	floor INTEGER,
	bedrooms INTEGER,
	area_sqft INTEGER,
	owner_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	is_active BOOLEAN NOT NULL DEFAULT TRUE,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE(tower_id, number)
);
CREATE INDEX IF NOT EXISTS idx_flats_tower_id ON flats(tower_id);
CREATE TRIGGER trg_flats_updated_at BEFORE UPDATE ON flats FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Flat occupancies (move-in/move-out logs)
CREATE TABLE IF NOT EXISTS flat_occupancies (
	id BIGSERIAL PRIMARY KEY,
	flat_id BIGINT NOT NULL REFERENCES flats(id) ON DELETE CASCADE,
	resident_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	occupant_kind occupant_type NOT NULL,
	move_in_date DATE NOT NULL,
	move_out_date DATE,
	notes TEXT,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Only one active occupancy per flat at a time
CREATE UNIQUE INDEX IF NOT EXISTS uniq_flat_active_occupancy ON flat_occupancies(flat_id) WHERE move_out_date IS NULL;
-- A resident cannot have two active occupancies simultaneously
CREATE UNIQUE INDEX IF NOT EXISTS uniq_resident_active_occupancy ON flat_occupancies(resident_user_id) WHERE move_out_date IS NULL;
CREATE INDEX IF NOT EXISTS idx_flat_occupancies_flat_id ON flat_occupancies(flat_id);
CREATE TRIGGER trg_flat_occupancies_updated_at BEFORE UPDATE ON flat_occupancies FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Maintenance bills
CREATE TABLE IF NOT EXISTS maintenance_bills (
	id BIGSERIAL PRIMARY KEY,
	flat_id BIGINT NOT NULL REFERENCES flats(id) ON DELETE CASCADE,
	bill_year INTEGER NOT NULL,
	bill_month INTEGER NOT NULL CHECK (bill_month BETWEEN 1 AND 12),
	bill_due_date DATE NOT NULL,
	amount_due NUMERIC(12,2) NOT NULL CHECK (amount_due >= 0),
	amount_paid NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (amount_paid >= 0),
	penalty_amount NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (penalty_amount >= 0),
	status bill_status NOT NULL DEFAULT 'unpaid',
	notes TEXT,
	generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE(flat_id, bill_year, bill_month)
);
CREATE INDEX IF NOT EXISTS idx_bills_flat_period ON maintenance_bills(flat_id, bill_year, bill_month);
CREATE INDEX IF NOT EXISTS idx_bills_status ON maintenance_bills(status);
CREATE TRIGGER trg_bills_updated_at BEFORE UPDATE ON maintenance_bills FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Payments
CREATE TABLE IF NOT EXISTS payments (
	id BIGSERIAL PRIMARY KEY,
	bill_id BIGINT NOT NULL REFERENCES maintenance_bills(id) ON DELETE CASCADE,
	flat_id BIGINT NOT NULL REFERENCES flats(id) ON DELETE CASCADE,
	user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
	status payment_status NOT NULL DEFAULT 'success',
	method VARCHAR(40),
	provider_payment_id VARCHAR(100) UNIQUE,
	paid_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	notes TEXT
);
CREATE INDEX IF NOT EXISTS idx_payments_bill_id ON payments(bill_id);
CREATE INDEX IF NOT EXISTS idx_payments_flat_id ON payments(flat_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status);

-- Complaints
CREATE TABLE IF NOT EXISTS complaints (
	id BIGSERIAL PRIMARY KEY,
	flat_id BIGINT NOT NULL REFERENCES flats(id) ON DELETE CASCADE,
	created_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	assigned_to_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	category VARCHAR(100) NOT NULL,
	description TEXT NOT NULL,
	status complaint_status NOT NULL DEFAULT 'open',
	priority SMALLINT NOT NULL DEFAULT 3 CHECK (priority BETWEEN 1 AND 5),
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	closed_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_complaints_status ON complaints(status);
CREATE INDEX IF NOT EXISTS idx_complaints_flat_id ON complaints(flat_id);
CREATE TRIGGER trg_complaints_updated_at BEFORE UPDATE ON complaints FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Visitors
CREATE TABLE IF NOT EXISTS visitors (
	id BIGSERIAL PRIMARY KEY,
	full_name VARCHAR(200) NOT NULL,
	phone VARCHAR(20),
	purpose VARCHAR(200),
	flat_id BIGINT NOT NULL REFERENCES flats(id) ON DELETE CASCADE,
	preapproved_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	check_in_time TIMESTAMPTZ,
	check_out_time TIMESTAMPTZ,
	status visitor_status NOT NULL DEFAULT 'expected',
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_visitors_flat_id ON visitors(flat_id);
CREATE INDEX IF NOT EXISTS idx_visitors_status ON visitors(status);
CREATE TRIGGER trg_visitors_updated_at BEFORE UPDATE ON visitors FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Amenities
CREATE TABLE IF NOT EXISTS amenities (
	id BIGSERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL UNIQUE,
	description TEXT,
	open_time TIME,
	close_time TIME,
	requires_approval BOOLEAN NOT NULL DEFAULT FALSE,
	slot_minutes INTEGER NOT NULL DEFAULT 60,
	capacity INTEGER NOT NULL DEFAULT 1,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_amenities_updated_at BEFORE UPDATE ON amenities FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
	id BIGSERIAL PRIMARY KEY,
	amenity_id BIGINT NOT NULL REFERENCES amenities(id) ON DELETE CASCADE,
	flat_id BIGINT NOT NULL REFERENCES flats(id) ON DELETE CASCADE,
	user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	start_time TIMESTAMPTZ NOT NULL,
	end_time TIMESTAMPTZ NOT NULL,
	status booking_status NOT NULL DEFAULT 'pending',
	approved_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	notes TEXT,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	CHECK (end_time > start_time)
);
CREATE INDEX IF NOT EXISTS idx_bookings_amenity_time ON bookings(amenity_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);
CREATE TRIGGER trg_bookings_updated_at BEFORE UPDATE ON bookings FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Polls
CREATE TABLE IF NOT EXISTS polls (
	id BIGSERIAL PRIMARY KEY,
	title VARCHAR(200) NOT NULL,
	description TEXT,
	type poll_type NOT NULL,
	options JSONB,
	start_time TIMESTAMPTZ NOT NULL DEFAULT now(),
	end_time TIMESTAMPTZ,
	created_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	CHECK (type <> 'multiple_choice' OR options IS NOT NULL),
	CHECK (type = 'yes_no' OR jsonb_typeof(options) = 'array')
);
CREATE INDEX IF NOT EXISTS idx_polls_type ON polls(type);
CREATE TRIGGER trg_polls_updated_at BEFORE UPDATE ON polls FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Votes (one per flat per poll)
CREATE TABLE IF NOT EXISTS votes (
	id BIGSERIAL PRIMARY KEY,
	poll_id BIGINT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
	flat_id BIGINT NOT NULL REFERENCES flats(id) ON DELETE CASCADE,
	user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	choice VARCHAR(200) NOT NULL,
	cast_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	UNIQUE (poll_id, flat_id)
);
CREATE INDEX IF NOT EXISTS idx_votes_poll_id ON votes(poll_id);

-- Feedback
CREATE TABLE IF NOT EXISTS feedback (
	id BIGSERIAL PRIMARY KEY,
	user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	flat_id BIGINT NOT NULL REFERENCES flats(id) ON DELETE CASCADE,
	category VARCHAR(100),
	rating INTEGER CHECK (rating BETWEEN 1 AND 5),
	message TEXT NOT NULL,
	response TEXT,
	responded_by_user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
	responded_at TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_feedback_flat_id ON feedback(flat_id);
CREATE INDEX IF NOT EXISTS idx_feedback_rating ON feedback(rating);

-- Incomes
CREATE TABLE IF NOT EXISTS incomes (
	id BIGSERIAL PRIMARY KEY,
	entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
	source VARCHAR(100) NOT NULL, -- e.g., maintenance, donation
	category VARCHAR(50) NOT NULL, -- e.g., maintenance, fine, rent, donation, other
	amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
	reference_type VARCHAR(50),
	reference_id BIGINT,
	notes TEXT,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_incomes_entry_date ON incomes(entry_date);
CREATE INDEX IF NOT EXISTS idx_incomes_category ON incomes(category);

-- Expenses
CREATE TABLE IF NOT EXISTS expenses (
	id BIGSERIAL PRIMARY KEY,
	entry_date DATE NOT NULL DEFAULT CURRENT_DATE,
	category VARCHAR(50) NOT NULL,
	amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
	payee VARCHAR(100),
	notes TEXT,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_expenses_entry_date ON expenses(entry_date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);

COMMIT;