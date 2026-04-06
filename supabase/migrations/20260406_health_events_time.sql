-- OI-0185 Task 1: Add time column to animal_health_events
-- Heat events store a time string locally. Run before deploying.

ALTER TABLE animal_health_events ADD COLUMN IF NOT EXISTS time text;
