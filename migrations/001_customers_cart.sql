-- ═══════════════════════════════════════════════════════════
--  PRESS LINE — Migration: customers + cart + address + drop time
--  Safe to run on top of the existing schema.sql (additive only)
--  Dashboard → SQL Editor → New query → paste → Run
-- ═══════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────
--  CUSTOMERS
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS customers (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone      text UNIQUE NOT NULL,
  name       text NOT NULL,
  flat_no    text,          -- apt / flat number
  floor      text,
  area       text,          -- locality / neighbourhood (free text, distinct from the `areas` zone table)
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE customers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "customers_public_read"
  ON customers FOR SELECT USING (true);

CREATE POLICY "customers_public_insert"
  ON customers FOR INSERT WITH CHECK (true);

CREATE POLICY "customers_admin_update"
  ON customers FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "customers_admin_delete"
  ON customers FOR DELETE TO authenticated USING (true);


-- ────────────────────────────────────────────────
--  ORDERS — additive columns
-- ────────────────────────────────────────────────
ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS order_code  text,                 -- human-readable ID, e.g. PL-0001
  ADD COLUMN IF NOT EXISTS customer_id uuid REFERENCES customers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS cart        jsonb NOT NULL DEFAULT '[]'::jsonb,  -- [{ "item": "Shirt", "qty": 3 }, ...]
  ADD COLUMN IF NOT EXISTS drop_at     timestamptz;          -- scheduled_at = pickup, drop_at = delivery back

-- order_code should be unique once populated (nulls allowed for legacy rows until backfilled)
CREATE UNIQUE INDEX IF NOT EXISTS orders_order_code_key
  ON orders (order_code) WHERE order_code IS NOT NULL;

-- sequence to auto-generate order codes like PL-0001, PL-0002, ...
CREATE SEQUENCE IF NOT EXISTS orders_code_seq;

CREATE OR REPLACE FUNCTION set_order_code()
RETURNS trigger AS $$
BEGIN
  IF NEW.order_code IS NULL THEN
    NEW.order_code := 'PL-' || lpad(nextval('orders_code_seq')::text, 4, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_order_code ON orders;
CREATE TRIGGER trg_set_order_code
  BEFORE INSERT ON orders
  FOR EACH ROW EXECUTE FUNCTION set_order_code();


-- ────────────────────────────────────────────────
--  BULK IMPORT FROM WHATSAPP DATA
--  Use this pattern per batch (edit the VALUES rows, or generate
--  this INSERT programmatically from your extracted WhatsApp data)
-- ────────────────────────────────────────────────

-- Step 1: upsert customers (phone is the natural key)
-- INSERT INTO customers (phone, name, flat_no, floor, area) VALUES
--   ('9876543210', 'Ravi Kumar', 'A-12', '3rd', 'Indiranagar')
-- ON CONFLICT (phone) DO UPDATE
--   SET name = EXCLUDED.name, flat_no = EXCLUDED.flat_no,
--       floor = EXCLUDED.floor, area = EXCLUDED.area;

-- Step 2: insert the order, linking to the customer via phone lookup
-- INSERT INTO orders (customer_id, name, phone, area_id, area_name, num_clothes, rate, bill,
--                      scheduled_at, drop_at, payment_timing, payment_status, cart)
-- SELECT c.id, c.name, c.phone, a.id, a.name, 5, a.rate, a.rate * 5,
--        '2026-08-01 10:00:00+05:30', '2026-08-02 18:00:00+05:30', 'dropoff', 'incomplete',
--        '[{"item":"Shirt","qty":3},{"item":"Trouser","qty":2}]'::jsonb
-- FROM customers c, areas a
-- WHERE c.phone = '9876543210' AND a.name = 'Zone A';
