BEGIN;

-- Users
INSERT INTO users (full_name, email, phone, role, password_hash) VALUES
	('Society Admin', 'admin@society.local', '+10000000000', 'admin', '$2y$10$examplehashforadmin'),
	('Security Guard', 'guard@society.local', '+10000000001', 'security', '$2y$10$examplehashforguard'),
	('John Resident', 'john@society.local', '+10000000002', 'resident', '$2y$10$examplehashforjohn'),
	('Jane Resident', 'jane@society.local', '+10000000003', 'resident', '$2y$10$examplehashforjane')
ON CONFLICT (email) DO NOTHING;

-- Towers
INSERT INTO towers (name, address, num_floors) VALUES
	('A', '123 Alpha Street', 10),
	('B', '456 Beta Avenue', 12)
ON CONFLICT (name) DO NOTHING;

-- Flats (a few examples per tower)
INSERT INTO flats (tower_id, number, floor, bedrooms, area_sqft, owner_user_id) VALUES
	((SELECT id FROM towers WHERE name = 'A'), '101', 1, 2, 900, (SELECT id FROM users WHERE email = 'john@society.local')),
	((SELECT id FROM towers WHERE name = 'A'), '102', 1, 3, 1100, (SELECT id FROM users WHERE email = 'jane@society.local')),
	((SELECT id FROM towers WHERE name = 'A'), '201', 2, 2, 950, NULL),
	((SELECT id FROM towers WHERE name = 'B'), '101', 1, 2, 900, NULL),
	((SELECT id FROM towers WHERE name = 'B'), '102', 1, 3, 1200, NULL),
	((SELECT id FROM towers WHERE name = 'B'), '201', 2, 2, 950, NULL)
ON CONFLICT DO NOTHING;

-- Current occupancies
INSERT INTO flat_occupancies (flat_id, resident_user_id, occupant_kind, move_in_date)
VALUES
	((SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101'), (SELECT id FROM users WHERE email='john@society.local'), 'owner', '2023-01-01'),
	((SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='102'), (SELECT id FROM users WHERE email='jane@society.local'), 'owner', '2023-03-01')
ON CONFLICT DO NOTHING;

-- Amenities
INSERT INTO amenities (name, description, open_time, close_time, requires_approval, slot_minutes, capacity) VALUES
	('Gym', 'Gym with basic equipment', '06:00', '22:00', FALSE, 60, 10),
	('Community Hall', 'Air-conditioned hall for events', '08:00', '21:00', TRUE, 120, 50),
	('Swimming Pool', 'Outdoor pool', '06:00', '20:00', TRUE, 60, 20)
ON CONFLICT (name) DO NOTHING;

-- Maintenance bills for current and previous month for A-101
WITH params AS (
	SELECT EXTRACT(YEAR FROM now())::INT AS y_cur,
		   EXTRACT(MONTH FROM now())::INT AS m_cur,
		   EXTRACT(YEAR FROM (now() - INTERVAL '1 month'))::INT AS y_prev,
		   EXTRACT(MONTH FROM (now() - INTERVAL '1 month'))::INT AS m_prev,
		   (date_trunc('month', now()) + INTERVAL '10 days')::DATE AS due_cur,
		   (date_trunc('month', now() - INTERVAL '1 month') + INTERVAL '10 days')::DATE AS due_prev
)
INSERT INTO maintenance_bills (flat_id, bill_year, bill_month, bill_due_date, amount_due, amount_paid, penalty_amount, status, notes)
SELECT f.id, y_prev, m_prev, due_prev, 1500.00, 1500.00, 0, 'paid'::bill_status, 'Previous month fully paid'
FROM params p, flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101'
ON CONFLICT DO NOTHING;

WITH params AS (
	SELECT EXTRACT(YEAR FROM now())::INT AS y_cur,
		   EXTRACT(MONTH FROM now())::INT AS m_cur,
		   (date_trunc('month', now()) + INTERVAL '10 days')::DATE AS due_cur
)
INSERT INTO maintenance_bills (flat_id, bill_year, bill_month, bill_due_date, amount_due, amount_paid, penalty_amount, status, notes)
SELECT f.id, y_cur, m_cur, due_cur, 1500.00, 0, 0, 'unpaid'::bill_status, 'Current month pending'
FROM params p, flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101'
ON CONFLICT DO NOTHING;

-- Payment for previous month bill
WITH prev_bill AS (
	SELECT mb.id, mb.flat_id FROM maintenance_bills mb
	JOIN flats f ON f.id=mb.flat_id
	JOIN towers t ON t.id=f.tower_id
	WHERE t.name='A' AND f.number='101'
	  AND (mb.bill_year, mb.bill_month) = (
		SELECT EXTRACT(YEAR FROM (now() - INTERVAL '1 month'))::INT,
		       EXTRACT(MONTH FROM (now() - INTERVAL '1 month'))::INT
	  )
)
INSERT INTO payments (bill_id, flat_id, user_id, amount, status, method, provider_payment_id, paid_at, notes)
SELECT pb.id, pb.flat_id, (SELECT id FROM users WHERE email='john@society.local'), 1500.00, 'success'::payment_status, 'cash', 'SEED-PAY-001', now() - INTERVAL '20 days', 'Seeded payment'
FROM prev_bill pb
ON CONFLICT DO NOTHING;

-- Booking example for Gym
INSERT INTO bookings (amenity_id, flat_id, user_id, start_time, end_time, status, notes)
SELECT (SELECT id FROM amenities WHERE name='Gym'),
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101'),
	   (SELECT id FROM users WHERE email='john@society.local'),
	   now() + INTERVAL '1 day', now() + INTERVAL '1 day' + INTERVAL '1 hour',
	   'approved'::booking_status,
	   'Seed booking'
WHERE NOT EXISTS (
	SELECT 1 FROM bookings b WHERE b.amenity_id = (SELECT id FROM amenities WHERE name='Gym')
);

-- Complaint example
INSERT INTO complaints (flat_id, created_by_user_id, assigned_to_user_id, category, description, status, priority)
SELECT (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='102'),
	   (SELECT id FROM users WHERE email='jane@society.local'),
	   (SELECT id FROM users WHERE email='admin@society.local'),
	   'Plumbing', 'Water leakage in bathroom', 'in_progress'::complaint_status, 2
WHERE NOT EXISTS (
	SELECT 1 FROM complaints c WHERE c.description = 'Water leakage in bathroom'
);

-- Polls and votes
INSERT INTO polls (title, description, type, options, start_time, end_time, created_by_user_id)
VALUES ('Install new CCTV cameras?', 'Proposal to add more CCTV coverage in common areas', 'yes_no', NULL, now() - INTERVAL '1 day', now() + INTERVAL '6 days', (SELECT id FROM users WHERE email='admin@society.local'))
ON CONFLICT DO NOTHING;

INSERT INTO polls (title, description, type, options, start_time, end_time, created_by_user_id)
VALUES ('Preferred cleaning schedule', 'Choose your preferred cleaning slot', 'multiple_choice', '["Morning", "Afternoon", "Evening"]'::jsonb, now() - INTERVAL '2 days', now() + INTERVAL '5 days', (SELECT id FROM users WHERE email='admin@society.local'))
ON CONFLICT DO NOTHING;

-- Vote: A-101 votes YES for CCTV
INSERT INTO votes (poll_id, flat_id, user_id, choice)
SELECT p.id,
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101'),
	   (SELECT id FROM users WHERE email='john@society.local'),
	   'yes'
FROM polls p WHERE p.title='Install new CCTV cameras?'
ON CONFLICT DO NOTHING;

-- Visitors
INSERT INTO visitors (full_name, phone, purpose, flat_id, preapproved_by_user_id, check_in_time, check_out_time, status)
SELECT 'Mike Visitor', '+10000000010', 'Friend visit',
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101'),
	   (SELECT id FROM users WHERE email='john@society.local'),
	   now() - INTERVAL '3 hours', now() - INTERVAL '2 hours', 'checked_out'::visitor_status
WHERE NOT EXISTS (
	SELECT 1 FROM visitors v WHERE v.full_name='Mike Visitor' AND v.purpose='Friend visit'
);

-- Feedback
INSERT INTO feedback (user_id, flat_id, category, rating, message, response, responded_by_user_id, responded_at)
SELECT (SELECT id FROM users WHERE email='jane@society.local'),
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='102'),
	   'Cleaning', 4, 'Common area cleaning is good but can improve near elevators.',
	   'Thanks for the feedback - we will instruct the staff.', (SELECT id FROM users WHERE email='admin@society.local'), now()
WHERE NOT EXISTS (
	SELECT 1 FROM feedback fb WHERE fb.category='Cleaning' AND fb.user_id=(SELECT id FROM users WHERE email='jane@society.local')
);

-- Additional incomes and expenses
INSERT INTO incomes (entry_date, source, category, amount, reference_type, notes)
VALUES (CURRENT_DATE - INTERVAL '20 days', 'Donation', 'donation', 2000.00, 'donation', 'Seed donation')
ON CONFLICT DO NOTHING;

INSERT INTO expenses (entry_date, category, amount, payee, notes)
VALUES
	(CURRENT_DATE - INTERVAL '15 days', 'Electricity', 800.00, 'Utility Board', 'Seed electricity bill'),
	(CURRENT_DATE - INTERVAL '10 days', 'Security Salary', 5000.00, 'Guards Co.', 'Monthly salaries')
ON CONFLICT DO NOTHING;

COMMIT;