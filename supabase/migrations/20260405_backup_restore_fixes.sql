-- ============================================================================
-- OI-0181: Align manure_batches schema with JS model
-- OI-harvest_event_fields: Add operation_id for consistency + restore deletes
-- Run in Supabase SQL Editor BEFORE deploying the code changes.
-- ============================================================================

-- ── manure_batches: add columns to match JS model ───────────────────────────
-- Existing columns (source_event_id, date_collected, quantity, unit, notes)
-- are kept for backward compatibility even though the JS model doesn't use them.

ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS name text;
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS label text;
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS location_name text;
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS mode text;
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS n_lbs numeric;
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS p_lbs numeric;
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS k_lbs numeric;
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS estimated_volume_lbs numeric;
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS remaining_lbs numeric;
-- created_at may already exist; safe to run regardless
ALTER TABLE manure_batches ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();


-- ── harvest_event_fields: add operation_id ──────────────────────────────────
-- This table previously had no operation_id — only harvest_event_id FK.
-- Adding operation_id makes it consistent with all other tables and enables
-- direct deletes during backup restore without subqueries.

ALTER TABLE harvest_event_fields ADD COLUMN IF NOT EXISTS operation_id uuid;

-- Backfill from parent harvest_events table
UPDATE harvest_event_fields hef
SET operation_id = he.operation_id
FROM harvest_events he
WHERE hef.harvest_event_id = he.id
  AND hef.operation_id IS NULL;

-- Make NOT NULL after backfill (only if all rows are filled)
-- If you have orphan harvest_event_fields with no matching harvest_events,
-- this will fail — clean those up first.
-- ALTER TABLE harvest_event_fields ALTER COLUMN operation_id SET NOT NULL;


-- ── RLS: ensure manure_batches has a WITH CHECK policy ──────────────────────
-- Check existing policies first:
-- SELECT policyname, cmd, with_check FROM pg_policies
--   WHERE tablename = 'manure_batches';
-- If the ALL policy has with_check = null (same issue as forage_types),
-- recreate it:

-- DROP POLICY IF EXISTS "operation_member_access" ON manure_batches;
-- CREATE POLICY "operation_member_access"
-- ON manure_batches FOR ALL
-- TO authenticated
-- USING (operation_id = get_my_operation_id())
-- WITH CHECK (operation_id = get_my_operation_id());


-- ── RLS: harvest_event_fields needs its own policy now ──────────────────────
-- Previously relied on harvest_event_id FK. With operation_id added,
-- give it the standard policy:

-- DROP POLICY IF EXISTS "operation_member_access" ON harvest_event_fields;
-- CREATE POLICY "operation_member_access"
-- ON harvest_event_fields FOR ALL
-- TO authenticated
-- USING (operation_id = get_my_operation_id())
-- WITH CHECK (operation_id = get_my_operation_id());
