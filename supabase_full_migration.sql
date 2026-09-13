-- ═══════════════════════════════════════════════════════════════════════════
-- SMART ALUMNI MANAGEMENT SYSTEM — COMPLETE CLOUD MIGRATION SCRIPT
-- Execute this entire script in your Supabase SQL Editor (Dashboard > SQL Editor)
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. TABLE: public.alumni_events
CREATE TABLE IF NOT EXISTS public.alumni_events (
  id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title            text        NOT NULL,
  category         text        NOT NULL DEFAULT 'General',
  date             text        NOT NULL,
  time             text        DEFAULT '09:00 AM',
  venue            text        NOT NULL,
  registered_count integer     NOT NULL DEFAULT 0,
  limit_count      text        DEFAULT '100',
  status           text        NOT NULL DEFAULT 'Upcoming',
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

-- 2. TABLE: public.event_registrations
CREATE TABLE IF NOT EXISTS public.event_registrations (
  id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  event_id      bigint      NOT NULL REFERENCES public.alumni_events(id) ON DELETE CASCADE,
  user_id       uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  alumni_email  text        NOT NULL,
  alumni_name   text        NOT NULL,
  registered_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT unique_user_event UNIQUE (event_id, user_id)
);

-- Trigger: auto-sync registered_count on alumni_events
CREATE OR REPLACE FUNCTION fn_sync_event_reg_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.alumni_events
      SET registered_count = registered_count + 1, updated_at = now()
      WHERE id = NEW.event_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.alumni_events
      SET registered_count = GREATEST(registered_count - 1, 0), updated_at = now()
      WHERE id = OLD.event_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_event_reg_count ON public.event_registrations;
CREATE TRIGGER trg_sync_event_reg_count
  AFTER INSERT OR DELETE ON public.event_registrations
  FOR EACH ROW
  EXECUTE FUNCTION fn_sync_event_reg_count();

-- 3. TABLE: public.batch_reunions
CREATE TABLE IF NOT EXISTS public.batch_reunions (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  batch           text        NOT NULL,
  title           text        NOT NULL,
  date            text        NOT NULL,
  venue           text        NOT NULL,
  attendees_count integer     NOT NULL DEFAULT 0,
  status          text        NOT NULL DEFAULT 'Upcoming',
  description     text,
  rsvp_list       text[]      DEFAULT '{}'::text[],
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- 4. TABLE: public.reunion_rsvps
CREATE TABLE IF NOT EXISTS public.reunion_rsvps (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  reunion_id   bigint      NOT NULL REFERENCES public.batch_reunions(id) ON DELETE CASCADE,
  user_id      uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  alumni_email text        NOT NULL,
  alumni_name  text        NOT NULL,
  status       text        NOT NULL DEFAULT 'Attending',
  created_at   timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT unique_user_reunion UNIQUE (reunion_id, user_id)
);

-- Trigger: auto-sync attendees_count on batch_reunions
CREATE OR REPLACE FUNCTION fn_sync_reunion_attendees_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.batch_reunions
      SET attendees_count = attendees_count + 1, updated_at = now()
      WHERE id = NEW.reunion_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.batch_reunions
      SET attendees_count = GREATEST(attendees_count - 1, 0), updated_at = now()
      WHERE id = OLD.reunion_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_reunion_attendees_count ON public.reunion_rsvps;
CREATE TRIGGER trg_sync_reunion_attendees_count
  AFTER INSERT OR DELETE ON public.reunion_rsvps
  FOR EACH ROW
  EXECUTE FUNCTION fn_sync_reunion_attendees_count();

-- 5. TABLE: public.newsletter_posts
CREATE TABLE IF NOT EXISTS public.newsletter_posts (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title      text        NOT NULL,
  category   text        NOT NULL DEFAULT 'Announcement',
  date       text        NOT NULL,
  author     text        NOT NULL DEFAULT 'Alumni Affairs Office',
  content    text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 6. TABLE: public.donor_campaigns
CREATE TABLE IF NOT EXISTS public.donor_campaigns (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title          text        NOT NULL,
  description    text        NOT NULL,
  current_amount numeric     NOT NULL DEFAULT 0,
  target_amount  numeric     NOT NULL DEFAULT 100000,
  deadline       text        NOT NULL,
  status         text        NOT NULL DEFAULT 'Active',
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);

-- 7. TABLE: public.donations
CREATE TABLE IF NOT EXISTS public.donations (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  campaign_id     bigint      REFERENCES public.donor_campaigns(id) ON DELETE SET NULL,
  campaign_title  text        NOT NULL,
  user_id         uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  donor_name      text        NOT NULL,
  donor_email     text        NOT NULL,
  batch           text,
  amount          numeric     NOT NULL CHECK (amount > 0),
  payment_channel text        NOT NULL DEFAULT 'GCash',
  reference_no    text        NOT NULL UNIQUE,
  message         text,
  status          text        NOT NULL DEFAULT 'Verified',
  donation_date   date        NOT NULL DEFAULT CURRENT_DATE,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Trigger: auto-increment campaign raised amount when a donation is added
CREATE OR REPLACE FUNCTION fn_sync_campaign_raised()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.donor_campaigns
      SET current_amount = current_amount + NEW.amount, updated_at = now()
      WHERE id = NEW.campaign_id OR title = NEW.campaign_title;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_campaign_raised ON public.donations;
CREATE TRIGGER trg_sync_campaign_raised
  AFTER INSERT ON public.donations
  FOR EACH ROW
  EXECUTE FUNCTION fn_sync_campaign_raised();

-- 8. TABLE: public.active_surveys
CREATE TABLE IF NOT EXISTS public.active_surveys (
  id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  title           text        NOT NULL,
  description     text        NOT NULL,
  target          text        NOT NULL DEFAULT 'All Alumni',
  questions       text        NOT NULL,
  created_at_date text        NOT NULL,
  status          text        NOT NULL DEFAULT 'Active',
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

-- 9. TABLE: public.survey_responses
CREATE TABLE IF NOT EXISTS public.survey_responses (
  id             bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  survey_id      bigint      REFERENCES public.active_surveys(id) ON DELETE SET NULL,
  survey_title   text        NOT NULL,
  user_id        uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  alumni_name    text        NOT NULL,
  alumni_email   text        NOT NULL,
  course_batch   text,
  satisfaction   text,
  relevance      text,
  employment     text,
  time_to_employ text,
  skills_used    text,
  suggestions    text,
  recommend      text,
  custom_answers jsonb       DEFAULT '[]'::jsonb,
  submitted_date text        NOT NULL,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT unique_user_survey UNIQUE (survey_id, user_id)
);

-- 10. TABLE: public.document_requests (Transcripts OTR)
CREATE TABLE IF NOT EXISTS public.document_requests (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tracking_id  text        NOT NULL UNIQUE,
  user_id      uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  alumni_name  text        NOT NULL,
  alumni_email text        NOT NULL,
  course_batch text,
  doc_type     text        NOT NULL DEFAULT 'Official Transcript of Records (OTR)',
  method       text        NOT NULL DEFAULT 'On-Campus Pickup',
  request_date text        NOT NULL,
  status       text        NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Processing', 'Ready', 'Completed', 'Rejected')),
  release_date text        DEFAULT '3-5 Business Days',
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- 11. TABLE: public.certificate_requests
CREATE TABLE IF NOT EXISTS public.certificate_requests (
  id           bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  tracking_id  text        NOT NULL UNIQUE,
  user_id      uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  alumni_name  text        NOT NULL,
  alumni_email text        NOT NULL,
  cert_type    text        NOT NULL,
  method       text        NOT NULL DEFAULT 'Digital Copy (PDF Email)',
  purpose      text        NOT NULL,
  request_date text        NOT NULL,
  status       text        NOT NULL DEFAULT 'Pending' CHECK (status IN ('Pending', 'Processing', 'Ready', 'Completed', 'Rejected')),
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- 12. TABLE: public.partner_companies
CREATE TABLE IF NOT EXISTS public.partner_companies (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name       text        NOT NULL,
  industry   text        NOT NULL,
  location   text        NOT NULL,
  contact    text,
  email      text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 13. TABLE: public.hired_alumni
CREATE TABLE IF NOT EXISTS public.hired_alumni (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  job_id     bigint      REFERENCES public.job_postings(id) ON DELETE SET NULL,
  name       text        NOT NULL,
  batch      text        NOT NULL,
  company    text        NOT NULL,
  position   text        NOT NULL,
  date_hired text        NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- 14. TABLE: public.user_read_notifications
CREATE TABLE IF NOT EXISTS public.user_read_notifications (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id    uuid        NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  notif_id   text        NOT NULL,
  read_at    timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT unique_user_read_notif UNIQUE (user_id, notif_id)
);

-- ═══════════════════════════════════════════════════════════════════════════
-- ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- ═══════════════════════════════════════════════════════════════════════════
ALTER TABLE public.alumni_events            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_registrations      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.batch_reunions           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reunion_rsvps            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.newsletter_posts         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donor_campaigns          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.donations                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.active_surveys           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.survey_responses         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_requests        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.certificate_requests     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.partner_companies        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hired_alumni             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_read_notifications  ENABLE ROW LEVEL SECURITY;

-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

-- Helper: Admin Check
-- auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'

-- ── 1. alumni_events ──
DROP POLICY IF EXISTS "events_select" ON public.alumni_events;
CREATE POLICY "events_select" ON public.alumni_events FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "events_admin_all" ON public.alumni_events;
CREATE POLICY "events_admin_all" ON public.alumni_events FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 2. event_registrations ──
DROP POLICY IF EXISTS "event_regs_select_own" ON public.event_registrations;
CREATE POLICY "event_regs_select_own" ON public.event_registrations FOR SELECT TO authenticated
USING (user_id = auth.uid() OR auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "event_regs_insert_own" ON public.event_registrations;
CREATE POLICY "event_regs_insert_own" ON public.event_registrations FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "event_regs_delete_own" ON public.event_registrations;
CREATE POLICY "event_regs_delete_own" ON public.event_registrations FOR DELETE TO authenticated
USING (user_id = auth.uid() OR auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 3. batch_reunions ──
DROP POLICY IF EXISTS "reunions_select" ON public.batch_reunions;
CREATE POLICY "reunions_select" ON public.batch_reunions FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "reunions_admin_all" ON public.batch_reunions;
CREATE POLICY "reunions_admin_all" ON public.batch_reunions FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 4. reunion_rsvps ──
DROP POLICY IF EXISTS "reunion_rsvps_select_own" ON public.reunion_rsvps;
CREATE POLICY "reunion_rsvps_select_own" ON public.reunion_rsvps FOR SELECT TO authenticated
USING (user_id = auth.uid() OR auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "reunion_rsvps_insert_own" ON public.reunion_rsvps;
CREATE POLICY "reunion_rsvps_insert_own" ON public.reunion_rsvps FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "reunion_rsvps_delete_own" ON public.reunion_rsvps;
CREATE POLICY "reunion_rsvps_delete_own" ON public.reunion_rsvps FOR DELETE TO authenticated
USING (user_id = auth.uid() OR auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 5. newsletter_posts ──
DROP POLICY IF EXISTS "news_select" ON public.newsletter_posts;
CREATE POLICY "news_select" ON public.newsletter_posts FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "news_admin_all" ON public.newsletter_posts;
CREATE POLICY "news_admin_all" ON public.newsletter_posts FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 6. donor_campaigns ──
DROP POLICY IF EXISTS "campaigns_select" ON public.donor_campaigns;
CREATE POLICY "campaigns_select" ON public.donor_campaigns FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "campaigns_admin_all" ON public.donor_campaigns;
CREATE POLICY "campaigns_admin_all" ON public.donor_campaigns FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 7. donations ──
DROP POLICY IF EXISTS "donations_select_all_leaderboard" ON public.donations;
CREATE POLICY "donations_select_all_leaderboard" ON public.donations FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "donations_insert_own" ON public.donations;
CREATE POLICY "donations_insert_own" ON public.donations FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid() OR auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "donations_admin_all" ON public.donations;
CREATE POLICY "donations_admin_all" ON public.donations FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 8. active_surveys ──
DROP POLICY IF EXISTS "surveys_select" ON public.active_surveys;
CREATE POLICY "surveys_select" ON public.active_surveys FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "surveys_admin_all" ON public.active_surveys;
CREATE POLICY "surveys_admin_all" ON public.active_surveys FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 9. survey_responses ──
DROP POLICY IF EXISTS "survey_resp_select_own_or_admin" ON public.survey_responses;
CREATE POLICY "survey_resp_select_own_or_admin" ON public.survey_responses FOR SELECT TO authenticated
USING (user_id = auth.uid() OR auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "survey_resp_insert_own" ON public.survey_responses;
CREATE POLICY "survey_resp_insert_own" ON public.survey_responses FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "survey_resp_update_own" ON public.survey_responses;
CREATE POLICY "survey_resp_update_own" ON public.survey_responses FOR UPDATE TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "survey_resp_admin_all" ON public.survey_responses;
CREATE POLICY "survey_resp_admin_all" ON public.survey_responses FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 10. document_requests ──
DROP POLICY IF EXISTS "doc_req_select_own_or_admin" ON public.document_requests;
CREATE POLICY "doc_req_select_own_or_admin" ON public.document_requests FOR SELECT TO authenticated
USING (user_id = auth.uid() OR auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "doc_req_insert_own" ON public.document_requests;
CREATE POLICY "doc_req_insert_own" ON public.document_requests FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "doc_req_admin_all" ON public.document_requests;
CREATE POLICY "doc_req_admin_all" ON public.document_requests FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 11. certificate_requests ──
DROP POLICY IF EXISTS "cert_req_select_own_or_admin" ON public.certificate_requests;
CREATE POLICY "cert_req_select_own_or_admin" ON public.certificate_requests FOR SELECT TO authenticated
USING (user_id = auth.uid() OR auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

DROP POLICY IF EXISTS "cert_req_insert_own" ON public.certificate_requests;
CREATE POLICY "cert_req_insert_own" ON public.certificate_requests FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "cert_req_admin_all" ON public.certificate_requests;
CREATE POLICY "cert_req_admin_all" ON public.certificate_requests FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 12. partner_companies ──
DROP POLICY IF EXISTS "partners_select" ON public.partner_companies;
CREATE POLICY "partners_select" ON public.partner_companies FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "partners_admin_all" ON public.partner_companies;
CREATE POLICY "partners_admin_all" ON public.partner_companies FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 13. hired_alumni ──
DROP POLICY IF EXISTS "hired_select" ON public.hired_alumni;
CREATE POLICY "hired_select" ON public.hired_alumni FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "hired_admin_all" ON public.hired_alumni;
CREATE POLICY "hired_admin_all" ON public.hired_alumni FOR ALL TO authenticated
USING (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin')
WITH CHECK (auth.jwt() ->> 'email' = 'admin@bestlink.edu.ph' OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin');

-- ── 14. user_read_notifications ──
DROP POLICY IF EXISTS "read_notif_select_own" ON public.user_read_notifications;
CREATE POLICY "read_notif_select_own" ON public.user_read_notifications FOR SELECT TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "read_notif_insert_own" ON public.user_read_notifications;
CREATE POLICY "read_notif_insert_own" ON public.user_read_notifications FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "read_notif_delete_own" ON public.user_read_notifications;
CREATE POLICY "read_notif_delete_own" ON public.user_read_notifications FOR DELETE TO authenticated
USING (user_id = auth.uid());

-- ═══════════════════════════════════════════════════════════════════════════
-- SEED SAMPLE DATA (Preserve existing IDs and defaults)
-- ═══════════════════════════════════════════════════════════════════════════

-- Events Seed
INSERT INTO public.alumni_events (id, title, category, date, time, venue, registered_count, limit_count, status)
OVERRIDING SYSTEM VALUE
VALUES
  (1, 'Grand Alumni Homecoming 2026', 'Reunion', 'December 12, 2026', '06:00 PM', 'BCP Main Campus Gymnasium', 245, '500', 'Upcoming'),
  (2, 'Career & Tech Industry Fair 2026', 'Career Fair', 'November 15, 2026', '09:00 AM', 'BCP Bulwagang Bonifacio', 120, '250', 'Upcoming'),
  (3, 'Alumni Tech Talk: AI & Cloud Computing', 'Webinar', 'October 24, 2026', '02:00 PM', 'Zoom Online / BCP AVR 1', 88, '150', 'Upcoming')
ON CONFLICT (id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('public.alumni_events', 'id'), 3, true);

-- Batch Reunions Seed
INSERT INTO public.batch_reunions (id, batch, title, date, venue, attendees_count, status, description, rsvp_list)
OVERRIDING SYSTEM VALUE
VALUES
  (1, '2024', 'Batch 2024 2-Year Grand Anniversary Gala', 'December 5, 2026', 'Novotel Manila Araneta Grand Ballroom', 142, 'Upcoming', 'Reconnect with fellow graduates, celebrate 2 years in industry, awards ceremony and networking buffet dinner.', '{}'::text[]),
  (2, '2023', 'Batch 2023 3-Year Reunion & Alumni Fellowship', 'November 20, 2026', 'BCP Bulwagang Bonifacio, Main Campus', 98, 'Upcoming', 'Catch up with batchmates, share industry stories, and hear updates on upcoming alumni scholarship projects.', '{}'::text[]),
  (3, '2022', 'Batch 2022 4th Year Milestone Homecoming', 'October 18, 2026', 'Quezon City Sports Club', 75, 'Upcoming', 'Annual milestone celebration featuring guest speakers from pioneer batch leaders and live band entertainment.', '{}'::text[])
ON CONFLICT (id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('public.batch_reunions', 'id'), 3, true);

-- Newsletter Seed
INSERT INTO public.newsletter_posts (id, title, category, date, author, content)
OVERRIDING SYSTEM VALUE
VALUES
  (1, 'Bestlink College Achieves 94.8% Graduate Employment Rate in 2025', 'Institutional News', '2026-03-01', 'Alumni Affairs Office', 'The Institutional Tracer Study confirms a record-breaking employment placement for BCP graduates across Information Technology, Business Administration, and Hospitality sectors.'),
  (2, 'Annual Grand Alumni Homecoming 2026 Official Schedule Announced', 'Events', '2026-02-20', 'Homecoming Committee', 'Join over 1,000 alumni this December 12 at the BCP Main Gymnasium. Registration passes are now open through the online portal.'),
  (3, 'BCP Partners with Top 15 IT Conglomerates for Priority Alumni Hiring', 'Partnerships', '2026-02-10', 'Career Services', 'New MOA signed with Accenture, PLDT Enterprise, and Globe Telecom offering accelerated interview lanes for BCP graduates.')
ON CONFLICT (id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('public.newsletter_posts', 'id'), 3, true);

-- Campaigns Seed
INSERT INTO public.donor_campaigns (id, title, description, current_amount, target_amount, deadline, status)
OVERRIDING SYSTEM VALUE
VALUES
  (1, 'BCP Student Financial Aid Fund 2026', 'Providing tuition assistance and digital laptops to deserving underprivileged BCP students.', 85000, 250000, 'December 31, 2026', 'Active'),
  (2, 'Library Digital Learning & Research Hub', 'Funding modern e-library workstations, scholarly subscriptions, and high-speed campus connectivity.', 62000, 150000, 'November 30, 2026', 'Active'),
  (3, 'Alumni Community Outreach & Calamity Fund', 'Supporting disaster relief missions and community outreach programs led by BCP Alumni Volunteers.', 45000, 100000, 'October 31, 2026', 'Active')
ON CONFLICT (id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('public.donor_campaigns', 'id'), 3, true);

-- Surveys Seed
INSERT INTO public.active_surveys (id, title, description, target, questions, created_at_date, status)
OVERRIDING SYSTEM VALUE
VALUES
  (1, '2026 Annual Alumni Satisfaction & Graduate Tracer Survey', 'Comprehensive evaluation of curriculum quality, faculty support, and career readiness after graduation.', 'All Alumni', E'1. How would you rate your overall satisfaction with your education at Bestlink College?\n2. How relevant are your college skills to your present job?\n3. What skills from college do you use most in your career?\n4. What services or programs should the school improve?\n5. Would you recommend Bestlink College to prospective students?', '2026-03-01', 'Active'),
  (2, 'Technology & Industry Skills Relevance Survey', 'Targeted feedback on cloud computing, software engineering, and digital tools demanded by modern tech employers.', 'BSIT, BSIS, Computer Engineering', E'1. Which programming languages, cloud platforms, or tools do you use in your daily workflow?\n2. Did your course provide sufficient practical hands-on laboratory experience?\n3. What emerging technologies (AI, Cloud, CyberSec) should be integrated into the syllabus?\n4. Are you open to conducting tech seminars or mentoring current students?', '2026-03-05', 'Active')
ON CONFLICT (id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('public.active_surveys', 'id'), 2, true);

-- Partner Companies Seed
INSERT INTO public.partner_companies (id, name, industry, location, contact, email)
OVERRIDING SYSTEM VALUE
VALUES
  (1, 'Accenture Philippines', 'IT / Software Services', 'BGC, Taguig City', 'Maria Santos (HR Lead)', 'careers@accenture.com.ph'),
  (2, 'PLDT Enterprise', 'Telecommunications', 'Makati City', 'Roberto Diaz (Talent Lead)', 'jobs@pldt.com.ph'),
  (3, 'Globe Telecom', 'Telecommunications / FinTech', 'BGC, Taguig City', 'Carla Gomez (Recruiting)', 'hr@globe.com.ph'),
  (4, 'Jollibee Foods Corporation', 'Food & Hospitality', 'Ortigas, Pasig City', 'Michael Ramos (HR)', 'careers@jollibee.com.ph'),
  (5, 'Canva Philippines', 'Technology & Design', 'BGC, Taguig City', 'Angelica Cruz (Talent)', 'jobs@canva.com')
ON CONFLICT (id) DO NOTHING;
SELECT setval(pg_get_serial_sequence('public.partner_companies', 'id'), 5, true);

-- ═══════════════════════════════════════════════════════════════════════════
-- REALTIME REPLICATION (Add all synchronized tables)
-- ═══════════════════════════════════════════════════════════════════════════
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.alumni_events;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.event_registrations;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.batch_reunions;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.reunion_rsvps;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.newsletter_posts;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.donor_campaigns;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.donations;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.active_surveys;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.survey_responses;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.document_requests;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.certificate_requests;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.partner_companies;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.hired_alumni;
  EXCEPTION WHEN OTHERS THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.user_read_notifications;
  EXCEPTION WHEN OTHERS THEN NULL; END;
END $$;
