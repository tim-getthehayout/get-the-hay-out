-- ══════════════════════════════════════════════════════════════════════════════
-- Migration: release_notes table
-- GH-2: Release manifest with per-user feedback auto-resolve
--
-- Pre-flight check (run these first, expect no results):
--   SELECT * FROM pg_tables WHERE tablename = 'release_notes';  -- should be empty
-- ══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS release_notes (
  id              bigserial PRIMARY KEY,
  version         text NOT NULL,               -- build stamp, e.g. 'b20260409.1200'
  resolved_items  jsonb NOT NULL DEFAULT '[]', -- array of { feedbackId, oiNumber, ghIssue, note }
  notes           text,                        -- optional human-readable release notes
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE release_notes ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read release notes.
-- The app queries this table directly (anon client) to detect resolved feedback.
-- Inserts are done via the admin-submissions edge function using the service role key,
-- which bypasses RLS — so no INSERT policy for authenticated users is needed.
CREATE POLICY "release_notes_select" ON release_notes
  FOR SELECT TO authenticated USING (true);
