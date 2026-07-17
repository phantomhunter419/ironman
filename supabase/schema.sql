-- ═══════════════════════════════════════════════════════════
--  PRESS LINE — Supabase Database Schema
--  Run this ENTIRE file once in Supabase SQL Editor
--  (Dashboard → SQL Editor → New query → paste → Run)
-- ═══════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────
--  TABLES
-- ────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS areas (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL,
  rate       numeric(10,2) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS orders (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  phone           text NOT NULL,
  area_id         uuid REFERENCES areas(id) ON DELETE SET NULL,
  area_name       text NOT NULL,
  num_clothes     int  NOT NULL CHECK (num_clothes > 0),
  rate            numeric(10,2) NOT NULL DEFAULT 0,
  bill            numeric(10,2) NOT NULL DEFAULT 0,
  scheduled_at    timestamptz NOT NULL,
  payment_timing  text NOT NULL DEFAULT 'dropoff' CHECK (payment_timing IN ('pickup', 'dropoff')),
  status          text NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'fulfilled')),
  ironing_done_at timestamptz,
  payment_status  text NOT NULL DEFAULT 'incomplete' CHECK (payment_status IN ('incomplete', 'pending', 'completed')),
  has_screenshot  boolean NOT NULL DEFAULT false,
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Seed three default areas (edit/delete these in the app settings)
INSERT INTO areas (name, rate) VALUES
  ('Zone A', 8),
  ('Zone B', 10),
  ('Zone C', 12)
ON CONFLICT DO NOTHING;


-- ────────────────────────────────────────────────
--  ROW LEVEL SECURITY
-- ────────────────────────────────────────────────

ALTER TABLE areas  ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- areas: anyone can READ, only authenticated users (admin) can WRITE
CREATE POLICY "areas_public_read"
  ON areas FOR SELECT
  USING (true);

CREATE POLICY "areas_admin_insert"
  ON areas FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "areas_admin_update"
  ON areas FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "areas_admin_delete"
  ON areas FOR DELETE
  TO authenticated
  USING (true);

-- orders: anyone can INSERT (customers book) and SELECT (customers look up by phone in the app)
--         only authenticated (admin) can UPDATE and DELETE
CREATE POLICY "orders_public_insert"
  ON orders FOR INSERT
  WITH CHECK (true);

CREATE POLICY "orders_public_read"
  ON orders FOR SELECT
  USING (true);

CREATE POLICY "orders_admin_update"
  ON orders FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "orders_admin_delete"
  ON orders FOR DELETE
  TO authenticated
  USING (true);


-- ────────────────────────────────────────────────
--  STORAGE — screenshots bucket
--  ⚠️  You must FIRST create the bucket manually:
--       Supabase Dashboard → Storage → New bucket
--       Name: screenshots   ✅ Make it PUBLIC
--  Then run the policies below.
-- ────────────────────────────────────────────────

-- Allow anyone (customers) to upload payment screenshots
CREATE POLICY "screenshots_public_upload"
  ON storage.objects FOR INSERT
  TO anon, authenticated
  WITH CHECK (bucket_id = 'screenshots');

-- Allow admin to delete screenshots (e.g., after rejection)
CREATE POLICY "screenshots_admin_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'screenshots');

-- Allow admin to update screenshot metadata
CREATE POLICY "screenshots_admin_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'screenshots');
