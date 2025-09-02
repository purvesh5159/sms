BEGIN;

-- Users (global)
INSERT INTO users (full_name, email, phone, role, password_hash) VALUES
	('Society Admin', 'admin@society.local', '+10000000000', 'admin', '$2y$10$examplehashforadmin'),
	('Security Guard', 'guard@society.local', '+10000000001', 'security', '$2y$10$examplehashforguard'),
	('John Resident', 'john@society.local', '+10000000002', 'resident', '$2y$10$examplehashforjohn'),
	('Jane Resident', 'jane@society.local', '+10000000003', 'resident', '$2y$10$examplehashforjane')
ON CONFLICT (email) DO NOTHING;

-- Societies
INSERT INTO societies (name, code, address, contact_email, phone) VALUES
	('Green Meadows', 'GM', 'Sunset Blvd, City', 'contact@greenmeadows.local', '+19999999990'),
	('Blue Heights', 'BH', 'Ocean Drive, City', 'contact@blueheights.local', '+19999999991')
ON CONFLICT DO NOTHING;

-- Permissions (global modules/actions)
WITH modules AS (
	SELECT UNNEST(ARRAY[
		'users','towers','flats','maintenance_bills','payments','complaints','visitors','amenities','bookings','polls','votes','feedback','incomes','expenses','reports','roles','permissions','memberships'
	]) AS module
), actions AS (
	SELECT UNNEST(ARRAY['create','read','update','delete','approve','export']) AS action
)
INSERT INTO permissions (module, action, description)
SELECT m.module, a.action, INITCAP(a.action) || ' ' || REPLACE(m.module, '_', ' ')
FROM modules m CROSS JOIN actions a
ON CONFLICT (module, action) DO NOTHING;

-- Roles per society
WITH s AS (
	SELECT id, name FROM societies
), r(name) AS (
	VALUES ('Admin'), ('Secretary'), ('Resident'), ('Committee Member'), ('Security')
)
INSERT INTO roles (society_id, name, description, is_system)
SELECT s.id, r.name, r.name || ' role', TRUE
FROM s CROSS JOIN r
ON CONFLICT (society_id, name) DO NOTHING;

-- Memberships: assign users to societies
-- Admin in both
INSERT INTO society_memberships (society_id, user_id)
SELECT s.id, (SELECT id FROM users WHERE email='admin@society.local') FROM societies s
ON CONFLICT (society_id, user_id) DO NOTHING;
-- Security in Green Meadows
INSERT INTO society_memberships (society_id, user_id)
SELECT (SELECT id FROM societies WHERE code='GM'), (SELECT id FROM users WHERE email='guard@society.local')
ON CONFLICT (society_id, user_id) DO NOTHING;
-- John & Jane in Green Meadows
INSERT INTO society_memberships (society_id, user_id)
SELECT (SELECT id FROM societies WHERE code='GM'), (SELECT id FROM users WHERE email='john@society.local')
ON CONFLICT (society_id, user_id) DO NOTHING;
INSERT INTO society_memberships (society_id, user_id)
SELECT (SELECT id FROM societies WHERE code='GM'), (SELECT id FROM users WHERE email='jane@society.local')
ON CONFLICT (society_id, user_id) DO NOTHING;

-- Assign roles to memberships (within same society)
-- Admin -> Admin role in all societies
WITH m AS (
	SELECT sm.id AS membership_id, sm.society_id, u.email
	FROM society_memberships sm JOIN users u ON u.id = sm.user_id
), r AS (
	SELECT roles.id AS role_id, roles.society_id, roles.name AS role_name FROM roles
)
INSERT INTO society_user_roles (membership_id, role_id, society_id)
SELECT m.membership_id, r.role_id, m.society_id
FROM m JOIN r ON r.society_id = m.society_id AND r.role_name = 'Admin'
WHERE m.email = 'admin@society.local'
ON CONFLICT DO NOTHING;

-- Security -> Security role (GM)
WITH m AS (
	SELECT sm.id AS membership_id, sm.society_id, u.email
	FROM society_memberships sm JOIN users u ON u.id = sm.user_id
), r AS (
	SELECT roles.id AS role_id, roles.society_id, roles.name AS role_name FROM roles
)
INSERT INTO society_user_roles (membership_id, role_id, society_id)
SELECT m.membership_id, r.role_id, m.society_id
FROM m JOIN r ON r.society_id = m.society_id AND r.role_name = 'Security'
WHERE m.email = 'guard@society.local'
ON CONFLICT DO NOTHING;

-- Residents -> Resident role (GM)
WITH m AS (
	SELECT sm.id AS membership_id, sm.society_id, u.email
	FROM society_memberships sm JOIN users u ON u.id = sm.user_id
), r AS (
	SELECT roles.id AS role_id, roles.society_id, roles.name AS role_name FROM roles
)
INSERT INTO society_user_roles (membership_id, role_id, society_id)
SELECT m.membership_id, r.role_id, m.society_id
FROM m JOIN r ON r.society_id = m.society_id AND r.role_name = 'Resident'
WHERE m.email IN ('john@society.local','jane@society.local')
ON CONFLICT DO NOTHING;

-- Role permissions
-- Admin: all permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r CROSS JOIN permissions p
WHERE r.name = 'Admin'
ON CONFLICT DO NOTHING;

-- Secretary: read/create/update/approve/export on all modules
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON p.action IN ('read','create','update','approve','export')
WHERE r.name = 'Secretary'
ON CONFLICT DO NOTHING;

-- Resident: read on most, and create/update on selected modules
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON (
	(p.action = 'read' AND p.module IN ('towers','flats','amenities','bookings','complaints','payments','polls','votes','visitors','feedback','reports')) OR
	(p.action IN ('create','update') AND p.module IN ('bookings','complaints','visitors','payments','votes','feedback'))
)
WHERE r.name = 'Resident'
ON CONFLICT DO NOTHING;

-- Committee Member: read all; create on polls and votes
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON (
	p.action = 'read' OR (p.action = 'create' AND p.module IN ('polls','votes'))
)
WHERE r.name = 'Committee Member'
ON CONFLICT DO NOTHING;

-- Security: read/create/update visitors; read bookings
INSERT INTO role_permissions (role_id, permission_id)
SELECT r.id, p.id
FROM roles r
JOIN permissions p ON (
	(p.module = 'visitors' AND p.action IN ('read','create','update')) OR
	(p.module = 'bookings' AND p.action = 'read')
)
WHERE r.name = 'Security'
ON CONFLICT DO NOTHING;

-- Domain data for Green Meadows (GM)
-- Towers
INSERT INTO towers (society_id, name, address, num_floors)
VALUES
	((SELECT id FROM societies WHERE code='GM'), 'A', '123 Alpha Street', 10),
	((SELECT id FROM societies WHERE code='GM'), 'B', '456 Beta Avenue', 12)
ON CONFLICT DO NOTHING;
-- Blue Heights example tower
INSERT INTO towers (society_id, name, address, num_floors)
VALUES ((SELECT id FROM societies WHERE code='BH'), 'C', '789 Coral Road', 14)
ON CONFLICT DO NOTHING;

-- Flats for GM
INSERT INTO flats (society_id, tower_id, number, floor, bedrooms, area_sqft, owner_user_id) VALUES
	((SELECT id FROM societies WHERE code='GM'), (SELECT id FROM towers WHERE name='A' AND society_id=(SELECT id FROM societies WHERE code='GM')), '101', 1, 2, 900, (SELECT id FROM users WHERE email='john@society.local')),
	((SELECT id FROM societies WHERE code='GM'), (SELECT id FROM towers WHERE name='A' AND society_id=(SELECT id FROM societies WHERE code='GM')), '102', 1, 3, 1100, (SELECT id FROM users WHERE email='jane@society.local')),
	((SELECT id FROM societies WHERE code='GM'), (SELECT id FROM towers WHERE name='A' AND society_id=(SELECT id FROM societies WHERE code='GM')), '201', 2, 2, 950, NULL),
	((SELECT id FROM societies WHERE code='GM'), (SELECT id FROM towers WHERE name='B' AND society_id=(SELECT id FROM societies WHERE code='GM')), '101', 1, 2, 900, NULL),
	((SELECT id FROM societies WHERE code='GM'), (SELECT id FROM towers WHERE name='B' AND society_id=(SELECT id FROM societies WHERE code='GM')), '102', 1, 3, 1200, NULL),
	((SELECT id FROM societies WHERE code='GM'), (SELECT id FROM towers WHERE name='B' AND society_id=(SELECT id FROM societies WHERE code='GM')), '201', 2, 2, 950, NULL)
ON CONFLICT DO NOTHING;

-- Current occupancies (GM)
INSERT INTO flat_occupancies (society_id, flat_id, resident_user_id, occupant_kind, move_in_date)
VALUES
	((SELECT id FROM societies WHERE code='GM'), (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101' AND f.society_id=(SELECT id FROM societies WHERE code='GM')), (SELECT id FROM users WHERE email='john@society.local'), 'owner', '2023-01-01'),
	((SELECT id FROM societies WHERE code='GM'), (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='102' AND f.society_id=(SELECT id FROM societies WHERE code='GM')), (SELECT id FROM users WHERE email='jane@society.local'), 'owner', '2023-03-01')
ON CONFLICT DO NOTHING;

-- Amenities (GM)
INSERT INTO amenities (society_id, name, description, open_time, close_time, requires_approval, slot_minutes, capacity) VALUES
	((SELECT id FROM societies WHERE code='GM'), 'Gym', 'Gym with basic equipment', '06:00', '22:00', FALSE, 60, 10),
	((SELECT id FROM societies WHERE code='GM'), 'Community Hall', 'Air-conditioned hall for events', '08:00', '21:00', TRUE, 120, 50),
	((SELECT id FROM societies WHERE code='GM'), 'Swimming Pool', 'Outdoor pool', '06:00', '20:00', TRUE, 60, 20)
ON CONFLICT DO NOTHING;

-- Maintenance bills for GM A-101 (previous and current month)
WITH params AS (
	SELECT EXTRACT(YEAR FROM now())::INT AS y_cur,
		   EXTRACT(MONTH FROM now())::INT AS m_cur,
		   EXTRACT(YEAR FROM (now() - INTERVAL '1 month'))::INT AS y_prev,
		   EXTRACT(MONTH FROM (now() - INTERVAL '1 month'))::INT AS m_prev,
		   (date_trunc('month', now()) + INTERVAL '10 days')::DATE AS due_cur,
		   (date_trunc('month', now() - INTERVAL '1 month') + INTERVAL '10 days')::DATE AS due_prev
)
INSERT INTO maintenance_bills (society_id, flat_id, bill_year, bill_month, bill_due_date, amount_due, amount_paid, penalty_amount, status, notes)
SELECT (SELECT id FROM societies WHERE code='GM'), f.id, y_prev, m_prev, due_prev, 1500.00, 1500.00, 0, 'paid'::bill_status, 'Previous month fully paid'
FROM params p, flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101' AND f.society_id=(SELECT id FROM societies WHERE code='GM')
ON CONFLICT DO NOTHING;

WITH params AS (
	SELECT EXTRACT(YEAR FROM now())::INT AS y_cur,
		   EXTRACT(MONTH FROM now())::INT AS m_cur,
		   (date_trunc('month', now()) + INTERVAL '10 days')::DATE AS due_cur
)
INSERT INTO maintenance_bills (society_id, flat_id, bill_year, bill_month, bill_due_date, amount_due, amount_paid, penalty_amount, status, notes)
SELECT (SELECT id FROM societies WHERE code='GM'), f.id, y_cur, m_cur, due_cur, 1500.00, 0, 0, 'unpaid'::bill_status, 'Current month pending'
FROM params p, flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101' AND f.society_id=(SELECT id FROM societies WHERE code='GM')
ON CONFLICT DO NOTHING;

-- Payment for previous month bill (GM A-101)
WITH prev_bill AS (
	SELECT mb.id, mb.flat_id, mb.society_id FROM maintenance_bills mb
	JOIN flats f ON f.id=mb.flat_id
	JOIN towers t ON t.id=f.tower_id
	WHERE t.name='A' AND f.number='101' AND mb.society_id=(SELECT id FROM societies WHERE code='GM')
	  AND (mb.bill_year, mb.bill_month) = (
		SELECT EXTRACT(YEAR FROM (now() - INTERVAL '1 month'))::INT,
		       EXTRACT(MONTH FROM (now() - INTERVAL '1 month'))::INT
	  )
)
INSERT INTO payments (society_id, bill_id, flat_id, user_id, amount, status, method, provider_payment_id, paid_at, notes)
SELECT pb.society_id, pb.id, pb.flat_id, (SELECT id FROM users WHERE email='john@society.local'), 1500.00, 'success'::payment_status, 'cash', 'SEED-PAY-001', now() - INTERVAL '20 days', 'Seeded payment'
FROM prev_bill pb
ON CONFLICT DO NOTHING;

-- Booking example for Gym (GM)
INSERT INTO bookings (society_id, amenity_id, flat_id, user_id, start_time, end_time, status, notes)
SELECT (SELECT id FROM societies WHERE code='GM'),
	   (SELECT id FROM amenities WHERE name='Gym' AND society_id=(SELECT id FROM societies WHERE code='GM')),
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101' AND f.society_id=(SELECT id FROM societies WHERE code='GM')),
	   (SELECT id FROM users WHERE email='john@society.local'),
	   now() + INTERVAL '1 day', now() + INTERVAL '1 day' + INTERVAL '1 hour',
	   'approved'::booking_status,
	   'Seed booking'
WHERE NOT EXISTS (
	SELECT 1 FROM bookings b WHERE b.amenity_id = (SELECT id FROM amenities WHERE name='Gym' AND society_id=(SELECT id FROM societies WHERE code='GM'))
);

-- Complaint example (GM)
INSERT INTO complaints (society_id, flat_id, created_by_user_id, assigned_to_user_id, category, description, status, priority)
SELECT (SELECT id FROM societies WHERE code='GM'),
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='102' AND f.society_id=(SELECT id FROM societies WHERE code='GM')),
	   (SELECT id FROM users WHERE email='jane@society.local'),
	   (SELECT id FROM users WHERE email='admin@society.local'),
	   'Plumbing', 'Water leakage in bathroom', 'in_progress'::complaint_status, 2
WHERE NOT EXISTS (
	SELECT 1 FROM complaints c WHERE c.description = 'Water leakage in bathroom' AND c.society_id=(SELECT id FROM societies WHERE code='GM')
);

-- Polls and votes (GM)
INSERT INTO polls (society_id, title, description, type, options, start_time, end_time, created_by_user_id)
VALUES ((SELECT id FROM societies WHERE code='GM'), 'Install new CCTV cameras?', 'Proposal to add more CCTV coverage in common areas', 'yes_no', NULL, now() - INTERVAL '1 day', now() + INTERVAL '6 days', (SELECT id FROM users WHERE email='admin@society.local'))
ON CONFLICT DO NOTHING;

INSERT INTO polls (society_id, title, description, type, options, start_time, end_time, created_by_user_id)
VALUES ((SELECT id FROM societies WHERE code='GM'), 'Preferred cleaning schedule', 'Choose your preferred cleaning slot', 'multiple_choice', '["Morning", "Afternoon", "Evening"]'::jsonb, now() - INTERVAL '2 days', now() + INTERVAL '5 days', (SELECT id FROM users WHERE email='admin@society.local'))
ON CONFLICT DO NOTHING;

-- Vote: GM A-101 votes YES for CCTV
INSERT INTO votes (society_id, poll_id, flat_id, user_id, choice)
SELECT (SELECT id FROM societies WHERE code='GM'), p.id,
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101' AND f.society_id=(SELECT id FROM societies WHERE code='GM')),
	   (SELECT id FROM users WHERE email='john@society.local'),
	   'yes'
FROM polls p WHERE p.title='Install new CCTV cameras?' AND p.society_id=(SELECT id FROM societies WHERE code='GM')
ON CONFLICT DO NOTHING;

-- Visitors (GM)
INSERT INTO visitors (society_id, full_name, phone, purpose, flat_id, preapproved_by_user_id, check_in_time, check_out_time, status)
SELECT (SELECT id FROM societies WHERE code='GM'), 'Mike Visitor', '+10000000010', 'Friend visit',
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='101' AND f.society_id=(SELECT id FROM societies WHERE code='GM')),
	   (SELECT id FROM users WHERE email='john@society.local'),
	   now() - INTERVAL '3 hours', now() - INTERVAL '2 hours', 'checked_out'::visitor_status
WHERE NOT EXISTS (
	SELECT 1 FROM visitors v WHERE v.full_name='Mike Visitor' AND v.purpose='Friend visit' AND v.society_id=(SELECT id FROM societies WHERE code='GM')
);

-- Feedback (GM)
INSERT INTO feedback (society_id, user_id, flat_id, category, rating, message, response, responded_by_user_id, responded_at)
SELECT (SELECT id FROM societies WHERE code='GM'), (SELECT id FROM users WHERE email='jane@society.local'),
	   (SELECT f.id FROM flats f JOIN towers t ON t.id=f.tower_id WHERE t.name='A' AND f.number='102' AND f.society_id=(SELECT id FROM societies WHERE code='GM')),
	   'Cleaning', 4, 'Common area cleaning is good but can improve near elevators.',
	   'Thanks for the feedback - we will instruct the staff.', (SELECT id FROM users WHERE email='admin@society.local'), now()
WHERE NOT EXISTS (
	SELECT 1 FROM feedback fb WHERE fb.category='Cleaning' AND fb.user_id=(SELECT id FROM users WHERE email='jane@society.local') AND fb.society_id=(SELECT id FROM societies WHERE code='GM')
);

-- Additional incomes and expenses (GM)
INSERT INTO incomes (society_id, entry_date, source, category, amount, reference_type, notes)
VALUES ((SELECT id FROM societies WHERE code='GM'), CURRENT_DATE - INTERVAL '20 days', 'Donation', 'donation', 2000.00, 'donation', 'Seed donation')
ON CONFLICT DO NOTHING;

INSERT INTO expenses (society_id, entry_date, category, amount, payee, notes)
VALUES
	((SELECT id FROM societies WHERE code='GM'), CURRENT_DATE - INTERVAL '15 days', 'Electricity', 800.00, 'Utility Board', 'Seed electricity bill'),
	((SELECT id FROM societies WHERE code='GM'), CURRENT_DATE - INTERVAL '10 days', 'Security Salary', 5000.00, 'Guards Co.', 'Monthly salaries')
ON CONFLICT DO NOTHING;

COMMIT;