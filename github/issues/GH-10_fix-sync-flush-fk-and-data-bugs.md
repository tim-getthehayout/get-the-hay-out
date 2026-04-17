## Title
Fix sync flush FK ordering, duplicate groups, and ai_bulls ID type mismatch

## Type
bug

## Labels
bug, area:sync, priority:high, from:design-session, ready-for-dev

## Linked Feedback
- **Feedback ID(s):** —
- **OI Number(s):** OI-0204, OI-0205, OI-0206
- **Submitter(s):** Will (Tim's son) — second user on the app, reported class duplication and sync errors

## Context

Will is using the app on a shared device and experiencing three compounding sync bugs:

1. **Flush delete ordering** — `flushToSupabase()` deletes parent records (Tier 1) before child records (Tier 2). Supabase FK constraints block every parent delete, creating 100+ errors per session that re-queue endlessly.
2. **Duplicate animal groups** — "Herd 1" and "Herd 2" each appear twice with different IDs. Memberships are split across both copies.
3. **ai_bulls ID type mismatch** — App generates string IDs like `"BULL-1776357644340"` but the Supabase `ai_bulls.id` column is `bigint`. Every bull write fails with "invalid input syntax for type bigint".

Error log from 2026-04-16 shows 143 entries, ~130 of which are the FK delete failures repeating on every flush cycle.

## Requirements

### Fix A — Reverse delete order in flush tiers (OI-0204)

- [ ] In `flushToSupabase()`, when processing deletes, flush them in **reverse tier order** (Tier 2 → Tier 1 → Tier 0) so child records are deleted before parent records
- [ ] Upsert order remains unchanged (Tier 0 → Tier 1 → Tier 2 — parents before children)
- [ ] Specifically: `animal_group_memberships` deletes must flush before `animal_groups` deletes; `animal_weight_records` deletes must flush before `animals` deletes

### Fix B — Deduplicate animal groups (OI-0205)

- [ ] Add a deduplication guard in the group save path: if a group with the same name already exists (case-insensitive) for the same operation, block the save and surface a toast/warning
- [ ] Add a one-time migration function that detects duplicate-named groups within the same operation, merges their memberships into the first (oldest) copy, re-queues the merged memberships to Supabase, and deletes the duplicate group(s)
- [ ] Migration runs in `ensureDataArrays()` or a similar startup path so it auto-cleans on next load

### Fix C — Fix ai_bulls ID generation (OI-0206)

- [ ] Change `ai_bulls` ID generation from `'BULL-'+Date.now()` to numeric `Date.now()` (matches bigint column)
- [ ] Add a migration that strips the `"BULL-"` prefix from existing bull IDs in `S.aiBulls` and re-queues them
- [ ] Verify `_aiBullRow()` shape function passes the numeric ID correctly

## Technical Notes

### Affected Areas
- **Screen(s):** All (flush runs globally)
- **Function(s):** `flushToSupabase()` (~L4251-4316), `FLUSH_TIERS` (~L4169), group save (~L14333+), bull creation (~L9975, ~L10219), `_aiBullRow()` (~L3807)
- **Supabase table(s):** `animal_groups`, `animal_group_memberships`, `animals`, `animal_weight_records`, `ai_bulls`
- **New columns needed:** None

### Fix A — Flush ordering detail

Current flush loop processes tiers 0→1→2, and within each tier does deletes-first then upserts. The problem is that tier ordering is designed for inserts (parents first), not deletes (children first).

Recommended approach: split the flush into two passes:
1. **Delete pass** — iterate tiers in reverse order (highest tier first): Tier 2 deletes, then Tier 1 deletes, then Tier 0 deletes
2. **Upsert pass** — iterate tiers in forward order (unchanged): Tier 0 upserts, then Tier 1 upserts, then Tier 2 upserts

This preserves FK integrity in both directions.

### Fix B — Group dedup detail

In the backup data:
- AG id=1776354800829 name="Herd 1" ← keep (oldest)
- AG id=1776355245460 name="Herd 1" ← duplicate, merge memberships into first, then delete
- AG id=1776354804911 name="Herd 2" ← keep (oldest)
- AG id=1776355464960 name="Herd 2" ← duplicate, merge memberships into first, then delete

Migration must:
1. Group `S.animalGroups` by lowercase name within the same operationId
2. For each duplicate set, keep the one with the lowest ID (oldest)
3. Move all `S.animalGroupMemberships` from duplicate group IDs to the kept group ID
4. Queue delete for duplicate groups, queue upsert for moved memberships
5. Remove duplicates from `S.animalGroups`

### Fix C — Bull ID detail

Two bulls in the data have string IDs: `"BULL-1776357644340"` and `"BULL-1776354067364"`. Migration:
1. For each bull in `S.aiBulls` where `id` starts with `"BULL-"`, strip the prefix and parse to number
2. Queue delete for old string ID, queue upsert with new numeric ID
3. Update any references to bull IDs elsewhere in `S` (check event data for bull references)

### CLAUDE.md Checklist
- [x] queueWrite for all mutations (migration writes + delete for dupes)
- [x] bumpSetupUpdatedAt if setup arrays change (animalGroups is a setup array)
- [ ] Backup/restore congruence check (migration must handle old backups with string bull IDs and duplicate groups)
- [ ] Syntax check before deploy

## Acceptance Criteria

1. **FK errors gone:** After deploying, run "Push all to Supabase" from Settings. Queue empties to zero with no FK constraint errors in the error log.
2. **No duplicate groups:** After migration runs, each group name appears exactly once per operation. UI shows clean group list.
3. **Bulls sync:** AI bull "Conneally" syncs to Supabase without type errors.
4. **Duplicate guard:** Attempting to create a group with a name that already exists shows an error/toast and does not create a second copy.
5. **Old backups restore cleanly:** Importing a backup that contains `"BULL-"` prefixed IDs or duplicate groups triggers the migration automatically.

## Open Questions

- **Group dedup — membership conflicts:** If both copies of "Herd 1" have the same animal as a member, the migration should deduplicate memberships (keep one, delete the other). Verify this edge case.
- **Bull ID references:** Are bull IDs referenced anywhere in event data (e.g., breeding events)? If so, those references need updating in the migration too.
