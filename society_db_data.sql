-- Adminer 5.3.0 PostgreSQL 16.10 dump

\connect "society_db";

DROP TYPE IF EXISTS "user_role";;
CREATE TYPE "user_role" AS ENUM ('admin', 'secretary', 'resident', 'security', 'committee');

DROP TYPE IF EXISTS "complaint_status";;
CREATE TYPE "complaint_status" AS ENUM ('open', 'in_progress', 'closed');

DROP TYPE IF EXISTS "payment_status";;
CREATE TYPE "payment_status" AS ENUM ('pending', 'success', 'failed', 'refunded');

DROP TYPE IF EXISTS "bill_status";;
CREATE TYPE "bill_status" AS ENUM ('unpaid', 'paid', 'partial', 'overdue');

DROP TYPE IF EXISTS "booking_status";;
CREATE TYPE "booking_status" AS ENUM ('pending', 'approved', 'rejected', 'cancelled');

DROP TYPE IF EXISTS "visitor_status";;
CREATE TYPE "visitor_status" AS ENUM ('expected', 'checked_in', 'checked_out', 'denied');

DROP TYPE IF EXISTS "poll_type";;
CREATE TYPE "poll_type" AS ENUM ('yes_no', 'multiple_choice');

DROP TYPE IF EXISTS "occupant_type";;
CREATE TYPE "occupant_type" AS ENUM ('owner', 'tenant');

DROP FUNCTION IF EXISTS "set_updated_at";;
CREATE FUNCTION "set_updated_at" () RETURNS trigger LANGUAGE plpgsql AS '
BEGIN
	NEW.updated_at = now();
	RETURN NEW;
END;
';

CREATE SEQUENCE amenities_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 4 CACHE 1;

CREATE TABLE "public"."amenities" (
    "id" bigint DEFAULT nextval('amenities_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "name" character varying(100) NOT NULL,
    "description" text,
    "open_time" time without time zone,
    "close_time" time without time zone,
    "requires_approval" boolean DEFAULT false NOT NULL,
    "slot_minutes" integer DEFAULT '60' NOT NULL,
    "capacity" integer DEFAULT '1' NOT NULL,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "amenities_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX amenities_society_id_name_key ON public.amenities USING btree (society_id, name);

CREATE UNIQUE INDEX amenities_id_society_id_key ON public.amenities USING btree (id, society_id);

CREATE INDEX idx_amenities_society_id ON public.amenities USING btree (society_id);


DELIMITER ;;

CREATE TRIGGER "trg_amenities_updated_at" BEFORE UPDATE ON "public"."amenities" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE bookings_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 2 CACHE 1;

CREATE TABLE "public"."bookings" (
    "id" bigint DEFAULT nextval('bookings_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "amenity_id" bigint NOT NULL,
    "flat_id" bigint NOT NULL,
    "user_id" bigint,
    "start_time" timestamptz NOT NULL,
    "end_time" timestamptz NOT NULL,
    "status" booking_status DEFAULT pending NOT NULL,
    "approved_by_user_id" bigint,
    "notes" text,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "bookings_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "bookings_check" CHECK ((end_time > start_time))
)
WITH (oids = false);

CREATE INDEX idx_bookings_amenity_time ON public.bookings USING btree (amenity_id, start_time, end_time);

CREATE INDEX idx_bookings_status ON public.bookings USING btree (status);

CREATE INDEX idx_bookings_society_id ON public.bookings USING btree (society_id);


DELIMITER ;;

CREATE TRIGGER "trg_bookings_updated_at" BEFORE UPDATE ON "public"."bookings" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE complaints_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 2 CACHE 1;

CREATE TABLE "public"."complaints" (
    "id" bigint DEFAULT nextval('complaints_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "flat_id" bigint NOT NULL,
    "created_by_user_id" bigint,
    "assigned_to_user_id" bigint,
    "category" character varying(100) NOT NULL,
    "description" text NOT NULL,
    "status" complaint_status DEFAULT open NOT NULL,
    "priority" smallint DEFAULT '3' NOT NULL,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    "closed_at" timestamptz,
    CONSTRAINT "complaints_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "complaints_priority_check" CHECK (((priority >= 1) AND (priority <= 5)))
)
WITH (oids = false);

CREATE INDEX idx_complaints_status ON public.complaints USING btree (status);

CREATE INDEX idx_complaints_flat_id ON public.complaints USING btree (flat_id);

CREATE INDEX idx_complaints_society_id ON public.complaints USING btree (society_id);


DELIMITER ;;

CREATE TRIGGER "trg_complaints_updated_at" BEFORE UPDATE ON "public"."complaints" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE expenses_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 3 CACHE 1;

CREATE TABLE "public"."expenses" (
    "id" bigint DEFAULT nextval('expenses_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "entry_date" date DEFAULT CURRENT_DATE NOT NULL,
    "category" character varying(50) NOT NULL,
    "amount" numeric(12,2) NOT NULL,
    "payee" character varying(100),
    "notes" text,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "expenses_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "expenses_amount_check" CHECK ((amount >= (0)::numeric))
)
WITH (oids = false);

CREATE INDEX idx_expenses_entry_date ON public.expenses USING btree (entry_date);

CREATE INDEX idx_expenses_category ON public.expenses USING btree (category);

CREATE INDEX idx_expenses_society_id ON public.expenses USING btree (society_id);


CREATE SEQUENCE feedback_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 2 CACHE 1;

CREATE TABLE "public"."feedback" (
    "id" bigint DEFAULT nextval('feedback_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "user_id" bigint,
    "flat_id" bigint NOT NULL,
    "category" character varying(100),
    "rating" integer,
    "message" text NOT NULL,
    "response" text,
    "responded_by_user_id" bigint,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "responded_at" timestamptz,
    CONSTRAINT "feedback_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "feedback_rating_check" CHECK (((rating >= 1) AND (rating <= 5)))
)
WITH (oids = false);

CREATE INDEX idx_feedback_flat_id ON public.feedback USING btree (flat_id);

CREATE INDEX idx_feedback_rating ON public.feedback USING btree (rating);

CREATE INDEX idx_feedback_society_id ON public.feedback USING btree (society_id);


CREATE SEQUENCE flat_occupancies_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 3 CACHE 1;

CREATE TABLE "public"."flat_occupancies" (
    "id" bigint DEFAULT nextval('flat_occupancies_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "flat_id" bigint NOT NULL,
    "resident_user_id" bigint,
    "occupant_kind" occupant_type NOT NULL,
    "move_in_date" date NOT NULL,
    "move_out_date" date,
    "notes" text,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "flat_occupancies_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX uniq_flat_active_occupancy ON public.flat_occupancies USING btree (flat_id) WHERE (move_out_date IS NULL);

CREATE UNIQUE INDEX uniq_resident_active_occupancy_soc ON public.flat_occupancies USING btree (resident_user_id, society_id) WHERE (move_out_date IS NULL);

CREATE INDEX idx_flat_occupancies_flat_id ON public.flat_occupancies USING btree (flat_id);

CREATE INDEX idx_flat_occupancies_society_id ON public.flat_occupancies USING btree (society_id);


DELIMITER ;;

CREATE TRIGGER "trg_flat_occupancies_updated_at" BEFORE UPDATE ON "public"."flat_occupancies" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE flats_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 7 CACHE 1;

CREATE TABLE "public"."flats" (
    "id" bigint DEFAULT nextval('flats_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "tower_id" bigint NOT NULL,
    "number" character varying(20) NOT NULL,
    "floor" integer,
    "bedrooms" integer,
    "area_sqft" integer,
    "owner_user_id" bigint,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "flats_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX flats_tower_id_number_key ON public.flats USING btree (tower_id, number);

CREATE UNIQUE INDEX flats_id_society_id_key ON public.flats USING btree (id, society_id);

CREATE INDEX idx_flats_tower_id ON public.flats USING btree (tower_id);

CREATE INDEX idx_flats_society_id ON public.flats USING btree (society_id);

INSERT INTO "flats" ("id", "society_id", "tower_id", "number", "floor", "bedrooms", "area_sqft", "owner_user_id", "is_active", "created_at", "updated_at") VALUES
(1,	1,	1,	'101',	1,	2,	900,	3,	'1',	'2025-08-29 13:39:00.290304+00',	'2025-08-29 13:39:00.290304+00'),
(2,	1,	1,	'102',	1,	3,	1100,	4,	'1',	'2025-08-29 13:39:00.290304+00',	'2025-08-29 13:39:00.290304+00'),
(3,	1,	1,	'201',	2,	2,	950,	NULL,	'1',	'2025-08-29 13:39:00.290304+00',	'2025-08-29 13:39:00.290304+00'),
(4,	1,	2,	'101',	1,	2,	900,	NULL,	'1',	'2025-08-29 13:39:00.290304+00',	'2025-08-29 13:39:00.290304+00'),
(5,	1,	2,	'102',	1,	3,	1200,	NULL,	'1',	'2025-08-29 13:39:00.290304+00',	'2025-08-29 13:39:00.290304+00'),
(6,	1,	2,	'201',	2,	2,	950,	NULL,	'1',	'2025-08-29 13:39:00.290304+00',	'2025-08-29 13:39:00.290304+00');

DELIMITER ;;

CREATE TRIGGER "trg_flats_updated_at" BEFORE UPDATE ON "public"."flats" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE incomes_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 2 CACHE 1;

CREATE TABLE "public"."incomes" (
    "id" bigint DEFAULT nextval('incomes_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "entry_date" date DEFAULT CURRENT_DATE NOT NULL,
    "source" character varying(100) NOT NULL,
    "category" character varying(50) NOT NULL,
    "amount" numeric(12,2) NOT NULL,
    "reference_type" character varying(50),
    "reference_id" bigint,
    "notes" text,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "incomes_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "incomes_amount_check" CHECK ((amount >= (0)::numeric))
)
WITH (oids = false);

CREATE INDEX idx_incomes_entry_date ON public.incomes USING btree (entry_date);

CREATE INDEX idx_incomes_category ON public.incomes USING btree (category);

CREATE INDEX idx_incomes_society_id ON public.incomes USING btree (society_id);


CREATE SEQUENCE maintenance_bills_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 3 CACHE 1;

CREATE TABLE "public"."maintenance_bills" (
    "id" bigint DEFAULT nextval('maintenance_bills_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "flat_id" bigint NOT NULL,
    "bill_year" integer NOT NULL,
    "bill_month" integer NOT NULL,
    "bill_due_date" date NOT NULL,
    "amount_due" numeric(12,2) NOT NULL,
    "amount_paid" numeric(12,2) DEFAULT '0' NOT NULL,
    "penalty_amount" numeric(12,2) DEFAULT '0' NOT NULL,
    "status" bill_status DEFAULT unpaid NOT NULL,
    "notes" text,
    "generated_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "maintenance_bills_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "maintenance_bills_bill_month_check" CHECK (((bill_month >= 1) AND (bill_month <= 12))),
    CONSTRAINT "maintenance_bills_amount_due_check" CHECK ((amount_due >= (0)::numeric)),
    CONSTRAINT "maintenance_bills_amount_paid_check" CHECK ((amount_paid >= (0)::numeric)),
    CONSTRAINT "maintenance_bills_penalty_amount_check" CHECK ((penalty_amount >= (0)::numeric))
)
WITH (oids = false);

CREATE UNIQUE INDEX maintenance_bills_flat_id_bill_year_bill_month_key ON public.maintenance_bills USING btree (flat_id, bill_year, bill_month);

CREATE INDEX idx_bills_flat_period ON public.maintenance_bills USING btree (flat_id, bill_year, bill_month);

CREATE INDEX idx_bills_status ON public.maintenance_bills USING btree (status);

CREATE INDEX idx_bills_society_id ON public.maintenance_bills USING btree (society_id);


DELIMITER ;;

CREATE TRIGGER "trg_bills_updated_at" BEFORE UPDATE ON "public"."maintenance_bills" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE payments_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 2 CACHE 1;

CREATE TABLE "public"."payments" (
    "id" bigint DEFAULT nextval('payments_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "bill_id" bigint NOT NULL,
    "flat_id" bigint NOT NULL,
    "user_id" bigint,
    "amount" numeric(12,2) NOT NULL,
    "status" payment_status DEFAULT success NOT NULL,
    "method" character varying(40),
    "provider_payment_id" character varying(100),
    "paid_at" timestamptz DEFAULT now() NOT NULL,
    "notes" text,
    CONSTRAINT "payments_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "payments_amount_check" CHECK ((amount > (0)::numeric))
)
WITH (oids = false);

CREATE UNIQUE INDEX payments_provider_payment_id_key ON public.payments USING btree (provider_payment_id);

CREATE INDEX idx_payments_bill_id ON public.payments USING btree (bill_id);

CREATE INDEX idx_payments_flat_id ON public.payments USING btree (flat_id);

CREATE INDEX idx_payments_status ON public.payments USING btree (status);

CREATE INDEX idx_payments_society_id ON public.payments USING btree (society_id);


CREATE SEQUENCE permissions_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 109 CACHE 1;

CREATE TABLE "public"."permissions" (
    "id" bigint DEFAULT nextval('permissions_id_seq') NOT NULL,
    "module" character varying(100) NOT NULL,
    "action" character varying(50) NOT NULL,
    "description" text,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "permissions_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX permissions_module_action_key ON public.permissions USING btree (module, action);


CREATE SEQUENCE polls_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 3 CACHE 1;

CREATE TABLE "public"."polls" (
    "id" bigint DEFAULT nextval('polls_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "title" character varying(200) NOT NULL,
    "description" text,
    "type" poll_type NOT NULL,
    "options" jsonb,
    "start_time" timestamptz DEFAULT now() NOT NULL,
    "end_time" timestamptz,
    "created_by_user_id" bigint,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "polls_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "polls_check" CHECK (((type <> 'multiple_choice'::poll_type) OR (options IS NOT NULL))),
    CONSTRAINT "polls_check1" CHECK (((type = 'yes_no'::poll_type) OR (jsonb_typeof(options) = 'array'::text)))
)
WITH (oids = false);

CREATE UNIQUE INDEX polls_society_id_title_key ON public.polls USING btree (society_id, title);

CREATE UNIQUE INDEX polls_id_society_id_key ON public.polls USING btree (id, society_id);

CREATE INDEX idx_polls_type ON public.polls USING btree (type);

CREATE INDEX idx_polls_society_id ON public.polls USING btree (society_id);


DELIMITER ;;

CREATE TRIGGER "trg_polls_updated_at" BEFORE UPDATE ON "public"."polls" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE TABLE "public"."role_permissions" (
    "role_id" bigint NOT NULL,
    "permission_id" bigint NOT NULL,
    CONSTRAINT "role_permissions_pkey" PRIMARY KEY ("role_id", "permission_id")
)
WITH (oids = false);


CREATE SEQUENCE roles_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 11 CACHE 1;

CREATE TABLE "public"."roles" (
    "id" bigint DEFAULT nextval('roles_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "name" character varying(100) NOT NULL,
    "description" text,
    "is_system" boolean DEFAULT false NOT NULL,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "roles_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX roles_society_id_name_key ON public.roles USING btree (society_id, name);

CREATE UNIQUE INDEX roles_id_society_id_key ON public.roles USING btree (id, society_id);


DELIMITER ;;

CREATE TRIGGER "trg_roles_updated_at" BEFORE UPDATE ON "public"."roles" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE societies_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 3 CACHE 1;

CREATE TABLE "public"."societies" (
    "id" bigint DEFAULT nextval('societies_id_seq') NOT NULL,
    "name" character varying(200) NOT NULL,
    "code" character varying(50),
    "address" text,
    "contact_email" character varying(320),
    "phone" character varying(20),
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "societies_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX societies_name_key ON public.societies USING btree (name);

CREATE UNIQUE INDEX societies_code_key ON public.societies USING btree (code);


DELIMITER ;;

CREATE TRIGGER "trg_societies_updated_at" BEFORE UPDATE ON "public"."societies" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE society_memberships_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 6 CACHE 1;

CREATE TABLE "public"."society_memberships" (
    "id" bigint DEFAULT nextval('society_memberships_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "user_id" bigint NOT NULL,
    "is_active" boolean DEFAULT true NOT NULL,
    "joined_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "society_memberships_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX society_memberships_society_id_user_id_key ON public.society_memberships USING btree (society_id, user_id);

CREATE UNIQUE INDEX society_memberships_id_society_id_key ON public.society_memberships USING btree (id, society_id);


CREATE TABLE "public"."society_user_roles" (
    "membership_id" bigint NOT NULL,
    "role_id" bigint NOT NULL,
    "society_id" bigint NOT NULL,
    CONSTRAINT "society_user_roles_pkey" PRIMARY KEY ("membership_id", "role_id")
)
WITH (oids = false);


CREATE SEQUENCE towers_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 4 CACHE 1;

CREATE TABLE "public"."towers" (
    "id" bigint DEFAULT nextval('towers_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "name" character varying(100) NOT NULL,
    "address" text,
    "num_floors" integer,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "towers_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX towers_society_id_name_key ON public.towers USING btree (society_id, name);

CREATE UNIQUE INDEX towers_id_society_id_key ON public.towers USING btree (id, society_id);

CREATE INDEX idx_towers_society_id ON public.towers USING btree (society_id);


DELIMITER ;;

CREATE TRIGGER "trg_towers_updated_at" BEFORE UPDATE ON "public"."towers" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE users_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 5 CACHE 1;

CREATE TABLE "public"."users" (
    "id" bigint DEFAULT nextval('users_id_seq') NOT NULL,
    "full_name" character varying(200) NOT NULL,
    "email" character varying(320) NOT NULL,
    "phone" character varying(20),
    "role" user_role DEFAULT resident NOT NULL,
    "password_hash" text NOT NULL,
    "profile_image_url" text,
    "is_active" boolean DEFAULT true NOT NULL,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);

CREATE UNIQUE INDEX users_phone_key ON public.users USING btree (phone);


DELIMITER ;;

CREATE TRIGGER "trg_users_updated_at" BEFORE UPDATE ON "public"."users" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE TABLE "v_current_occupancies" ("society_id" bigint, "society_name" character varying(200), "tower_id" bigint, "tower_name" character varying(100), "flat_id" bigint, "flat_number" character varying(20), "occupant_kind" occupant_type, "move_in_date" date, "resident_user_id" bigint, "resident_name" character varying(200));


CREATE TABLE "v_flat_balances" ("society_id" bigint, "society_name" character varying(200), "tower_name" character varying(100), "flat_id" bigint, "flat_number" character varying(20), "total_billed" numeric, "total_paid" numeric, "balance" numeric);


CREATE TABLE "v_monthly_financials" ("society_id" bigint, "society_name" character varying(200), "year" integer, "month" integer, "total_income" numeric(12,2), "total_expense" numeric(12,2), "net" numeric(12,2));


CREATE SEQUENCE visitors_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 2 CACHE 1;

CREATE TABLE "public"."visitors" (
    "id" bigint DEFAULT nextval('visitors_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "full_name" character varying(200) NOT NULL,
    "phone" character varying(20),
    "purpose" character varying(200),
    "flat_id" bigint NOT NULL,
    "preapproved_by_user_id" bigint,
    "check_in_time" timestamptz,
    "check_out_time" timestamptz,
    "status" visitor_status DEFAULT expected NOT NULL,
    "created_at" timestamptz DEFAULT now() NOT NULL,
    "updated_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "visitors_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE INDEX idx_visitors_flat_id ON public.visitors USING btree (flat_id);

CREATE INDEX idx_visitors_status ON public.visitors USING btree (status);

CREATE INDEX idx_visitors_society_id ON public.visitors USING btree (society_id);


DELIMITER ;;

CREATE TRIGGER "trg_visitors_updated_at" BEFORE UPDATE ON "public"."visitors" FOR EACH ROW EXECUTE FUNCTION set_updated_at();;

DELIMITER ;

CREATE SEQUENCE votes_id_seq INCREMENT 1 MINVALUE 1 MAXVALUE 9223372036854775807 START 2 CACHE 1;

CREATE TABLE "public"."votes" (
    "id" bigint DEFAULT nextval('votes_id_seq') NOT NULL,
    "society_id" bigint NOT NULL,
    "poll_id" bigint NOT NULL,
    "flat_id" bigint NOT NULL,
    "user_id" bigint,
    "choice" character varying(200) NOT NULL,
    "cast_at" timestamptz DEFAULT now() NOT NULL,
    CONSTRAINT "votes_pkey" PRIMARY KEY ("id")
)
WITH (oids = false);

CREATE UNIQUE INDEX votes_poll_id_flat_id_key ON public.votes USING btree (poll_id, flat_id);

CREATE INDEX idx_votes_poll_id ON public.votes USING btree (poll_id);

CREATE INDEX idx_votes_society_id ON public.votes USING btree (society_id);


ALTER TABLE ONLY "public"."amenities" ADD CONSTRAINT "amenities_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."bookings" ADD CONSTRAINT "bookings_amenity_id_fkey" FOREIGN KEY (amenity_id) REFERENCES amenities(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."bookings" ADD CONSTRAINT "bookings_amenity_id_society_id_fkey" FOREIGN KEY (amenity_id, society_id) REFERENCES amenities(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."bookings" ADD CONSTRAINT "bookings_approved_by_user_id_fkey" FOREIGN KEY (approved_by_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."bookings" ADD CONSTRAINT "bookings_flat_id_fkey" FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."bookings" ADD CONSTRAINT "bookings_flat_id_society_id_fkey" FOREIGN KEY (flat_id, society_id) REFERENCES flats(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."bookings" ADD CONSTRAINT "bookings_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."bookings" ADD CONSTRAINT "bookings_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;

ALTER TABLE ONLY "public"."complaints" ADD CONSTRAINT "complaints_assigned_to_user_id_fkey" FOREIGN KEY (assigned_to_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."complaints" ADD CONSTRAINT "complaints_created_by_user_id_fkey" FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."complaints" ADD CONSTRAINT "complaints_flat_id_fkey" FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."complaints" ADD CONSTRAINT "complaints_flat_id_society_id_fkey" FOREIGN KEY (flat_id, society_id) REFERENCES flats(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."complaints" ADD CONSTRAINT "complaints_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."expenses" ADD CONSTRAINT "expenses_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."feedback" ADD CONSTRAINT "feedback_flat_id_fkey" FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."feedback" ADD CONSTRAINT "feedback_flat_id_society_id_fkey" FOREIGN KEY (flat_id, society_id) REFERENCES flats(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."feedback" ADD CONSTRAINT "feedback_responded_by_user_id_fkey" FOREIGN KEY (responded_by_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."feedback" ADD CONSTRAINT "feedback_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."feedback" ADD CONSTRAINT "feedback_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;

ALTER TABLE ONLY "public"."flat_occupancies" ADD CONSTRAINT "flat_occupancies_flat_id_fkey" FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."flat_occupancies" ADD CONSTRAINT "flat_occupancies_flat_id_society_id_fkey" FOREIGN KEY (flat_id, society_id) REFERENCES flats(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."flat_occupancies" ADD CONSTRAINT "flat_occupancies_resident_user_id_fkey" FOREIGN KEY (resident_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."flat_occupancies" ADD CONSTRAINT "flat_occupancies_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."flats" ADD CONSTRAINT "flats_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."flats" ADD CONSTRAINT "flats_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."flats" ADD CONSTRAINT "flats_tower_id_fkey" FOREIGN KEY (tower_id) REFERENCES towers(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."flats" ADD CONSTRAINT "flats_tower_id_society_id_fkey" FOREIGN KEY (tower_id, society_id) REFERENCES towers(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."incomes" ADD CONSTRAINT "incomes_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."maintenance_bills" ADD CONSTRAINT "maintenance_bills_flat_id_fkey" FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."maintenance_bills" ADD CONSTRAINT "maintenance_bills_flat_id_society_id_fkey" FOREIGN KEY (flat_id, society_id) REFERENCES flats(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."maintenance_bills" ADD CONSTRAINT "maintenance_bills_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."payments" ADD CONSTRAINT "payments_bill_id_fkey" FOREIGN KEY (bill_id) REFERENCES maintenance_bills(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."payments" ADD CONSTRAINT "payments_flat_id_fkey" FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."payments" ADD CONSTRAINT "payments_flat_id_society_id_fkey" FOREIGN KEY (flat_id, society_id) REFERENCES flats(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."payments" ADD CONSTRAINT "payments_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."payments" ADD CONSTRAINT "payments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;

ALTER TABLE ONLY "public"."polls" ADD CONSTRAINT "polls_created_by_user_id_fkey" FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."polls" ADD CONSTRAINT "polls_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."role_permissions" ADD CONSTRAINT "role_permissions_permission_id_fkey" FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."role_permissions" ADD CONSTRAINT "role_permissions_role_id_fkey" FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."roles" ADD CONSTRAINT "roles_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."society_memberships" ADD CONSTRAINT "society_memberships_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."society_memberships" ADD CONSTRAINT "society_memberships_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."society_user_roles" ADD CONSTRAINT "society_user_roles_membership_id_society_id_fkey" FOREIGN KEY (membership_id, society_id) REFERENCES society_memberships(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."society_user_roles" ADD CONSTRAINT "society_user_roles_role_id_society_id_fkey" FOREIGN KEY (role_id, society_id) REFERENCES roles(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."society_user_roles" ADD CONSTRAINT "society_user_roles_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."towers" ADD CONSTRAINT "towers_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."visitors" ADD CONSTRAINT "visitors_flat_id_fkey" FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."visitors" ADD CONSTRAINT "visitors_flat_id_society_id_fkey" FOREIGN KEY (flat_id, society_id) REFERENCES flats(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."visitors" ADD CONSTRAINT "visitors_preapproved_by_user_id_fkey" FOREIGN KEY (preapproved_by_user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;
ALTER TABLE ONLY "public"."visitors" ADD CONSTRAINT "visitors_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;

ALTER TABLE ONLY "public"."votes" ADD CONSTRAINT "votes_flat_id_fkey" FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."votes" ADD CONSTRAINT "votes_flat_id_society_id_fkey" FOREIGN KEY (flat_id, society_id) REFERENCES flats(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."votes" ADD CONSTRAINT "votes_poll_id_fkey" FOREIGN KEY (poll_id) REFERENCES polls(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."votes" ADD CONSTRAINT "votes_poll_id_society_id_fkey" FOREIGN KEY (poll_id, society_id) REFERENCES polls(id, society_id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."votes" ADD CONSTRAINT "votes_society_id_fkey" FOREIGN KEY (society_id) REFERENCES societies(id) ON DELETE CASCADE NOT DEFERRABLE;
ALTER TABLE ONLY "public"."votes" ADD CONSTRAINT "votes_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL NOT DEFERRABLE;

DROP TABLE IF EXISTS "v_current_occupancies";
CREATE VIEW "v_current_occupancies" AS SELECT s.id AS society_id,
    s.name AS society_name,
    t.id AS tower_id,
    t.name AS tower_name,
    f.id AS flat_id,
    f.number AS flat_number,
    o.occupant_kind,
    o.move_in_date,
    u.id AS resident_user_id,
    u.full_name AS resident_name
   FROM ((((flat_occupancies o
     JOIN flats f ON (((f.id = o.flat_id) AND (f.society_id = o.society_id))))
     JOIN towers t ON (((t.id = f.tower_id) AND (t.society_id = f.society_id))))
     JOIN societies s ON ((s.id = f.society_id)))
     LEFT JOIN users u ON ((u.id = o.resident_user_id)))
  WHERE (o.move_out_date IS NULL);

DROP TABLE IF EXISTS "v_flat_balances";
CREATE VIEW "v_flat_balances" AS WITH billed AS (
         SELECT maintenance_bills.flat_id,
            sum((maintenance_bills.amount_due + maintenance_bills.penalty_amount)) AS total_billed
           FROM maintenance_bills
          GROUP BY maintenance_bills.flat_id
        ), paid AS (
         SELECT payments.flat_id,
            sum(payments.amount) AS total_paid
           FROM payments
          WHERE (payments.status = 'success'::payment_status)
          GROUP BY payments.flat_id
        )
 SELECT s.id AS society_id,
    s.name AS society_name,
    t.name AS tower_name,
    f.id AS flat_id,
    f.number AS flat_number,
    COALESCE(b.total_billed, (0)::numeric) AS total_billed,
    COALESCE(p.total_paid, (0)::numeric) AS total_paid,
    (COALESCE(b.total_billed, (0)::numeric) - COALESCE(p.total_paid, (0)::numeric)) AS balance
   FROM ((((flats f
     JOIN towers t ON (((t.id = f.tower_id) AND (t.society_id = f.society_id))))
     JOIN societies s ON ((s.id = f.society_id)))
     LEFT JOIN billed b ON ((b.flat_id = f.id)))
     LEFT JOIN paid p ON ((p.flat_id = f.id)))
  ORDER BY s.name, t.name, f.number;

DROP TABLE IF EXISTS "v_monthly_financials";
CREATE VIEW "v_monthly_financials" AS WITH payments_m AS (
         SELECT payments.society_id,
            date_trunc('month'::text, payments.paid_at) AS month_start,
            (sum(payments.amount))::numeric(12,2) AS total
           FROM payments
          WHERE (payments.status = 'success'::payment_status)
          GROUP BY payments.society_id, (date_trunc('month'::text, payments.paid_at))
        ), incomes_m AS (
         SELECT incomes.society_id,
            date_trunc('month'::text, (incomes.entry_date)::timestamp without time zone) AS month_start,
            (sum(incomes.amount))::numeric(12,2) AS total
           FROM incomes
          GROUP BY incomes.society_id, (date_trunc('month'::text, (incomes.entry_date)::timestamp without time zone))
        ), expenses_m AS (
         SELECT expenses.society_id,
            date_trunc('month'::text, (expenses.entry_date)::timestamp without time zone) AS month_start,
            (sum(expenses.amount))::numeric(12,2) AS total
           FROM expenses
          GROUP BY expenses.society_id, (date_trunc('month'::text, (expenses.entry_date)::timestamp without time zone))
        ), combined_income AS (
         SELECT s_1.society_id,
            s_1.month_start,
            (sum(s_1.total))::numeric(12,2) AS total_income
           FROM ( SELECT payments_m.society_id,
                    payments_m.month_start,
                    payments_m.total
                   FROM payments_m
                UNION ALL
                 SELECT incomes_m.society_id,
                    incomes_m.month_start,
                    incomes_m.total
                   FROM incomes_m) s_1
          GROUP BY s_1.society_id, s_1.month_start
        )
 SELECT s.id AS society_id,
    s.name AS society_name,
    (EXTRACT(year FROM COALESCE(ci.month_start, (e.month_start)::timestamp with time zone)))::integer AS year,
    (EXTRACT(month FROM COALESCE(ci.month_start, (e.month_start)::timestamp with time zone)))::integer AS month,
    (COALESCE(ci.total_income, (0)::numeric))::numeric(12,2) AS total_income,
    (COALESCE(e.total, (0)::numeric))::numeric(12,2) AS total_expense,
    ((COALESCE(ci.total_income, (0)::numeric) - COALESCE(e.total, (0)::numeric)))::numeric(12,2) AS net
   FROM ((combined_income ci
     FULL JOIN expenses_m e ON (((e.society_id = ci.society_id) AND (e.month_start = ci.month_start))))
     JOIN societies s ON ((s.id = COALESCE(ci.society_id, e.society_id))))
  ORDER BY s.name, ((EXTRACT(year FROM COALESCE(ci.month_start, (e.month_start)::timestamp with time zone)))::integer), ((EXTRACT(month FROM COALESCE(ci.month_start, (e.month_start)::timestamp with time zone)))::integer);

-- 2025-08-29 13:54:30 UTC
