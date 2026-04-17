# GTHO v2: Table Gap Analysis + Schema Quality Audit

**Date:** 2026-04-10
**Source:** v1 production Supabase schema (38 tables) vs v2 ARCHITECTURE.md entity specs
**Purpose:** Identify every missing table AND flag v1 workarounds so v2 gets best-practice schemas, not inherited debt.

---

## Part 1: System-Wide v1 Anti-Patterns

Before going table-by-table, these are the patterns that recur across the v1 schema. v2 has already fixed some of these in the 12 tables it specs. The remaining 26 tables need to follow v2's conventions, not copy v1.

### 1A. ID Type Chaos

v1 uses three different ID types with no clear rule:

| ID Type | Tables Using It |
|---|---|
| **bigint** (auto-increment) | 25 tables — animals, events, batches, event_sub_moves, etc. |
| **text** (string UUIDs or prefixed IDs) | 10 tables — farms, pastures, feed_types, forage_types, treatment_types, harvest_events, harvest_event_fields, batch_nutritional_profiles |
| **uuid** (native) | 3 tables — operations, operation_members, soil_tests |

This creates FK type mismatches. For example, `batches.id` is bigint but `batch_nutritional_profiles.batch_id` is text — they reference each other across types.

**v2 fix (already established in §4c):** All IDs are native `uuid` via `crypto.randomUUID()`. Every new table must follow this.

### 1B. Denormalized Name Snapshots

Eight v1 tables copy entity names into their own columns to avoid JOINs:

| Column | Tables |
|---|---|
| `pasture_name` | events, event_sub_moves, event_paddock_windows, event_npk_deposits, input_application_locations |
| `group_name` | event_group_memberships |
| `product_name` | input_applications |
| `land_name` | harvest_event_fields |

**Why v1 did this:** Offline-first PWA with no server-side JOINs. Name display without loading the parent entity.

**DECIDED: Drop all name snapshots.** Link by FK only. Display names resolved from entity cache at render time. Parent and child records are linked by IDs that users never see — what we display and how we link are separate concerns. v2's entity pattern includes `fromSupabaseShape()` which hydrates names from the local entity cache.

### 1C. JSONB Bags Instead of Proper Schemas

| Table.Column | What's In It | Problem |
|---|---|---|
| **operation_settings.data** | Entire app settings as one blob | Can't query individual settings, no schema validation, no column-level defaults |
| **event_feed_residual_checks.type_checks_json** | Per-feed-type check data | Should be a child table or at minimum a typed JSONB array |
| **operation_members.field_modules** | Module permission flags | Should be individual boolean columns or a junction table |
| **surveys.draft_ratings** | Per-pasture draft scores | Should be a child table (survey_ratings) |
| **todos.assigned_to** | Array of user IDs | Should be a junction table |
| **manure_batch_transactions.pasture_names** | Array of pasture names | Should be a junction table with FK to pastures |
| **release_notes.resolved_items** | Array of resolved issue refs | Acceptable — display-only, no queries needed |
| **submissions.thread** | Conversation messages | Acceptable — append-only log |

**v2 already addressed one:** `event_residual_checks.typeChecks` is kept as JSONB in v2 but with a defined shape: `[{feedTypeId, batchId, remainingPct, remainingUnits}]`. This is a reasonable choice — it's a bounded array tied to a single check event.

**v2 recommendation for new tables:** Replace the other JSONB bags with proper tables or typed columns, except thread/resolved_items which are fine as JSONB.

### 1D. Timestamp Inconsistency

v1 uses four different naming patterns for "when was this recorded":

| Pattern | Tables |
|---|---|
| `created_at` | farms, forage_types, animal_weight_records, batch_nutritional_profiles, harvest_events, harvest_event_fields, operation_members, surveys, todos |
| `updated_at` | batches, event_feed_deliveries, event_sub_moves, events, animals, todos |
| `recorded_at` | animal_health_events, event_feed_residual_checks, event_npk_deposits, paddock_observations, manure_batch_transactions |
| `ts` | submissions |

**v2 fix (already established):** Every entity gets both `created_at` and `updated_at` with `DEFAULT now()`. No exceptions.

### 1E. Time Stored as Text

Six v1 tables store time-of-day as `text` instead of a proper `time` type:

`events.time_in/time_out`, `event_sub_moves.time_in/time_out`, `event_group_memberships.time_added/time_removed`, `event_feed_residual_checks.check_time`, `animal_health_events.time`

**Why v1 did this:** Mobile form input returns a string; storing as text avoided parsing.

**v2 recommendation:** Use `time` type in Supabase, convert on write. Or if offline storage makes this painful, keep as text but enforce HH:MM format with a CHECK constraint.

### 1F. Stored Computed Values

Several v1 tables store values that could be calculated:

| Table | Stored Column | Could Be Computed From |
|---|---|---|
| event_feed_deliveries | dm_lbs | quantity × dm_pct |
| event_feed_deliveries | cost | quantity × cost_per_unit from batch |
| event_sub_moves | duration_hours | date_out/time_out - date_in/time_in |
| event_npk_deposits | n_lbs, p_lbs, k_lbs, npk_value | head × weight × days × species rates |
| event_group_memberships | head_snapshot, weight_snapshot | group head count and avg weight at date_added |

**DECIDED: Don't store computed values.** Compute on read in JS. Storing them creates drift when source values change (e.g., batch dm_pct is corrected but delivery dm_lbs isn't recalculated). This includes NPK deposits — compute on demand from the paddock window and group membership ledgers (see Decision 5).

### 1G. The Mega-Table Problem

`animal_health_events` (24 columns) crams 5 different record types into one table:

| Type Value | Columns Used | Columns Null |
|---|---|---|
| BCS score | bcs_score | 18 treatment/breeding/calving columns |
| Treatment | treatment_type_id through withdrawal_date | 10 breeding/calving/BCS columns |
| Breeding | breeding_subtype through ai_tech | 10 treatment/calving/BCS columns |
| Calving | calving_calf_id, calving_stillbirth | 18 treatment/breeding/BCS columns |
| General health note | notes only | ~20 columns |

Each row wastes 10-18 null columns. This is a classic "entity-attribute-value table disguised as a wide table."

**DECIDED: Split into separate tables by type** (animal_bcs_scores, animal_treatments, animal_breeding_records, animal_calving_records). Users focus on different things at different times — breeding season vs treatment records vs body condition. Separate tables let you build focused screens for each context. The v2 entity pattern (FIELDS + validate + shape functions) supports this cleanly.

### 1H. Units — Imperial vs Metric

v1 stores everything in imperial units (weight_lbs, dm_lbs, volume_lbs, dm_lbs_per_inch_per_acre).

**v2 fix (already established):** Internal storage is metric (weightKg, areaHa, heightCm). Display layer converts to user's preferred unit system. All new tables must use metric.

---

## Part 2: Table-by-Table Mapping

### Status Key

| Status | Meaning |
|---|---|
| SPEC'D | Full schema in v2 ARCHITECTURE.md |
| RENAMED | Same concept, new name in v2 |
| REPLACED | v2 has a different table serving the same purpose |
| MISSING-HIGH | Not spec'd, blocks core functionality |
| MISSING-MED | Not spec'd, needed for important features |
| MISSING-LOW | Not spec'd, deferrable or droppable |

---

### Tier 0 — Operation Setup (v1: 7 tables)

**operations** — SPEC'D (§8a)
v2 schema defined. Drops herd_count/herd_weight/herd_dmi (these are per-group in v2, not operation-level). Drops residual_graze_height/forage_utilization_pct/dm_per_aud (move to operation_settings or per-pasture). Adds unit_system, locale.
*v1 workaround:* Crammed calculation defaults (residual height, utilization %, DMI) onto the operation row. These are per-pasture or per-forage-type settings.

**operation_settings** — MISSING-HIGH
v1 stores all settings as a single JSONB blob. This is the biggest JSONB-bag problem in v1.
**DECIDED: No separate operation_settings table.** Settings go as typed columns directly on the operations table. Operations is the parent; settings are attributes of the operation. Add columns like `default_residual_height_cm`, `forage_utilization_pct`, `dm_per_aud_kg`, notification preferences directly to operations. New settings down the road = ALTER TABLE ADD COLUMN (rare event, correct approach).
*Belongs in:* CP1 or CP14 (as additions to the existing operations schema)

**forage_types** — MISSING-HIGH
Pastures reference forage_type_id. Without this table, pasture forage assignments don't work, grass height-to-yield calculations can't run, and DMI estimates have no species-level rates.
*v1 schema is reasonable* but needs: uuid IDs, metric units (dm_kg_per_cm_per_ha instead of dm_lbs_per_inch_per_acre), min_residual_height_cm, created_at + updated_at.
*v2 FIELDS needed:*
```
id, operationId, name, dmPct, nPerTonneDm, pPerTonneDm, kPerTonneDm,
dmKgPerCmPerHa, minResidualHeightCm, isSeeded, notes, createdAt, updatedAt
```
*Belongs in:* CP11 (pastures) — pastures already reference forageTypeId

**animal_classes** — MISSING-MED
Groups reference class_id. Without this, group classification (cow, heifer, steer, bull, calf) is just a text string — no standardization, no class-level DMI rates, no composition tracking.
*v1 schema is clean.* Just needs uuid IDs and created_at/updated_at.
*v2 FIELDS needed:*
```
id, operationId, name, species, dmiMultiplier (new — class-level DMI adjustment),
archived, createdAt, updatedAt
```
*Belongs in:* CP12 (animals)

**treatment_types** — MISSING-LOW (until health module)
Reference data for health event treatments.
*v1 schema is clean.* uuid IDs, add created_at/updated_at.
*Belongs in:* CP with animal_health_events

**input_products** — MISSING-LOW (until input module)
Reference data for fertilizer/amendment products.
*v1 schema is clean* but needs: uuid IDs, metric units (cost_per_kg not cost_per_unit with separate unit column).
*Belongs in:* CP with input_applications

**ai_bulls** — MISSING-LOW (until breeding module)
Reference data for AI sire catalog.
*v1 schema is fine.* uuid IDs, add created_at/updated_at.
*Belongs in:* CP with animal_breeding

---

### Tier 1 — Core Entities (v1: 5 tables)

**farms** — SPEC'D (§8a)
v2 adds area_ha (metric). Drops address (unused in practice, not a farm management field).
*No workarounds to fix.*

**feed_types** — SPEC'D (§4e)
v2 simplifies: drops forage_type_id link (batches link to feed_types directly), drops cutting_num/harvest_active/default_weight_lbs (these are batch-level attributes in v2, not feed-type-level). Adds category.
*v1 workaround fixed:* v1 overloaded feed_types with harvest tracking fields. v2 correctly separates feed type definition from batch/harvest data.

**animals** — SPEC'D (§4e)
v2 adds eid (electronic ID), uses metric weightKg. Keeps tagId, name, sex, classId, groupId (nullable), birthDate.
*v1 workarounds fixed:* v1 had breeding fields on the animal record (confirmed_bred, confirmed_bred_date). v2 moves breeding to a separate health/breeding table — animal record stays clean.

**animal_groups** — SPEC'D as "groups" (§4e)
v2 renames to groups. Adds description. Keeps name, classId, color.
*No major workarounds to fix.* v1's setup_updated_at is replaced by standard updated_at.

**submissions** — REPLACED by feedback (§23b)
v2 creates a new feedback table with a simpler schema. The 20+ column submissions table was accumulating scope (bug reports + feature requests + beta feedback + dev responses + threading).
*v2 best practice:* Smaller, focused table. If threading is needed, use a separate thread table or JSONB (acceptable for append-only logs).

---

### Tier 2 — Relationships & Events (v1: 8 tables)

**pastures** — SPEC'D (§4e)
v2 adds locationType ('paddock'|'drylot'|'barn'), metric areaHa/residualGrazeHeightCm. Keeps forageTypeId FK (but forage_types table is MISSING — see above).
*v1 workaround:* land_use stored as free text. v2 replaces with typed locationType enum.

**batches** — SPEC'D (§4e)
v2 redesigns significantly: adds source ('purchase'|'harvest'), quantityOriginal (immutable), weightPerUnitKg (metric), costTotal (not per-unit). Drops wt (ambiguous abbreviation).
*v1 workaround fixed:* v1's wt column had no clear definition (weight per bale? total weight?). v2 is explicit.

**events** — SPEC'D (§4b)
v2 redesigns: uses startDate/endDate (not date_in/date_out), drops pasture_name snapshot, status is derived not stored, adds source ('manual'|'voice').
*v1 workarounds fixed:* denormalized pasture_name, stored status.

**event_sub_moves** — SPEC'D as "sub_moves" (§4f)
v2 renames, uuid IDs, metric heights (heightInCm/heightOutCm). Drops stored duration_hours (compute on read), drops pasture_name snapshot.
*v1 workaround fixed:* stored computed duration, denormalized name.

**manure_batches** — MISSING-MED
Tracks collected manure as an inventory item (similar to feed batches but for manure).
*v1 issues:* 16 columns mixing identity, NPK content, volume tracking, and location. `label` and `name` are redundant. `mode` is an untyped text field. `remaining_lbs` is a stored computed value that drifts.
*v2 best practice:* Tighter schema. Track quantity received vs quantity applied via transactions (like feed batches use feed entries). Drop remaining_lbs — compute from transactions. Use metric. Merge name/label into one field.
*v2 FIELDS needed:*
```
id, operationId, farmId, name, sourceEventId (nullable FK to events),
dateCollected, quantityKg, nPct, pPct, kPct,
notes, createdAt, updatedAt
```
*Belongs in:* CP22 (manure/soil module)

**animal_weight_records** — MISSING-MED
Individual animal weights over time. Used for ADG (average daily gain) calculations.
*v1 schema is clean* except: uses `recorded_at` (date type, confusingly named like a timestamp) and `created_at` (actual timestamp). Needs uuid IDs, metric weight_kg, standard timestamp naming.
*v2 FIELDS needed:*
```
id, operationId, farmId, animalId, date, weightKg,
source ('manual'|'scale'|'estimated'), note, createdAt, updatedAt
```
*Belongs in:* CP with animal detail screen (CP12 or later)

**animal_group_memberships** — MISSING-MED
Tracks which animals belong to which groups over time.
*v1 schema is correct in concept* but date_joined/date_left are nullable (they shouldn't be — date_joined is always known). Needs uuid IDs.
*v2 FIELDS needed:*
```
id, operationId, farmId, groupId, animalId,
dateJoined (NOT NULL), dateLeft (nullable — null means current),
reason, createdAt, updatedAt
```
*Belongs in:* CP12 (animals) — needed for accurate group head counts

**animal_group_class_compositions** — MISSING-MED
For operations that manage by class (e.g., "50 cows, 10 heifers") instead of individual animals.
*v1 schema is fine* conceptually. Needs uuid IDs, farmId.
*v2 FIELDS needed:*
```
id, operationId, farmId, groupId, classId,
headCount, effectiveDate, createdAt, updatedAt
```
*Belongs in:* CP12 (animals) — alternative to individual animal tracking

**animal_health_events** — MISSING-MED
*This is the mega-table problem (see §1G above).* v1 crams BCS, treatments, breeding, and calving into 24 columns.
**DECIDED: Split into separate tables per type (Decision 4).** Users focus on different things at different times — breeding season vs treatment records vs body condition. Separate tables enable focused screens per context.

**animal_bcs_scores:**
```
id, operationId, farmId, animalId, date, time,
score (1-9), notes, createdAt, updatedAt
```
**animal_treatments:**
```
id, operationId, farmId, animalId, date, time,
treatmentTypeId, treatmentName, dose, unit, batchNumber,
withdrawalDate, likelyCull, notes, createdAt, updatedAt
```
**animal_breeding_records:**
```
id, operationId, farmId, animalId, date, time,
subtype ('ai'|'natural'|'embryo'), sireId (nullable FK to ai_bulls),
bullAnimalId (nullable FK to animals), sireName, sireRegNum,
semenId, aiTech, expectedCalvingDate, notes, createdAt, updatedAt
```
**animal_calving_records:**
```
id, operationId, farmId, animalId, date, time,
calfId (FK to animals), isStillbirth, notes, createdAt, updatedAt
```

*Belongs in:* New CP or CP17 (the doc mentions "advanced livestock" but doesn't define tables)

---

### Tier 3 — Measurement & Tracking (v1: 9 tables)

**surveys** — SPEC'D (§4e) + needs child table
v2 redesigns: uses heightCm (metric), adds density (1-5) and condition (1-5) scales, adds source. Drops draft_ratings JSONB.
**DECIDED: Add survey_ratings child table (Decision 8).** The survey is the parent event ("I walked the farm on March 10"), each pasture rating is a child record. Child records link to both the parent survey AND the individual pasture, so data is accessible from both directions. Draft/submitted status lives on the parent survey. When submitted, survey_ratings also become paddock_observations (Decision 3).

**survey_ratings** (new child table):
```
id, operationId, farmId, surveyId, pastureId,
heightCm, density (1-5), condition (1-5), foragePct,
notes, createdAt, updatedAt
```

**event_feed_deliveries** — REPLACED by event_feed_entries (§4f)
v2 unifies deliveries and transfers into one ledger (positive qty = delivery, negative = transfer). Drops stored computed dm_lbs and cost. Adds kind ('delivery'|'transfer') and transferPairId.
*v1 workarounds fixed:* stored computed values, separate delivery/transfer logic.

**event_feed_residual_checks** — SPEC'D as event_residual_checks (§4f)
v2 keeps typeChecks as JSONB (with defined shape). Drops redundant residual_pct and bales_remaining_pct (superseded by per-type checks). Renames check_date → date.
*v1 workaround partially fixed:* v1 had both a global residual_pct AND a per-type type_checks_json, causing confusion about which was authoritative.

**soil_tests** — MISSING-MED
Per-paddock soil health data.
*v1 schema is clean* and already uses uuid IDs. Just needs farmId, metric units (though NPK in soil tests is typically already in standard units), standard timestamps.
*v2 FIELDS needed:*
```
id, operationId, farmId, pastureId, date,
n, p, k, unit ('ppm'|'lbs_per_acre'|'mg_per_kg'),
ph, organicMatterPct, lab, notes, createdAt, updatedAt
```
*Belongs in:* CP22 (soil module)

**harvest_events + harvest_event_fields** — MISSING-MED
Hay cutting records with per-field detail. Two linked tables in v1.
*v1 issues:* harvest_event_fields duplicates NPK rates from forage_types (n_per_tonne_dm, etc.) — these should be looked up, not copied. land_name is a denormalized snapshot.
*v2 best practice:* Keep the two-table structure (header + line items). Drop duplicated NPK rates. Drop land_name snapshot. Use metric.

**harvest_events:**
```
id, operationId, farmId, date, notes, createdAt, updatedAt
```
**harvest_fields:**
```
id, operationId, farmId, harvestEventId, pastureId, feedTypeId,
quantity, unit, weightPerUnitKg, dmPct,
batchId (auto-created batch FK), notes, createdAt, updatedAt
```
*Belongs in:* CP19 (harvest)

**paddock_observations** — MISSING-MED
Observations about paddock condition from any source — pasture walks, sub_move height readings, manual entry.
**DECIDED: Merge with surveys into one table (Decision 3).** The observations are the same data coming from different input contexts. The calculation engine needs one place to look for "what do we last know about this paddock" — shouldn't have to query two tables. Source field tracks where the data came from.
*v2 FIELDS needed:*
```
id, operationId, farmId, pastureId, date, source ('survey'|'sub_move'|'manual'),
sourceId (nullable FK to source record), confidenceRank,
vegHeightCm, forageCoverPct, forageQuality (1-5),
recoveryMinDays, recoveryMaxDays, forageCondition, notes, createdAt, updatedAt
```
*Belongs in:* With surveys (survey_ratings write to this table on submit)

**input_applications + input_application_locations** — MERGED into amendments (Decision 7)
**DECIDED: No separate input_applications table.** There is no meaningful difference between "I applied an amendment" and "I applied a commercial input" — they're the same action from different sources. v2's amendments table (§4e) handles fertilizer, lime, manure, compost, and everything else applied to a paddock. The per-paddock location breakdown becomes a child table:

**amendment_locations** (new child table):
```
id, operationId, farmId, amendmentId, pastureId,
areaHa, nKg, pKg, kKg, costShare, createdAt, updatedAt
```
*Belongs in:* With amendments (§4e) — add amendment_locations as a child entity in the same section

**todos** — MISSING-LOW
In-app task list.
*v1 issues:* assigned_to is JSONB (should be junction table if multi-assign is real). paddock is text (should be FK to pastures).
*v2 recommendation:* If keeping, fix FKs and drop JSONB. But this is a standalone feature, not core grazing.
*Belongs in:* Separate CP or defer

**event_group_memberships** — MISSING-HIGH
Tracks which groups are on a grazing event and when they joined/left. This is one of two independent axes that drive NPK calculations (the animal axis).
*v1 issues:* group_name is a denormalized snapshot. head_snapshot and weight_snapshot are stored computed values.
**DECIDED:** Drop all snapshots (Decision 1). Head count and weight computed from group composition at that date. This table is a ledger — every time a group joins or leaves an event, a line is drawn for NPK recalculation.
*v2 FIELDS needed:*
```
id, operationId, farmId, eventId, groupId,
dateAdded, timeAdded, dateRemoved (nullable), timeRemoved (nullable),
createdAt, updatedAt
```
*Belongs in:* CP7-10 (event CRUD) — events MUST know which groups are grazing

**event_paddock_windows** — MISSING-HIGH
Tracks which paddocks are accessible during an event and their acreage. This is the second independent axis that drives NPK calculations (the acreage axis).
*v1 issues:* pasture_name is a denormalized snapshot.
**DECIDED:** Keep as a separate table from sub_moves (Decision 2). These are two different concepts: paddock_windows = "which gates are open" (acreage allocation), sub_moves = "where the cattle are" (location tracking). Both feed the NPK calculation engine — when either axis changes, a new calculation window is created. Drop pasture_name snapshot (Decision 1). Keep isPrimary.
*v2 FIELDS needed:*
```
id, operationId, farmId, eventId, pastureId,
isPrimary, areaHa, dateAdded, dateRemoved (nullable),
createdAt, updatedAt
```
*Belongs in:* CP7-10 (event CRUD)

---

### Tier 4 — Ledger & Derived Data (v1: 7 tables)

**event_feed_deliveries** — REPLACED (see Tier 3)

**event_feed_residual_checks** — SPEC'D (see Tier 3)

**event_npk_deposits** — DROPPED (computed, not stored)
The fertility ledger — N/P/K deposited on each paddock from grazing.
**DECIDED: Compute on demand, no Supabase table (Decision 5).** NPK deposits are derived from event_paddock_windows (acreage axis) and event_group_memberships (animal axis). The calculation engine reads both ledgers, finds every point where either changed, and computes NPK for each resulting time window. Always accurate, never stale.
*The calculation logic belongs in:* CP17 (fertility ledger) — as a JS computation module, not a database table

**harvest_event_fields** — MISSING-MED (see harvest_events in Tier 3)

**input_application_locations** — MISSING-LOW (see input_applications in Tier 3)

**manure_batch_transactions** — MISSING-MED
Ledger of manure collection and application events.
*v1 issues:* pasture_names is JSONB (should be proper FKs via application_locations). Stores NPK per transaction (could compute from batch NPK × volume).
*v2 best practice:* If manure tracking is kept, this is the ledger for manure batches (like event_feed_entries is for feed batches). Should follow the same ledger pattern.
```
id, operationId, farmId, manureBatchId,
type ('collection'|'application'), date,
volumeKg, sourceEventId (nullable), applicationId (nullable),
notes, createdAt, updatedAt
```
NPK per transaction computed from batch concentration × volume.
*Belongs in:* CP22 (manure module)

**batch_nutritional_profiles** — MISSING-LOW
Lab test results for feed batches.
*v1 schema is clean* — well-structured with standard forage analysis fields. Just needs uuid IDs (currently text), farmId, metric.
*v2 FIELDS needed:*
```
id, operationId, farmId, batchId, date, source ('lab'|'book_value'|'nir'),
dmPct, proteinPct, adfPct, ndfPct, tdnPct, rfv,
nPct, pPct, kPct, lab, notes, createdAt, updatedAt
```
*Belongs in:* CP20 (DMI calculations) or CP22

---

### System / Meta (v1: 3 tables + 1 not in tiers)

**operation_members** — MISSING-HIGH
Multi-user access control. v2's auth section (§8a) describes multi-user but doesn't spec the members table.
*v1 issues:* field_modules is JSONB (should be typed). email + invited_at + accepted_at is a homegrown invite system.
*v2 best practice:* Clean member table with proper role enum and individual permission columns.
```
id (uuid), operationId, userId (FK to auth.users), email,
displayName, role ('owner'|'manager'|'field_user'),
fieldMode (boolean), invitedAt, acceptedAt,
createdAt, updatedAt
```
Module permissions: either individual boolean columns (canViewFeed, canEditAnimals, etc.) or a permissions JSONB with defined schema. Individual columns are queryable and type-safe.
*Belongs in:* CP14 (auth/onboarding)

**release_notes** — MISSING-LOW
In-app changelog.
*v1 schema is fine.* JSONB for resolved_items is acceptable (display-only).
*Belongs in:* Anytime. Standalone feature.

**submissions** — REPLACED by feedback (§23b)
(See Tier 1.)

---

## Part 3: Summary — What the Architecture Doc Needs

### Tables that must be added to existing checkpoints (blocks current build)

| Table | Checkpoint | Why It Blocks |
|---|---|---|
| forage_types | CP11 (pastures) | Pastures reference forageTypeId — FK target doesn't exist |
| animal_classes | CP12 (animals) | Groups reference classId — FK target doesn't exist |
| event_group_memberships | CP7-10 (events) | Events can't track which groups are grazing (animal axis for NPK) |
| event_paddock_windows | CP7-10 (events) | Events can't track multi-paddock access (acreage axis for NPK) |
| settings columns on operations | CP1 or CP14 | App settings have no persistence mechanism (Decision 6: no separate table) |
| operation_members | CP14 (auth) | Multi-user auth described but no table |
| animal_group_memberships | CP12 (animals) | Can't track group composition over time |
| animal_group_class_compositions | CP12 (animals) | Can't track class-based herd composition |
| survey_ratings | With surveys | Bulk survey needs per-pasture child records (Decision 8) |

### Tables that should be added to later checkpoints

| Table | Suggested CP | Feature Area |
|---|---|---|
| animal_bcs_scores | CP17 or new | Body condition scoring (Decision 4: split health table) |
| animal_treatments | CP17 or new | Treatment records (Decision 4) |
| animal_breeding_records | CP17 or new | Breeding records (Decision 4) |
| animal_calving_records | CP17 or new | Calving records (Decision 4) |
| animal_weight_records | CP17 or new | Weight tracking / ADG |
| harvest_events + harvest_fields | CP19 | Hay harvest |
| soil_tests | CP22 | Soil health |
| amendment_locations | With amendments | Per-paddock breakdown (Decision 7: merged with amendments) |
| manure_batches + manure_batch_transactions | CP22 | Manure cycle |
| batch_nutritional_profiles | CP20 or CP22 | Feed quality lab results |
| paddock_observations | With surveys | Unified observation table (Decision 3: merged with surveys) |
| treatment_types | with health module | Reference data |
| input_products | with amendments | Reference data (Decision 7: no separate input module) |
| ai_bulls | with breeding module | Reference data |

### Tables that can be deferred or dropped

| Table | Recommendation |
|---|---|
| submissions | Replaced by feedback — drop |
| release_notes | Defer — standalone, add anytime |
| todos | Defer — standalone, not core grazing |
| event_npk_deposits | Drop as stored table — compute on demand (Decision 5) |
| input_applications | Drop — merged into amendments (Decision 7) |
| input_application_locations | Drop — replaced by amendment_locations (Decision 7) |

### Design Decisions — All Resolved

1. **Denormalized name snapshots** — **DROP.** Link by FK only. Display resolved from entity cache. Parent-child linked by IDs the user never sees.
2. **event_paddock_windows vs sub_moves** — **KEEP BOTH.** Two independent axes of the same NPK calculation. Paddock windows = acreage axis (which land). Group memberships = animal axis (which herds). Changes to either draw a line for recalculation.
3. **paddock_observations vs surveys** — **MERGE** into one paddock_observations table with a source field. Same data from different input contexts. Calculation engine looks in one place.
4. **animal_health mega-table** — **SPLIT** into separate tables per type (BCS, treatments, breeding, calving). Users focus on different things at different times.
5. **NPK deposits** — **COMPUTE ON DEMAND.** No stored table. Derived from paddock_windows × group_memberships. Always accurate.
6. **operation_settings** — **COLUMNS ON OPERATIONS TABLE.** Operations is the parent; settings are its attributes. No separate table, no JSONB blob.
7. **input_applications vs amendments** — **MERGE.** No difference between an amendment and a commercial input. v2's amendments table covers all. Add amendment_locations child table for per-paddock breakdown.
8. **survey_ratings child table** — **YES.** Survey is parent event, each pasture rating is a child record. Linked to both survey and pasture. On submit, ratings become paddock_observations.

---

## Part 4: v2 Convention Checklist (for every new table)

When adding any of the above tables to the v2 architecture doc, each must follow these established conventions:

| Convention | Rule | Source |
|---|---|---|
| ID type | `uuid` via `crypto.randomUUID()` | §4c |
| ID column | `id uuid PRIMARY KEY DEFAULT gen_random_uuid()` | §4c |
| Scoping | Every table has `operation_id uuid NOT NULL` and `farm_id uuid NOT NULL` | §8a/§8b |
| Timestamps | `created_at timestamptz DEFAULT now()`, `updated_at timestamptz DEFAULT now()` | §4e pattern |
| FK type | Always `uuid` matching parent's ID type | §4c |
| JS naming | camelCase fields in FIELDS object | §4e |
| SQL naming | snake_case columns via sbColumn mapping | §4e |
| Units | Metric internal (kg, cm, ha) — display layer converts | §4e |
| FIELDS object | Every entity gets `[TABLE]_FIELDS` with type, required, sbColumn | §4e |
| Helper functions | `create()`, `validate()`, `toSupabaseShape()`, `fromSupabaseShape()` | §4e |
| Soft delete | `archived boolean DEFAULT false` (setup entities only) | §4e |
| Source tracking | `source ('manual'|'voice')` where applicable | §4e |
| No stored computed values | Compute on read, don't store derived data | v2 principle (Decision 5) |
| No denormalized names | Use FK lookups, not name snapshots | v2 principle (Decision 1) |
| No JSONB bags for structured data | Use child tables or typed columns, not JSONB blobs | v2 principle (Decisions 6, 8) |
| One table per concept | Don't cram multiple record types into one wide table | v2 principle (Decision 4) |
| Settings on parent | Operation settings go as columns on operations, not a separate table | Decision 6 |
| CASCADE on children | Child tables CASCADE delete when parent is deleted | §4f |
| RLS | Row-level security via operation_id | §8a |
