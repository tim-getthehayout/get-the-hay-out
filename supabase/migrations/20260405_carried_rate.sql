-- OI-0183 Fix 2: Add carried_rate column to event_feed_residual_checks
-- Stores the daily stored DMI rate from the source event when feed is transferred.
-- Used by getDailyStoredDMI() to estimate stored DMI on the destination event
-- before the first real feed check is done.
-- Run in Supabase SQL Editor BEFORE deploying the code changes.

ALTER TABLE event_feed_residual_checks
  ADD COLUMN IF NOT EXISTS carried_rate numeric;
