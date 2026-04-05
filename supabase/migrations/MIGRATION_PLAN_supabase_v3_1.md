# Get The Hay Out — Supabase Migration Plan
**Version:** 3.1
**Created:** b20260325.0037
**Updated:** b20260330.1913
**Status:** M6 complete. M7 (Land, Farms & Harvest) fully designed — ready to implement. M8 (Voice Field Mode) fully designed. Next: OI-0069 (rotation calendar sub-move colour), then M7 implementation.
**Managed by Claude.** Update this document at the end of every migration session.

> This document is the authoritative roadmap for migrating GTHY from
> Google Drive sync to Supabase (normalized PostgreSQL schema).
> Upload it to the Claude Project alongside SESSION_RULES.md so it is
> available at the start of every migration session.

---

## 0. How This Document Works With Session Rules

SESSION_RULES.md governs every coding session on this project and continues
to do so during migration. This document does not replace those rules — it
works alongside them. Read both at session start.

### What Changes During Migration Sessions

| Rule | Normal Sessions | Migration Sessions |
|---|---|---|
| Read SESSION_RULES.md | ✅ Always | ✅ Always |
| Read ARCHITECTURE.md | ✅ Always | ✅ Always |
| Read MIGRATION_PLAN.md | N/A | ✅ Always — read before any code |
| Deliver updated HTML | ✅ If HTML changed | ✅ If HTML changed |
| Deliver ARCHITECTURE.md | ✅ Always | ✅ Always — migration changes architecture |
| Deliver OPEN_ITEMS.md | ✅ Always | ✅ Always |
| Deliver PROJECT_CHANGELOG.md | ✅ Always | ✅ Always |
| Deliver MIGRATION_PLAN.md | N/A | ✅ Always — update progress tracker |
| Bump build stamp | ✅ Every HTML delivery | ✅ Every HTML delivery |

### When HTML Is NOT Delivered

Session M1 (Supabase project setup) produces no HTML changes — it is
pure infrastructure. In that session: deliver ARCHITECTURE.md, OPEN_ITEMS.md,
PROJECT_CHANGELOG.md, and MIGRATION_PLAN.md only. No HTML, no build stamp bump.
All other migration sessions produce HTML changes and follow normal delivery rules.

### Migration Plan Version Numbering

This document uses semantic versioning (v1.0, v1.1, v2.0).
Increment the minor version at the end of each migration session.
Increment the major version only if the plan fundamentally changes direction.
Always note the build at which the version was written.

---

## 1. Why We Are Doing This

### The Problem With Google Drive Sync

Google Drive is a file storage API designed for human document management,
not concurrent multi-device data sync. Three architectural walls cannot be
patched away:

1. **No atomic writes.** Two devices reading stale state both merge and write;
   last write wins regardless of data recency. This caused the 2026-03-25 data
   loss event where 11 feedback items, 2 treatment types, 2 todos, and 1 event
   were lost between mobile and desktop.

2. **No server-side merge.** Both devices must hold the full dataset, merge
   locally, and write the result. With large datasets this becomes slow and
   error-prone.

3. **Token expiry in PWA standalone mode.** Google OAuth requires a real
   browser context for silent refresh. PWA standalone mode cannot reliably
   refresh tokens after ~1 hour, silently cutting off sync.

Every fix applied since b20260322 has been patching around these walls.
The patches are accumulating faster than they are solving the problem.

### Why Supabase Normalized (Not Firebase or Supabase Blob)

**Firebase Firestore:** Solves sync but keeps data as a blob. Reports and
fertility queries still require loading all data to the client and computing
in JavaScript. Google lock-in continues.

**Supabase blob (single JSONB column):** Solves sync and removes Google lock-in
but keeps the same reporting ceiling. Every fertility ledger query still requires
full-dataset client-side computation. This would need to be undone when reporting
features are built.

**Supabase normalized:** Solves sync, removes lock-in, AND enables server-side
queries. The fertility ledger — per-paddock NPK balance, stored feed cost per AUD,
season-over-season productivity trend — requires joins and aggregations across
events, animals, pastures, and feed entries. These are SQL queries that run in
milliseconds on the server. They are not feasible as client-side JavaScript on a
phone with years of farm data.

The normalized migration is more work upfront. It is also the last infrastructure
work required for a very long time. Every report and dashboard feature after it
is built on a foundation that can support it.

---

## 2. Architecture: Before and After

### Before (Current)
```
Browser (mobile or desktop)
  └── localStorage['gthy']        ← S object (entire farm state as JSON)
  └── localStorage['gthy-drive']  ← Drive connection state
        ↕ Google Drive API
  Single JSON file in Google Drive ← shared between devices
```

Problems: Race conditions, token expiry, no push, last-write-wins.

### After (Target)
```
Browser (mobile or desktop)
  └── localStorage['gthy-offline-queue']  ← pending writes when offline
  └── In-memory S object                  ← populated from Supabase on load
        ↕ Supabase JS SDK (realtime + REST)
  Supabase Project
    ├── PostgreSQL (normalized tables)    ← source of truth
    ├── Supabase Auth (native email/magic link)  ← replaces Drive OAuth + Google
    ├── Row-Level Security                ← multi-farmer isolation
    └── Realtime (postgres_changes)       ← push to all connected devices
```

### The S Object During and After Migration

The S object remains the in-memory working representation throughout.
Render functions (`renderHome()`, `renderAnimalsScreen()`, etc.) read from S
and do not change. What changes:

- **Load path:** S is populated from Supabase tables at startup (not from localStorage)
- **Write path:** Mutations write to Supabase (not to localStorage as primary)
- **Sync path:** Supabase Realtime listeners update S when other devices write
- **Offline path:** localStorage holds a write queue; flushed to Supabase on reconnect

The render layer is completely insulated from the backend change.

---

## 2b. Core Architecture Decisions (Resolved b20260326.0859)

These decisions were reached through a dedicated architecture session before any
migration work began. They resolve the most consequential schema design questions
and must be treated as settled before M0 prep work starts.

---

### Decision 1: Discrete Tables Per Event Data Class

**The current model stores sub-arrays embedded inside each event record:**
`ev.groups[]`, `ev.subMoves[]`, `ev.feedEntries[]`, `ev.paddocks[]`, `ev.feedResidual`.
The attribution engine then does forensic reconstruction — scanning embedded timestamps
to infer time windows and compute NPK/DMI splits.

**The resolved model uses discrete, normalized tables per data class**, each linked
to its parent event by foreign key. Every data class has a different shape, different
write frequency, and different query pattern. Embedding them denies SQL the ability
to aggregate, filter, or join them independently.

**The discrete tables:**

| Table | Replaces | Purpose |
|---|---|---|
| `event_group_memberships` | `ev.groups[]` | One row per group-entry with `date_added`/`date_removed`; head/weight snapshot per entry |
| `event_paddock_windows` | `ev.paddocks[]` | One row per paddock activation; `date_added`/`date_removed`; `acres` at activation time |
| `event_sub_moves` | `ev.subMoves[]` | One row per excursion; full grazing fields per sub-move |
| `event_feed_deliveries` | `ev.feedEntries[]` | One row per feeding; `sub_move_id` nullable (null = anchor paddock) |
| `event_feed_residual_checks` | `ev.feedResidual` (scalar) | **Series**, not scalar — one row per residual check; enables mid-event checkpointing |
| `event_npk_deposits` | Computed at close, discarded | Stored at period boundaries; `paddock_id`, date window, N/P/K lbs |

**Why `event_feed_residual_checks` is critical:** The current `ev.feedResidual` scalar
stores only the most recent reading. A 21-day bale-grazing event may have three residual
checks. The last one overwrites the others. The checkpoint-based attribution engine
(`calcGrassDMIByWindow`) is working around this gap by using sub-move
`parentFeedCheckpointPct` as a proxy. In the normalized model, residual checks are
a proper time series — the attribution engine reads the sequence directly.

**Why `event_npk_deposits` is stored, not computed-on-read:** NPK is currently computed
at `wizCloseEvent` and the result is either displayed or lost. If inputs change
retroactively (head count edit, weight correction), there is no audit trail of what was
computed and when. Storing NPK at period boundaries means the migration script can import
real historical data rather than recomputing from potentially changed inputs. It also
makes season-over-season NPK reporting a simple `SUM GROUP BY` — no reconstruction.

---

### Decision 2: Event Periods as Derived Windows (Not a Stored Table)

An open event changes composition over time: groups join and leave, sub-moves open and
close, paddocks activate and deactivate. Each stable interval between changes is a
**period** — a window where everything is constant enough to attribute DMI and NPK cleanly.

**Two implementation options were considered:**

**Option A — Stored periods:** Every state change writes a new `event_periods` row.
Periods are the source of truth for attribution.

**Option B — Derived periods:** The `event_group_memberships`, `event_paddock_windows`,
and `event_sub_moves` tables carry the raw state-change timestamps. A SQL view or
function materializes periods by joining and windowing them on demand.

**Resolved: Option B — Derived.** This preserves the ledger architecture (state-change
records are the source of truth; derived values are computed from them) and avoids
write-time complexity. Every sub-move close or group departure would otherwise require
writing a period row in addition to its own record. Option B gets the same query power
through a well-designed view without the write dependency.

**Implementation note for M3/M4:** A `event_period_windows` SQL view will be defined
alongside the schema. It joins `event_group_memberships`, `event_paddock_windows`, and
`event_sub_moves` to produce ordered, non-overlapping windows with stable composition
snapshots. Attribution queries for NPK and DMI join against this view.

---

### Decision 3: Unified `paddock_observations` Table

**The problem:** Pasture condition data comes from two sources with different capture paths:
1. **Event open/close** — `ev.heightIn`, `ev.heightOut`, recovery min/max captured at wizard steps
2. **Pasture surveys** — `S.surveys[]` with rating, `vegHeight`, `forageCover`, recovery min/max

Currently `lastGrazingRecordForPasture()` scans events and sub-moves separately to find
the most recent condition data for a paddock. The pasture record itself carries
`pasture.recoveryMinDays` / `pasture.recoveryMaxDays` as mutable fields updated as a
side-effect of sub-move saves — a proxy for the most-recent-observation pattern.

**The resolved model:** A single `paddock_observations` table stores all paddock condition
readings regardless of source. Both event open/close heights and survey readings write rows
here. The dashboard "most recent condition" query becomes a single indexed lookup:

```sql
SELECT DISTINCT ON (paddock_id) *
FROM paddock_observations
WHERE paddock_id = ?
ORDER BY paddock_id, observed_at DESC, confidence_rank DESC
```

**`confidence_rank` for same-date tie-breaking:**

| Source | Rank | Rationale |
|---|---|---|
| `survey` | 3 | Direct measurement; highest confidence |
| `event_close` | 2 | Post-graze residual; accurate for recovery start |
| `sub_move_close` | 2 | Same as event close for sub-location |
| `event_open` | 1 | Pre-graze reading; useful for productivity trend |
| `sub_move_open` | 1 | Same as event open for sub-location |

**Why this matters for forecasting:** The recovery forecasting logic branches on `source`:
- If last record is `event_close` or `sub_move_close`: recovery clock starts from
  `observed_at`; current height is inferred by modelling regrowth forward from residual.
- If last record is `survey`: direct current measurement; no inference needed; compare
  directly against target grazing height.

The branch is necessary because the *calculation path* differs, not just the data.

**`pasture.recoveryMinDays` / `pasture.recoveryMaxDays` are derived state — not source
of truth.** These fields on the pasture record exist as a fast-lookup proxy for the most
recent observation's recovery window. They must not be treated as independently editable
fields during migration. In Supabase, they will be removed from the `pastures` table
entirely; recovery windows are always read from the most recent `paddock_observations` row.

---

---

### Decision 5: Four Additional One-to-Many Relationships Require Discrete Tables

A full audit of the data model identified four embedded sub-arrays that carry the same
problems as the event sub-arrays resolved in Decision 1: mutable snapshots instead of
immutable ledgers, no independent queryability, and state history that is silently
overwritten rather than preserved.

**The unifying principle:** Every one of these normalization decisions converts a mutable
snapshot into an immutable ledger of state changes. Nothing is overwritten — every change
is a new row, dated, attributable, and permanently traceable. This enables answering
questions years from now that have not been thought of yet, because the raw state-change
record always exists.

#### 5a. `animal_weight_records` (replaces `animal.weightHistory[]`)

Every animal carries an embedded `weightHistory[]` array of `{date, weightLbs, note}`.
This is a genuine time series — structurally identical to `event_feed_residual_checks`.
Current limitations: no query for "average weight gain per group during this grazing
event," no weight trend across a season without loading all animals, no way to know
which device recorded which weight.

**Target table:** `animal_weight_records`
- `animal_id` → FK to `animals`
- `recorded_at` → date of measurement
- `weight_lbs` → numeric
- `note` → reason for entry
- `source` → `'manual'` | `'group_update'` | `'birth'` | `'import'`

This is kept separate from `animal_health_events` — weight has different query patterns
(trend lines, gain rates per paddock event, weight-adjusted DMI) than clinical events.
Migration: `animal.weightHistory[]` entries write one row each.

#### 5b. `input_application_locations` (replaces `inputApplication.locations[]`)

Each input application record carries an embedded `locations[]` array with per-paddock
NPK allocation: `{name, pastureId, acres, nLbs, pLbs, kLbs, costShare}`. This is the
amendment side of the fertility ledger — livestock NPK is in `event_npk_deposits`,
amendment NPK belongs alongside it. Without this table, total fertility delivery per
paddock per season (livestock + amendments combined) is impossible to query cleanly.

**Target table:** `input_application_locations`
- `application_id` → FK to `input_applications`
- `pasture_id` → FK to `pastures` (nullable — some locations may not match a pasture record)
- `pasture_name` → denormalized snapshot
- `acres` → at time of application
- `n_lbs`, `p_lbs`, `k_lbs` → allocated share
- `cost_share` → dollar value allocated to this paddock

**Unified fertility query this enables:**
```sql
SELECT pasture_id, SUM(n_lbs), SUM(p_lbs), SUM(k_lbs)
FROM (
  SELECT pasture_id, n_lbs, p_lbs, k_lbs FROM event_npk_deposits
  UNION ALL
  SELECT pasture_id, n_lbs, p_lbs, k_lbs FROM input_application_locations
) all_npk
WHERE operation_id = ? AND period_start >= ?
GROUP BY pasture_id
```

This is the core fertility ledger query the app exists to support. It requires both
tables to be normalized.

#### 5c. `manure_batch_transactions` (replaces `manureBatch.events[]`)

Manure batches carry an embedded transaction log — entries of type `'input'` (additions
from confinement events) and `'application'` (drawdowns from spreading). Currently the
only way to know remaining volume is to replay this embedded array. Additionally,
`loc.accumulatingBatchId` is a mutable pointer on the pasture record — a tight coupling
that breaks when a pasture is renamed or a batch is reassigned.

**Target table:** `manure_batch_transactions`
- `batch_id` → FK to `manure_batches`
- `type` → `'input'` | `'application'`
- `date` → transaction date
- `volume_lbs` → amount moved
- `n_lbs`, `p_lbs`, `k_lbs` → NPK in this transaction
- `source_event_id` → FK to `events` (for `'input'` type — which confinement event produced this)
- `application_id` → FK to `input_applications` (for `'application'` type)
- `pasture_names` → JSONB array of destination paddocks (for `'application'` type)
- `notes`

`batch.remaining` becomes a derived value: `SUM(input volumes) - SUM(application volumes)`.
The `loc.accumulatingBatchId` coupling on the pasture record is removed — the active
batch for a location is found by querying `manure_batch_transactions` for the most recent
open `'input'` transaction linked to that location's events.

#### 5d. `animal_group_memberships` (replaces `animalGroup.animalIds[]`)

Animal groups carry a flat `animalIds[]` array. This is a many-to-many relationship —
animals move between groups, groups split. The current model records only the current
state. There is no way to know which animals were in a group during a grazing event that
closed three months ago. Without membership dates, connecting individual animal health
records to paddock events is impossible.

**Target table:** `animal_group_memberships`
- `group_id` → FK to `animal_groups`
- `animal_id` → FK to `animals`
- `date_joined` → date animal entered this group
- `date_left` → date animal left (null = still active member)
- `reason` → `'initial'` | `'split'` | `'move'` | `'import'` (optional — traceability)

Migration: current `animalIds[]` entries write as open-ended memberships
(`date_joined = null`, `date_left = null`) — current state is preserved, historical
state begins accumulating from migration date forward.

**Traceability this enables:** "What was the exact composition of this group during
this grazing event?" joins `animal_group_memberships` on `group_id` where
`date_joined <= event.date_in AND (date_left IS NULL OR date_left >= event.date_out)`.
This is the join that makes per-animal weight gain attribution to paddocks possible.

---

### Design Note: The Traceability Architecture

Taken together, Decisions 1–5 implement a consistent pattern across every domain of the app:

| Domain | State-change record | What becomes traceable |
|---|---|---|
| Grazing events | `event_group_memberships`, `event_paddock_windows` | Who was where, when, at what acreage |
| Feed delivery | `event_feed_deliveries`, `event_feed_residual_checks` | What was put out, what was consumed, per paddock per period |
| NPK — livestock | `event_npk_deposits` | Per-paddock fertility contribution per period |
| NPK — amendments | `input_application_locations` | Per-paddock amendment contribution |
| NPK — manure | `manure_batch_transactions` | Volume in, volume out, per spreading event |
| Animal weights | `animal_weight_records` | Full weight history, attributable to events |
| Group composition | `animal_group_memberships` | Who was in what group at any point in time |
| Paddock condition | `paddock_observations` | Full condition history from all sources |

No domain has a mutable scalar that silently overwrites history. Every change is a
dated row. The question "what was the state of X at time T?" is always answerable by
querying the appropriate table with a date filter.

---

### Decision 4: Feature Sequencing — What Waits for Supabase

**The core rule:** Features that require aggregation across multiple events, paddocks,
or seasons wait until after M4 (data migration complete). Features that improve data
capture and are driven by the model changes above can and should be built in M0 prep.

| Feature | Timing | Reason |
|---|---|---|
| Mid-event residual check UI (series input) | **M0 — before migration** | Captures data the current scalar loses; migration-ready from day one |
| Sub-move UI improvements | **M0 — before migration** | UI driven by existing model; no query dependency |
| Observation-driven recovery display on Pastures screen | **M0 — before migration** | Replaces the mutable `pasture.recoveryMinDays` proxy |
| `paddock_observations` as localStorage concept | **M0 — before migration** | Cleanly maps to Supabase table at M4; no data loss |
| Per-paddock NPK balance dashboard | **Post-M4** | Requires `SUM GROUP BY paddock_id` across `event_npk_deposits` |
| Season-over-season productivity trend | **Post-M4** | Requires date windowing across multiple event seasons |
| Grazing sequence forecasting ("which paddock next") | **Post-M4** | Requires `DISTINCT ON` + recovery modelling across all observations |
| Stored feed cost per AUD by period | **Post-M4** | Requires joins across `event_feed_deliveries`, `event_group_memberships`, `batches` |
| DMI split (pasture vs stored) per paddock | **Post-M4** | Requires `event_period_windows` view + checkpoint series |

**Building post-M4 features before migration would mean writing them twice** — once in
JavaScript against embedded arrays (with all the reconstruction complexity), and again
in SQL against normalized tables. The SQL version is the one that scales. Build it once.

---

## 3. Data Model: S Object → Supabase Tables

Full mapping of every array and field in the current S object.

### 3a. Top-Level Tables

| S field | Supabase table | Notes |
|---|---|---|
| `S.pastures[]` | `pastures` | `recoveryMinDays`/`recoveryMaxDays` removed — derived from `paddock_observations` |
| `S.events[]` | `events` | Core fields only — all sub-arrays split into discrete tables |
| `S.events[].groups[]` | `event_group_memberships` | One row per group-entry; head/weight snapshot; `date_added`/`date_removed` |
| `S.events[].paddocks[]` | `event_paddock_windows` | One row per paddock activation; acres at activation time; `date_added`/`date_removed` |
| `S.events[].subMoves[]` | `event_sub_moves` | All sm.* fields as proper columns |
| `S.events[].feedEntries[]` | `event_feed_deliveries` | One row per feeding; `sub_move_id` nullable (null = anchor) |
| `ev.feedResidual` (scalar) | `event_feed_residual_checks` | **Series** — one row per check; replaces single scalar |
| (computed at close, discarded) | `event_npk_deposits` | NPK stored at period boundaries; enables direct aggregation |
| `S.surveys[]` | `paddock_observations` (source=`survey`) | Unified with event height readings; `ratings[]` sub-array dissolved into individual rows |
| `ev.heightIn` / `ev.heightOut` | `paddock_observations` (source=`event_open`/`event_close`) | All paddock condition readings in one table |
| `sm.heightIn` / `sm.heightOut` | `paddock_observations` (source=`sub_move_open`/`sub_move_close`) | Sub-move grazing readings |
| `S.batches[]` | `batches` | Feed inventory |
| `S.feedTypes[]` | `feed_types` | |
| `S.animalGroups[]` | `animal_groups` | Core fields only — sub-arrays split out |
| `S.animalGroups[].animalIds[]` | `animal_group_memberships` | Many-to-many with dates; enables historical composition lookup |
| `S.animalGroups[].classes[]` | `animal_group_class_compositions` | Class-based (non-individual) composition; lower priority |
| `S.animalClasses[]` | `animal_classes` | |
| `S.animals[]` | `animals` | Core fields only — sub-arrays split out |
| `S.animals[].healthEvents[]` | `animal_health_events` | Treatments, BCS, breeding, calvings, notes |
| `S.animals[].weightHistory[]` | `animal_weight_records` | Full weight time series; separate from health events |
| `S.animals[].calvingRecords[]` | `animal_health_events` (type=`calving`) | `calving_calf_id` FK to `animals` already in schema |
| `S.treatmentTypes[]` | `treatment_types` | |
| `S.aiBulls[]` | `ai_bulls` | |
| `S.todos[]` | `todos` | |
| `S.feedback[]` | `feedback` | |
| `S.manureBatches[]` | `manure_batches` | Core fields only — `events[]` split out |
| `S.manureBatches[].events[]` | `manure_batch_transactions` | Input and application transactions; `remaining` becomes derived |
| `S.inputProducts[]` | `input_products` | |
| `S.inputApplications[]` | `input_applications` | Core fields only — `locations[]` split out |
| `S.inputApplications[].locations[]` | `input_application_locations` | Per-paddock NPK allocation; enables unified fertility query |
| `S.users[]` | `operation_members` + Supabase Auth | |
| `S.herd` | `operations` (columns) | name, type, count, weight, dmi |
| `S.settings` | `operation_settings` (JSONB) | Keep as JSONB — highly variable |
| `S.version` | `operations.schema_version` | |
| `S.testerName` | `operation_members.display_name` | |

### 3b. ID Strategy

Current IDs are JavaScript timestamps (`1774010630500`). These are kept as-is
during migration, stored as `bigint` primary keys. This means:
- Zero ID remapping in the migration script
- Existing backup files import cleanly
- New records continue using the same `Date.now()` generation pattern

UUIDs are NOT introduced. The timestamp ID pattern is simple, collision-free
for a single-operation app, and sortable by creation time. Revisit only if
multi-farmer concurrent record creation causes collisions (extremely unlikely
given the millisecond precision).

### 3c. Full Schema

> **Note (v1.8):** This schema is the corrected, run-ready version. The original §3c had
> a foreign key ordering bug (`input_applications` and `manure_batch_transactions` referenced
> `manure_batches` before it was created). This version fixes the ordering and also includes
> all M0 fields (`n_pct/p_pct/k_pct` on feed_types, `source`/`dm_lbs_deposited` on
> event_npk_deposits, `is_close_reading` on event_feed_residual_checks) and the complete
> `todos` column set. Run `gthy_schema.sql` first, then `gthy_rls.sql`.

```sql
-- ─────────────────────────────────────────────────────────────────────────────
-- GTHY Supabase Schema — Run this entire script in one shot in the SQL Editor
-- Tables are ordered so every foreign key reference is satisfied before use.
-- ─────────────────────────────────────────────────────────────────────────────


-- ── 1. OPERATIONS ─────────────────────────────────────────────────────────────

create table operations (
  id             uuid primary key default gen_random_uuid(),
  owner_id       uuid references auth.users not null,
  name           text not null default 'My Farm',
  herd_type      text,
  herd_count     int default 0,
  herd_weight    numeric default 0,
  herd_dmi       numeric default 2.5,
  schema_version text default 'v1.2',
  created_at     timestamptz default now()
);

create table operation_members (
  id            uuid primary key default gen_random_uuid(),
  operation_id  uuid references operations not null,
  user_id       uuid references auth.users not null,
  display_name  text,
  role          text default 'worker',   -- 'owner' | 'worker'
  field_mode    bool default false,
  created_at    timestamptz default now(),
  unique (operation_id, user_id)
);

create table operation_settings (
  operation_id  uuid primary key references operations,
  data          jsonb not null default '{}'
);


-- ── 2. REFERENCE / SETUP DATA ─────────────────────────────────────────────────

create table pastures (
  id                bigint primary key,   -- JS timestamp ID preserved
  operation_id      uuid references operations not null,
  name              text not null,
  type              text default 'pasture',  -- 'pasture' | 'confinement' | 'hay_storage'
  acres             numeric,
  min_days          int,
  max_days          int,
  archived          bool default false,
  setup_updated_at  timestamptz
);

create table feed_types (
  id                text primary key,     -- existing 'FT-00001' format preserved
  operation_id      uuid references operations not null,
  name              text not null,
  dm_pct            numeric default 0.9,
  cost_per_unit     numeric,
  unit              text,
  n_pct             numeric,              -- M0-J: hay analysis — N% from lab test (null = not provided)
  p_pct             numeric,              -- M0-J: hay analysis — P%
  k_pct             numeric,              -- M0-J: hay analysis — K%
  archived          bool default false,
  setup_updated_at  timestamptz
);

create table animal_classes (
  id            bigint primary key,
  operation_id  uuid references operations not null,
  name          text not null,
  species       text,
  archived      bool default false
);

create table animal_groups (
  id                bigint primary key,
  operation_id      uuid references operations not null,
  name              text not null,
  class_id          bigint references animal_classes,
  color             text,
  archived          bool default false,
  setup_updated_at  timestamptz
);

create table treatment_types (
  id            text primary key,
  operation_id  uuid references operations not null,
  name          text not null,
  category      text,
  archived      bool default false
);

create table ai_bulls (
  id            bigint primary key,
  operation_id  uuid references operations not null,
  name          text,
  breed         text,
  tag           text,
  archived      bool default false
);

create table input_products (
  id             bigint primary key,
  operation_id   uuid references operations not null,
  name           text,
  type           text,
  npk_n          numeric,
  npk_p          numeric,
  npk_k          numeric,
  cost_per_unit  numeric,
  unit           text,
  archived       bool default false
);

create table batches (
  id             bigint primary key,
  operation_id   uuid references operations not null,
  feed_type_id   text references feed_types,
  name           text,
  quantity       numeric,
  unit           text,
  dm_pct         numeric default 0.9,
  cost_per_unit  numeric,
  purchase_date  date,
  notes          text,
  updated_at     timestamptz
);


-- ── 3. ANIMALS ────────────────────────────────────────────────────────────────

create table animals (
  id                  bigint primary key,
  operation_id        uuid references operations not null,
  tag                 text,
  name                text,
  species             text,
  sex                 text,
  class_id            bigint references animal_classes,
  group_id            bigint references animal_groups,
  birth_date          date,
  weaned              bool,
  weaned_date         date,
  wean_target_date    date,
  confirmed_bred      bool default false,
  confirmed_bred_date date,
  dam_id              bigint references animals,   -- self-reference: fine in PostgreSQL
  status              text default 'active',       -- 'active' | 'culled'
  cull_date           date,
  cull_reason         text,
  notes               text,
  updated_at          timestamptz
);

create table animal_health_events (
  id                bigint primary key,
  animal_id         bigint references animals not null,
  operation_id      uuid references operations not null,
  type              text not null,  -- 'bcs'|'treatment'|'calving'|'breeding'|'heat'|'note'
  date              date,
  bcs_score         int,
  treatment_type_id text references treatment_types,
  treatment_name    text,
  treatment_dose    numeric,
  treatment_unit    text,
  treatment_batch   text,
  withdrawal_date   date,
  breeding_subtype  text,           -- 'ai' | 'bull' | 'heat'
  ai_bull_id        bigint references ai_bulls,
  bull_animal_id    bigint references animals,
  sire_name         text,
  sire_reg_num      text,
  semen_id          text,
  ai_tech           text,
  expected_calving  date,
  calving_calf_id   bigint references animals,
  calving_stillbirth bool,
  notes             text,
  recorded_at       timestamptz default now()
);

create table animal_weight_records (
  id            bigint primary key,
  animal_id     bigint references animals not null,
  operation_id  uuid references operations not null,
  recorded_at   date not null,
  weight_lbs    numeric not null,
  note          text,
  source        text,    -- 'manual' | 'group_update' | 'birth' | 'import'
  created_at    timestamptz default now()
);

create table animal_group_memberships (
  id            bigint primary key,
  group_id      bigint references animal_groups not null,
  animal_id     bigint references animals not null,
  operation_id  uuid references operations not null,
  date_joined   date,    -- null = pre-existing at migration time
  date_left     date,    -- null = still active member
  reason        text,    -- 'initial'|'split'|'move'|'import'
  unique (group_id, animal_id, date_joined)
);

create table animal_group_class_compositions (
  id              bigint primary key,
  group_id        bigint references animal_groups not null,
  class_id        bigint references animal_classes not null,
  count           int not null,
  effective_date  date,
  operation_id    uuid references operations not null
);


-- ── 4. EVENTS ─────────────────────────────────────────────────────────────────

create table events (
  id            bigint primary key,
  operation_id  uuid references operations not null,
  pasture_id    bigint references pastures,
  pasture_name  text,
  status        text default 'open',   -- 'open' | 'closed'
  date_in       date,
  date_out      date,
  time_in       text,
  time_out      text,
  no_pasture    bool default false,
  notes         text,
  updated_at    timestamptz
);

create table event_group_memberships (
  id              bigint primary key,
  event_id        bigint references events not null,
  operation_id    uuid references operations not null,
  group_id        bigint references animal_groups not null,
  group_name      text,
  head_snapshot   int,
  weight_snapshot numeric,
  date_added      date not null,
  date_removed    date    -- null = still active
);

create table event_paddock_windows (
  id            bigint primary key,
  event_id      bigint references events not null,
  operation_id  uuid references operations not null,
  pasture_id    bigint references pastures,
  pasture_name  text,
  is_primary    bool default false,
  acres         numeric,
  date_added    date not null,
  date_removed  date    -- null = still active
);

create table event_sub_moves (
  id                          bigint primary key,
  event_id                    bigint references events not null,
  operation_id                uuid references operations not null,
  pasture_id                  bigint references pastures,
  pasture_name                text,
  date_in                     date,
  time_in                     text,
  date_out                    date,
  time_out                    text,
  duration_hours              numeric,
  no_pasture                  bool default false,
  height_in                   numeric,
  height_out                  numeric,
  recovery_days_min           int,
  recovery_days_max           int,
  parent_feed_checkpoint_pct  numeric,
  notes                       text,
  updated_at                  timestamptz
);

create table event_feed_deliveries (
  id            bigint primary key,
  event_id      bigint references events not null,
  operation_id  uuid references operations not null,
  sub_move_id   bigint references event_sub_moves,  -- null = anchor paddock
  batch_id      bigint references batches,
  date          date not null,
  quantity      numeric,
  unit          text,
  dm_pct        numeric,
  dm_lbs        numeric,
  cost          numeric,
  updated_at    timestamptz
);

create table event_feed_residual_checks (
  id                  bigint primary key,
  event_id            bigint references events not null,
  sub_move_id         bigint references event_sub_moves,  -- null = anchor check
  operation_id        uuid references operations not null,
  check_date          date not null,
  residual_pct        numeric,
  bales_remaining_pct numeric,
  is_close_reading    bool default false,   -- M0-L: true = final reading at event/sub-move close
  notes               text,
  recorded_at         timestamptz default now()
);

create table event_npk_deposits (
  id              bigint primary key,
  event_id        bigint references events not null,
  operation_id    uuid references operations not null,
  pasture_id      bigint references pastures,
  pasture_name    text,
  period_start    date not null,
  period_end      date not null,
  source          text default 'livestock_excretion',  -- M0-K: 'livestock_excretion' | 'feed_residual'
  head            int,
  avg_weight_lbs  numeric,
  days            numeric,
  acres           numeric,
  n_lbs           numeric,
  p_lbs           numeric,
  k_lbs           numeric,
  npk_value       numeric,
  dm_lbs_deposited numeric,   -- M0-K: for feed_residual entries only
  recorded_at     timestamptz default now()
);


-- ── 5. PADDOCK OBSERVATIONS ───────────────────────────────────────────────────

create table paddock_observations (
  id                bigint primary key,
  operation_id      uuid references operations not null,
  pasture_id        bigint references pastures not null,
  observed_at       date not null,
  source            text not null,  -- 'event_open'|'event_close'|'sub_move_open'
                                    -- |'sub_move_close'|'survey'
  source_id         bigint,
  confidence_rank   int not null,   -- 3=survey, 2=close, 1=open
  veg_height        numeric,
  forage_cover_pct  numeric,
  forage_quality    int,
  recovery_min_days int,
  recovery_max_days int,
  notes             text,
  recorded_at       timestamptz default now()
);

create view paddock_current_condition as
select distinct on (pasture_id)
  pasture_id, observed_at, source, source_id,
  veg_height, forage_cover_pct, forage_quality,
  recovery_min_days, recovery_max_days, notes
from paddock_observations
order by pasture_id, observed_at desc, confidence_rank desc;


-- ── 6. MANURE + INPUTS ────────────────────────────────────────────────────────
-- manure_batches MUST come before input_applications (which references it)
-- and before manure_batch_transactions (which references both).

create table manure_batches (
  id               bigint primary key,
  operation_id     uuid references operations not null,
  source_event_id  bigint references events,
  date_collected   date,
  quantity         numeric,
  unit             text,
  notes            text
);

create table input_applications (
  id               bigint primary key,
  operation_id     uuid references operations not null,
  product_id       bigint references input_products,
  product_name     text,
  source_type      text,   -- 'product' | 'manure' | 'custom'
  manure_batch_id  bigint references manure_batches,  -- needs manure_batches to exist first
  date             date,
  quantity         numeric,
  unit             text,
  n_lbs_total      numeric,
  p_lbs_total      numeric,
  k_lbs_total      numeric,
  total_cost       numeric,
  notes            text
);

create table input_application_locations (
  id              bigint primary key,
  application_id  bigint references input_applications not null,
  operation_id    uuid references operations not null,
  pasture_id      bigint references pastures,
  pasture_name    text,
  acres           numeric,
  n_lbs           numeric,
  p_lbs           numeric,
  k_lbs           numeric,
  cost_share      numeric
);

create table manure_batch_transactions (
  id               bigint primary key,
  batch_id         bigint references manure_batches not null,
  operation_id     uuid references operations not null,
  type             text not null,   -- 'input' | 'application'
  date             date not null,
  volume_lbs       numeric,
  n_lbs            numeric,
  p_lbs            numeric,
  k_lbs            numeric,
  source_event_id  bigint references events,
  application_id   bigint references input_applications,
  pasture_names    jsonb,
  notes            text,
  recorded_at      timestamptz default now()
);


-- ── 7. TODOS + FEEDBACK ───────────────────────────────────────────────────────

create table todos (
  id            bigint primary key,
  operation_id  uuid references operations not null,
  title         text,
  status        text default 'open',   -- 'open' | 'in_progress' | 'closed'
  note          text,
  paddock       text,
  animal_id     bigint references animals,
  assigned_to   jsonb,                 -- array of user IDs
  created_by    uuid,
  created_at    timestamptz default now(),
  updated_at    timestamptz
);

create table feedback (
  id                    bigint primary key,
  operation_id          uuid references operations not null,
  cat                   text,   -- 'roadblock'|'bug'|'calc'|'ux'|'feature'|'idea'
  status                text default 'open',
  note                  text,
  tester                text,
  version               text,
  ts                    timestamptz,
  screen                text,
  area                  text,
  resolved_in_version   text,
  resolution_note       text,
  linked_to             bigint references feedback   -- self-ref: fine in PostgreSQL
);

```

### 3d. Row-Level Security (Multi-Farmer)

Applied to every table. Members see only their operation's data. The complete
script covers all 27 tables — run it in the Supabase SQL Editor after the schema.

```sql
-- ─────────────────────────────────────────────────────────────────────────────
-- GTHY Row-Level Security — Run AFTER the schema script
-- Enables RLS on every table and creates the member-access policy.
-- The policy: a user can only read/write rows belonging to operations
-- they are a member of.
-- ─────────────────────────────────────────────────────────────────────────────

-- Helper: the sub-select used by every policy
-- auth.uid() must appear in operation_members for that row's operation_id

-- ── OPERATIONS ────────────────────────────────────────────────────────────────
alter table operations enable row level security;
create policy "operation members" on operations
  using (id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── OPERATION MEMBERS ─────────────────────────────────────────────────────────
alter table operation_members enable row level security;
create policy "operation members" on operation_members
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── OPERATION SETTINGS ────────────────────────────────────────────────────────
alter table operation_settings enable row level security;
create policy "operation members" on operation_settings
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── PASTURES ──────────────────────────────────────────────────────────────────
alter table pastures enable row level security;
create policy "operation members" on pastures
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── FEED TYPES ────────────────────────────────────────────────────────────────
alter table feed_types enable row level security;
create policy "operation members" on feed_types
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── ANIMAL CLASSES ────────────────────────────────────────────────────────────
alter table animal_classes enable row level security;
create policy "operation members" on animal_classes
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── ANIMAL GROUPS ─────────────────────────────────────────────────────────────
alter table animal_groups enable row level security;
create policy "operation members" on animal_groups
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── TREATMENT TYPES ───────────────────────────────────────────────────────────
alter table treatment_types enable row level security;
create policy "operation members" on treatment_types
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── AI BULLS ──────────────────────────────────────────────────────────────────
alter table ai_bulls enable row level security;
create policy "operation members" on ai_bulls
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── INPUT PRODUCTS ────────────────────────────────────────────────────────────
alter table input_products enable row level security;
create policy "operation members" on input_products
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── BATCHES ───────────────────────────────────────────────────────────────────
alter table batches enable row level security;
create policy "operation members" on batches
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── ANIMALS ───────────────────────────────────────────────────────────────────
alter table animals enable row level security;
create policy "operation members" on animals
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── ANIMAL HEALTH EVENTS ──────────────────────────────────────────────────────
alter table animal_health_events enable row level security;
create policy "operation members" on animal_health_events
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── ANIMAL WEIGHT RECORDS ─────────────────────────────────────────────────────
alter table animal_weight_records enable row level security;
create policy "operation members" on animal_weight_records
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── ANIMAL GROUP MEMBERSHIPS ──────────────────────────────────────────────────
alter table animal_group_memberships enable row level security;
create policy "operation members" on animal_group_memberships
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── ANIMAL GROUP CLASS COMPOSITIONS ──────────────────────────────────────────
alter table animal_group_class_compositions enable row level security;
create policy "operation members" on animal_group_class_compositions
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── EVENTS ────────────────────────────────────────────────────────────────────
alter table events enable row level security;
create policy "operation members" on events
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── EVENT GROUP MEMBERSHIPS ───────────────────────────────────────────────────
alter table event_group_memberships enable row level security;
create policy "operation members" on event_group_memberships
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── EVENT PADDOCK WINDOWS ─────────────────────────────────────────────────────
alter table event_paddock_windows enable row level security;
create policy "operation members" on event_paddock_windows
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── EVENT SUB MOVES ───────────────────────────────────────────────────────────
alter table event_sub_moves enable row level security;
create policy "operation members" on event_sub_moves
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── EVENT FEED DELIVERIES ─────────────────────────────────────────────────────
alter table event_feed_deliveries enable row level security;
create policy "operation members" on event_feed_deliveries
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── EVENT FEED RESIDUAL CHECKS ────────────────────────────────────────────────
alter table event_feed_residual_checks enable row level security;
create policy "operation members" on event_feed_residual_checks
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── EVENT NPK DEPOSITS ────────────────────────────────────────────────────────
alter table event_npk_deposits enable row level security;
create policy "operation members" on event_npk_deposits
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── PADDOCK OBSERVATIONS ──────────────────────────────────────────────────────
alter table paddock_observations enable row level security;
create policy "operation members" on paddock_observations
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── MANURE BATCHES ────────────────────────────────────────────────────────────
alter table manure_batches enable row level security;
create policy "operation members" on manure_batches
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── INPUT APPLICATIONS ────────────────────────────────────────────────────────
alter table input_applications enable row level security;
create policy "operation members" on input_applications
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── INPUT APPLICATION LOCATIONS ───────────────────────────────────────────────
alter table input_application_locations enable row level security;
create policy "operation members" on input_application_locations
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── MANURE BATCH TRANSACTIONS ─────────────────────────────────────────────────
alter table manure_batch_transactions enable row level security;
create policy "operation members" on manure_batch_transactions
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── TODOS ─────────────────────────────────────────────────────────────────────
alter table todos enable row level security;
create policy "operation members" on todos
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

-- ── FEEDBACK ──────────────────────────────────────────────────────────────────
alter table feedback enable row level security;
create policy "operation members" on feedback
  using (operation_id in (select operation_id from operation_members where user_id = auth.uid()))
  with check (operation_id in (select operation_id from operation_members where user_id = auth.uid()));

```

This policy, repeated for each table, is the entire multi-tenancy model.
Adding a new farmer: insert into `operations` + `operation_members`.
Inviting a worker: insert into `operation_members` with their user_id.

---

## 4. Session-by-Session Plan


### Session M0 — Pre-Migration Data Model Prep (localStorage)

**Goal:** Bring the localStorage data model into alignment with the normalized
Supabase schema before any Supabase infrastructure exists. This session produces
no backend changes — it is purely HTML/JS work that makes M4 (data migration)
dramatically simpler and improves data capture quality immediately.

**Why do this before M1:** The M4 migration script reads the backup JSON and
writes rows to Supabase tables. If the backup JSON still contains scalar
`feedResidual`, embedded height arrays, and mutable `pasture.recoveryMinDays`
fields, the migration script has to implement all the reconstruction logic that
currently lives in the JS attribution engine. Doing M0 first means the backup
JSON already matches the target schema — the migration script becomes a direct
translation with no reconstruction.

**Work in Claude during the session:**

**A — `ev.feedResidualChecks[]` series (replaces `ev.feedResidual` scalar)**

Add `ev.feedResidualChecks: []` array to the data model. Each entry:
```javascript
{ id, date, residualPct, balesRemainingPct, notes }
```
UI change: The single "residual %" field at event close becomes a "Log residual
check" action available any time the event is open, plus a final entry at close.
The close wizard records the final residual as a check entry rather than writing
a scalar. Attribution functions updated to read the check series instead of the
scalar. Old `ev.feedResidual` scalar migrated to a single-entry
`feedResidualChecks[]` array on first load.

**B — `ev.npkLedger[]` entries at period boundaries**

Add `ev.npkLedger: []` array. Written by `wizCloseEvent` and at sub-move close
points. Each entry:
```javascript
{ paddockName, periodStart, periodEnd, head, avgWeight, days, acres, nLbs, pLbs, kLbs }
```
Enables the M4 migration script to import real NPK history without recomputing
from changed inputs. Does not change how NPK is displayed — the existing totals
display continues reading from computed totals.

**C — `paddock_observations` as a localStorage concept**

Add `S.paddockObservations: []` array. Every event open/close and survey write
produces an entry here in addition to wherever it currently writes. Each entry:
```javascript
{ id, pastureId, observedAt, source, sourceId, confidenceRank,
  vegHeight, forageCoverPct, forageQuality, recoveryMinDays, recoveryMaxDays, notes }
```
The `lastGrazingRecordForPasture()` function is updated to query
`S.paddockObservations` instead of scanning events and sub-moves separately.
The Pastures screen recovery display reads from this array.

**F — `animal.weightHistory[]` → `S.animalWeightRecords[]` top-level array**

Add `S.animalWeightRecords: []` as a top-level array (not embedded per-animal). Each
entry carries `animalId` as a FK reference. Migration at init reads each animal's
`weightHistory[]` and writes entries here. The per-animal `weightHistory[]` array is
retained read-only during M0 for backward compat and removed at M4.

```javascript
// Entry shape
{ id, animalId, recordedAt, weightLbs, note, source }
```

Weight lookups updated to read from `S.animalWeightRecords` filtered by `animalId`
rather than from `animal.weightHistory`.

**G — `animalGroup.animalIds[]` → `S.animalGroupMemberships[]` top-level array**

Add `S.animalGroupMemberships: []`. Migration at init reads each group's `animalIds[]`
and writes open-ended membership rows (`dateJoined: null`, `dateLeft: null`). All
split, move, and add operations write a new membership row rather than mutating
`animalIds[]`. The `animalIds[]` array is kept in sync during M0 for any code that
hasn't been updated to read memberships yet; marked as derived at M4.

**H — `S.inputApplications[].locations[]` → `S.inputApplicationLocations[]`**

Add `S.inputApplicationLocations: []`. Each input application save writes per-paddock
allocation rows here rather than embedding them in the application record. Existing
embedded `locations[]` are migrated at init. Fertility summary functions updated
to read from `S.inputApplicationLocations` filtered by `applicationId`.

**I — `S.manureBatches[].events[]` → `S.manureBatchTransactions[]`**

Add `S.manureBatchTransactions: []`. Each manure batch input or drawdown writes a row
here. `getBatchRemaining()` updated to derive remaining volume from transactions rather
than the embedded `events[]` array. `loc.accumulatingBatchId` on pasture records is
documented as derived state (same pattern as `pasture.recoveryMinDays`).

**J — `S.feedTypes[]` NPK analysis fields**

Add optional `nPct`, `pPct`, `kPct` fields to feed type records. Existing records
receive `null` values — no migration needed. Feed type edit UI gains three optional
number inputs labeled "Hay analysis — N% / P% / K%" with a note that values come
from a lab feed test. These fields are entirely optional; the feature degrades
gracefully when absent (DM deposited still recorded, NPK shows null).

**K — `ev.npkLedger[]` feed residual entries**

The `ev.npkLedger[]` entries introduced in step B now carry a `source` field:
`'livestock_excretion'` or `'feed_residual'`. Feed residual entries additionally
carry `dmLbsDeposited`. Written by `wizCloseEvent` after the livestock excretion
entries, one per paddock that received feed deliveries.

**L — `ev.feedResidualChecks[]` close-reading flag**

Each entry in the residual check series gains `isCloseReading: bool`. The
`wizCloseEvent` path sets this to `true` on the final entry it writes. Intermediate
checkpoint entries (recorded mid-event) remain `false`. The organic matter
calculation reads only the entry where `isCloseReading === true`.

**D — `pasture.recoveryMinDays` / `pasture.recoveryMaxDays` documented as derived**

These fields on the pasture record are flagged as display-only cache in
ARCHITECTURE.md. They continue to be written as a fast-lookup proxy but are
explicitly documented as not-source-of-truth. The migration script will skip
them — Supabase derives these from `paddock_observations` via the
`paddock_current_condition` view.

**E — UI refinements driven by the model changes**

Any UI work that is a direct consequence of A–I above is in scope for M0:
- Mid-event residual check UI (series input, check history display)
- Recovery display on Pastures screen reading from `paddockObservations` instead
  of `pasture.recoveryMinDays`
- Sub-move improvements that improve the quality of observation data captured
- Weight history display reading from `S.animalWeightRecords` (no visible change,
  just internal source shift)

UI work that requires Supabase query capability (dashboards, reporting, forecasting)
is explicitly out of scope for M0. See Decision 4 in §2b.

**Documents updated this session (M0):**
- ARCHITECTURE.md — data model additions: `ev.feedResidualChecks[]` (with
  `isCloseReading`), `ev.npkLedger[]` (with `source` + `dmLbsDeposited`),
  `S.paddockObservations[]`, `S.animalWeightRecords[]`,
  `S.animalGroupMemberships[]`, `S.inputApplicationLocations[]`,
  `S.manureBatchTransactions[]`; `nPct/pPct/kPct` on feed types;
  derived-state notes for `pasture.recoveryMinDays` and `loc.accumulatingBatchId`
- OPEN_ITEMS.md — mark M0 tasks complete; close any OI items resolved by these changes
- PROJECT_CHANGELOG.md — full entry for all data model changes
- MIGRATION_PLAN.md — update status to "M0 complete"

**HTML delivered:** Yes (significant data model changes — build stamp bumped)

**Rollback:** Migration at init backfills new arrays from existing data.
No data is lost; new arrays are additive.

**Risk:** `feedResidualChecks` migration at init must handle events with
`feedResidual` scalar and produce a single-entry array. Test on both open
and closed events with existing residual values before delivery.

---

### M0 Sub-Task Progress Tracker

Updated at the end of every M0 session. If M0 spans multiple sessions,
the next session reads this table first to find the resume point.

| ID | Sub-task | Status | Completed in build | Notes |
|---|---|---|---|---|
| A | `ev.feedResidualChecks[]` series — replaces scalar `ev.feedResidual` | ✅ Complete | b20260327.2332 | Written at wizCloseEvent + saveSmClose; getEffectiveFeedResidual() helper; all DMI callers updated; migrateM0aData() backfills |
| B | `ev.npkLedger[]` — NPK stored at period boundaries | ✅ Complete | b20260327.2332 | Written at wizCloseEvent from paddockNPK; migrateM0aData() backfills from totals.paddockNPK |
| C | `S.paddockObservations[]` — unified paddock condition array | ✅ Complete | b20260327.2332 | Written by 5 functions; lastGrazingRecordForPasture() queries first; migrateM0aData() backfills all events + surveys |
| D | `pasture.recoveryMinDays` documented as derived state (ARCHITECTURE only) | ✅ Complete | b20260327.2332 | Documented in ARCHITECTURE.md Data Model section |
| F | `S.animalWeightRecords[]` — top-level weight time series | ✅ Complete | b20260328.0008 | `_recordAnimalWeight()` helper; 3 live write sites updated; migrateM0aData() backfills from animal.weightHistory[] |
| G | `S.animalGroupMemberships[]` — top-level membership ledger | ✅ Complete | b20260328.0008 | `_openGroupMembership()` + `_closeGroupMembership()` helpers; 7 mutation paths updated; migrateM0aData() backfills current animalIds[] |
| H | `S.inputApplicationLocations[]` — top-level amendment locations | ✅ Complete | b20260328.0008 | saveApplyInput() writes rows; migrateM0aData() backfills from application.locations[] |
| I | `S.manureBatchTransactions[]` — top-level transaction ledger | ✅ Complete | b20260328.0008 | addToManureBatch() + saveApplyInput() + saveSpreadEvent() write rows; migrateM0aData() backfills from batch.events[] |
| J | `S.feedTypes[]` NPK analysis fields (`nPct`, `pPct`, `kPct`) | ✅ Complete | b20260328.0008 | Optional fields; Feed Types sheet gains "Hay analysis" section; badge in renderFeedTypes when set |
| K | `ev.npkLedger[]` feed residual entries — `source` field + `dmLbsDeposited` | ✅ Complete | b20260328.0008 | source:'livestock_excretion' on all entries; source:'feed_residual' + dmLbsDeposited entry at wizCloseEvent when OM>0 |
| L | `ev.feedResidualChecks[]` close-reading flag (`isCloseReading`) | ✅ Complete | b20260328.0008 | isCloseReading:true at event/sub-move close; backfill sets true (scalar = close reading) |
| E | UI refinements driven by A–I (residual check UI, recovery display, etc.) | ✅ Complete | b20260328.0140 | Forage cover slider+number (b20260328.0119). Event edit full layout rebuild: active paddocks block, inline close form with recovery/cover capture, "open next paddock" shortcut, feed checks section, anchor close sequence (b20260328.0140). |

**Resume point:** M0 fully complete. Open decisions in §6 resolved (see session notes). Next: user completes Supabase infrastructure setup, then M1 coding session.

---

### Session M1 — Foundation (Infrastructure Only, No HTML)

**Goal:** Supabase project exists, schema is deployed, auth works, connection
from the app is verified. No user-visible changes. No data moved yet.

**Work outside Claude (user does this before the session):**
1. ✅ Create a Supabase project at supabase.com (free tier) — done
2. Note the Project URL and anon public key (Settings → API in Supabase Dashboard)
3. In Supabase Dashboard → Authentication → Providers → enable **Email** provider
   (magic link / OTP — no Google Cloud Console setup required)
4. In Supabase Dashboard → SQL Editor → run the schema from §3c above
5. Set up RLS policies from §3d for all tables (see §3d for the complete SQL block)
6. Share Project URL and anon key with Claude at session start

**Work in Claude during the session:**
- Add Supabase JS SDK to HTML (CDN script tag, no build tools needed)
- Add `supabaseClient` initialization with project URL + anon key
- Add Supabase Auth sign-in flow using native email magic link (`signInWithOtp`)
- Add sign-out function; replace Drive connect UI in Settings with Supabase auth status
- Add a connection test: on Settings screen, show Supabase connection status and signed-in email
- Verify auth token flow works on both mobile PWA and desktop browser
- Verify RLS blocks cross-operation access

**Documents updated this session:**
- ARCHITECTURE.md — add Supabase section: project URL pattern, SDK version,
  auth flow, table inventory, RLS policy pattern
- OPEN_ITEMS.md — add migration tasks as OI items; mark M1 complete
- PROJECT_CHANGELOG.md — entries for SDK addition + auth stubs
- MIGRATION_PLAN.md — update status to "M1 complete", note any deviations

**HTML delivered:** Yes (minor — SDK tag + auth stubs added, build stamp bumped)

**Rollback:** Remove SDK tag and auth stubs. Drive sync unaffected — it still runs.

**Risk:** Email delivery for magic links depends on Supabase's email provider (SendGrid on free tier). Deliverability is reliable for personal use. If magic link emails don't arrive, check spam or use the Supabase Dashboard to confirm the user was created and manually set a password as a fallback.

---

### Session M2 — Load Path

**Goal:** The app loads its data from Supabase at startup instead of from
localStorage. Realtime listeners push changes from other devices instantly.
Drive sync still runs in parallel as a safety net (not yet removed).

**Work in Claude during the session:**

**A — `loadFromSupabase(operationId)`**
New async function called at app init (after auth). Queries all tables for the
operation, assembles the S object, calls `ensureDataArrays()`, calls
`renderCurrentScreen()`. Pattern:

```javascript
async function loadFromSupabase(operationId) {
  const [eventsRes, animalsRes, pasturesRes, ...] = await Promise.all([
    supabase.from('events').select('*, event_groups(*), sub_moves(*), feed_entries(*)')
            .eq('operation_id', operationId),
    supabase.from('animals').select('*, animal_health_events(*)')
            .eq('operation_id', operationId),
    supabase.from('pastures').select('*').eq('operation_id', operationId),
    // ... all other tables
  ]);
  S.events   = assembleEvents(eventsRes.data);   // re-nest sub-arrays
  S.animals  = assembleAnimals(animalsRes.data);
  S.pastures = pasturesRes.data || [];
  // ... etc
  ensureDataArrays();
  saveLocal(); // keep localStorage warm as offline cache
}
```

**B — Realtime listeners**
One `supabase.channel()` per table that matters for live UI.
On any change (INSERT, UPDATE, DELETE), re-fetch that record and merge into S.

```javascript
function subscribeRealtime(operationId) {
  supabase.channel('farm-data')
    .on('postgres_changes',
      { event: '*', schema: 'public', table: 'events',
        filter: `operation_id=eq.${operationId}` },
      payload => { mergeEventFromServer(payload); renderCurrentScreen(); }
    )
    .on('postgres_changes', { event: '*', schema: 'public', table: 'todos',
        filter: `operation_id=eq.${operationId}` },
      payload => { mergeTodoFromServer(payload); renderCurrentScreen(); }
    )
    // ... one .on() per table
    .subscribe();
}
```

**C — Fallback**
If Supabase load fails (offline), fall back to `S = JSON.parse(localStorage.getItem('gthy'))`.
Show "Offline — showing cached data" in the sync indicator.

**Documents updated this session:**
- ARCHITECTURE.md — document `loadFromSupabase`, `subscribeRealtime`,
  assembly functions, offline fallback path
- OPEN_ITEMS.md — mark M2 tasks complete; note any deviations
- PROJECT_CHANGELOG.md — full entry for load path
- MIGRATION_PLAN.md — update status to "M2 complete"

**Session M2 completion notes (b20260328.1140):**

*Deviations from plan:*
- **Identity system (Option B):** Plan described `getActiveUser()` branching to S.users[] fallback. After design discussion, chose Option B (clean break) instead — S.users[] is inert storage; getActiveUser() reads session → gthy-identity cache → guest. No S.users[] fallback. Cleaner architecture, no dual-system complexity.
- **Bootstrap design:** Plan implied a setup prompt or confirmation. Implemented as fully silent auto-bootstrap using existing S.herd data — no screen, no prompt. operation_id cached in gthy-operation-id localStorage key.
- **INITIAL_SESSION handled:** Plan said "on sign-in"; implementation also handles INITIAL_SESSION (page-load with existing session) so returning users don't need to re-sign-in to trigger the load chain.
- **Realtime strategy:** Plan described per-record merge helpers (`mergeEventFromServer` etc.). Implemented as full `loadFromSupabase()` reload on any change instead — simpler, correct, and per-record merge is logged as M5+ optimisation.
- **Assembly functions:** All five implemented (`assembleEvents`, `assembleAnimals`, `assembleGroups`, `assembleManureBatches`, `assembleInputApplications`) but are dead code until M4 due to pre-M4 guard. OI-0075 logged for verification pass during M4.
- **S.surveys:** No Supabase surveys table. Surveys kept from localStorage through M4. Will map to paddock_observations during M4 migration script.
- **Home nudge banner:** Not in original M2 plan. Added — green strip with "Sign in" button renders in `renderHome()` when _sbSession is null. Disappears on sign-in re-render.
- **Two new OI items:** OI-0074 (display name input in Settings) and OI-0075 (assembly function verification at M4).
- **OTP hotfix (b20260328.1211):** Magic link auth fails in PWA standalone mode due to Safari cross-context storage isolation. Switched to 6-digit OTP code flow (`sbSendCode` + `sbVerifyOtp`). No `emailRedirectTo` — auth completes within PWA context. Requires Supabase email template update to use `{{ .Token }}`. OI-0076 logged and closed.
- **OTP code length (b20260328.1221):** Supabase sends 8-digit codes, not 6. Input maxlength and validation updated to accept 4+ digits.
- **RLS policy fixes (b20260328.1221):** Three policy bugs blocked bootstrap. (1) `operation_members` SELECT was self-referential → infinite recursion → 500. Fixed with direct `user_id = auth.uid()` check. (2) `operation_members` had no INSERT policy. (3) `operations` had no owner-direct SELECT or INSERT policy — chained `.insert().select()` in bootstrap was blocked. All fixed via Dashboard SQL. OI-0077 logged and closed. See ARCHITECTURE Supabase section for correct policy set.
- **⚠️ MIGRATION_PLAN §3d schema RLS block is incorrect:** The template `operation_members` policy in §3d is recursive. Do not re-run it. Use the corrected policies documented in ARCHITECTURE.md instead.

**HTML delivered:** Yes (significant changes — build stamp bumped)

**Rollback:** Remove `loadFromSupabase` call from init; app reverts to
loading from localStorage as before. Drive sync unaffected.

**Risk:** Supabase cold-start latency (~200–500ms on free tier) adds to
initial load time. Mitigation: load localStorage first for instant render,
then merge Supabase data in the background and re-render.

---

### Session M3 — Write Path

**Goal:** All mutations write to Supabase. `save()` is replaced with
table-specific upserts. Drive sync is removed.

**Work in Claude during the session:**

**A — Replace `save()`**

Current `save()` calls `saveLocal()` then `driveSyncDebounced()`.
New `save()` calls `saveLocal()` (offline buffer) then `supabaseSyncDebounced()`.

```javascript
function save() {
  saveLocal();             // always — offline buffer
  supabaseSyncDebounced(); // replaces driveSyncDebounced()
}

let _supabaseTimer;
function supabaseSyncDebounced() {
  if (_supabaseTimer) clearTimeout(_supabaseTimer);
  _supabaseTimer = setTimeout(flushToSupabase, 800); // shorter than Drive's 3s
}
```

**B — `flushToSupabase()`**
Reads the offline queue from localStorage and upserts each pending change.
On success, clears the queue. On failure, leaves queue intact for retry.

```javascript
async function flushToSupabase() {
  const queue = JSON.parse(localStorage.getItem('gthy-sync-queue') || '[]');
  if (!queue.length) return;
  for (const op of queue) {
    await supabase.from(op.table).upsert(op.record, { onConflict: 'id' });
  }
  localStorage.removeItem('gthy-sync-queue');
}
```

**C — Mutation functions updated**
Every function that currently calls `save()` continues to call `save()` —
no changes at the call sites. The change is entirely inside `save()` itself
and the new sync layer.

The write queue is built by a new `queueWrite(table, record)` helper that
each mutation function calls before `save()`:

```javascript
function queueWrite(table, record) {
  const queue = JSON.parse(localStorage.getItem('gthy-sync-queue') || '[]');
  // Replace existing entry for same id, or append
  const idx = queue.findIndex(q => q.table === table && q.record.id === record.id);
  if (idx >= 0) queue[idx] = { table, record };
  else queue.push({ table, record });
  localStorage.setItem('gthy-sync-queue', JSON.stringify(queue));
}
```

**D — Drive sync removal**
All Drive sync code removed: `driveSync`, `driveSyncDebounced`,
`driveFetchFile`, `driveWriteFile`, `driveFindOrCreateFile`,
`drivePushLocal`, `onAppResume`, `maybeResumeTokenRefresh`,
`loadGISAndConnect`, `doGISConnect`, Drive state variables,
Drive connect UI in Settings, sync status indicator (repurposed
for Supabase sync state).

This removes approximately 200 lines and all Google OAuth complexity.

**Documents updated this session:**
- ARCHITECTURE.md — document new save/write path, remove Drive section entirely,
  add offline queue pattern, update sync indicator behavior
- OPEN_ITEMS.md — mark M3 tasks complete; close OI items related to Drive sync bugs
- PROJECT_CHANGELOG.md — entries for write path + Drive removal
- MIGRATION_PLAN.md — update status to "M3 complete"

**HTML delivered:** Yes (significant — Drive code removed, build stamp bumped)

**Rollback:** Restore Drive sync from backup. (After M3, Drive is the rollback
point — the app is fully on Supabase.)

**Risk:** The mutation function audit must be thorough. Grep for every
`queueWrite` call site before delivery. Missing even one means that data
type doesn't persist to Supabase.

---

### Session M4 — Data Migration

**Goal:** Existing farm data moves from the JSON backup into Supabase tables.
Both devices read from Supabase and show identical state. localStorage is
now only an offline buffer, not the source of truth.

**Work in Claude during the session:**

**A — Migration script**
A standalone Node.js script (or in-app one-time function) that:
1. Reads the backup JSON (the mobile truth backup from this project)
2. Inserts/upserts each record into the correct Supabase table
3. Handles the S object → normalized table mapping from §3a
4. Preserves all existing IDs (bigint, no remapping)
5. Sets `operation_id` on every record from the user's Supabase operation row

```javascript
// Migration script (Node.js, run once)
const { createClient } = require('@supabase/supabase-js');
const backup = require('./Mobile_gthy-backup-2026-03-25-2001.json');
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY); // service role bypasses RLS

async function migrate() {
  const opId = 'YOUR_OPERATION_UUID';

  // Pastures
  await supabase.from('pastures').upsert(
    backup.pastures.map(p => ({ ...p, id: p.id || nameToId(p.name), operation_id: opId }))
  );

  // Animals
  await supabase.from('animals').upsert(
    backup.animals.map(a => ({ ...a, operation_id: opId }))
  );

  // Events (core fields — sub-arrays handled below)
  await supabase.from('events').upsert(
    backup.events.map(ev => ({
      id: ev.id, operation_id: opId,
      pasture_name: ev.pasture, status: ev.status,
      date_in: ev.start, date_out: ev.end,
      no_pasture: ev.noPasture,
      updated_at: ev.updatedAt
    }))
  );

  // event_groups (from events[].groups[])
  const eventGroups = backup.events.flatMap(ev =>
    (ev.groups||[]).map(g => ({ ...g, event_id: ev.id, operation_id: opId }))
  );
  await supabase.from('event_groups').upsert(eventGroups);

  // sub_moves, feed_entries similarly...
  // todos, feedback, surveys...
}
```

**B — Verification**
After migration:
- Count records in each Supabase table and compare to backup JSON array lengths
- Load app on both devices and verify data matches backup
- Spot-check: open events, animal count, feed entries, feedback count

**C — Cleanup**
- Clear `localStorage['gthy']` (no longer the source of truth)
- Keep `localStorage['gthy-offline-queue']` (active offline buffer)

**Documents updated this session:**
- ARCHITECTURE.md — note data migration complete, confirm all tables populated
- OPEN_ITEMS.md — mark M4 tasks complete
- PROJECT_CHANGELOG.md — data migration entry with record counts
- MIGRATION_PLAN.md — update status to "M4 complete"; log migration record counts

**HTML delivered:** Minor (cleanup of migration UI if any, build stamp bumped)

**Rollback:** Restore from the backup JSON using the existing import function.
Migration can be re-run after fixing any schema issues (upsert is idempotent).

---

### Session M4.5 — Settings Repair ✅ Complete (b20260329.1630)

**Goal:** Close correctness gaps in the post-M4 write path discovered during a settings
page audit (b20260328.2324). Three categories of functions currently bypass Supabase
entirely and must be fixed before M5 offline queue work begins — the offline queue
assumes the write path is complete.

**Outcome:**
- A ✅ `saveSettings()` — two `queueWrite` calls added; `queueWrite` extended with `conflictKey` param for `operation_settings` (PK is `operation_id`)
- B ✅ Reset functions — Supabase FK-safe delete in both modes; offline queue cleared post-delete
- C ✅ `importDataJSON` — async, calls new `pushAllToSupabase()` when signed in
- D ⚪ Historical events import — deferred as OI-0084 (low priority, one-time path)
- E ✅ Setup XLSX import — 6 `queueWrite` calls added after `migrateSystemIds()`
- F ✅ Stale Drive labels — all 6 instances updated
- G ⚪ NPK recalc bulk — deferred as OI-0085 (low priority, manual-trigger path)

---

**A — `saveSettings()` has no `queueWrite` call** ← START HERE

**Root cause:** `saveSettings()` calls `save()`, which calls `supabaseSyncDebounced()`.
But `supabaseSyncDebounced` only flushes the write queue — and nothing was queued.
The entire `S.settings` object (NPK rates, wean targets, recovery windows, AU weight,
thresholds, home screen stats) **and** `S.herd.name` (operation name) never reach
Supabase after any save.

**Grep to confirm before touching:**
```bash
grep -n 'queueWrite' # confirm saveSettings() (~L6838) has zero queueWrite calls
```

**Fix — two queueWrite calls at the end of `saveSettings()`:**

```javascript
// At end of saveSettings(), before save():

// 1. Operation name → operations table
queueWrite('operations', {
  id: _sbOperationId,
  herd_name: S.herd.name,
  updated_at: new Date().toISOString()
});

// 2. Settings blob → operation_settings table
queueWrite('operation_settings', {
  operation_id: _sbOperationId,
  data: S.settings
});
```

Note: `operation_settings` uses `operation_id` as its primary key (not `id`), so
`queueWrite` must use `onConflict: 'operation_id'` for this table. Confirm the
`queueWrite` helper handles this or add a `conflictKey` parameter.

Also verify that `_sbToSnake` does not need to be called on the `operation_settings`
record — the `data` column is JSONB and the JS camelCase keys are intentional there.

---

**B — Reset functions call `saveLocal()` only — Supabase rows survive**

**Root cause:** Both `executeReset('events')` and `executeReset('all')` clear the
in-memory `S` object and call `saveLocal()` — but Supabase tables are untouched.
On next app load, `loadFromSupabase()` floods all the "deleted" data back.

**Fix — delete from Supabase when signed in:**

```javascript
async function executeReset() {
  if (document.getElementById('reset-confirm-input').value !== 'YES') return;
  const mode = document.getElementById('reset-confirm-btn').dataset.mode || 'all';

  // If signed in, delete from Supabase first
  if (_sbSession && _sbOperationId) {
    if (mode === 'events') {
      const eventTables = ['events', 'event_group_memberships', 'event_paddock_windows',
        'event_sub_moves', 'event_feed_deliveries', 'event_feed_residual_checks',
        'event_npk_deposits', 'todos', 'manure_batch_transactions'];
      for (const t of eventTables) {
        await supabase.from(t).delete().eq('operation_id', _sbOperationId);
      }
      // Reset batch remaining values in Supabase
      // (batches table rows are kept; remaining = qty)
    } else {
      // Full reset — delete all operation data rows
      // Tables ordered by FK dependency (children first)
      const allTables = [
        'event_npk_deposits','event_feed_residual_checks','event_feed_deliveries',
        'event_sub_moves','event_paddock_windows','event_group_memberships','events',
        'animal_health_events','animal_weight_records','animal_group_memberships',
        'animal_group_class_compositions','animals','animal_groups','animal_classes',
        'manure_batch_transactions','manure_batches','input_application_locations',
        'input_applications','input_products','paddock_observations','pastures',
        'batches','feed_types','treatment_types','ai_bulls','todos','feedback',
        'operation_settings'
        // Do NOT delete from operations or operation_members — user loses access
      ];
      for (const t of allTables) {
        await supabase.from(t).delete().eq('operation_id', _sbOperationId);
      }
    }
  }

  // Then clear local state as before
  // ... (existing local S reset code) ...
  saveLocal();
  // ...
}
```

**RLS note:** The delete queries above rely on `operation_id` FK on every table.
This is already the pattern — all RLS policies scope to `operation_id`. No new
policies needed; the signed-in user can only delete their own operation's rows.

**UX note:** Reset confirmation modal text should add: "This will also erase your
data from the cloud (Supabase). You cannot undo this." Update the warning text
strings in `openResetSheet()`.

---

**C — `importDataJSON()` (backup restore) calls `saveLocal()` only**

**Root cause:** After a successful JSON import, `importDataJSON()` calls `saveLocal()`
then shows a success toast. If signed in, nothing is written to Supabase. On next
load from another device, old Supabase data overwrites the just-restored state.

**The right behavior:** A backup restore should be treated as a full re-migration —
re-upsert all records from the imported JSON blob to Supabase, replacing whatever
was there.

**Fix — after successful import, re-push all data to Supabase:**

```javascript
// In importDataJSON(), after S = JSON.parse(...) and ensureDataArrays():
saveLocal();

if (_sbSession && _sbOperationId) {
  _importStatusEl.textContent = 'Restoring to cloud…';
  _importStatusEl.style.display = 'block';
  // Re-queue every table from S for upsert
  // Simplest path: call a new pushAllToSupabase() function that
  // iterates S arrays and queues every record, then flushes.
  await pushAllToSupabase();
  _importStatusEl.textContent = '✓ Restored & synced to cloud.';
} else {
  _importStatusEl.textContent = '✓ Restored locally. Sign in to sync to other devices.';
}
```

`pushAllToSupabase()` is a new function that:
1. Iterates every array in `S` (pastures, events, animals, etc.)
2. Calls `queueWrite(table, record)` for each row
3. Calls `flushToSupabase()` immediately (no debounce — this is explicit, not incremental)

This is essentially the M4 migration script re-run in the browser using the existing
infrastructure. It is safe to run repeatedly (upsert is idempotent).

---

**D — Historical events import — verify `queueWrite`**

Grep `importEventsFile()` (~L11518) and trace to confirm individual `queueWrite` calls
are made per imported event row. If they are not, add them following the same pattern
as `addInputProduct()`.

---

**E — Setup XLSX import — verify `queueWrite`**

Grep `importSetupFile()` (~L9186) and trace. It does bulk inserts into `S.pastures[]`,
`S.animalClasses[]`, `S.animalGroups[]`, etc. Confirm each inserted record gets a
`queueWrite` call. The individual add-functions (`addUser`, `addFeedType`, etc.) each
have `queueWrite` — but bulk import may bypass these and push directly to the arrays.
If it does, add per-record `queueWrite` calls after each push.

---

**F — Stale "Drive" UI labels**

Two places where "Drive" appears as a hardcoded string post-M3:

1. `syncSidebarSync()` (~L13532) — default label argument is `'Drive'`. Change to
   `'Supabase'` or `'Sync'`.
2. Farm users card label `"Email (for Drive sharing)"` (~L1190 HTML). Change to
   `"Email"` or `"Email address"`. The Drive-sharing context is gone.
3. Mobile sync indicator (`#sync-label`) default text in HTML (~L594): `Drive`.
   Change to `Sync`.

---

**G — NPK recalc bulk mutation has no per-row `queueWrite`**

`recalcNpkValues()` (~Settings) modifies `ev.npkValue` on multiple past events then
calls `save()`. No `queueWrite` per event. As a result, bulk NPK price recalculations
only update localStorage. Fix: after updating each event in the loop, call
`queueWrite('events', _sbToSnake({...ev, operationId: _sbOperationId}))`.
This may be deferred to post-M5 if the bulk event mutation is low-frequency — log
as OI item if not fixed in this session.

---

**Documents updated this session:**
- ARCHITECTURE.md — document `pushAllToSupabase()`, update settings write path note,
  update sync label default
- OPEN_ITEMS.md — close settings audit items; log any deferred items (G)
- PROJECT_CHANGELOG.md — settings repair entries
- MIGRATION_PLAN.md — update status to "M4.5 complete"

**HTML delivered:** Yes (saveSettings queueWrite, reset Supabase deletes,
importDataJSON Supabase push, stale labels fixed, build stamp bumped)

---

### Session M5 — Offline Queue Polish

**Goal:** The app works correctly with zero connectivity. A farmer in a field
with no signal can log feed, add a weight, close an event. When they come back
online, all pending writes flush to Supabase automatically.

**Work in Claude during the session:**

**A — Sync indicator repurposed**
Current Drive sync dot → Supabase sync dot.
States: `online-synced` (green) | `online-pending` (amber, flushing) |
`offline-queued` (grey, X items queued) | `error` (red).

**B — Connectivity detection**
```javascript
window.addEventListener('online',  () => { flushToSupabase(); setSyncStatus('pending','Syncing...'); });
window.addEventListener('offline', () => { setSyncStatus('offline', `Offline — ${queueLength()} items queued`); });
```

**C — Queue display in Settings**
Small card showing queue depth. "Flush now" button for manual trigger.
If queue has been stuck > 24 hours, show warning.

**D — Conflict resolution for offline writes**
When device comes back online and flushes, another device may have written
the same record. Resolution: last `updated_at` wins, same as the current
`mergeData()` logic. The Supabase upsert with `onConflict: 'id'` handles this
at the database level.

**Documents updated this session:**
- ARCHITECTURE.md — offline queue pattern fully documented
- OPEN_ITEMS.md — mark M5 tasks complete
- PROJECT_CHANGELOG.md — offline queue entries
- MIGRATION_PLAN.md — update status to "M5 complete"

**HTML delivered:** Yes (sync indicator + queue UI, build stamp bumped)

---

### Session M6 — User System + Multi-Farmer Foundation

**Goal:** Replace the legacy `S.users[]` local user list with a real `operation_members`
system backed by Supabase Auth. Admins can invite new users by email directly from
Settings — the invitee receives an OTP, signs in, and is automatically connected to
the farm. Roles (owner / admin / member) gate sensitive actions across the app.
A second farmer creating their own operation remains a stretch goal in this session.

---

#### M6 Design: Role Model

Three levels cover every farm operation scenario:

| Role | Who | Capabilities |
|---|---|---|
| `owner` | Creator of the operation | Everything. Cannot be removed or demoted by anyone. |
| `admin` | Trusted farm managers | All write operations + add/remove users + promote members to admin + reset data + delete/archive animals/pastures |
| `member` | Workers, vets, advisors | All day-to-day operations: log feed, move animals, record events, add surveys, view reports. Cannot add users, delete records, or reset data. |

**`isAdmin()` helper — used at every gate point:**
```javascript
function isAdmin() {
  return _sbProfile?.role === 'owner' || _sbProfile?.role === 'admin';
}
```
`_sbProfile` is the current user's `operation_members` row, already loaded during
`loadFromSupabase()`. No extra network call needed for gating.

---

#### M6 Design: Schema Changes Required

The deployed `operation_members` schema needs four ALTER statements before M6 work
begins. **Run these in the Supabase SQL Editor before the coding session:**

```sql
-- 1. user_id becomes nullable — pending invites have no user_id yet
ALTER TABLE operation_members ALTER COLUMN user_id DROP NOT NULL;

-- 2. Add invite tracking columns
ALTER TABLE operation_members ADD COLUMN IF NOT EXISTS email text;
ALTER TABLE operation_members ADD COLUMN IF NOT EXISTS invited_at timestamptz;
ALTER TABLE operation_members ADD COLUMN IF NOT EXISTS accepted_at timestamptz;

-- 3. Expand role constraint to include 'admin'
ALTER TABLE operation_members DROP CONSTRAINT IF EXISTS operation_members_role_check;
ALTER TABLE operation_members ADD CONSTRAINT operation_members_role_check
  CHECK (role IN ('owner', 'admin', 'member'));

-- 4. SECURITY DEFINER function — lets an unauthenticated invitee claim their
--    pending row despite RLS blocking direct writes to user_id = null rows
CREATE OR REPLACE FUNCTION claim_pending_invite(p_email text, p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE operation_members
  SET user_id = p_user_id, accepted_at = now()
  WHERE email = p_email AND user_id IS NULL;
END;
$$;
```

**RLS update for pending rows:** The existing `operation_members` policy gates on
`user_id = auth.uid()`. Pending rows have `user_id = null` and will be invisible to
invitees until claimed. The `SECURITY DEFINER` function above handles the claim step.
After `accepted_at` is set, normal RLS applies.

---

#### M6 Design: Invite Flow

**Admin perspective (Settings → Farm users card):**

1. Admin enters invitee email + selects role (Admin / Member) → taps "Send invite"
2. App does two things:
   - Inserts pending `operation_members` row:
     `{ operation_id, email, role, invited_at: now(), user_id: null }`
   - Calls `supabase.auth.signInWithOtp({ email: inviteeEmail })` — sends OTP to
     invitee. **This does not affect the calling admin's session.**
3. Pending user appears in the members list with a "⏳ Pending" badge
4. Admin can cancel a pending invite (deletes the pending row) before it is claimed

**New `sbInviteMember()` function:**
```javascript
async function sbInviteMember(email, role) {
  if (!isAdmin()) { alert('Admin access required'); return; }
  email = email.trim().toLowerCase();
  if (!email) return;

  // Insert pending row
  const { error: insertErr } = await _sbClient.from('operation_members').insert({
    operation_id: _sbOperationId,
    email,
    role,
    invited_at: new Date().toISOString()
    // user_id intentionally omitted — null = pending
  });
  if (insertErr) { alert('Invite failed: ' + insertErr.message); return; }

  // Send OTP to invitee (does not affect admin session)
  const { error: otpErr } = await _sbClient.auth.signInWithOtp({ email });
  if (otpErr) { alert('Could not send invite email: ' + otpErr.message); return; }

  renderOperationMembersList();
  // Show confirmation
}
```

**Invitee perspective (first time opening the app):**

1. They receive the OTP email, open the app, enter their email + 6-digit code
2. On successful OTP verification, `sbPostSignInCheck()` runs:
   ```javascript
   async function sbPostSignInCheck(user) {
     // Check for a pending invite for this email
     const { data } = await _sbClient.rpc('claim_pending_invite', {
       p_email: user.email,
       p_user_id: user.id
     });
     // claim_pending_invite sets user_id + accepted_at on the pending row
     // Then load the operation_id from the now-claimed row
     const { data: member } = await _sbClient
       .from('operation_members')
       .select('operation_id, role, display_name')
       .eq('user_id', user.id)
       .single();
     if (member) {
       _sbOperationId = member.operation_id;
       _sbProfile = member;
       sbCacheIdentity(user.email, member.display_name, member.operation_id);
       loadFromSupabase(); // load the farm
     }
   }
   ```
3. Home screen loads with full farm data. Invitee is now a connected member.

---

#### M6 Design: Remove Legacy `S.users[]` System

The local user system (`S.users[]`, `addUser()`, `renderUsersList()`, `switchToUser()`,
`activeUserId`, `getActiveUser()`) was the pre-Supabase multi-user mechanism. It is
retired in M6. Migration checklist:

- `S.users[]` → superseded by `operation_members` Supabase table
- `addUser()` → replaced by `sbInviteMember()`
- `renderUsersList()` → replaced by `renderOperationMembersList()`
- `switchToUser()` / `activeUserId` → identity is now Supabase `_sbSession.user`
- `getActiveUser()` → replaced by `_sbProfile` (the `operation_members` row)
- `S.testerName` → already migrated to `operation_members.display_name` in M3
- Farm users card HTML (Settings ~L1177–1203) → replaced with new members UI

**Backward compatibility:** During M6, existing single-user setups are unaffected.
The owner who set up the farm in M1–M4 already has an `operation_members` row with
`role = 'owner'`. `_sbProfile.role === 'owner'` → `isAdmin()` returns true → full
access as before. Nothing breaks.

---

#### M6 Design: Role Gates

Gate pattern at each action: client-side check prevents the UI action; RLS on the
server prevents the data write even if the client check were bypassed.

**Settings page:**
- Add member (send invite) → `isAdmin()` required
- Remove member → `isAdmin()` required; owner cannot be removed
- Reset events / Reset all → `isAdmin()` required
- Restore from backup → `isAdmin()` required

**Animals screen:**
- Delete / cull animal → `isAdmin()` required
- Edit animal record → `member` can do this

**Pastures screen:**
- Archive / delete pasture → `isAdmin()` required
- Edit pasture settings (acres, name) → `isAdmin()` required

**Feed / Batches:**
- Delete feed type → `isAdmin()` required
- Adjust batch quantities (daily operation) → `member` can do this

**Events:**
- Delete / void event → `isAdmin()` required
- Log feed, close event, add sub-move → `member` can do this

**Implementation pattern (same one-liner everywhere):**
```javascript
function deleteAnimal(id) {
  if (!isAdmin()) { alert('Admin access required to delete animals.'); return; }
  // ... existing delete logic
}
```

---

#### M6 Design: Settings Farm Users Card — New UI

Replace the existing "Farm users" card (~L1177–1203) with:

```
┌─ Farm users ────────────────────────────────────────┐
│ Members                                              │
│ ┌──────────────────────────────────────────────────┐ │
│ │ 🟢 Tim (you)        owner           [—]          │ │
│ │ 🟡 Jane Smith       admin           [Remove]     │ │
│ │ ⏳ bob@ranch.com    member (pending) [Cancel]    │ │
│ └──────────────────────────────────────────────────┘ │
│                                                      │
│ Invite a member               [Admin only — hidden   │
│ Email: [____________]          when role = member]   │
│ Role:  [Member ▾]                                    │
│ [Send invite]                                        │
└──────────────────────────────────────────────────────┘
```

- Owner row has no Remove button (cannot remove owner)
- Pending rows show email (not display name) + Cancel button
- Invite form is hidden entirely when `!isAdmin()`
- Current user row marked with "(you)"

---

#### M6 Sub-task A: Schema ALTERs (pre-session, manual)

Run the 4 SQL statements from the schema changes section above in Supabase SQL Editor
before starting the coding session. Verify by checking `operation_members` table
structure in Supabase Dashboard.

#### M6 Sub-task B: `isAdmin()` helper + `_sbProfile` loading

Confirm `_sbProfile` is populated from `operation_members` row during `loadFromSupabase()`
or `sbPostSignInCheck()`. Add `isAdmin()` function. Test with owner account → should
return true.

#### M6 Sub-task C: `sbInviteMember()` + `sbPostSignInCheck()`

Implement both new functions. Wire `sbPostSignInCheck()` into the OTP verification
success path (currently in `sbVerifyOtp()`).

#### M6 Sub-task D: `renderOperationMembersList()`

New render function for the farm users card. Reads `operation_members` from Supabase
(or from `S.operationMembers[]` loaded at startup). Shows pending rows with email +
Cancel, accepted rows with display name + role + Remove (admin-only).

#### M6 Sub-task E: Settings card HTML replacement

Replace Farm users card HTML (Settings ~L1177–1203) with new invite UI.
Hide invite form when `!isAdmin()`.

#### M6 Sub-task F: Role gates on natural gate points

Add `isAdmin()` checks to: delete/cull animal, archive pasture, archive/delete feed type,
reset events, reset all, restore backup, remove operation member. One line per gate.

#### M6 Sub-task G: Retire `S.users[]` system

Remove `addUser()`, `renderUsersList()` (old), `switchToUser()`, `activeUserId`,
`getActiveUser()`. Remove `S.users` from `ensureDataArrays()`. Remove legacy HTML
form fields (name/role/email/color-picker inputs). Update any remaining `getActiveUser()`
call sites to use `_sbProfile` or `_sbSession.user`.

#### M6 Sub-task H: Multi-operation support (stretch goal)

If user is a member of multiple operations: show operation picker on first load.
`generateFarmCode()` encodes `_sbOperationId` for sharing. `joinOperation(code)`
decodes and inserts member row. Can be deferred to a follow-on session if M6 is long.

---

**Documents updated this session:**
- ARCHITECTURE.md — document `isAdmin()`, `_sbProfile`, `operation_members` load path,
  invite flow, role gate pattern, remove legacy user system section
- OPEN_ITEMS.md — mark M6 tasks complete
- PROJECT_CHANGELOG.md — user system + roles entries
- MIGRATION_PLAN.md — update status to "M6 complete"

**HTML delivered:** Yes (new users card, isAdmin gates, retired S.users system,
build stamp bumped)

---

---

### Session M7 — Land, Farms & Harvest

**Status:** ⬜ Not started
**Goal:** Introduce Farm grouping for all land, add Land Use taxonomy to pasture
records, implement crop harvest events with per-field batch creation, add soil test
entry as an NPK ledger anchor, and rename the "Pastures" UI to "Fields".

**OI tracking:** OI-0111

---

#### M7 Design: All Decisions Resolved (b20260330)

Full design conversation completed. All open questions resolved before any
implementation. Summary of decisions:

| Decision | Resolution |
|---|---|
| Land use taxonomy | `pasture` / `mixed-use` / `crop` / `confinement` — additive field `landUse` on `S.pastures` |
| Harvestable land | Any field — no restriction. `landUse` is a filter/display aid, not a gate |
| NPK removal at harvest | Calculated from feed type reference values. Overridable per harvest event |
| Soil test | Dated record per field. Anchors NPK baseline (same philosophy as pasture survey anchors DM state). Most recent record wins — ledger calculates forward from it |
| Soil test units | Stored as `unit` string alongside values (`'lbs/acre'` \| `'kg/ha'` \| `'ppm'`). Default TBD pending user research — schema ready for any unit |
| Batch unit of measure | User-selected per harvest: `round-bale` / `square-small` / `square-large` / `tonne` / `kg` |
| Batch weight/DM% source | Feed type `harvestDefaults` object. Overridable per harvest event field record |
| Batch granularity | One batch per field per harvest event — full traceability for organic record-keeping |
| Organic batch ID | User-entered text field per field sub-record |
| Multi-field harvest | Supported — one harvest event, per-field sub-records (mirrors multi-paddock grazing). Proration by acres where needed |
| Farm grouping | All land belongs to a Farm. Auto-create "Home Farm" on migration. Fully editable — no special-case in code |
| Farm record fields | `name`, `address`, `notes`, `createdAt` |
| Existing pasture migration | All assigned to auto-created "Home Farm" |
| Nav tab rename | "Pastures" → "Fields" (UI labels only — `S.pastures` JS variable name unchanged) |
| Filter UI | Chips: All / Pasture / Mixed-Use / Crop / Confinement |
| Fields view grouping | Grouped by Farm (collapsible section headers) |
| Harvest entry point | Button on Fields screen + future field mode shortcut |
| JS variable rename | None — `S.pastures` stays as internal alias throughout |
| Supabase scope | 4 new tables: `farms`, `soil_tests`, `harvest_events`, `harvest_event_fields` |

---

#### M7 Data Model

**New collection: `S.farms[]`**
```javascript
{
  id,        // timestamp bigint (existing pattern)
  name,      // string — e.g. "Home Farm"
  address,   // string (optional)
  notes,     // string (optional)
  createdAt  // ISO string
}
```

**`S.pastures[]` additions** (additive — no removals)
```javascript
farmId,   // string FK → S.farms[].id
landUse,  // 'pasture' | 'mixed-use' | 'crop' | 'confinement'
```
Migration: all existing records get `landUse: 'pasture'` (or `'confinement'` where
`locationType === 'confinement'`) and `farmId` of the auto-created Home Farm id.
`locationType` is NOT removed — existing codebase uses it everywhere. `landUse` is
additive and will supersede it over time without a big-bang rename.

**New collection: `S.soilTests[]`**
```javascript
{
  id, landId, date,
  n, p, k,          // numeric — NPK values
  unit,             // 'lbs/acre' | 'kg/ha' | 'ppm'
  pH,               // numeric (optional)
  organicMatter,    // numeric % (optional)
  lab,              // string — lab name (optional)
  notes,            // string (optional)
  createdAt
}
```
Ledger behaviour: most recent soil test for a field anchors the NPK baseline.
Subsequent grazing deposits, harvest withdrawals, amendments, and manure spreads
accumulate forward from that point. Replayed at query time — nothing stored.

**New collection: `S.harvestEvents[]`**
```javascript
{
  id, date,
  notes,     // event-level notes
  createdAt,
  fields: [
    {
      landId,
      landName,
      acres,
      feedTypeId,
      batchUnit,        // 'round-bale' | 'square-small' | 'square-large' | 'tonne' | 'kg'
      quantity,         // number of units harvested
      weightPerUnitKg,  // overridden from feedType.harvestDefaults if user changes it
      dmPct,            // overridden from feedType.harvestDefaults if user changes it
      nPerTonneDM,      // kg N removed per tonne DM (ref values from feedType)
      pPerTonneDM,
      kPerTonneDM,
      batchId,          // user-entered organic batch ID (optional)
      notes             // per-field notes (optional)
    }
  ]
}
```
Saving a harvest event auto-creates one `S.batches[]` entry per field sub-record.
Each batch carries `sourceHarvestEventId` and `sourceFieldId` for full nutrient
tracing: removed from Field A → batch created → fed at Paddock B → NPK deposited at B.

**Mass balance approach:** The ledger does not attempt to track specific nutrients
from source field to destination field. Instead it uses standard mass balance — NPK
withdrawal is recorded at the harvest field using feed type reference values; NPK
deposit is recorded at the feeding location using the same batch nutritional values
(identical to how purchased feed is handled today). The `sourceFieldId` on the batch
exists for organic record-keeping traceability only, not for any special ledger
arithmetic. This is close enough for fertility accounting purposes and keeps the
model consistent with the rest of the system.

**`S.feedTypes[]` addition** — `harvestDefaults` object (optional, only on forage types)
```javascript
harvestDefaults: {
  weightPerUnitKg,  // kg per bale (or per unit for tonne/kg)
  dmPct,            // dry matter %
  nPerTonneDM,      // kg N removed per tonne DM (from research reference values)
  pPerTonneDM,
  kPerTonneDM
}
```

---

#### M7 Unified Removal Ledger (per field)

Machine harvest is the first withdrawal-type transaction in the ledger. The full
ledger per field now reads:

```
[Soil test anchor]   ← most recent resets NPK baseline to known value
    ↓
[Grazing event]      → DM withdrawal (cow mouth) + NPK deposit (manure return, net +)
[Harvest event]      → DM withdrawal (machine)   + NPK withdrawal (crop removes nutrients)
[Amendment/manure]   → NPK deposit
[Bale graze]         → NPK deposit
    ↓
[Derived balance]    ← replayed at query time from most recent soil test anchor forward
```

Harvest is the sibling of a grazing event in the unified removal ledger. The
symmetry is intentional: both are DM removal events; only the NPK vector differs
(grazing = net deposit via manure return; harvest = net withdrawal).

---

#### M7 Supabase Schema (4 new tables + 2 ALTERs)

Run in Supabase SQL Editor before the coding session:

```sql
-- 1. Farms table
CREATE TABLE farms (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_id    uuid NOT NULL REFERENCES operations(id) ON DELETE CASCADE,
  name            text NOT NULL,
  address         text,
  notes           text,
  created_at      timestamptz DEFAULT now()
);
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "operation_member_access" ON farms
  USING (operation_id = (SELECT operation_id FROM operation_members
                          WHERE user_id = auth.uid() LIMIT 1));

-- 2. Add farm_id and land_use to pastures
ALTER TABLE pastures ADD COLUMN farm_id uuid REFERENCES farms(id);
ALTER TABLE pastures ADD COLUMN land_use text DEFAULT 'pasture';

-- 3. Soil tests table
CREATE TABLE soil_tests (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_id    uuid NOT NULL REFERENCES operations(id) ON DELETE CASCADE,
  land_id         uuid NOT NULL REFERENCES pastures(id) ON DELETE CASCADE,
  date            date NOT NULL,
  n               numeric,
  p               numeric,
  k               numeric,
  unit            text DEFAULT 'lbs/acre',
  ph              numeric,
  organic_matter  numeric,
  lab             text,
  notes           text,
  created_at      timestamptz DEFAULT now()
);
ALTER TABLE soil_tests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "operation_member_access" ON soil_tests
  USING (operation_id = (SELECT operation_id FROM operation_members
                          WHERE user_id = auth.uid() LIMIT 1));

-- 4. Harvest events table
CREATE TABLE harvest_events (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  operation_id    uuid NOT NULL REFERENCES operations(id) ON DELETE CASCADE,
  date            date NOT NULL,
  notes           text,
  created_at      timestamptz DEFAULT now()
);
ALTER TABLE harvest_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "operation_member_access" ON harvest_events
  USING (operation_id = (SELECT operation_id FROM operation_members
                          WHERE user_id = auth.uid() LIMIT 1));

-- 5. Harvest event fields (per-field sub-records)
CREATE TABLE harvest_event_fields (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  harvest_event_id    uuid NOT NULL REFERENCES harvest_events(id) ON DELETE CASCADE,
  land_id             uuid REFERENCES pastures(id),
  land_name           text,
  acres               numeric,
  feed_type_id        uuid REFERENCES feed_types(id),
  batch_unit          text,
  quantity            numeric,
  weight_per_unit_kg  numeric,
  dm_pct              numeric,
  n_per_tonne_dm      numeric,
  p_per_tonne_dm      numeric,
  k_per_tonne_dm      numeric,
  batch_id            text,
  notes               text
);
-- No separate RLS needed — access controlled via harvest_events parent
```

**Migration note:** After creating the `farms` table, run a one-time script to:
1. Insert one `farms` row `{ name: 'Home Farm', operation_id: <opId> }`
2. `UPDATE pastures SET farm_id = <homefarmId>` for all rows in the operation
3. `UPDATE pastures SET land_use = 'confinement' WHERE type = 'confinement'`
4. `UPDATE pastures SET land_use = 'pasture' WHERE land_use IS NULL`

---

#### M7 UI Changes

**Nav rename:** All UI labels reading "Pastures" → "Fields". `S.pastures` JS variable
and all function names using `pasture`/`Pasture` are unchanged.

**Fields screen (`renderPastures()` → still `renderPastures()` internally):**
- Filter chips row: `All` · `Pasture` · `Mixed-Use` · `Crop` · `Confinement`
- Grouped by Farm — collapsible section headers with farm name
- Each field card gains: `landUse` badge, farm name sub-label
- "Add Field" sheet gains: Farm selector (required) + Land Use selector (required, default `pasture`)
- "Harvest" button in the screen header (admin only via `isAdmin()`)

**Harvest event sheet (new):**
- Step 1 — Date + event-level notes
- Step 2 — Add field records: field picker (all non-archived pastures), feed type,
  bale unit, quantity; defaults populate from `feedType.harvestDefaults`; all
  numeric defaults overridable inline
- Per-field: organic batch ID (optional), per-field notes (optional)
- Save: writes `S.harvestEvents[]` entry + auto-creates one `S.batches[]` per field
- Supabase: `queueWrite('harvest_events', ...)` + `queueWrite('harvest_event_fields', ...)`
  per field row + `queueWrite('batches', ...)` per generated batch

**Feed type sheet additions:**
- New "Harvest defaults" expandable section (only shown for non-confinement feed types)
- Fields: weight per unit (kg), DM%, N/P/K removal per tonne DM

**Soil test entry (new sheet, accessed from field card):**
- Date, N, P, K, unit selector, pH, organic matter %, lab name, notes
- Saves to `S.soilTests[]` + queues write to `soil_tests` table
- Field card shows "Last tested: [date]" and most recent N/P/K values

---

#### M7 Sub-tasks

**Pre-session (manual SQL):** Run the 5 SQL blocks above in Supabase SQL Editor.
Run migration script for Home Farm assignment.

**A — `S.farms[]` + Farm management UI**
Add `S.farms` to `ensureDataArrays()`. Add `_farmRow()` shape function.
Add Farm to Settings screen (add/edit/delete, same pattern as feed types).
Wire `queueWrite('farms', _farmRow(f, opId))` on save.
Load farms in `loadFromSupabase()` and assemble into `S.farms[]`.

**B — `S.pastures[]` `farmId` + `landUse` fields**
Add `farmId` and `landUse` to `_pastureRow()`. Update `openAddLocationSheet()` and
edit sheet to include Farm selector and Land Use selector.
Migration guard: in `ensureDataArrays()` or assembly, default `landUse` to
`'confinement'` where `locationType === 'confinement'`, else `'pasture'`.

**C — Fields screen UI updates**
Rename all visible "Pastures" labels to "Fields" (nav, screen header, empty state,
add button). Add filter chips. Add Farm section grouping to `renderPastures()`.
Add `landUse` badge to field card. Add "Harvest" button (admin-gated).

**D — Soil test sheet + ledger integration**
New `openSoilTestSheet(landId)` / `saveSoilTest()` functions.
Add `S.soilTests` to `ensureDataArrays()` and `_soilTestRow()` shape function.
Update NPK ledger engine to use most-recent soil test as baseline anchor when
replaying from `S.soilTests[]`.

**E — Feed type harvest defaults**
Add `harvestDefaults` object to feed type data model.
Add "Harvest defaults" section to feed type add/edit sheet.
Populate with research reference values for common forage types (grass hay, mixed
hay, alfalfa) — documented in the sheet as editable defaults.

**F — Harvest event sheet + batch auto-creation**
New `openHarvestSheet()` / `saveHarvestEvent()` functions.
Multi-field entry (add/remove rows). Defaults from `feedType.harvestDefaults`.
On save: write `S.harvestEvents[]` entry, auto-create one `S.batches[]` per field
with `sourceHarvestEventId` + `sourceFieldId` set, queue all writes to Supabase.

**G — Document updates**
- ARCHITECTURE.md — new sections: Farms, Soil Tests, Harvest Events, Unified
  Removal Ledger; update Screen Map (Fields tab rename); update `_pastureRow` note
- OPEN_ITEMS.md — mark M7 sub-tasks complete; close OI-0111
- PROJECT_CHANGELOG.md — Land/Farms/Harvest entries
- MIGRATION_PLAN.md — update status to "M7 complete"

**HTML delivered:** Yes (all UI changes + new sheets + field type additions)

---

**Documents updated this session:**
- ARCHITECTURE.md — Farms, Soil Tests, Harvest Events data model; Fields screen
  rename; Unified Removal Ledger pattern
- OPEN_ITEMS.md — OI-0111 added (M7 tracking)
- PROJECT_CHANGELOG.md — M7 design session entry
- MIGRATION_PLAN.md — M7 phase block added; status tracker updated

---

### Session Post-M4 — Dashboard, Reporting, and Forecasting

**Goal:** Build the analytics features that are the whole reason the normalized
schema was built. These sessions are not numbered because their scope and
sequence will be clearer once M4 is complete and real query patterns are known.
They are listed here to document what is explicitly deferred from M0.

**Features in scope for post-M4 sessions:**

**Per-paddock NPK balance dashboard**
```sql
SELECT pasture_name, SUM(n_lbs), SUM(p_lbs), SUM(k_lbs), SUM(npk_value)
FROM event_npk_deposits
WHERE operation_id = ? AND period_start >= ?
GROUP BY pasture_name
ORDER BY SUM(npk_value) DESC
```

**Season-over-season productivity trend**
```sql
SELECT pasture_id, date_trunc('year', period_start) as season,
       SUM(n_lbs + p_lbs + k_lbs) as total_npk,
       COUNT(DISTINCT event_id) as graze_events
FROM event_npk_deposits
WHERE operation_id = ?
GROUP BY pasture_id, season
```

**Stored feed cost per AUD by event**
```sql
SELECT e.id, SUM(d.cost) / (SUM(m.head_snapshot * date_diff) / au_weight) as cost_per_aud
FROM events e
JOIN event_feed_deliveries d ON d.event_id = e.id
JOIN event_group_memberships m ON m.event_id = e.id
WHERE e.operation_id = ?
GROUP BY e.id
```

**Grazing sequence forecasting — which paddock next**
```sql
SELECT p.id, p.name, c.observed_at, c.recovery_min_days, c.veg_height,
       NOW()::date - c.observed_at as days_since_observation
FROM pastures p
JOIN paddock_current_condition c ON c.pasture_id = p.id
WHERE p.operation_id = ? AND p.type = 'pasture' AND NOT p.archived
ORDER BY (c.recovery_min_days - (NOW()::date - c.observed_at)) ASC
```

**The discipline:** No JavaScript reimplementation of these queries before M4.
The JavaScript versions would be approximations that diverge from the SQL
versions and require maintenance on two paths.

---

## 5. Document Production Reference

How the five project documents interact during migration.

```
Every migration session start:
  1. Read SESSION_RULES.md
  2. Read MIGRATION_PLAN.md  ← NEW during migration
  3. Read ARCHITECTURE.md
  4. Read OPEN_ITEMS.md (surface migration tasks in the session's area)

Every migration session end:
  1. Write PROJECT_CHANGELOG.md first (write-first rule)
  2. Bump HTML build stamp (if HTML changed)
  3. Update ARCHITECTURE.md (new section: Supabase; update existing)
  4. Update OPEN_ITEMS.md (mark migration tasks complete / add new ones)
  5. Update MIGRATION_PLAN.md (update status, log deviations)
  6. Deliver all changed files

Files to upload to Claude Project after each session:
  - get-the-hay-out_bYYYYMMDD.HHMM.html
  - ARCHITECTURE_bYYYYMMDD.HHMM.md
  - OPEN_ITEMS_bYYYYMMDD.HHMM.md
  - PROJECT_CHANGELOG_bYYYYMMDD.HHMM.md
  - MIGRATION_PLAN_supabase_vX.Y.md  ← always latest version, no build stamp in name
```

### What Goes in ARCHITECTURE During Migration

ARCHITECTURE.md gets two new permanent sections:

**Section: Supabase Backend**
- Project URL pattern
- SDK version and CDN tag
- Auth flow (Supabase Auth — native email magic link)
- Table inventory (cross-reference to schema in MIGRATION_PLAN)
- RLS policy pattern
- Realtime listener pattern
- Offline queue pattern

**Section: Data Layer (replaces Drive Sync section)**
- `loadFromSupabase()` — startup load
- `subscribeRealtime()` — live listeners
- `save()` → `queueWrite()` + `flushToSupabase()` — write path
- Offline fallback behavior
- S object as in-memory cache (render layer unchanged)

### What Goes in OPEN_ITEMS During Migration

Migration tasks are tracked as OI items with a `Migration` source tag.
They follow the same format as all other OI items.
At session start, surface migration OI items the same way as any open items.

Suggested OI structure for migration:

| OI | Title | Session |
|---|---|---|
| OI-0070 | M1: Supabase foundation + auth | M1 |
| OI-0071 | M2: Load path + realtime listeners | M2 |
| OI-0072 | M3: Write path + Drive removal | M3 |
| OI-0073 | M4: Data migration from backup | M4 |
| OI-0074 | M5: Offline queue polish | M5 |
| OI-0075 | M6: Multi-farmer foundation | M6 |

---

## 6. Decisions Made / Open Questions

### Decided

| Decision | Choice | Rationale |
|---|---|---|
| Backend | Supabase (normalized) | Server-side fertility queries; open source; no Google lock-in |
| ID format | Keep bigint timestamp IDs | Zero migration remapping; collision-free for single-farm use |
| Settings storage | JSONB column | Too variable to normalize usefully; no query need |
| S object retention | Yes — in-memory cache | Render functions unchanged; offline fallback |
| Drive sync removal | Session M3 | Keep Drive as safety net through M2 |
| Offline strategy | localStorage write queue | Familiar pattern; flush on reconnect |
| Event sub-arrays | Discrete normalized tables per data class | Different shape, query pattern, write frequency per class; no EAV |
| feed_entries | Replaced by `event_feed_deliveries` (one row per delivery) + `event_feed_residual_checks` (series) | Scalar residual loses mid-event readings; series enables checkpoint attribution |
| NPK storage | `event_npk_deposits` table — stored at period boundaries | Audit trail; enables direct aggregation; migration imports real history |
| Paddock condition data | `paddock_observations` unified table | Surveys and event heights answer the same question; `confidence_rank` + `observed_at` resolve ties |
| Period derivation | Derived via SQL view, not stored `event_periods` table | Preserves ledger-replay principle; avoids write-time dependency on period rows |
| `pasture.recoveryMinDays` | Derived state — not source of truth | Removed from `pastures` table in Supabase; always read from `paddock_observations` |
| `animal.weightHistory[]` | `animal_weight_records` — top-level table, FK to animal | Time series; separate from health events; gain-rate queries per grazing event |
| `animalGroup.animalIds[]` | `animal_group_memberships` — dated membership rows | Historical composition; "who was in this group during this event" becomes a date-join |
| `inputApplication.locations[]` | `input_application_locations` — FK to application | Enables unified NPK query: livestock + amendments in one `UNION ALL` |
| `manureBatch.events[]` | `manure_batch_transactions` — input/drawdown ledger | `remaining` becomes derived; removes `loc.accumulatingBatchId` coupling on pasture |
| Feature sequencing | Dashboard/reporting/forecasting waits until post-M4 | SQL queries are the right implementation; building JS versions first = building twice |
| Feed residual organic matter | `event_npk_deposits` with `source='feed_residual'`; `feed_types` gains optional `n_pct/p_pct/k_pct`; `event_feed_residual_checks` gains `is_close_reading` flag | Uneaten bales are a real fertility input; captured in same table as livestock excretion; degrades gracefully when no hay analysis present |
| Pre-migration prep | Session M0 before M1 | Aligns localStorage model with target schema; simplifies M4 migration script |
| Auth provider | Supabase native email + magic link | No Google dependency; PWA-safe token refresh; any email works; no Google Cloud Console setup |
| Settings queueWrite | `saveSettings()` queues writes to `operations` (herd name) and `operation_settings` (JSONB blob) | Both were missing from M3 write path audit; S.settings → JSONB is an existing schema decision |
| Reset behavior post-Supabase | `executeReset()` deletes from Supabase tables when signed in, in FK-safe order (children first) | Reset without Supabase delete causes data to flood back on next loadFromSupabase(); "erase everything" must mean everything |
| Backup restore post-Supabase | `importDataJSON()` calls `pushAllToSupabase()` after local restore when signed in | Restored backup must replace Supabase state, not just localStorage; equivalent to re-running M4 migration on the imported file |
| User roles | Three levels: `owner` / `admin` / `member` | Two levels (owner/worker) too coarse for real farms; admin gates structural changes (add users, delete records, reset); member covers day-to-day operations |
| Invite flow | Admin calls `sbInviteMember(email, role)` → inserts pending `operation_members` row + calls `signInWithOtp` on invitee email | No separate invite service needed; OTP flow already exists; pending row visible to admin while invitee is unregistered |
| `claim_pending_invite` | `SECURITY DEFINER` Postgres function | RLS blocks invitee from writing to `user_id = null` rows; SECURITY DEFINER runs with elevated permissions for the single claim update |
| Legacy `S.users[]` retirement | Removed in M6; replaced by `operation_members` + `_sbProfile` | Local user list was pre-Supabase multi-user hack; Supabase Auth is the correct identity layer |
| `isAdmin()` helper | `_sbProfile?.role === 'owner' \|\| _sbProfile?.role === 'admin'` | Simple, readable, no extra network call — profile already loaded at startup |
| Land use taxonomy | `pasture` / `mixed-use` / `crop` / `confinement` — additive `landUse` field on `S.pastures[]` | Additive to existing `locationType`; no big-bang rename; UI filters by `landUse` |
| Farm grouping | All land belongs to a Farm. `S.farms[]` new collection. Auto-create "Home Farm" on M7 migration | Universal parent — not just for leased land; "Home Farm" gets no special code treatment |
| Harvest event granularity | One `S.batches[]` row per field per harvest event | Organic record-keeping traceability; each batch carries `sourceHarvestEventId` + `sourceFieldId` |
| Nutrient transfer accounting | Mass balance — withdrawal at harvest field, deposit at feeding location, using same batch nutritional values | Consistent with purchased feed model; `sourceFieldId` for traceability only, not ledger arithmetic |
| Harvest NPK removal | Calculated from `feedType.harvestDefaults` reference values; overridable per harvest event | Close enough for ledger purposes; soil test anchors reset baseline when real data available |
| Soil test units | Stored as `unit` string alongside values — not assumed | `'lbs/acre'` / `'kg/ha'` / `'ppm'` options; default TBD pending user research |
| Unified removal ledger | Grazing (cow DMI) and harvest (machine) both written as DM removal transactions to same ledger per field | Single coherent DM story per field; harvest is first withdrawal-type transaction |
| `S.pastures` JS rename | None — `S.pastures` stays as internal alias; only UI labels change | ~100 call sites; refactor risk not worth it; "Fields" is purely a display name |

### Open (Decide Before Starting)

All decisions resolved as of b20260328.0157. No open questions remain before M1.

| Question | Decision | Rationale |
|---|---|---|
| Supabase project tier | Free | Sufficient for single-farm use; upgrade when storage approaches 400MB |
| Auth provider | Supabase native email / magic link | No Google Cloud Console setup; no PWA token refresh risk; any email works for future farmers |
| Google OAuth | Not used | Removed from plan — Drive is gone, no reason to keep Google in the auth path |
| Supabase project region | US East | Closest to primary user location (Charlotte, NC) |
| Migration script runtime | Node.js local script | Service role key stays local; easier to debug and re-run |
| Multi-farm support | Single operation per user to start | M6 adds operation picker when needed |

---

## 7. Migration Status Tracker

Updated at the end of each session.

| Session | Status | Build | Resume point | Notes |
|---|---|---|---|---|
| M0 — Pre-migration prep | ✅ Complete | b20260328.0140 | — | All sub-tasks A–L and E complete. Data model aligned with Supabase schema. UI refinements shipped. |
| M1 — Foundation | ✅ Complete | b20260328.0243 | — | SDK added. sbInitClient/sbSignIn/sbSignOut/sbUpdateAuthUI implemented. Settings card added. Drive retained as safety net. |
| M2 — Load path | ✅ Complete | b20260328.1211 | — | Identity system (Option B clean break). Bootstrap on first sign-in. loadFromSupabase with pre-M4 guard. subscribeRealtime full-reload. Home nudge banner. OTP auth fix (b20260328.1211): magic link replaced with 6-digit code flow — PWA/Safari localStorage isolation prevented session tokens from reaching PWA context. |
| M3 — Write path | ✅ Complete | b20260328.1623 | — | Full write infrastructure (_sbToSnake, queueWrite, queueEventWrite, flushToSupabase, supabaseSyncDebounced). 68 mutation call sites instrumented. Drive code removed (~356 lines). OI-0074 (display name) resolved. |
| M4 — Data migration | ✅ Complete | b20260328.2241 | — | 457 rows migrated. All assembly bugs resolved across multiple builds: feedEntries lines[], calvingRecords, field aliases, animalIds, FK hint, paddock_observations realtime, batch.wt schema gap, saveBatchAdj queueWrite gap. Fully verified: 77 animals, 30 Cow-Calf members, DMI correct. |
| M4.5 — Settings repair | ✅ Complete | b20260329.1630 | — | All 7 sub-tasks done. Two low-priority items deferred as OI-0084 (historical events import write path) and OI-0085 (NPK recalc bulk write). |
| M5 — Offline queue | ✅ Complete | b20260329.2319 | — | Online/offline listeners (B), Flush now button (C-i), >24h stuck warning (C-ii). Conflict resolution (D) was already present via onConflict upsert. |
| M6 — User system + multi-farmer | ✅ Complete | b20260330.0020 | — | B–G complete. isAdmin(), _sbProfile, sbInviteMember, sbPostSignInCheck, renderOperationMembersList, role gates, legacy S.users[] retired. H (multi-operation) deferred. |
| M7 — Land, Farms & Harvest | 🟡 Designed | — | Sub-task A | Full design resolved b20260330. Schema, data model, UI, sub-tasks A–G all documented. Pre-session SQL ready. Pending: soil test units (user research). |
| M8 — Voice Field Mode | 🟡 Designed | — | Sub-task A | Full design documented b20260330.1913. Three-phase plan: Claude API → training capture → on-device WebLLM. Nine sub-tasks A–I. Awaits M7 completion. |
| Post-M4 — Dashboard / reporting | ⬜ Not started | — | — | Awaits M4 verification (OI-0075) |

**Current state:** M6 complete (b20260330.0020). M7 (Land, Farms & Harvest) fully designed. M8 (Voice Field Mode) fully designed (b20260330.1913).
Next session: OI-0069 (rotation calendar — pasture sub-move blocks should render green, not tan/hay colour).
Resume point: `OI-0069`.

> **How to use the Resume point column:** If a session ends mid-way through a
> multi-sub-task session (M0, M4), update this field with the next unstarted
> sub-task ID, e.g. `"Resume at F"`. The next session's opening read resolves
> immediately to the right starting point without re-reading all completed work.

---

## 8. Reference: Key Functions Being Replaced or Removed

| Current function | Fate | Replacement |
|---|---|---|
| `driveSync()` | Removed M3 | `flushToSupabase()` + realtime listeners |
| `driveSyncDebounced()` | Removed M3 | `supabaseSyncDebounced()` |
| `driveFetchFile()` | Removed M3 | `loadFromSupabase()` at startup |
| `driveWriteFile()` | Removed M3 | `supabase.from(table).upsert()` |
| `driveFindOrCreateFile()` | Removed M3 | Supabase creates tables at schema deploy time |
| `drivePushLocal()` | Removed M3 | `flushToSupabase()` |
| `onAppResume()` | Modified M3 | Calls `flushToSupabase()` instead of `driveSync()` |
| `maybeResumeTokenRefresh()` | Removed M3 | Supabase Auth handles token refresh automatically — no Google session cookie dependency |
| `loadGISAndConnect()` | Removed M3 | `supabase.auth.signInWithOtp({ email })` (native Supabase magic link) |
| `mergeData()` | Removed M3 | Supabase is source of truth; no client merge needed |
| `save()` | Modified M3 | `saveLocal()` + `queueWrite()` + `supabaseSyncDebounced()` |
| `saveLocal()` | Kept | Offline buffer write |
| `ensureDataArrays()` | Kept | Still needed after `loadFromSupabase()` |
| `exportDataJSON()` | Kept | Backup export still valuable |
| `importDataJSON()` | Modified M4.5 | Calls `pushAllToSupabase()` after local restore when signed in |
| `executeReset()` | Modified M4.5 | Deletes from Supabase tables (FK-safe order) when signed in, then clears local S |
| `saveSettings()` | Modified M4.5 | Adds `queueWrite` for `operations` (herd name) and `operation_settings` (JSONB) |
| `generateFarmCode()` | Modified M6 | Encodes Supabase operation_id instead of Drive file_id |
| `addUser()` | Removed M6 | Replaced by `sbInviteMember(email, role)` |
| `renderUsersList()` | Removed M6 | Replaced by `renderOperationMembersList()` |
| `switchToUser()` / `activeUserId` | Removed M6 | Identity is Supabase `_sbSession.user` + `_sbProfile` |
| `getActiveUser()` | Removed M6 | Replaced by `_sbProfile` (operation_members row) |
| `isAdmin()` | New M6 | `_sbProfile?.role === 'owner' \|\| _sbProfile?.role === 'admin'` |
| `sbInviteMember(email, role)` | New M6 | Insert pending operation_members row + signInWithOtp to invitee |
| `sbPostSignInCheck(user)` | New M6 | Claims pending invite via RPC, sets _sbOperationId, loads farm |
| `pushAllToSupabase()` | New M4.5 | Queues + flushes all S arrays to Supabase; used by importDataJSON restore path |
| `lastGrazingRecordForPasture()` | Modified M0 | Reads `S.paddockObservations[]` instead of scanning events/sub_moves |
| `calcGrassDMIByWindow()` | Modified M0 | Reads `ev.feedResidualChecks[]` series instead of scalar `ev.feedResidual` |
| `calcEventTotalsWithSubMoves()` | Modified M0 | Writes `ev.npkLedger[]` entries at period boundaries |
| `getBatchRemaining()` | Modified M0 | Derives remaining from `S.manureBatchTransactions[]` instead of embedded `events[]` |
| `getGroupTotals()` | Modified M0 | Reads from `S.animalGroupMemberships[]` in addition to `group.animalIds[]` |
| weight history reads | Modified M0 | Read from `S.animalWeightRecords[]` filtered by `animalId` |
| `saveApplyInput()` | Modified M0 | Writes to `S.inputApplicationLocations[]` instead of embedding in application record |
| `wizCloseEvent()` | Modified M0 | Writes feed residual OM deposit entries to `ev.npkLedger[]` with `source='feed_residual'`; uses `isCloseReading` flag to identify final residual check; looks up `feedType.nPct/pPct/kPct` for NPK values |
---

### Session M8 — Voice Field Mode

**Goal:** A farmer standing in a paddock taps a mic button, speaks naturally about
what they just did, and the app turns that into correct, reviewed ledger entries
with zero keyboard input. An LLM holds a short clarifying conversation when
information is missing or ambiguous, speaks its questions aloud so the farmer
keeps eyes up, and only produces review cards when it has enough confidence.
Approved entries flow through the existing `queueWrite` path — no new write
infrastructure is required.

This is a three-phase feature. Phase 1 ships a working Claude API-backed
implementation. Phase 2 accumulates labelled training data silently in the
background. Phase 3 swaps the inference backend to an on-device model — zero
ongoing cost, works offline. The app interface and data path are identical across
all three phases. Only the inference call changes.

---

#### M8 Design: Entry Types in Scope

Voice parsing covers every entry type a farmer would make in the field. The full
scope, ordered by frequency of field use:

| Entry type | Example utterance | Target write path |
|---|---|---|
| Grazing move (new event) | "Moved the Angus cows, 47 head, onto the river paddock this morning" | `wizSaveNew()` equivalent |
| Grazing move (sub-move) | "Put the Angus cows into the south end of the river paddock" | `saveSubMove()` |
| Close event | "Closed out the river paddock, grass was about three inches" | `wizCloseEvent()` |
| Feed delivery | "Fed out two round bales of hay to the yearlings at the creek paddock" | `queueEventWrite('event_feed_deliveries', ...)` |
| Animal health event | "Treated tag 4471 for pinkeye with Terramycin" | `saveAnimalHealthEvent()` |
| Weight entry | "Weighed the calf group — averaging 380 pounds" | `saveWeightRecord()` |
| Pasture survey | "Surveyed the creek paddock — eight inches of growth, good cover" | `saveSurvey()` |
| Operations note / to-do | "Remind me to check the water trough in the river paddock tomorrow" | `saveTodo()` |
| Feed residual check | "Checked the bale grazing site — about 15 percent residual remaining" | `queueEventWrite('event_feed_residual_checks', ...)` |

Scope for Phase 1 implementation: grazing move (new event), close event, feed
delivery, animal health event. Remaining types added in Phase 1 follow-on
sessions using the same infrastructure.

---

#### M8 Design: System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    VOICE FIELD MODE                          │
│                                                              │
│  [Mic button] ──► Web Speech API (SpeechRecognition)        │
│                        │                                     │
│                        ▼ transcript string                   │
│              ┌─────────────────────┐                        │
│              │  _vfmSession{}      │ ← context payload      │
│              │  messages[]         │   (field names,        │
│              │  transcripts[]      │    groups, batches,    │
│              └─────────────────────┘    feed types)         │
│                        │                                     │
│                        ▼                                     │
│              LLM Inference Call                              │
│              (Phase 1: Claude API)                           │
│              (Phase 3: WebLLM on-device)                     │
│                        │                                     │
│         ┌──────────────┴──────────────┐                     │
│         ▼                             ▼                      │
│   clarifying question           structured JSON              │
│   (text + TTS spoken aloud)     { status: 'ready',          │
│         │                         entries: [...] }          │
│         ▼                             │                      │
│   farmer speaks answer               ▼                      │
│   (loop continues)           Review Cards UI                │
│                                       │                      │
│                              farmer approves/edits           │
│                                       │                      │
│                                       ▼                      │
│                              queueWrite() per entry         │
│                              ──► flushToSupabase()           │
└─────────────────────────────────────────────────────────────┘
```

---

#### M8 Design: Session State Object

The voice session lives entirely in memory. Nothing is persisted except the
final approved entries (via `queueWrite`). If the farmer abandons mid-session,
the raw transcript string is saved to `S.voiceTranscriptQueue[]` for recovery.

```javascript
// Session state — created fresh on each Field Mode activation
let _vfmSession = null;

function _vfmNewSession() {
  return {
    active: false,
    messages: [],          // full conversation history sent to LLM each turn
    transcripts: [],       // raw utterances this session (for training export)
    pendingEntries: [],    // parsed entries awaiting review
    listening: false,      // mic currently open
    speaking: false        // TTS currently playing
  };
}
```

---

#### M8 Design: Context Payload

The LLM cannot resolve natural-language references without knowing what exists
on this farm. A compact context block is serialised from live `S` state and
injected into the system prompt at session start. It is NOT re-sent each turn —
it lives in the first `messages[0]` system turn only.

```javascript
function _vfmBuildContext() {
  // Field / paddock names
  const fields = S.pastures
    .filter(p => !p.archived)
    .map(p => ({ id: p.id, name: p.name, type: p.type || 'pasture' }));

  // Animal groups
  const groups = S.animalGroups
    .filter(g => !g.archived)
    .map(g => ({ id: g.id, name: g.name, species: g.species }));

  // Feed / batch inventory
  const feedTypes = S.feedTypes
    .filter(f => !f.archived)
    .map(f => ({ id: f.id, name: f.name, unit: f.unit }));

  // Treatment types (for health events)
  const treatments = S.treatmentTypes
    .filter(t => !t.archived)
    .map(t => ({ id: t.id, name: t.name }));

  // Currently open events (grazing events in progress)
  const openEvents = S.events
    .filter(ev => ev.status === 'open')
    .map(ev => ({
      id: ev.id,
      groupName: (S.animalGroups.find(g => g.id === ev.animalGroupId) || {}).name,
      fieldName: ev.location,
      dateIn: ev.dateIn
    }));

  return { fields, groups, feedTypes, treatments, openEvents };
}
```

**Token budget:** At typical farm scale (30 fields, 10 groups, 20 feed types),
this context serialises to approximately 1,200–1,800 tokens. Well within budget
for all three inference backends.

---

#### M8 Design: System Prompt

The system prompt is assembled once at session start from a template plus the
context payload. It does three things: establishes the farm vocabulary, defines
the two response modes (clarifying question vs. ready-to-commit JSON), and sets
the conversational tone.

```javascript
function _vfmBuildSystemPrompt(ctx) {
  return `You are a farm record assistant for a regenerative livestock operation.
Your job is to listen to what the farmer says they just did and turn it into
structured farm records. You know the farm vocabulary listed below.

## Farm vocabulary

Fields / paddocks:
${ctx.fields.map(f => `- "${f.name}" (${f.type})`).join('\n')}

Animal groups:
${ctx.groups.map(g => `- "${g.name}" (${g.species})`).join('\n')}

Feed and supplement types:
${ctx.feedTypes.map(f => `- "${f.name}"`).join('\n')}

Treatment products:
${ctx.treatments.map(t => `- "${t.name}"`).join('\n')}

Currently open grazing events:
${ctx.openEvents.length
  ? ctx.openEvents.map(ev =>
      `- ${ev.groupName} on ${ev.fieldName} (started ${ev.dateIn})`).join('\n')
  : '- None currently open'}

## Your two response modes

**Mode 1 — Clarifying question (when information is missing or ambiguous):**
Respond with a single plain-English question. Keep it short. One question at a
time. Do not ask for information you already have. Ask the most important missing
piece first. Speak as if you are a helpful colleague, not a form.

Response format for Mode 1:
{ "status": "clarifying", "question": "Which group did you move?" }

**Mode 2 — Ready to commit (when you have everything you need):**
Respond with a structured list of entries ready for the farmer to review.

Response format for Mode 2:
{
  "status": "ready",
  "summary": "One plain-English sentence summarising what will be recorded.",
  "entries": [
    {
      "type": "grazing_move",
      "groupId": <id>,
      "groupName": "<name>",
      "fieldId": <id>,
      "fieldName": "<name>",
      "headCount": <number or null>,
      "dateIn": "<YYYY-MM-DD>",
      "notes": "<any extra detail>"
    }
  ]
}

## Entry types you can produce

grazing_move — moving a group to a new paddock (opens a new event)
sub_move — moving within an existing open event to a sub-location
close_event — ending a grazing event with a residual height reading
feed_delivery — feed put out to a group on a paddock
health_event — treatment or observation for a specific animal or group
weight_entry — bodyweight recorded for a group or individual animal
survey — pasture condition survey with height and cover readings
todo — reminder or task to follow up

## Rules

- Today's date is the default date unless the farmer specifies otherwise.
- If the farmer says "this morning" or "earlier today", use today's date.
- If a name is ambiguous (e.g. "south block" could match two fields), ask.
- Never guess at a group or field if the match is not clear. Ask instead.
- Keep all responses as valid JSON only. No markdown, no preamble.
- Ask at most two clarifying turns before producing a best-effort entry with
  a note flagging the uncertainty for the farmer to review.`;
}
```

---

#### M8 Design: LLM Inference Layer

The inference layer is a single function that Phase 3 replaces without touching
any other code. The interface is identical: takes a messages array, returns
parsed JSON.

**Phase 1 — Claude API:**

```javascript
async function _vfmInfer(messages) {
  const resp = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: 'claude-haiku-4-5-20251001',   // cheapest; ~$0.001/session
      max_tokens: 512,
      system: _vfmSession.systemPrompt,
      messages: messages
    })
  });
  const data = await resp.json();
  const raw = data.content?.[0]?.text || '{}';
  try { return JSON.parse(raw); }
  catch { return { status: 'error', message: raw }; }
}
```

**Phase 3 — WebLLM on-device (swap-in replacement):**

```javascript
async function _vfmInfer(messages) {
  // _vfmEngine is initialised once at Field Mode entry
  // using webllm.CreateMLCEngine('Phi-3.5-mini-instruct-q4f16_1-MLC')
  const reply = await _vfmEngine.chat.completions.create({
    messages: [
      { role: 'system', content: _vfmSession.systemPrompt },
      ...messages
    ],
    max_tokens: 512
  });
  const raw = reply.choices[0].message.content || '{}';
  try { return JSON.parse(raw); }
  catch { return { status: 'error', message: raw }; }
}
```

The only difference between Phase 1 and Phase 3 is which function body is
active. Everything above and below this function is identical.

**API key handling (Phase 1):** The Claude API key is stored in
`S.settings.voiceApiKey` (Settings card, admin-only, masked input). It is
included in the `Authorization` header of the fetch call. For a single-operator
app this is acceptable. The key is scoped to the `claude-haiku-4-5-20251001`
model and should have a monthly spend cap set in the Anthropic console.

---

#### M8 Design: The Conversation Loop

The loop is the heart of the feature. It runs until the LLM returns
`{ status: 'ready' }`, at which point it exits to the review card UI.

```javascript
async function _vfmProcessTurn(transcript) {
  // Append farmer's utterance to history
  _vfmSession.messages.push({ role: 'user', content: transcript });
  _vfmSession.transcripts.push(transcript);

  // Show thinking indicator
  _vfmSetStatus('thinking');

  const result = await _vfmInfer(_vfmSession.messages);

  if (result.status === 'clarifying') {
    // Append assistant question to history
    _vfmSession.messages.push({
      role: 'assistant',
      content: JSON.stringify(result)
    });
    // Speak the question aloud and show it on screen
    _vfmSpeak(result.question);
    _vfmSetStatus('listening');
    _vfmStartListening();  // re-open mic immediately after TTS finishes

  } else if (result.status === 'ready') {
    // Append assistant confirmation to history
    _vfmSession.messages.push({
      role: 'assistant',
      content: JSON.stringify(result)
    });
    // Speak the summary aloud
    _vfmSpeak(result.summary);
    // Store entries and open review UI
    _vfmSession.pendingEntries = result.entries;
    _vfmOpenReviewCards();

  } else {
    // Parsing failure — show raw text, let farmer try again
    _vfmSetStatus('error', result.message || 'Could not understand. Try again.');
  }
}
```

**TTS bridge:** The mic does not re-open while the app is speaking. This
prevents the app from hearing its own question. `_vfmSpeak()` uses
`SpeechSynthesisUtterance` and sets `_vfmSession.speaking = true` during
playback. `_vfmStartListening()` checks this flag before opening
`SpeechRecognition`.

---

#### M8 Design: Voice I/O Utilities

```javascript
// Text-to-speech
function _vfmSpeak(text) {
  window.speechSynthesis.cancel();    // clear any queued speech
  const utt = new SpeechSynthesisUtterance(text);
  utt.rate = 1.0;
  utt.onend = () => {
    _vfmSession.speaking = false;
    // If still in listening state, re-open mic
    if (_vfmSession.active && !_vfmSession.listening) _vfmStartListening();
  };
  _vfmSession.speaking = true;
  window.speechSynthesis.speak(utt);
}

// Speech recognition (one utterance at a time — not continuous)
function _vfmStartListening() {
  if (_vfmSession.speaking || _vfmSession.listening) return;
  const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
  if (!SR) { _vfmSetStatus('error', 'Voice input not supported on this browser.'); return; }

  const rec = new SR();
  rec.lang = 'en-US';
  rec.interimResults = false;
  rec.maxAlternatives = 1;

  rec.onresult = (e) => {
    const transcript = e.results[0][0].transcript;
    _vfmSession.listening = false;
    _vfmProcessTurn(transcript);
  };
  rec.onerror = (e) => {
    _vfmSession.listening = false;
    _vfmSetStatus('error', `Mic error: ${e.error}. Tap to try again.`);
  };
  rec.onend = () => { _vfmSession.listening = false; };

  _vfmSession.listening = true;
  _vfmSetStatus('listening');
  rec.start();
}
```

**Browser support:** Web Speech API (`SpeechRecognition` + `SpeechSynthesis`)
is supported in Chrome on Android and iOS Safari 14.5+. It requires HTTPS
(already the case on GitHub Pages). It does NOT work offline — if the device
is offline, voice input falls back to a text input field with the same
processing pipeline. This is acceptable for Phase 1 because the Claude API
also requires connectivity.

---

#### M8 Design: Review Card UI

When the LLM returns `{ status: 'ready' }`, the conversation loop exits and the
review card UI opens. This is a sheet overlay (same pattern as all other sheets
in GTHY) displaying one card per proposed entry.

**Sheet DOM ID:** `#vfm-review-wrap`

**Card anatomy:**

```
┌─ Grazing Move ─────────────────────────────────────────────┐
│  Group:   Angus Cows                                        │
│  To:      River Paddock                                     │
│  Head:    47                                                │
│  Date:    2026-03-30                                        │
│  Notes:   —                                                 │
│                                                             │
│  [Edit]                         [✓ Approve]  [✗ Skip]      │
└─────────────────────────────────────────────────────────────┘
```

Each card has three actions:
- **Approve** — entry is added to `_vfmApproved[]`
- **Skip** — entry is discarded silently
- **Edit** — opens the normal entry sheet for that type (e.g. opens the Move
  Wizard for a grazing_move entry, pre-populated with the parsed values).
  On save, the edited entry replaces the voice-parsed version.

**Commit button:** "Save [N] entries" at the bottom of the sheet. Visible only
when at least one entry has been approved. Tapping it calls `_vfmCommit()`.

```javascript
function _vfmCommit() {
  for (const entry of _vfmApproved) {
    _vfmWriteEntry(entry);         // routes to the correct queueWrite path
  }
  _vfmSaveTranscriptForTraining(); // Phase 2 training data capture
  _vfmEndSession();
  closeVfmReviewSheet();
  showToast(`${_vfmApproved.length} entr${_vfmApproved.length === 1 ? 'y' : 'ies'} saved.`);
}
```

---

#### M8 Design: Entry Write Router

Each entry type maps to an existing write path. The router translates the LLM's
JSON structure into the correct function calls.

```javascript
function _vfmWriteEntry(entry) {
  const now = new Date().toISOString();
  const opId = _sbOperationId;

  switch (entry.type) {

    case 'grazing_move': {
      // Build a new event record (equivalent to wizSaveNew path)
      const ev = {
        id: Date.now(),
        operationId: opId,
        animalGroupId: entry.groupId,
        location: entry.fieldName,
        pastureId: entry.fieldId,
        dateIn: entry.dateIn,
        head: entry.headCount,
        status: 'open',
        source: 'voice',           // audit trail — differentiates voice from manual
        notes: entry.notes || '',
        updatedAt: now
      };
      S.events.push(ev);
      queueEventWrite(ev);
      break;
    }

    case 'close_event': {
      // Find the open event for this group/field and close it
      const ev = S.events.find(e =>
        e.status === 'open' &&
        (e.animalGroupId === entry.groupId || e.location === entry.fieldName)
      );
      if (ev) {
        ev.status = 'closed';
        ev.dateOut = entry.dateOut || new Date().toISOString().split('T')[0];
        ev.heightOut = entry.heightInches || null;
        ev.source = 'voice';
        ev.updatedAt = now;
        queueEventWrite(ev);
      }
      break;
    }

    case 'feed_delivery': {
      const record = {
        id: Date.now(),
        operationId: opId,
        eventId: entry.eventId || null,
        feedTypeId: entry.feedTypeId,
        feedTypeName: entry.feedTypeName,
        qty: entry.qty,
        unit: entry.unit,
        deliveredAt: entry.dateIn || now.split('T')[0],
        fieldId: entry.fieldId,
        fieldName: entry.fieldName,
        source: 'voice',
        updatedAt: now
      };
      queueWrite('event_feed_deliveries', _sbToSnake(record));
      break;
    }

    case 'health_event': {
      const record = {
        id: Date.now(),
        operationId: opId,
        animalId: entry.animalId || null,
        groupId: entry.groupId || null,
        treatmentTypeId: entry.treatmentTypeId || null,
        treatmentName: entry.treatmentName,
        notes: entry.notes || '',
        eventDate: entry.dateIn || now.split('T')[0],
        source: 'voice',
        updatedAt: now
      };
      queueWrite('animal_health_events', _sbToSnake(record));
      break;
    }

    // Additional types added in follow-on sessions using same pattern
  }

  save();
}
```

**`source: 'voice'` field:** Added to every voice-committed record. This is
both an audit trail and the training data signal — it identifies which records
originated from the voice pipeline.

---

#### M8 Design: Training Data Capture (Phase 2)

Every committed voice session is a labelled training example: the raw transcript
sequence maps to the approved entry set. This data accumulates silently in
`S.voiceTrainingLog[]` and is exportable from Settings (admin-only).

```javascript
function _vfmSaveTranscriptForTraining() {
  if (!S.settings.voiceTrainingCapture) return;  // opt-in flag
  const example = {
    id: Date.now(),
    date: new Date().toISOString(),
    transcripts: _vfmSession.transcripts,       // raw utterance strings
    conversation: _vfmSession.messages,          // full messages[] exchange
    approved: _vfmSession.pendingEntries         // entries the farmer approved
      .filter((_, i) => _vfmApproved.includes(_vfmSession.pendingEntries[i])),
    build: document.getElementById('app-version-meta').getAttribute('content')
  };
  if (!S.voiceTrainingLog) S.voiceTrainingLog = [];
  S.voiceTrainingLog.push(example);
  saveLocal();  // training log is local only — not synced to Supabase
}
```

After 100–200 sessions, `S.voiceTrainingLog` is exported as a JSONL file (one
example per line) for fine-tuning a small base model. The guided script sessions
(see below) produce especially clean examples because the farmer's phrasing
follows a known template.

---

#### M8 Design: Guided Script Library

A set of structured speaking prompts that teach the farmer natural dictation
patterns while generating clean training examples. Accessible from the Voice
Field Mode home screen as a "Practice" button.

Each script card presents a fill-in-the-blank template. The farmer reads it
aloud. The LLM parses it and shows the result immediately. After two or three
practice runs per entry type, the pattern is internalized.

**Script card examples:**

```
GRAZING MOVE
───────────────────────────────────────────────────────────
"Moved the [GROUP NAME], [NUMBER] head, onto [PADDOCK NAME],
 [today / yesterday / date]."

Example: "Moved the Angus cows, 47 head, onto the river paddock, today."
───────────────────────────────────────────────────────────

CLOSE EVENT
───────────────────────────────────────────────────────────
"Closed the [GROUP NAME] off [PADDOCK NAME]. Grass was
 [HEIGHT] inches."

Example: "Closed the Angus cows off the river paddock. Grass was three inches."
───────────────────────────────────────────────────────────

FEED DELIVERY
───────────────────────────────────────────────────────────
"Fed out [QUANTITY] [FEED TYPE] to [GROUP NAME] at
 [PADDOCK NAME]."

Example: "Fed out two round bales of hay to the yearlings at the creek paddock."
───────────────────────────────────────────────────────────

HEALTH EVENT
───────────────────────────────────────────────────────────
"Treated [TAG / GROUP] for [CONDITION] with [PRODUCT]."

Example: "Treated tag 4471 for pinkeye with Terramycin."
───────────────────────────────────────────────────────────
```

The script library doubles as onboarding — a new farm worker can run through
all eight cards in under ten minutes and be ready to use voice mode
independently.

---

#### M8 Design: UI Touchpoints

**1. Field Mode home screen** (`renderFieldHome()`, currently a stub — OI-0006)

M8 adds a prominent mic tile to the field home screen:

```
┌─────────────────────────────────────┐
│                                     │
│         🎙  Speak an entry          │
│                                     │
│   Tap to record what you just did   │
│                                     │
└─────────────────────────────────────┘
```

Tapping opens the Voice Field Mode session. The tile is the primary CTA on the
field home screen — larger than the other action tiles.

**2. Voice session screen** (replaces the home content during an active session)

```
┌─────────────────────────────────────┐
│  ●  Listening...                    │
│                                     │
│  "Moved the Angus cows onto the     │
│   river paddock this morning"       │
│                                     │
│  ─────────────────────────────────  │
│  ◉  Which field — River Paddock     │
│     East or River Paddock West?     │  ← LLM question, spoken aloud
│                                     │
│  [Tap to speak answer]     [Cancel] │
└─────────────────────────────────────┘
```

Status indicator states:
- `listening` — mic open, pulsing red dot
- `thinking` — spinner, "Checking..."
- `speaking` — speaker icon, question text displayed and being read aloud
- `ready` — checkmark, "Review entries →"
- `error` — warning icon, error text, retry button

**3. Review sheet** (`#vfm-review-wrap`)

Standard GTHY sheet overlay pattern. One card per entry. Approve / Edit / Skip
per card. "Save N entries" commit button at bottom.

**4. Settings card: Voice assistant** (admin-only)

```
┌─ Voice assistant ──────────────────────────────────────────┐
│  API key: [●●●●●●●●●●●●●●●●]  [Show]  [Save]              │
│                                                             │
│  ☑  Capture training data (opt-in)                         │
│  Training examples collected: 47                           │
│  [Export training data]                                    │
│                                                             │
│  [Practice scripts]                                        │
└─────────────────────────────────────────────────────────────┘
```

---

#### M8 Design: Offline Behaviour

Voice mode requires connectivity in Phase 1 (Claude API) and Phase 3
(WebLLM model already downloaded). The connectivity states:

| State | Phase 1 behaviour | Phase 3 behaviour |
|---|---|---|
| Online | Full voice mode | Full voice mode |
| Offline | Show "Voice needs a connection. Type instead?" — text input field displayed, same LLM pipeline used when connectivity returns | Full voice mode (on-device inference) |
| Model not yet downloaded (Phase 3) | Falls back to Phase 1 API | N/A |

The text-input fallback uses the identical processing pipeline — same session
object, same review cards, same `queueWrite` path. Only the capture method
(mic vs. keyboard) differs.

---

#### M8 Design: New Schema Additions

No new Supabase tables are required. Two additions to existing structures:

**1. `source` column on events and related tables**

Add `source TEXT DEFAULT 'manual'` to:
- `events`
- `event_feed_deliveries`
- `animal_health_events`

This is a non-breaking addition — existing rows default to `'manual'`.

```sql
ALTER TABLE events ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';
ALTER TABLE event_feed_deliveries ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';
ALTER TABLE animal_health_events ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual';
```

**2. `S.voiceTrainingLog[]`** — local only, never synced to Supabase

Added to `ensureDataArrays()`:
```javascript
if (!S.voiceTrainingLog) S.voiceTrainingLog = [];
```

**3. New settings keys** (stored in `S.settings` JSONB blob, no schema change):
- `S.settings.voiceApiKey` — encrypted at rest in localStorage, never logged
- `S.settings.voiceTrainingCapture` — boolean, default `false`

---

#### M8 Sub-tasks

**A — Schema SQL (pre-session, manual in Supabase SQL Editor)**
Run the three `ALTER TABLE` statements above. Verify in dashboard.

**B — Core voice infrastructure**
`_vfmNewSession()`, `_vfmBuildContext()`, `_vfmBuildSystemPrompt()`,
`_vfmInfer()` (Phase 1, Claude API), `_vfmSpeak()`, `_vfmStartListening()`,
`_vfmProcessTurn()`. These are pure JS functions with no DOM dependency.
Unit-testable by passing mock transcripts directly to `_vfmProcessTurn()`.

**C — Voice session UI**
Mic tile on field home screen. Session status screen (listening / thinking /
speaking / ready states). Cancel / done controls.

**D — Review card sheet**
`#vfm-review-wrap` HTML. `_vfmOpenReviewCards()`, `_vfmRenderReviewCards()`.
Approve / Edit / Skip per card. Commit button. `_vfmCommit()`.

**E — Entry write router**
`_vfmWriteEntry()` for the four Phase 1 entry types: `grazing_move`,
`close_event`, `feed_delivery`, `health_event`.

**F — Settings card**
Voice assistant card in Settings (admin-only). API key input (masked).
Training capture toggle. Export training data button.

**G — Guided script library**
`_vfmOpenScriptLibrary()`. Eight script cards, one per entry type.
Each card shows template + example + mic button to try it.

**H — Training data capture**
`_vfmSaveTranscriptForTraining()`. `exportVoiceTrainingData()` in Settings.
Adds `voiceTrainingLog` to `ensureDataArrays()`.

**I — Offline text fallback**
Detect offline state in `_vfmStartListening()`. Render text input field.
Route typed text through same `_vfmProcessTurn()` pipeline.

---

#### M8 Design: Cost and Model Path Summary

| Phase | Inference | Cost | Offline | When |
|---|---|---|---|---|
| 1 | Claude Haiku API | ~$0.001/session, ~$2/yr | No (connectivity required) | Ship now — fast iteration |
| 2 | Claude Haiku API + training capture | Same | No | Accumulate data silently; no code change |
| 3 | WebLLM on-device (Phi-3.5 or Gemma 3 1B) | Zero | Yes | Swap `_vfmInfer()` body; ~1GB one-time download |

The Phase 1 → Phase 3 swap is a single function body change. Every other piece
of the system (session loop, review cards, write router, training capture) is
identical in all three phases.

---

**Documents updated this session:**
- MIGRATION_PLAN.md — M8 section added; v3_1 reconciles v2_10 (M7 design) with v3_0 (M8 design)

**HTML delivered:** No. Design-only session. No build stamp bump.

**Next session after M8 design:** OI-0069 (rotation calendar sub-move block
colours) is the next active implementation task. M7 implementation follows OI-0069.
M8 implementation begins after M7 is complete.
