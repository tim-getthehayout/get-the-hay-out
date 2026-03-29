# Get The Hay Out — Living Architecture Map
**File:** `get-the-hay-out.html` (~14,532 lines · ~724KB · single-file PWA)
**Deploy:** `deploy.py` → GitHub Pages → getthehayout.com
**Current build:** `b20260329.2150`
**Last updated:** 2026-03-29

> This is the authoritative navigation guide for every AI coding session.
> Update it at the end of every session using the SESSION_RULES.md protocol.

---

## Build Versioning

**Format:** `bYYYYMMDD.HHMM` — e.g. `b20260322.0942`

**Location in file:** Line 8 — `<meta name="app-version" content="b20260322.1353" id="app-version-meta"/>`

**Rule:** Every time an updated HTML file is delivered to the user, the build stamp **must** be bumped to the current date and time (24hr local). Generate with:
```python
from datetime import datetime
build = 'b' + datetime.now().strftime('%Y%m%d') + '.' + datetime.now().strftime('%H%M')
```

**`S.settings.homeViewMode`** — `'groups'` (default) or `'locations'`. Persisted. Controls home screen view. Toggle via `setHomeViewMode(mode)` → `save()` → `renderHome()`.

**Version is read from the meta tag at runtime** — not from `S.version`. The `S.version` field is legacy and unreliable. All version references in feedback items, error logs, and the dev brief pull from `document.getElementById('app-version-meta').getAttribute('content')`.

---

## File Structure Overview

| Line Range | Section |
|---|---|
| 1–460 | `<head>`: meta, PWA manifest (line 8 = build stamp), inline `<style>` CSS; Supabase JS SDK CDN tag (line ~478, M1) |
| 461–526 | `<body>`: desktop sidebar nav (220px fixed, IDs: `#dbn-*`) |
| 527–1367 | Screen divs (`#s-home` through `#s-settings`) + mobile bottom nav (`#bn-*`) |
| 1368–1452 | Global sheet overlays always in DOM: `#fb-sheet-wrap`, `#resolve-sheet-wrap`, `#todo-sheet-wrap` |
| 1453 | `<script>` tag + JS Section TOC comment block |
| ~1533 | App Update Banner |
| ~1594 | Data init (`S` object), localStorage keys, save helpers |
| ~1682 | **Supabase M3 write path:** `_sbToSnake`, `_pastureRow`, shape functions (`_animalRow`, `_batchRow`, `_feedTypeRow`, `_animalClassRow`, `_animalGroupRow`, `_aiBullRow`, `_inputProductRow`, `_todoRow`, `_treatmentTypeRow`, `_animalGroupMembershipRow`, `_animalWeightRecordRow`, `_manureBatchTransactionRow`), `queueWrite`, `queueEventWrite`, `flushToSupabase`, `supabaseSyncDebounced`, `setSyncStatus` |
| ~1745 | **Supabase auth (M1):** `SUPABASE_URL`, `SUPABASE_KEY` constants; `_sbClient`, `_sbSession` module vars; `sbInitClient()`, `sbSignIn()`, `sbSignOut()`, `sbUpdateAuthUI()` |
| ~1984 | Export / Import JSON (including `importDataJSON` full-replace + Drive force-write) |
| ~2138 | Nav routing |
| ~2164 | User system |
| ~2238 | Desktop dashboard header + Mobile perf strip |
> **Header layout (b20260324.1030):** Mobile uses `flex-direction:column` — title/op-name on row 1, sync/build/field/avatar on row 2. Desktop overrides back to single-row via `body.desktop .hdr`. Op name in `updateHeader()` shows operation name only — head count removed.
| ~2532 | Home screen + group cards + `renderFieldHome()` stub (field mode) |
| ~2627 | Home view toggle (`renderHomeViewToggle`, `setHomeViewMode`) + Locations view (`renderLocationsView`, `renderLocationCard`, `renderUnplacedGroupsSection`) |
> **Home card DMI/NPK (b20260324.1730):** `renderLocationCard()` now shows event-level DMI total across all groups (sum of `getGroupTotals().dmiTarget`) + stored-vs-pasture split + progress bar + NPK. BW aggregation corrected — uses `getGroupTotals()` per group, not `ae.head * ae.wt` (event snapshot). `renderGroupCard()` NPK fixed — uses group's own `getGroupTotals()` head/weight (`grpBW`), not `ae.head * ae.wt` which was the whole-event aggregate.
> **Quick Feed picker (b20260324.1730):** `qfShowEventStep()` is now location-centric — shows location name + type badge as primary, group names as secondary. Cancel button (`#qf-step1-cancel`) added to step-1 picker, hidden on step-2.
| ~2921 | To-Do system |
| ~3070 | Feed screen + Quick Feed sheet + Feed Types + Feed Goal + goFeedGroup |
| ~3417 | Move Wizard (including `wizCloseEvent` TDZ fix, `wizSaveNew` location fix, no-pasture checkbox, dynamic recovery label) |
| ~3549 | Events section header + `switchEventsView()` + Rotation Calendar engine |
| ~4212 | Pasture Survey |
> **Pasture Survey (b20260325.1918):** Both multi-pasture and single-pasture survey modes now render all fields consolidated per card — forage quality slider, veg height (inches), forage cover (%), and recovery min/max with live graze window preview. Multi-pasture previously split rating cards and recovery windows into separate scrollable sections; these are now a single per-paddock card. Two new state dicts: `surveyVegHeight`, `surveyForageCover`. Data model: each rating entry in `S.surveys[].ratings[]` now includes optional `vegHeight` (inches, float) and `forageCover` (%, float). The separate `#survey-recovery-list` DOM element and `#survey-recovery-section-hdr` are retained in HTML but set to empty/hidden at render time. OI-0010 (expected graze dates) resolved — the live `rec-preview-` block in each card supersedes the old static `gdHtml` approach.
| ~4780 | Multi-paddock wizard helpers + Event Edit multi-paddock |
| ~5347 | Treatment Types, AI Bulls, Manage sheets (classes/treatments/sires) + `TREATMENT_CATEGORIES` |
| ~5598 | Batch Adjustment / Reconcile |
| ~5805 | **`renderEventsLog()`** ← displaced here by Batch Adj insertion; logically part of Events section above. Now renders consolidated parent + sub-move thread (OI-0029, b20260329.1751) |
| ~5954 | Pastures screen + recovery date helpers |
| ~6030 | Settings screen — includes Sync queue inspector card (`renderSyncQueueInspector`, `exportSyncQueue`) |
| ~6222 | Feedback tab + Dev Brief + Export CSV |
| ~6432 | Manure system |
| ~6532 | Animal Classes & Groups + Add/Edit Group sheet + Animal Health Events |
| ~7579 | Individual Animals (add/edit/cull) |
| ~7969 | Add/Edit Group sheet (`openAddGroupSheet`, `openEditGroupSheet`, `closeAddGroupSheet`) |
| ~8311 | Setup Template Export / Import (XLSX) |
| ~8797 | Stats Engine |
| ~8901 | Calving sheet |
| ~9030 | Sub-move system (`openSubMoveSheet`, `saveSubMove`, `calcEventTotalsWithSubMoves`, `lastGrazingRecordForPasture`) |
| ~9830 | Per-paddock attribution engine (`feedDMIPutOutToDate`, `calcGrassDMIByWindow`, `calcSubMoveNPKByAcres`) |
| ~9634 | Input Products & Applications |
| ~9875 | Cull system + Reset data |
| ~9963 | Historical Events Import |
| ~10262 | Error log |
| ~10320 | Event Edit sheet + Recalculate totals + NPK recalc |
| ~10830 | Animals screen + Animal move sheet + DMI Variance |
| ~11203 | Multi-paddock helpers, Archive/ID system, Sort helpers, Responsive mode (`detectMode`), **Field mode** (`applyFieldMode`, `toggleFieldMode`, `setFieldModeUI`) |
| ~11653 | **Weaning system** (`normalizeSpecies`, `birthTermForSpecies`, `computeWeanTargetDate`, `daysUntilDate`, `migrateWeaningFields`, `renderWeaningDashboard`, `renderWeaningNudge`, `weanToggleFilter`, `weanToggleCheck`, `markAnimalsWeanedFromDashboard`) |
| ~14205 | Reports screen + **`renderRotationCalendar()`** (shared — also called by Events screen; **actual location ~L14205** as of b20260329.1708) |
| ~12796 | App init (top-level bootstrap, not DOMContentLoaded) |
| ~12840 | All sheet HTML (spread manure → batch adj; last sheet ~L14300) |
| ~13778 | Service Worker registration |

---

## Screen → Render Function Map

| Screen | DOM ID | Authoritative Render Function | Nav Button IDs |
|---|---|---|---|
| `home` | `#s-home` | `renderHome()` → branches on `S.settings.homeViewMode` (`groups` or `locations`) | `#bn-home` `#dbn-home` |
| `feed` | `#s-feed` | `renderFeedScreen()` → `renderFeedOverview()` | `#bn-feed` `#dbn-feed` |
| `animals` | `#s-animals` | **`renderAnimalsScreen()`** ◄ AUTHORITATIVE | `#bn-animals` `#dbn-animals` |
| `events` | `#s-events` | `renderEventsLog()` (~L5805) or `renderRotationCalendar()` (~L14205) | `#bn-events` `#dbn-events` |
| `todos` | `#s-todos` | `renderTodos()` | `#bn-todos` `#dbn-todos` |
| `pastures` | `#s-pastures` | `renderPastures()` | `#bn-pastures` `#dbn-pastures` |
| `feedback` | `#s-feedback` | `renderFeedbackTab()` | `#bn-feedback` `#dbn-feedback` |
| `reports` | `#s-reports` | `renderReportsScreen()` | `#dbn-reports` (desktop only) |

**Reports tabs (RPT_TABS):** `rotation` · `npk` · `feed` · `animals` · `summary` · `survey` · `weaning`

**⚠️ renderRotationCalendar is a shared function:** It lives at ~L14205 (in the Reports section) but is called by both the Events screen (`switchEventsView`) and the Reports screen (`renderReportsScreen`). It takes a `containerId` argument — `'rotation-calendar'` for the events tab, container IDs for reports. If you're working on the calendar render, edit the function at L14205 — not a non-existent copy near the Events section header.

**Weaning system data model** (as of b20260322.2021):
- `animal.birthDate: ISO string | null` — set by `saveCalving()`, `saveAnimalEdit()`, or migrated from dam's `calvingRecords`
- `animal.weaned: bool | null` — `null` = unknown (pre-existing animals); `false` = not yet weaned; `true` = weaned
- `animal.weanTargetDate: ISO string | null` — computed from `birthDate + weanTargetDays(species)`
- `animal.weanedDate: ISO string | null` — date user marked animal weaned
- `S.settings.weanTargets: { cattle, sheep, goat }` — days from birth, defaults 205/60/60
- Species mapping: `normalizeSpecies(str)` → `'cattle'|'sheep'|'goat'|'pig'|'other'`
- `migrateWeaningFields()` — runs at init; backfills missing fields; derives `birthDate` from dam's `calvingRecords` when absent
| `settings` | `#s-settings` | `loadSettings()` + `renderUsersList()` + `renderClassesList()` + `renderGroupsList()` + `renderGrpAnimalPicker()` | `#bn-settings` `#dbn-settings` |

**⚠️ Screen div nesting — critical rule:** All `.scr` divs must be direct siblings at the same DOM depth inside `.app`. A missing `</div>` closing any screen before the next one opens will cause every subsequent screen to be nested inside the unclosed one — making them invisible when the parent is inactive. Confirmed failure mode: see b20260322.1135 fix below.

**⚠️ Events screen function displacement:** `renderEventsLog()` is physically at ~L5805, not near the `// ─── EVENTS ───` section header (~L3549). The Batch Adjustment / Reconcile section (~L5598–5803) was inserted between `switchEventsView()` and `renderEventsLog()`, pushing the render function ~2250 lines past its section header. If editing the events log render, search for `function renderEventsLog` — do not assume it's near the Events section header.

---

## Sheet Overlay Map

All sheets are always in the DOM. Toggle: add/remove `.open` on the `-wrap` div. Backdrop click calls close function.

| Sheet Purpose | Wrap ID | Open Function | Close Function |
|---|---|---|---|
| User picker | `#user-picker-wrap` | `openUserPicker()` | `closeUserPicker()` |
| Submit feedback | `#fb-sheet-wrap` | `openFeedbackSheet()` | `closeFeedbackSheet()` |
| Resolve feedback | `#resolve-sheet-wrap` | `openResolveSheet(id)` | `closeResolveSheet()` |
| To-do add/edit | `#todo-sheet-wrap` | `openTodoSheet(id)` | `closeTodoSheet()` |
| Quick feed | `#quick-feed-wrap` | `openQuickFeedSheet(groupId)` | `closeQuickFeedSheet()` |
| Feed types config | `#feed-types-wrap` | `openFeedTypesSheet()` | `closeFeedTypesSheet()` |
| Feed day goal | `#feed-goal-wrap` | `openFeedGoalSheet()` | `closeFeedGoalSheet()` |
| Location add/edit | `#loc-edit-wrap` | `openAddLocation()` / `openLocEdit(idx)` | `closeLocEdit()` |
| Animal add/edit | `#ae-sheet-wrap` | `openNewAnimalSheet()` / `openAnimalEdit(id)` | `closeAnimalEdit()` |
| Animal event (note/treatment/breeding) | `#animal-event-wrap` | `openAnimalEventSheet(id, type, editId)` | `closeAnimalEventSheet()` |
| Animal move/split | `#animal-move-wrap` | `openAnimalMoveSheet(mode)` | `closeAnimalMoveSheet()` |
| **Add/edit animal group** | `#add-group-wrap` | **`openAddGroupSheet()`** / **`openEditGroupSheet(id)`** | **`closeAddGroupSheet()`** |
| Manage animal classes | `#manage-classes-wrap` | `openManageClassesSheet()` | `closeManageClassesSheet()` |
| Manage treatment types | `#manage-treatments-wrap` | `openManageTreatmentTypesSheet()` | `closeManageTreatmentTypesSheet()` |
| Manage AI sires | `#manage-ai-bulls-wrap` | `openManageAIBullsSheet()` | `closeManageAIBullsSheet()` |
| Batch adjust/reconcile | `#batch-adj-wrap` | `openBatchAdjSheet(batchId, mode)` | `closeBatchAdjSheet()` |
| Pasture survey | `#survey-sheet-wrap` | `openSurveySheet(pastureId)` | `closeSurveySheet()` |
| Event edit | `#event-edit-wrap` | `openEventEdit(eventId)` | `closeEventEdit()` | **Rebuilt b20260328.0140.** New layout: active paddocks block (`#ee-active-paddocks`) → closed chips (`#ee-paddock-chips`) → add selector. Feed checks section (`#ee-feed-checks-section`) revealed on noPasture. Anchor close button (`#ee-close-event-btn-wrap`) open events only. |
| Spread manure | `#spread-sheet-wrap` | `openSpreadSheet()` | `closeSpreadSheet()` |
| Apply input product | `#apply-input-wrap` | `openApplyInputSheet()` | `closeApplyInputSheet()` |
| Split group | `#split-sheet-wrap` | `openSplitSheet(groupId)` | `closeSplitSheet()` |
| Group weight | `#wt-sheet-wrap` | `openWtSheet(groupId)` | `closeWtSheet()` |
| Calving | `#calving-sheet-wrap` | `openCalvingSheet()` | `closeCalvingSheet()` |
| Sub-move | `#sm-sheet-wrap` | `openSubMoveSheet(eventId)` | `closeSubMoveSheet()` |
| Cull animal | `#cull-sheet-wrap` | `openCullSheet(animalId)` | `closeCullSheet()` |
| Reset data | `#reset-sheet-wrap` | `openResetSheet(mode)` | `closeResetSheet()` |

---

## Data Model (`S` — persisted to `localStorage['gthy']`)

| Key | Type | Description |
|---|---|---|
| `S.pastures` | Array | All locations. `locationType`: `"pasture"` or `"confinement"` |
| `S.events` | Array | Grazing events (open + closed). Core ledger. Contains `feedEntries[]` sub-records. Each event now carries `groups[]` array (group entries with `groupId`, `groupName`, `dateAdded`, `dateRemoved`). Legacy `groupId` scalar kept for backward compat — always equals `groups[0].groupId`. |
| `S.feedTypes` | Array | Feed type templates (unit, DM%, category). **M0b-J:** optional `nPct`, `pPct`, `kPct` fields (hay analysis — from lab test). Null when not provided; degrades gracefully. Displayed as `N/P/K` badge in Feed Types sheet when set. |
| `S.batches` | Array | Feed batches (specific deliveries; `typeId` links to feedType) |
| `S.manureBatches` | Array | Manure batches captured from confinement events |
| `S.inputProducts` | Array | Commercial amendment products |
| `S.inputApplications` | Array | Records of input products applied to pastures |
| `S.animalClasses` | Array | Species/class definitions (default weight, DMI%) |
| `S.animalGroups` | Array | Named herd compositions. Fields: `id`, `name`, `color`, `animalIds[]`, `classes[]`, `archived` |
| `S.animals` | Array | Individual animal records |
| `S.users` | Array | Farm users (name, color, avatar) |
| `S.todos` | Array | Farm task records |
| `S.feedback` | Array | In-app feedback items |
| `S.surveys` | Array | Pasture survey ratings |
| `S.treatmentTypes` | Array | Treatment type templates. Each record: `id`, `name`, `category` (one of `TREATMENT_CATEGORIES`), `archived` |
| `S.aiBulls` | Array | AI sire records |
| `S.paddockObservations` | Array | **M0a-C** Unified paddock condition log. Every event open/close, sub-move open/close, and survey write appends here. Entry shape: `{id, pastureId, pastureName, observedAt, source, sourceId, confidenceRank, vegHeight, forageCoverPct, forageQuality, recoveryMinDays, recoveryMaxDays, notes}`. Sources: `event_open`(rank 1), `event_close`(2), `sub_move_open`(1), `sub_move_close`(2), `survey`(3). Used by `lastGrazingRecordForPasture()` as primary lookup. |
| `S.animalWeightRecords` | Array | **M0b-F** Top-level weight time series. Entry: `{id, animalId, recordedAt, weightLbs, note, source}`. Sources: `'manual'`, `'group_update'`, `'import'`. Backfilled from `animal.weightHistory[]` at init. Written by `_recordAnimalWeight()`. `animal.weightHistory[]` kept in sync for backward compat. |
| `S.animalGroupMemberships` | Array | **M0b-G** Top-level group membership ledger. Entry: `{id, animalId, groupId, dateJoined, dateLeft}`. Open rows have `dateLeft:null`. Backfilled from `group.animalIds[]` at init (historical rows have `dateJoined:null`). Written by `_openGroupMembership()` / `_closeGroupMembership()` at every add/move/cull/delete. `animalIds[]` kept in sync for backward compat. |
| `S.inputApplicationLocations` | Array | **M0b-H** Top-level amendment location ledger. Entry: `{id, applicationId, pastureId, pastureName, acres, nLbs, pLbs, kLbs, costShare}`. Backfilled from `inputApplication.locations[]` at init. Written by `saveApplyInput()`. Enables unified NPK query: `event_npk_deposits UNION ALL input_application_locations`. |
| `S.manureBatchTransactions` | Array | **M0b-I** Top-level manure batch transaction ledger. Entry: `{id, batchId, type, date, volumeLbs, nLbs, pLbs, kLbs, sourceEventId, applicationId, pastureNames, notes}`. Types: `'input'` (from confinement event), `'application'` (spread). Backfilled from `manureBatch.events[]` at init. Written by `addToManureBatch()` and `saveApplyInput()`. `getBatchRemaining()` still reads `batch.events[]` for now — will switch to transactions at M4. |
| `S.herd` | Object | Legacy herd summary — superseded by `animalGroups`. Do not rely on for head count. |
| `S.settings` | Object | All settings — see sub-fields below |
| `S.errorLog` | Array | Client-side error log (capped at 200 entries) |
| `S.setupUpdatedAt` | String | ISO timestamp bumped by `stampSetup()` on every config change — used by Drive merge to prefer newer side wholesale |
| `S.testerName` | String | Tester/farmer name used for feedback attribution. Set in Settings. |
| `S.version` | String | Legacy field — initialized to `'v1.2'` but not used. Authoritative version always comes from the HTML meta tag at runtime. Do not read or write. |

**`ev` (event record) sub-fields added in M0a/M0b:**

| Field | Type | Description |
|---|---|---|
| `ev.feedResidualChecks` | Array | **M0a-A / M0b-L** Series of residual readings. Entry: `{id, date, residualPct, balesRemainingPct, notes, isCloseReading}`. `isCloseReading:true` marks the final entry written at event/sub-move close — the one used for OM attribution. Intermediate checkpoint entries have `isCloseReading:false`. Written at event close and sub-move close. `getEffectiveFeedResidual(ev)` reads last entry; falls back to scalar `ev.feedResidual` for pre-M0a data. |
| `ev.npkLedger` | Array | **M0a-B / M0b-K** NPK deposits stored at period boundaries. Entry: `{id, paddockName, pastureId, periodStart, periodEnd, head, avgWeight, days, acres, nLbs, pLbs, kLbs, source, dmLbsDeposited?}`. `source`: `'livestock_excretion'` or `'feed_residual'`. Feed residual entries additionally carry `dmLbsDeposited` (lbs DM left behind). Written at `wizCloseEvent`. Enables M4 migration script to import real NPK history. |
| `ev.feedResidual` | Number | **Derived display cache** — scalar residual %. Still written for backward compat (CSV, display). Source of truth is `feedResidualChecks[]`. Do not use for DMI computation — use `getEffectiveFeedResidual(ev)`. |
| `ev.forageCoverIn` | Number | **New b20260328.0119** Optional pre-graze forage cover % (0–100). Set via event edit form slider+number. Written to `paddock_observations` as `forageCoverPct` on event_open when present. |
| `ev.forageCoverOut` | Number | **New b20260328.0119** Optional post-graze forage cover % (0–100). Set via event edit form. Written to `paddock_observations` as `forageCoverPct` on event_close. |

**`pasture` record derived-state fields:**

| Field | Note |
|---|---|
| `pasture.recoveryMinDays` / `pasture.recoveryMaxDays` | **Display-only cache.** Written as a fast-lookup proxy by `saveSmClose()` and `saveSurvey()`. Source of truth is `S.paddockObservations` — `lastGrazingRecordForPasture()` queries observations first. The M4 migration script will skip these fields; Supabase derives recovery windows from `paddock_observations` via `paddock_current_condition` view. |

**`S.settings` sub-fields:**

| Sub-field | Default | Description |
|---|---|---|
| `nPrice` / `pPrice` / `kPrice` | 0.55 / 0.65 / 0.42 | Fertilizer prices ($/lb) for NPK value calc |
| `nExc` / `pExc` / `kExc` | 0.32 / 0.09 / 0.30 | Excretion rates (fraction of body weight/1000/day) |
| `manureVolumeRate` | 65 | Gallons per animal unit day (manure volume calc) |
| `manureLoadLbs` | 8000 | Pounds per spreader load |
| `manureVolumeUnit` | `'loads'` | Display unit: `'loads'` or `'gallons'` |
| `homeStats` | `['pasture_dmi','feed_cost','pasture_pct','npk_lbs_acre','npk_val_acre']` | Ordered list of stat tiles to show on home screen |
| `homeStatPeriod` | `'7d'` | Rolling period for home stat calculations |
| `homeViewMode` | `'groups'` | Home screen layout: `'groups'` or `'locations'` |
| `auWeight` | 1000 | Animal Unit reference weight (lbs) for AUD calculations |
| `recoveryRequired` | `false` | If true, warn when moving to a paddock that hasn't met recovery minimum |
| `recoveryMinDays` | 30 | Default recovery minimum days (used when no pasture-specific value set) |
| `recoveryMaxDays` | 60 | Default recovery maximum days |
| `thresholds` | `{}` | Per-metric threshold object for home stat color coding |
| `feedDayGoal` | 90 (default via `\|\| 90`) | Target days of feed on hand; drives feed screen progress bar |
| `weanTargets` | `{ cattle: 205, sheep: 60, goat: 60 }` | Per-species wean target days from birth |

**Other localStorage keys:**
- `gthy-sync-queue` → Supabase offline write queue (array of `{table, record}` ops)
- `gthy-user` → Active user ID

---

## Key Utility Functions

| Function | Purpose |
|---|---|
| `save()` | **Always use this.** Saves to localStorage AND triggers Supabase sync debounce (when signed in). Never call `saveLocal()` directly except in the restore flow. |
| `saveLocal()` | Saves to localStorage only. Used in `importDataJSON` restore to avoid triggering Drive merge. |
| `stampSetup()` | Call whenever a config array (pastures, feedTypes, animalGroups, animalClasses, inputProducts) is modified. Updates `S.setupUpdatedAt` so Drive merge picks the newer side. |
| `calcConsumedDMI(entries, resid)` | Core DMI calc — residual % applied to last entry only |
| `getEffectiveFeedResidual(evOrSm)` | **M0a-A** Returns final residual % from `feedResidualChecks[]` last entry, or falls back to scalar `feedResidual`. Use this everywhere DMI is computed — never read `ev.feedResidual` directly for computation. |
| `_writePaddockObservation(obs)` | **M0a-C** Appends one observation to `S.paddockObservations[]`. Deduplicates by `source + sourceId + pastureId` so re-saves are idempotent. |
| `calcNPK(head, wt, days)` | NPK deposit calculation |
| `calcEntryCost(entries)` | Feed cost total from batch entries |
| `nav(screen, btn)` | Navigate to screen, update active nav state |
| `renderCurrentScreen()` | Master screen router — call after every nav change or data restore |
| `evPaddocks(ev)` | Returns paddock records for an event (handles old string format + new paddocks[] array) |
| `evGroups(ev)` | Returns `ev.groups[]` or synthesises single-entry array from legacy `ev.groupId`. Every group lookup goes through this — never read `ev.groupId` directly. |
| `evGroupsDisplay(ev, maxChars)` | Returns display string for groups: "Cow herd", "Cow herd + Yearlings", or "Multiple" if over character limit. |
| `migrateToGroupsField()` | One-time migration: backfills `ev.groups[]` for events that only carry the old `ev.groupId` scalar. Called at init alongside `migrateToPaddocksField()`. |
| `migrateM0aData()` | **M0a/M0b** Backfills all M0 top-level arrays from embedded legacy data. Runs at init; dedup-guarded (safe to run multiple times). Backfills: `feedResidualChecks[]` (A+L, with `isCloseReading:true`), `npkLedger[]` (B+K, with `source:'livestock_excretion'`), `paddockObservations[]` (C), `animalWeightRecords[]` (F), `animalGroupMemberships[]` (G), `inputApplicationLocations[]` (H), `manureBatchTransactions[]` (I). |
| `_recordAnimalWeight(a, date, wt, note, source)` | **M0b-F** Writes to both `animal.weightHistory[]` (legacy read compat) and `S.animalWeightRecords[]`. Use this everywhere a weight is recorded — never push to `weightHistory[]` directly. Sources: `'manual'`, `'group_update'`, `'import'`. |
| `_openGroupMembership(animalId, groupId, dateJoined)` | **M0b-G** Opens a new membership row in `S.animalGroupMemberships[]`. Skips if an open row already exists for this animal+group. `dateJoined` null = historical/unknown. |
| `_closeGroupMembership(animalId, groupId, dateLeft)` | **M0b-G** Closes the open membership row for an animal leaving a group. No-op if no open row found. Called at cull, delete, group edit, and all move operations. |
| `initEeGroups(ev)` | Initialises `eeGroups[]` working copy for event edit sheet from `evGroups(ev)`. Parallel to `initEePaddocks`. |
| `renderEeActivePaddocks()` | **b20260328.0140** Renders the active paddocks block in event edit: anchor + active additional paddocks as color-coded cards, plus active sub-moves with "Record return". Each card has an expandable inline close form. State vars: `eePaddockCloseIdx` (index of card showing form), `eePaddockJustClosed` (close details for "next paddock" shortcut). |
| `openEePaddockClose(idx)` / `saveEePaddockClose(idx)` / `cancelEePaddockClose()` | **b20260328.0140** Inline close form lifecycle. Save writes `dateRemoved`, `timeRemoved`, `forageCoverOut`, `recoveryMinDays`, `recoveryMaxDays`, `feedResidualPct` onto `eePaddocks[idx]`. After save, triggers "Open next paddock" shortcut. |
| `addEeNextPaddock()` / `dismissEeNextPaddock()` | **b20260328.0140** "Open next paddock" shortcut — adds selected paddock to `eePaddocks[]` with `dateAdded` pre-filled from just-closed paddock's close date. |
| `renderEeFeedChecks(ev)` | **b20260328.0140** Renders intermediate feed checkpoint list in event edit. Shows `ev.feedResidualChecks[]` entries with `isCloseReading:false`. |
| `openEeFeedCheck()` / `editEeFeedCheck(ckId)` / `saveEeFeedCheck()` / `deleteEeFeedCheck(ckId)` / `closeEeFeedCheck()` | **b20260328.0140** CRUD for intermediate feed residual checkpoints in event edit. Saves to `ev.feedResidualChecks[]` with `isCloseReading:false`. These drive `calcGrassDMIByWindow()`. |
| `sbInitClient()` | **M1/M2** Creates `_sbClient` via `supabase.createClient()`. Registers `onAuthStateChange` listener — on `SIGNED_IN` or `INITIAL_SESSION` triggers M2 load chain: `sbGetOperationId()` → `loadFromSupabase()` → `subscribeRealtime()`. On `SIGNED_OUT` clears operation cache and re-renders. |
| `sbSignIn(email)` | **M1** Sends magic link via `_sbClient.auth.signInWithOtp()`. Email from `#sb-email-input` or direct param. Shows inline confirmation on success. |
| `sbSignOut()` | **M1** Calls `_sbClient.auth.signOut()`, clears `_sbSession`, calls `sbUpdateAuthUI()`. |
| `sbUpdateAuthUI()` | **M1** Toggles `#sb-signed-out` / `#sb-signed-in` based on `_sbSession`. Populates `#sb-user-email`. Called from auth listener, `loadSettings()`, Settings nav handler, `sbSignOut()`. |
| `openAnimalTodoSheet(animalId)` | **b20260328.0157** Opens the todo sheet pre-linked to a specific animal. Thin wrapper around `openTodoSheet(null, false, animalId)`. Called from the 📋 Todo button on each animal row in `renderAnimalsScreen()`. |
| `openEeAnchorClose()` / `cancelEeAnchorClose()` | **b20260328.0140** Anchor close sequence. Reveals pre-flight checklist block (`#ee-anchor-close-wrap`) with step completion indicators. |
| `saveAndCloseFromEdit()` | **b20260328.0140** Saves event edit then calls `moveAllGroupsInEvent(evId)` via 100ms timeout to launch Move Wizard for all active groups. |
| `addEeGroup()` | Adds a group to `eeGroups[]` with `_isNew:true`. Calls `syncEeGroupTotals()`. |
| `startMoveGroup(idx)` | Initiates departure for a saved-active group: sets `dateRemoved` to today and `_moveAction = 'picking'` to show destination selector. Primary-group (idx===0) is protected. Replaces the `closeGroup()` name documented in earlier sessions — that function does not exist. |
| `setMoveGroupExisting(idx, targetEvId)` | Sets `_moveAction = 'existing'` and records the target event ID for post-save attachment. |
| `setMoveGroupWizard(idx)` | Sets `_moveAction = 'wizard'` so the wizard opens for this group after event save. |
| `cancelGroupMove(idx)` | Clears `dateRemoved` and all `_moveAction` state for a group in the edit sheet. |
| `reopenGroup(idx)` | Clears `dateRemoved` and all move state on `eeGroups[idx]`. Parallel to `reopenPaddock`. |
| `renderEeGroupChips()` | Renders group chips with four states: primary (locked), unsaved (×), saved-active (Remove Group button), saved-closed (Reopen button). |
| `syncEeGroupTotals()` | Aggregates head count and weighted-average weight from all active `eeGroups` entries and writes them to the `ee-head` / `ee-wt` form fields. Implements Path B auto-sum. |
| `applyEeGroupsToEvent(ev)` | Strips `_isNew`, writes `ev.groups[]`, updates legacy `ev.groupId` to `groups[0].groupId`. |
| `toggleWizGroup(gId)` | Toggles a group in/out of `wizGroupIds[]` array; re-renders the group selector. |
| `initWizFromGroups()` | Aggregates head/wt from all `wizGroupIds` groups; finds active event for any selected group; navigates to wizard step 0. Replaces `initWizFromGroup()` (kept as alias). |
| `closePaddock(idx)` | Sets `dateRemoved` on `eePaddocks[idx]` to today; re-renders chips. Called from "Close Paddock" button in Event Edit sheet. |
| `reopenPaddock(idx)` | Clears `dateRemoved` on `eePaddocks[idx]`; re-renders chips. Called from "Reopen" button. |
| `removeEePaddock(name)` | Discards a session-only (`_isNew`) paddock addition. Guard prevents removal of committed paddock entries. |
| `evMatchesPasture(ev, name, id)` | Match event to pasture by name or ID |
| `sortedPastures(includeArchived)` | Filtered + sorted pasture list |
| `sortedGroups(includeArchived)` | Filtered + sorted group list |
| `sortedAnimals(arr)` | Sorted animal list |
| `mergeData(local, remote)` | Drive sync merge — union arrays by `id`, prefer newer. **NOT used for backup restore.** |
| `ensureDataArrays()` | Guarantees all `S.*` arrays exist after any merge/load |
| `getGroupById(id)` | Returns group by id |
| `getActiveEventForGroup(gId)` | Returns the open event for a group, or null |
| `getGroupTotals(g)` | Returns `{totalHead, avgWeight, dmiTarget}` for a group |
| `filterAnimalsByGroup(groupId)` | Toggles the animal list filter to a group; called from group chip onclick |
| `goFeedGroup(gId)` | Bridge: home Feed button → nav to feed → open Quick Feed sheet |
| `goFeedEvent(evId)` | Location-view feed bridge: finds first active group in event, delegates to `goFeedGroup`. `qfFromHome` flag ensures cancel/save return to home. (~L3434) |
| `moveAllGroupsInEvent(evId)` | Location-view "Move All": collects all active group IDs from event via `evGroups()`, sets `wizGroupIds`, launches Move Wizard. (~L2930) |
| `exportFeedbackJSON()` | Exports `S.feedback` as `gthy-feedback-YYYY-MM-DD-HHMM.json` for Claude session import into OPEN_ITEMS.md. Distinct from the full backup — feedback only, structured for machine parsing. |
| `exportFeedbackCSV()` | Human-readable CSV export of feedback. For record-keeping; Claude uses the JSON export. |
| `exportDataJSON()` | Full data backup as `gthy-backup-YYYY-MM-DD-HHMM.json`. Full replacement restore — not merged. |
| `flushToSupabase()` | Called on `visibilitychange` → visible. Drains `gthy-sync-queue` to Supabase. Also called by `supabaseSyncDebounced` 800ms after every `save()`. Uses `op.conflictKey \|\| 'id'` per entry — supports tables whose PK is not `id`. |
| `pushAllToSupabase()` | **M4.5-C** Full re-push of entire S state to Supabase. Iterates all S arrays, queues every record using correct patterns (`_pastureRow` for pastures, `queueEventWrite` for events, `_sbToSnake` for flat tables), then calls `flushToSupabase()` immediately. Called by `importDataJSON()` after backup restore when signed in. Safe to call repeatedly — all writes are upserts. |
| `queueWrite(table, record, conflictKey='id')` | **M4.5-A** Appends/replaces one record in the offline write queue. Third param `conflictKey` (default `'id'`) controls both dedup key and the `onConflict` hint passed to Supabase upsert. Required for tables whose PK is not `id` (e.g. `operation_settings` uses `conflictKey='operation_id'`). |
| `maybeResumeTokenRefresh()` | Called at init. Schedules token refresh or triggers silent re-auth if already expired. |
| `editTreatmentType(id)` | Populates manage-treatments form with existing values; sets `_editingTreatmentId`. Switches button label to "Save changes" and shows Cancel. |
| `cancelEditTreatment()` | Clears `_editingTreatmentId`; calls `_mtResetForm()` to return form to add mode. |
| `_mtResetForm()` | Resets the manage-treatments form fields and button state to blank "add" mode. |

---

## Critical Behavioral Notes


### M4.5 — Settings, Reset, and Restore Write Paths (fixed b20260329.1630)

Three categories of functions were silently bypassing Supabase post-M4:

**`saveSettings()` — no queueWrite** (fixed): Settings saves called `save()` but never queued anything. The entire `S.settings` blob and `S.herd.name` (operation name) never reached Supabase. Fix: two `queueWrite` calls added at end of `saveSettings()` before `save()` — one to `operations` (herd name), one to `operation_settings` (full settings JSONB, `conflictKey='operation_id'`).

**Reset functions — Supabase rows survived** (fixed): `executeReset()` cleared local state and called `saveLocal()` but left all Supabase rows intact. On next load, `loadFromSupabase()` flooded all "deleted" data back. Fix: `executeReset()` now deletes from Supabase in FK-safe order before clearing local state, then clears `gthy-sync-queue` to prevent re-population from pending queued writes.

**`importDataJSON()` — backup restore never synced to cloud** (fixed): After restore, `saveLocal()` was called but nothing was pushed to Supabase. On next multi-device load, old Supabase data overwrote the just-restored state. Fix: `importDataJSON()` is now async; calls new `pushAllToSupabase()` after local restore when signed in.

**`queueWrite` conflictKey param added**: `flushToSupabase` was hardcoding `onConflict: 'id'` which broke `operation_settings` (PK is `operation_id`, not `id`). `queueWrite` now accepts optional `conflictKey='id'`; queue entries store this value; `flushToSupabase` uses `op.conflictKey || 'id'` per entry.

### saveBatchAdj — Missing queueWrite (fixed b20260328.2241)

`saveBatchAdj()` was calling `save()` but never calling `queueWrite('batches', ...)` first. `save()` only flushes the queue — it does not queue records itself. Result: all batch edits (remaining adjustments, weight corrections, label changes) were persisted to localStorage but never written to Supabase.

**Fix:** `queueWrite('batches', _sbToSnake({...b, operationId: _sbOperationId}))` added immediately before `save()` in `saveBatchAdj`. Same pattern already present in `addBatch` and the archive path.

**Pattern reminder:** Every mutation that changes a record must call `queueWrite(table, record)` before `save()`. `save()` alone does not write to Supabase.

### animal_health_events — Ambiguous FK Requires Hint (b20260328.2219)

`animal_health_events` has two FKs to `animals`: `animal_id` (primary — the treated/noted animal) and `calving_calf_id` (the calf born). Supabase nested select cannot resolve which FK to use without an explicit hint, returning "Could not embed because more than one relationship was found" and silently returning `undefined` for the entire animals fetch.

**Fix:** The nested select uses the FK name explicitly: `animal_health_events!animal_health_events_animal_id_fkey(*)`. If the schema FK name ever changes, this hint must be updated to match.

**Side effect — calving record duplication:** The migration script uses `nextId()` to generate IDs for calving rows (derived from `calvingRecords[]` which have no natural ID). Re-running the script inserts new rows each time rather than upserting. After debugging runs, duplicate calving rows were cleaned with: `delete from animal_health_events where type='calving' and id not in (select min(id) from animal_health_events where type='calving' group by animal_id, date)`.

### paddock_observations — Realtime Requires REPLICA IDENTITY FULL (b20260328.2219)

`paddock_observations` was returning a 400 error in the realtime subscription (not in the fetch — `_sbFetch` returned 4 rows correctly). Supabase realtime requires `REPLICA IDENTITY FULL` on any table in the `WATCHED` list, otherwise the subscription returns 400.

**Fix applied in Supabase SQL Editor:** `alter table paddock_observations replica identity full;`

**If this occurs on other tables:** run the same `alter table [table] replica identity full;` in the SQL Editor. Any table in the `WATCHED` array in `subscribeRealtime()` needs this set.

### Supabase → S Object Field Name Mapping (b20260328.2211)

Several Supabase column names differ from the JS field names the rest of the app expects. All mappings are applied during assembly in `loadFromSupabase`. **Never change the JS-side field names** — too many render functions depend on them.

| Table | Supabase column | JS field | How mapped |
|---|---|---|---|
| `animals` | `tag` | `tagNum` | `a.tagNum = a.tag` in `assembleAnimals` |
| `animals` | `status: 'culled'/'active'` | `active: bool` | `a.active = a.status !== 'culled'` |
| `animals` | `cull_date`, `cull_reason` | `cullRecord: {date, reason}` | Reconstructed in `assembleAnimals` |
| `pastures` | `type` | `locationType` | `p.locationType = p.type` in pasture flat-map |
| `batches` | `name` | `label` | `b.label = b.name` in batch flat-map |
| `batches` | `feed_type_id` | `typeId` | `b.typeId = b.feedTypeId` |
| `batches` | `dm_pct` | `dm` | `b.dm = b.dmPct` |
| `batches` | `cost_per_unit` | `cpu` | `b.cpu = b.costPerUnit` |
| `batches` | `quantity` | `remaining` (seed value) | `b.remaining = b.quantity` (true remaining is live-decremented) |
| `batches` | `wt` | `wt` | Direct — no conversion needed (no underscores) |
| `animal_groups` | *(no animalIds column)* | `animalIds[]` | Derived from `S.animalGroupMemberships` open rows in `assembleGroups` |

**`wt` (batch bale weight)** is stored in the Supabase `batches` table as of b20260328.2241. Populated for existing batches via a one-time SQL update. Passes through `_sbToCamel` unchanged (no underscore conversion). Used by DMI calculations: `b.wt ? l.qty * b.wt : l.qty` for as-fed lbs.

### assembleEvents — feedEntries Shape Mismatch (fixed b20260328.2200)

`assembleEvents` was putting flat `event_feed_deliveries` rows directly into `ev.feedEntries[]`. Every render function reads `fe.lines[]` (the old shape: one feed entry = one date, with a `lines[]` array of `{batchId, qty}`). The flat rows had no `lines` property — all feed/cost/DMI calculations crashed silently.

**Fix:** `assembleEvents` now groups `event_feed_deliveries` rows by date, building `{id, date, lines:[{batchId, qty}]}` entries. Sub-move feed deliveries are filtered by `sub_move_id` and assembled the same way per sub-move. `ev.locationType` is now derived from the `S.pastures` lookup (not stored in the `events` table). Paddock entries get a `locationType: 'pasture'` fallback.

### Supabase assembly audit — four additional field alias gaps (fixed b20260328.2324)

A systematic audit of all assembly functions identified four categories of missing field aliases that were silently producing `undefined` across many render and calc paths.

**Fix A — Sub-move field aliases in `assembleEvents()` (`event_sub_moves` → JS app names):**
All sub-move display, the sub-move close sheet, duration calculation, and recovery windows were broken for Supabase-loaded events. Five aliases added after `_sbToCamel(sm)`:

| Supabase → camelCase | App reads |
|---|---|
| `date_in` → `dateIn` | `sm.date` |
| `time_in` → `timeIn` | `sm.time` |
| `pasture_name` → `pastureName` | `sm.locationName` |
| `recovery_days_min` → `recoveryDaysMin` | `sm.recoveryMinDays` |
| `recovery_days_max` → `recoveryDaysMax` | `sm.recoveryMaxDays` |

**Fix B — `ev.pasture` alias in `assembleEvents()` (read path):**
`pasture_name` → `pastureName` via `_sbToCamel`. App uses `ev.pasture` in ~20 places (event list display, location cards, manure summary, CSV export, wizard filter). Added `if (!ev.pasture && ev.pastureName) ev.pasture = ev.pastureName;` in `assembleEvents()`.

**Fix C — Pasture `recoveryMinDays`/`recoveryMaxDays` alias (read + write path):**
`pastures` table stores `min_days`/`max_days`; `_sbToCamel` gives `minDays`/`maxDays`. App reads `p.recoveryMinDays`/`p.recoveryMaxDays` in 6 places (recovery window display, expected graze dates). Added aliases in flat pasture assembly in `loadFromSupabase()`.

Write path also fixed: `queueWrite('pastures', _sbToSnake({...p}))` was converting `recoveryMinDays` → `recovery_min_days` and `locationType` → `location_type`, neither of which matches the actual column names (`min_days`, `max_days`, `type`). New `_pastureRow(p, opId)` helper function builds the correct schema-safe row. All three `queueWrite('pastures',...)` call sites updated to use it.

**Fix D — `ev.totals` auto-rebuild for closed events on Supabase load:**
`totals` is a computed JS object never stored in Supabase. Closed events loaded from Supabase had `ev.totals === undefined`, causing blank/zero values in the events log detail line, pasture NPK totals, reports screen, and CSV export. Added a pass in `loadFromSupabase()` after migrations run: `S.events.forEach(ev => { if (ev.status==='closed' && !ev.totals) recalcEventTotals(ev); })`. Errors are caught per-event and non-fatal.

---

### assembleEvents — head/wt and forage fields missing from Event Edit sheet (fixed b20260328.2258)

The `events` Supabase table has a **minimal schema** — it does not store `head`, `wt`, `heightIn`, `heightOut`, `forageCoverIn/Out`, `recoveryMinDays/MaxDays`. After `_sbToCamel(r)` these were all `undefined`, so the Event Edit sheet showed blank fields for every event.

**Root cause:** These values are normalized into child tables, not stored on the event row itself.

**Fix — three derivations added inside `assembleEvents()`:**
1. **`ev.head` / `ev.wt`** — summed/averaged from `ev.groups[].headSnapshot` / `weightSnapshot` across active (non-removed) groups.
2. **`ev.heightIn`, `ev.forageCoverIn`** — read from `S.paddockObservations` where `sourceId === ev.id` and `source === 'event_open'`.
3. **`ev.heightOut`, `ev.forageCoverOut`, `ev.recoveryMinDays`, `ev.recoveryMaxDays`** — read from `S.paddockObservations` where `source === 'event_close'`.

`S.paddockObservations` is assigned in `loadFromSupabase()` before `assembleEvents()` runs, so the lookup is safe.

**Fix — `queueEventWrite` group membership snapshot fields (same build):**
`event_group_memberships` rows were being written with `headSnapshot: g.head` — but assembled group objects carry `g.headSnapshot`/`g.weightSnapshot` (from Supabase) not `g.head`/`g.wt`. Fixed to `g.headSnapshot ?? g.head ?? ev.head` / `g.weightSnapshot ?? g.wt ?? ev.wt` — covering (a) Supabase-assembled groups, (b) legacy localStorage groups, and (c) newly created events where head/wt sit on the event object rather than the group entry.

### assembleAnimals — calvingRecords Always Empty (fixed b20260328.2204)

`assembleAnimals` set `a.calvingRecords = []` as a hardcoded empty array. The calving data was correctly migrated into `animal_health_events` with `type='calving'` during M4, but the assembly function never read it back out.

**Fix:** `assembleAnimals` now filters `animal_health_events` by type: non-calving events go into `a.healthEvents[]`; calving events are mapped to `a.calvingRecords[]` with the shape `{date, calfId, sireTag, stillbirth}` that render functions expect. Field mapping: `calvingCalfId`→`calfId`, `sireName`→`sireTag`, `calvingStillbirth`→`stillbirth`.
`TREATMENT_CATEGORIES` constant defines six allowed values: `Vaccine`, `Parasite Control`, `Antibiotic`, `Wound/Surgery`, `Nutritional`, `Other`. Each treatment type record carries `t.category: string | null`. The manage-treatments sheet displays a category `<select>` alongside the name field, and renders a category badge on each row.

**Edit mode state:** `_editingTreatmentId` (module-level `let`, initially `null`) tracks whether the form is in add vs. edit mode. Duplicate name check in edit mode excludes the record being edited. `archiveTreatmentType()` and `unarchiveTreatmentType()` call both `renderMtTypesList()` and `renderTreatmentTypesList()` (two separate list renderers exist — `renderMtTypesList` in the manage sheet, `renderTreatmentTypesList` in the treatment event sheet).

### Multi-Group Event — Group Departure Flow (as of b20260323.2354)
When a group is removed from an event in the Event Edit sheet, the flow has three steps:

1. **`startMoveGroup(idx)`** — sets `dateRemoved` + `_moveAction = 'picking'`; reveals destination selector in the chip. Primary group (idx===0) is locked.
2. **User picks destination:**
   - `setMoveGroupExisting(idx, targetEvId)` — attach to an existing open event after save
   - `setMoveGroupWizard(idx)` — open move wizard for this group after save
3. **`cancelGroupMove(idx)`** — clears `dateRemoved` and `_moveAction`; group stays active

`_moveAction` values: `null` (default) · `'picking'` (choosing) · `'existing'` (attach to event) · `'wizard'` (open wizard). `_moveTargetEventId` stores the target for `'existing'` mode.

**⚠️ `closeGroup()` does not exist.** Earlier docs referenced this name. The actual function is `startMoveGroup()`.


**Root cause:** Previous `removeEePaddock()` had no guard — it would silently remove any non-primary paddock from the working copy, including ones loaded from committed event records. If the user accidentally clicked × on a saved paddock and then saved the event, that paddock entry and its NPK window would be permanently lost.
**Fix:** `addEePaddock()` now stamps new entries with `_isNew: true`. `removeEePaddock()` guards on that flag — it only removes `_isNew` entries. Committed paddock entries use `closePaddock()` (sets `dateRemoved`) and `reopenPaddock()` (clears it) instead. `applyEePaddocksToEvent()` strips `_isNew` before writing back to the event record so the flag never leaks into persisted data.

### Move times (`timeIn`, `timeOut`, sub-move `time`)
Events now store optional `timeIn` and `timeOut` fields (HH:MM strings) captured from the wizard move-in and move-out steps. Sub-move records carry an optional `time` field from the sub-move sheet. All three are metadata only — no calculations use time values currently. Fields are `null` when not entered. Display functions can show them alongside dates where relevant.

### Multi-Group Events (`ev.groups[]`)
Events now support multiple groups via `ev.groups[]`, parallel to `ev.paddocks[]`. Each entry carries `groupId`, `groupName` (snapshot), `dateAdded`, `dateRemoved`. The legacy `ev.groupId` scalar is kept pointing at `groups[0].groupId` for backward compat with any code that hasn't been updated.

**`getActiveEventForGroup(gId)`** checks `evGroups(e).some(g=>g.groupId===gId&&!g.dateRemoved)` — a group with `dateRemoved` set is no longer "active" in the event and won't block a new event being opened for it.

**Path B head/wt sync:** When groups change in the Event Edit sheet, `syncEeGroupTotals()` aggregates head count and weighted-average weight from all active groups and pushes into the form fields. On save, `saveEventEdit()` repeats this aggregation to write the final values to `ev.head` / `ev.wt`. The user can override these fields manually if their observed count differs.

**Wizard multi-select:** `wizGroupIds[]` replaces the old `wizGroupId` scalar. The group selector step shows tap-to-toggle tiles with a checkmark indicator and a "Continue with N groups →" button that appears once at least one is selected.

**`_isNew` flag:** Same as paddocks — new additions in the current edit session carry `_isNew:true`. `removeEeGroup()` only fires on these. Committed entries use `startMoveGroup()` / `reopenGroup()` (departure) or `cancelGroupMove()` (undo). Stripped by `applyEeGroupsToEvent()` before persist.

### Backup / Restore (importDataJSON)
**Full replacement — not a merge.** The restore flow is:
1. `S = JSON.parse(JSON.stringify(imported))` — deep clone, complete replacement
2. Cancel any pending sync timers (`syncTimer`, `syncRetryTimer`) before saving
3. `saveLocal()` only (not `save()`) to avoid triggering Drive merge
4. `driveWriteFile()` directly to force-overwrite Drive with the restored data immediately
5. `renderCurrentScreen()` to refresh UI

**Why this matters:** The old merge-based restore allowed Drive sync to re-fetch and re-merge post-restore, pulling back data that should have been replaced. The force-write ensures Drive and localStorage both reflect the restore.

### Backup File Naming
Format: `gthy-backup-YYYY-MM-DD-HHMM.json` (e.g. `gthy-backup-2026-03-22-0942.json`).
Files sort chronologically by name. Latest is always at the bottom of a sorted list.

### Supabase Sync — visibilitychange / PWA Resume (M3)
`flushToSupabase()` is registered on `document.visibilitychange` in the init block. Fires every time the app becomes visible — phone unlock, switching back from another app, returning to a backgrounded tab. Drains the `gthy-sync-queue` to Supabase if `_sbClient` and `_sbOperationId` are set.

**This is separate from the `visibilitychange` handler inside the SW registration block**, which only calls `reg.update()` to check for app updates. Two separate listeners — one for data sync, one for SW updates.

### Missing Semicolon Syntax Errors — b20260322.0936 Lockup (Fixed b20260322.1031)
Build b20260322.0936 had **four missing semicolons** between adjacent function calls, all introduced in the same prior session. Because JS is parsed as a whole before any execution, a single syntax error anywhere in the 12,500-line file prevents all JS from running — causing a complete load lockup. The four errors were:
- `renderCurrentScreen()` (L2161): `renderGroupsList()renderGrpAnimalPicker()` → `renderGroupsList();renderGrpAnimalPicker()`
- `addAnimal()` (L6690): `save()renderGroupsList()` → `save();renderGroupsList()`
- `saveAnimal()` (L6879): `closeAnimalEdit()renderGroupsList()` → `closeAnimalEdit();renderGroupsList()`
- `deleteAnimal()` (L6890): `closeAnimalEdit()renderGroupsList()` → `closeAnimalEdit();renderGroupsList()`

**Lesson:** After any session that touches multiple JS call sites, run `node --check` on the extracted JS before delivering. This catches syntax errors instantly.

### s-feed Missing Closing Tag — All Screens Blank (Fixed b20260322.1135)
The `</div>` closing `#s-feed` was missing before `#s-animals` opened. This caused every screen div from `#s-animals` through `#s-settings` to be **nested inside** `#s-feed` rather than being siblings. Because `.scr { display:none }` and only `.scr.active { display:block }`, when `#s-feed` was not the active screen it hid everything inside it — making all other screens invisible regardless of their `.active` class. Only `#s-home` was a true sibling and therefore always visible.

**Symptom:** Home screen rendered correctly. Every other screen appeared completely blank when navigated to.

**Fix:** One `</div><!-- /s-feed -->` inserted between the last feed card and the `#s-animals` div.

**Lesson:** When diagnosing blank screens, check `.scr` div nesting depth first. Use the depth-counting script below to verify all screen divs open at the same depth:
```python
import re
depth = 0
in_script = in_style = False
for i, line in enumerate(open('get-the-hay-out.html'), 1):
    if '<script' in line and '</script>' not in line: in_script = True
    if '</script>' in line: in_script = False
    if '<style' in line and '</style>' not in line: in_style = True
    if '</style>' in line: in_style = False
    if in_script or in_style: continue
    if 'class="scr' in line:
        m = re.search(r'id="([^"]+)"', line)
        if m: print(f'{m.group(1):20s} L{i:5d}  depth={depth}')
    depth += len(re.findall(r'<div[\s>]', line)) - line.count('</div>')
# All .scr divs should show depth=2. Final depth should be 0.
```

### Sub-Move System — Lifecycle & Anchor Paddock Model (as of b20260324.0054; picker updated b20260324.1730)

**Core concept:** Sub-moves are *supplemental grazing visits* from an anchor paddock. The anchor paddock (stored in `ev.paddocks[]`) stays active for the full event duration. Sub-moves represent temporary excursions to nearby paddocks — animals return to the anchor between visits. This models the bale-grazing workflow: stored feed at anchor, supplemental grazing at adjacent paddocks.

**`openSubMoveSheet()` — location dropdown rules (as of b20260324.1730):**
- Excludes ALL paddocks in the event via `evPaddocks(ev).map(p=>p.pastureName)` plus `ev.pasture` (legacy fallback).
- Excludes archived pastures.
- Event label now uses `evGroups(ev)` for group names and `evDisplayName(ev)` for location — not the legacy `ev.groupId` / `ev.pasture` scalars.

**State machine — `sm.durationHours`:**

| Value | State | Meaning |
|---|---|---|
| `0` | **Active** | Animals are currently at this sub-location |
| `> 0` | **Closed** | Animals have returned; duration was recorded |

No other field stores sub-move state. `durationHours === 0` is the only "active" signal.

**Sub-move data fields (as of b20260324.1800):**
- `sm.id` — unique identifier
- `sm.date` — date animals moved to sub-location (date in)
- `sm.time` — time in (optional)
- `sm.timeOut` — time returned (optional; set at creation if same-day, or at close)
- `sm.dateOut` — date returned (optional; set at close time if multi-day visit — new as of b20260324.0054)
- `sm.durationHours` — total hours at sub-location; `0` = still active
- `sm.locationName` — name of the supplemental paddock
- `sm.noPasture` — `bool`; independent stored-feed flag for this sub-move; confinement = always `true`; non-confinement defaults `false` (grazing) unless user checks the toggle
- `sm.heightIn` / `sm.heightOut` — pre/post graze heights at sub-location (grazing only)
- `sm.feedEntries[]` / `sm.feedResidual` — feed added during sub-move
- `sm.recoveryMinDays` / `sm.recoveryMaxDays` — recovery window for sub-location (grazing only)
- `sm.parentFeedCheckpointPct` — 0–100; % of bales remaining at parent event when this sub-move closes; enables `calcGrassDMIByWindow` to attribute per-paddock grass DMI; `null` if not recorded
- `sm.notes`

**Transition: Active → Closed**
- Triggered by: `saveSmClose()` in the sub-move sheet close form
- UI path: Home → Sub-move button → "Recorded sub-moves" section → "Record return" on active sub-move
- Writes: `sm.durationHours`, `sm.dateOut`, `sm.timeOut`, `sm.heightOut`, `sm.recoveryMinDays/Max`
- Also stamps recovery onto the location record for `getExpectedGrazeDates()`

**Transition: None → Active (create)**
- Triggered by: `saveSubMove()` — always creates with `durationHours: 0` if no hours entered
- UI path: Home → Sub-move button → "Add sub-move" form at bottom of sheet

**Multiple sub-moves per event:**
- `ev.subMoves[]` can hold any number of records
- Sequential pattern: close one, add another to a different paddock
- Concurrent pattern: multiple active sub-moves simultaneously (animals split across locations — edge case)
- `eventSubMoveHours(ev)` sums `durationHours` across all sub-moves for pasture % calculation
- Active sub-moves (`durationHours === 0`) contribute 0 hours to off-paddock time until closed

**Display contract:**
- Rotation calendar: anchor paddock row spans full event; sub-move rows appear only during their window (`sm.date` → `sm.dateOut` or today if active). Do NOT clip the anchor paddock row when sub-moves exist.
- Location card / group card header: show anchor paddock as primary location; list active sub-moves as supplemental (`⇢ locationName [active]`). Active = `durationHours === 0`.
- Sub-move sheet: `renderSmExistingList(ev)` renders existing sub-moves at sheet top; active ones show "Record return" + "Edit" buttons; closed ones show "Edit" only.
- Edit mode: `openSmEditForm(smId)` pre-fills the add form; save button reads "Save changes"; amber "Cancel edit" button appears. `resetSmForm()` returns to add mode.
- Event Edit sheet: "⇢ Manage sub-moves" button calls `openSubMoveSheetFromEdit()` — bridges to sub-move sheet without losing the event context. Enables editing sub-moves on both open and closed (historical) events.

**What the anchor paddock is NOT:**
- The anchor paddock is NOT replaced by a sub-move location
- `evDisplayName(ev)` always returns the anchor paddock name(s) from `ev.paddocks[]`
- Sub-move locations are supplemental and never appear in `ev.paddocks[]`

### Sub-move System — Grazing Fields and noPasture Flag (as of b20260324.1800)
Sub-move records capture the same grazing information as a full move wizard, plus an independent stored-feed flag:
- **`sm.noPasture`** — independent flag; `true` = stored feed only at this sub-location; `false` (default) = grazing. Confinement locations always set `true`. Non-confinement shows a "100% stored feed at this location" toggle in the UI; when checked, height and recovery fields are hidden.
- **`sm.heightIn`** — pre-graze height at the sub-location (grazing only)
- **`sm.heightOut`** — residual height on exit (grazing only)
- **`sm.feedResidual`** — % of last sub-move feeding left uneaten (0 if no feed)
- **`sm.recoveryMinDays`** / **`sm.recoveryMaxDays`** — recovery window for the sub-location (grazing only)
- **`sm.parentFeedCheckpointPct`** — bale feed remaining (%) at parent event when this sub-move closes; set via the "Bales remaining right now" slider in the Record Return form; shown only when parent event has bale feed entries and sub-move is grazing

**Confinement locations** — height, recovery, and checkpoint fields are hidden in the UI and stored as `null` / `true` for `noPasture`.

**DMI calculation:** `calcEventTotalsWithSubMoves()` applies each sub-move's own `feedResidual` to its own `feedEntries`. The `effectivelyNoPasture` guard checks `ae.noPasture && !hasGrazingSubMoves` — a bale-grazing parent with at least one grazing sub-move unlocks pasture DMI inference via mass balance.

**Recovery tracking:** `lastGrazingRecordForPasture(pastureId, pastureName)` wraps `lastClosedEventForPasture()` and also scans all events' `subMoves` for records that visited the named location and carry recovery data. Returns the most recent record (event or sub-move). `getExpectedGrazeDates()` calls this function, so sub-move pasture visits feed directly into the recovery calendar on the Pastures screen.

When a sub-move is saved to a non-confinement grazing location, the recovery window is also written directly to `pasture.recoveryMinDays` / `pasture.recoveryMaxDays` as a fallback for the recovery lookup chain.

### Per-Paddock Attribution Engine (~L9830)
New engine added in b20260324.1800. Three functions:

**`feedDMIPutOutToDate(entries, cutoffDate)`** — date-filters feed entries and sums gross DMI put out on or before `cutoffDate`. Used by `calcGrassDMIByWindow` to build cumulative bale consumption at each checkpoint.

**`calcGrassDMIByWindow(ae, outDate, feedRes)`** — checkpoint-driven grass DMI attribution.
- Collects grazing sub-moves that have `parentFeedCheckpointPct` recorded and a `dateOut`
- Builds an ordered checkpoint timeline: each sub-move close date + final event close date
- For each window: computes bale DMI consumed in that window (`feedDMIPutOutToDate × (1 − checkpointPct)`), then infers grass DMI by mass balance (`expected − bale consumed`)
- Credits each window's grass DMI to the paddock that closed at that checkpoint
- Falls back to whole-event balance credited to primary paddock if no checkpoints recorded
- Returns `[{locationName, grassDMI}]` — stored as `ae.totals.grassDMIByPaddock` on event close

**`calcSubMoveNPKByAcres(ae, outDate)`** — acres-weighted, time-windowed NPK attribution for sub-move locations.
- Builds breakpoints from all sub-move `date` / `dateOut` values
- For each window where sub-moves are active alongside the primary paddock: distributes that window's total NPK across all active paddocks by their `acres` value (equal share fallback when acres = 0)
- Returns only the sub-move locations' shares — primary paddock NPK is handled by the existing `paddockNPK` logic in `wizCloseEvent`
- Called by `calcEventTotalsWithSubMoves`; result passed to `wizCloseEvent` as `subMoveNPK`

**Design rationale:** NPK is distributed by acres because animals are physically present across all simultaneously active paddocks — manure deposition tracks grazeable area, not time. Grass DMI uses checkpoints because time-fraction is not meaningful when animals freely shuttle between bale-graze and adjacent paddocks.

### wizCloseEvent — const isCon TDZ
`const isCon` must be declared **immediately after** `ae.status='closed'`, before any code that references it. A temporal dead zone (TDZ) bug caused `const isCon` declared late in the function to throw `ReferenceError` when referenced earlier, silently aborting after the event was closed in memory but before `save()` or `wizGo(1)` could run. Fixed in b20260320.1035.

### wizSaveNew — Location Reading
Reads the primary location from `wizPaddocks[0].pastureName` first, **not** from the dropdown element. The dropdown resets to blank after a chip is added, which was causing a false "select a location" error even when a paddock chip was visibly selected. Fixed in b20260320.1041.

### Animals Screen Layout (as of b20260323.2354)
- Management buttons (Classes, Treatments, AI Sires) sit **above** the groups card
- `+ Add Animal` button is in the filter/search row
- Group chips are **clickable filters** — tapping toggles the list to show only that group's animals; tap again to clear. The active chip shows a green `✕ clear filter` badge to make deselect discoverable. Toggle logic lives in `filterAnimalsByGroup(groupId)`.
- Group chips show an Edit button that opens `openEditGroupSheet(id)` for inline editing
- **`closeAnimalEdit()` calls `renderAnimalsScreen()`** when `curScreen==='animals'` — ensures list reflects changes immediately on sheet close. (Added b20260323.2354 — previously only `saveAnimalEdit()` triggered a re-render.)

### Animal Health Event Types (as of b20260322.1958)
Health events are stored in `animal.healthEvents[]`. Supported types:
| Type | Icon | Key fields | Sheet section |
|---|---|---|---|
| `note` | 📝 | `text` | `#ae-evt-note-section` |
| `treatment` | 💉 | `treatmentTypeId`, `treatmentName`, `product`, `dose`, `withdrawalDate` | `#ae-evt-treatment-section` |
| `breeding` | ♀ | `subtype` (ai/bull), `sireName`, `expectedCalving` | `#ae-evt-breeding-section` |
| `heat` | 🌡 | `notes` | `#ae-evt-breeding-section` (subtype=heat) |
| `bcs` | 📊 | `score` (int 1–10), `notes` | `#ae-evt-bcs-section` |

BCS chips use class `.bcs-chip` / `.bcs-chip.on`. Toggle handled by `bcsChipToggle(el)`.

### Confirmed Bred Flag (as of b20260322.1958)
Female animals have two new fields: `animal.confirmedBred: bool` and `animal.confirmedBredDate: ISO string | null`. These are distinct from breeding events (which record the breeding act) — confirmed bred records a subsequent pregnancy confirmation (palpation, ultrasound, etc.).
- UI: checkbox + date field in `#ae-confirmed-bred-section` (shown only for females)
- Toggle handler: `onConfirmedBredChange()` shows/hides the date field and pre-fills today
- Badge: `✓ bred` shown on animal card row and in the `ae-title` of the edit sheet
- Saved in both new-animal and edit-animal paths of `saveAnimalEdit()`

### ae-sheet-wrap Section Order (as of b20260322.1958)
1. Tag + EID · Sex + Class · Weight + Group · Dam + Sire · Notes
2. `#ae-calving-section` — females only
3. `#ae-confirmed-bred-section` — females only
4. `#ae-wt-history` — weight log
5. `#ae-health-events` — health event history (all types including BCS)
6. `#ae-cull-section` — cull/reactivate

### Drive Sync Timers
`syncTimer` and `syncRetryTimer` are the debounce handles. Clear both before any operation that must not trigger a Drive fetch+merge (currently only the backup restore flow).

### Rotation Calendar — Sub-Move Paddocks (as of b20260323.2354)
`renderRotationCalendar()` previously collected `paddockNames` only from `evPaddocks(ev)` (main event paddock array). Sub-move locations stored in `ev.subMoves[].locationName` were never included, so any paddock a group visited only via a sub-move was invisible in the calendar.

**Fix:** `subMovePaddockNames` is now collected separately and merged into `paddockNames`. The week-map builder was replaced with a `windows[]` approach: each paddock row collects both main-paddock windows (with the end date clipped to the first sub-move's date when an open event has sub-moves) and sub-move windows (from `sm.date` to next sub-move date or `ev.dateOut`). Sub-move cells render with a dashed top border and `⇢ (sub-move)` in the hover tooltip.

**Critical rule:** When editing `renderRotationCalendar()`, the week-map is now built from `windows[]` objects (each carrying `{ev, start, end, isSubMove}`), not directly from event objects. Cell rendering reads `c.win.ev`, `c.win.start`, `c.win.end` — not `c.ev`, `c.ev.dateIn`, `c.ev.dateOut`.

### Rotation Calendar — Season Totals / eventAUDs (as of b20260323.2354)
`eventAUDs(ev)` inside `renderRotationCalendar()` returned 0 for open events where `ev.head` / `ev.wt` were not stamped on the event record (common for group-based events created via `initWizFromGroups()`). Fixed: when `ev.head` is missing and the event is open, the function now falls back to live group totals via `evGroups(ev)` + `getGroupTotals()`, summing head across all groups and taking weight from the first group with a value.

### Rotation Calendar — Semantic Colors (as of b20260323.2354)
Calendar blocks no longer use group colors. All blocks use one of two semantic colors via `evCalColor(ev)`:
- **`#639922` (green)** — pasture grazing events (`ev.noPasture` falsy)
- **`#C4A882` (tan)** — 100% stored-feed or confinement events (`ev.noPasture` true or `ev.locationType==='confinement'`)

`grpColor()` is no longer called from within `renderRotationCalendar()`. The legend now shows "Pasture grazing / Hay / stored feed / Sub-move" instead of group names.

### Sub-Move Toast — Duration Warning Removed (as of b20260323.2354)
`saveSubMove()` previously showed `'\nDuration not set — edit to add hours later.'` whenever `hrs === 0`. Duration is not required at sub-move creation time — it is inferred from the next move or event close. The branch was removed. The alert now confirms the location only, with the pasture % line appearing only when hours were entered.

### Animal List — No Delete Button (as of b20260323.2354)
The `×` delete button and its `onclick="deleteAnimalFromScreen()"` call were removed from the row template in `renderAnimalsScreen()`. The `deleteAnimalFromScreen()` function still exists in the codebase but is no longer reachable from the UI. Culling/deletion is only accessible from inside the animal edit sheet via `#ae-cull-section`.

---

### Startup Sequence Ordering (as of b20260329.1831)
Critical ordering constraint for the app init block at bottom of `<script>`:
1. `detectMode()` + `applyFieldMode()` — **must run before any render** so `body.desktop` class is set on first paint
2. `sbInitClient()` — auth restore; may trigger `loadFromSupabase()` asynchronously
3. `renderHome()` — first paint; layout class must already be set
4. Migration functions (`migrateM0aData()` etc.) run **before** `sbInitClient()`, so `_sbOperationId` is null at that point. They must never call `queueWrite` directly — any writes must guard on `if(_sbOperationId)`.


## Supabase Backend (M4 — data migration complete)

**Status:** M4 complete. Data migrated from localStorage backup to Supabase tables. Supabase is now the source of truth. localStorage is the offline cache only.

| Item | Value |
|---|---|
| Project URL | `https://eufknjkbgknowlcxmjfp.supabase.co` |
| SDK | `@supabase/supabase-js@2` — UMD bundle via jsDelivr CDN |
| Auth method | Native email OTP (`signInWithOtp` + `verifyOtp`) |
| Session persistence | Supabase stores session in `localStorage['sb-*']` automatically |
| Token refresh | Handled by `onAuthStateChange` listener — no manual refresh needed |
| Client var | `_sbClient` — module-level, initialized by `sbInitClient()` at app init |
| Session var | `_sbSession` — updated by `onAuthStateChange`, read by `sbUpdateAuthUI()` |
| Operation var | `_sbOperationId` — UUID; cached in `localStorage['gthy-operation-id']` |
| Realtime var | `_sbRealtimeChannel` — active Supabase channel; replaced on re-subscribe |
| Write queue | `gthy-sync-queue` localStorage key — array of `{table, record}` ops |

**Auth flow (M2 — OTP code, b20260328.1211):**
1. User enters email in Settings → Supabase card → taps **Send code**
2. `sbSendCode()` calls `signInWithOtp({ email })` — no `emailRedirectTo` — Supabase emails a 6-digit code
3. Step-2 div shown; user types the code
4. `sbVerifyOtp()` calls `verifyOtp({ email, token, type: 'email' })` — verifies in-app within PWA context
5. `onAuthStateChange` fires `SIGNED_IN` in PWA localStorage context → M2 load chain runs

**Why OTP instead of magic link:** Magic link clicks open in regular Safari. PWA and Safari have isolated `localStorage` contexts — Supabase writes `sb-*` session tokens to Safari's storage; the PWA never sees them. `onAuthStateChange` never fires in the PWA. OTP sidesteps this entirely — the code is verified in-app, session tokens are written directly to PWA localStorage.

**Requires Supabase Dashboard change:** Authentication → Email Templates → Magic Link → replace `{{ .ConfirmationURL }}` with `{{ .Token }}` in email body.

**M2 load chain (triggered by `SIGNED_IN` or `INITIAL_SESSION`):**
1. `sbGetOperationId()` — queries `operation_members` for the user's `operation_id`; calls `sbBootstrapOperation()` on first sign-in (no row found)
2. `loadFromSupabase(opId)` — parallel-fetches all tables; assembles S from Supabase rows; calls all migrate guards; `saveLocal()`; re-renders
3. `subscribeRealtime(opId)` — opens a Supabase channel; one `postgres_changes` listener per watched table; any change triggers a full `loadFromSupabase()` reload

**Identity system (M2 — Option B, clean break):**
- `getActiveUser()` reads: Supabase session → `gthy-identity` localStorage cache → guest fallback
- Always returns non-null `{id, name, email, color, role, fieldMode}` — render functions never need null guards
- `sbCacheIdentity(displayName, operationId)` — writes/refreshes the `gthy-identity` cache
- `S.users[]` retained as inert storage for todo assignment compat; no longer the identity source
- User picker (`openUserPicker`, `maybePromptUserSelect`) retired — `maybePromptUserSelect` is a no-op

**Key functions (M2):**

| Function | Location | Purpose |
|---|---|---|
| `sbGetOperationId()` | ~L1895 | Query `operation_members`; cache result; bootstrap if none |
| `sbBootstrapOperation()` | ~L1920 | Create `operations` + `operation_members` on first sign-in |
| `sbCacheIdentity(name, opId)` | ~L1877 | Write/refresh `gthy-identity` localStorage cache |
| `getActiveUser()` | ~L2239 | M2 identity: session → cache → guest |
| `_sbLoadCachedIdentity()` | ~L1872 | Read `gthy-identity` cache safely |
| `_sbToCamel(obj)` | ~L1958 | snake_case → camelCase converter for Supabase rows |
| `_sbFetch(table, opId)` | ~L1970 | Safe per-table fetch; returns `[]` on error |
| `_pastureRow(p, opId)` | ~L2398 | Build Supabase-safe pastures row. Maps `locationType`→`type`, `recoveryMinDays`→`min_days`, `recoveryMaxDays`→`max_days`. Used by all three `queueWrite('pastures',...)` call sites. |
| `assembleEvents(rows)` | ~L1984 | Re-nest event sub-tables. Reconstructs `feedEntries[].lines[]` from flat `event_feed_deliveries` rows (grouped by date). Reconstructs `subMoves[].feedEntries[]` per sub-move. Derives `ev.locationType` from `S.pastures` lookup. Adds `locationType` fallback to paddock entries. |
| `assembleAnimals(rows)` | ~L2001 | Re-nest `animal_health_events` (via FK hint `!animal_health_events_animal_id_fkey` — required because `calving_calf_id` also references `animals`, creating an ambiguous join). Reconstructs `calvingRecords[]` from health events with `type='calving'`. Field aliases: `tag`→`tagNum`, `status`→`active` (bool), `cullDate/cullReason`→`cullRecord{}`. Derives `weightLbs` from latest `S.animalWeightRecords` entry. |
| `assembleGroups(rows)` | ~L2011 | Re-nest `animal_group_class_compositions`. Derives `animalIds[]` from `S.animalGroupMemberships` (open rows, `dateLeft` null) — not stored as an empty array. |
| `assembleGroups(rows)` | ~L2011 | Re-nest `animal_group_class_compositions` |
| `assembleManureBatches(rows)` | ~L2021 | Re-nest `manure_batch_transactions` |
| `assembleInputApplications(rows)` | ~L2030 | Re-nest `input_application_locations` |
| `loadFromSupabase(opId)` | ~L2048 | Full parallel load; assembles S from Supabase; re-renders |
| `subscribeRealtime(opId)` | ~L2172 | Postgres realtime channel; full reload on any change |


**Correct RLS policy set (as of b20260328.1221 — post-bootstrap testing):**

The schema in §3d of MIGRATION_PLAN has recursive policies that cause 500 errors on first sign-in.
The working policy set for `operations` and `operation_members` is:

```sql
-- operation_members: simple direct user_id check (NOT self-referential)
create policy "own rows"        on operation_members for select using (user_id = auth.uid());
create policy "own rows update" on operation_members for update using (user_id = auth.uid());
create policy "self insert"     on operation_members for insert with check (user_id = auth.uid());

-- operations: owner-direct check (NOT via operation_members subquery for bootstrap)
create policy "owner select"    on operations for select using (owner_id = auth.uid());
create policy "owner insert"    on operations for insert with check (owner_id = auth.uid());
```

The member-based SELECT policy on `operations` (workers reading another owner's farm)
is an M6 addition. Do not add it until M6 — it is not needed for single-farmer use.

All other tables retain the template `operation_members` subquery policy — the recursion
only occurs when `operation_members` queries itself.

**OTP rate limit note:** Supabase free tier allows 2 OTP emails per hour per address.
Exceeded limit returns "email rate limit exceeded" from `sbSendCode`. Sessions persist
across reloads via `sb-*` localStorage — rate limit only affects new sign-in attempts.

**Pre-M4 guard:** Removed at M4. `loadFromSupabase` now always assembles S from Supabase rows regardless of whether localStorage has data.

**`S.surveys` note:** No Supabase surveys table. `S.surveys[]` stays from localStorage. Survey data was already folded into `S.paddockObservations[]` during M0 migration — the Supabase `paddock_observations` table captures this path.

**Settings UI (b20260328.1623 — M3):**
- `#sb-step1` — email input + "Send code" button + error status line
- `#sb-step2` — 6-digit code input (`inputmode="numeric"`, `autocomplete="one-time-code"`) + "Verify code" + "Use different email" + status line; hidden until code sent
- `#sb-signed-out` — wrapper for both steps; shown when not authenticated
- `#sb-signed-in` — green banner with email + display name input (OI-0074) + Save name + Sign out; shown when authenticated
- Drive card **removed** at M3

**Key write-path functions (M3):**

| Function | Location | Purpose |
|---|---|---|
| `_sbToSnake(obj)` | ~L2273 | Shallow camelCase→snake_case for upsert records |
| `queueWrite(table, record)` | ~L2282 | Append/replace in `gthy-sync-queue` |
| `queueEventWrite(ev)` | ~L2295 | Queue parent event + all 6 child tables |
| `flushToSupabase()` | ~L2385 | Best-effort drain; failed items stay in queue |
| `supabaseSyncDebounced()` | ~L2408 | 800ms debounce; called by `save()` |
| `setSyncStatus(state, label)` | ~L2415 | 4 states: off/pending/ok/error; updates dot + sidebar |
| `sbSaveDisplayName()` | ~L1957 | Save display name to identity cache (OI-0074) |

**What M4 completed (data migration):**
- 457 rows migrated from `gthy-backup-2026-03-28-1327.json` to Supabase (see MIGRATION_PLAN §7 for full counts)
- Assembly functions (`assembleEvents`, `assembleAnimals`, etc.) are now live code — no longer dead code behind the guard
- Orphan group remap: event group membership referencing old "Cow-Calf Herd" id `1773607143162` remapped to current id `1773829317829` during migration
- `S.surveys[]` kept from localStorage — no Supabase surveys table; surveys already folded into `S.paddockObservations[]` via M0 migration

---

## M3 Write Path — Offline Queue

**Pattern:** Every mutation calls `queueWrite(table, record)` or `queueEventWrite(ev)` **before** `save()`. `save()` calls `saveLocal()` then `supabaseSyncDebounced()` (800ms debounce → `flushToSupabase()`).

**`queueEventWrite(ev)`** queues the parent event + 6 child tables in one call:
- `events` — flat parent fields
- `event_paddock_windows` — `ev.paddocks[]`; synthetic id = `ev.id * 1000 + i` if missing (write-once)
- `event_group_memberships` — `ev.groups[]`; synthetic id = `ev.id * 2000 + i`
- `event_sub_moves` — `ev.subMoves[]`
- `event_feed_deliveries` — `ev.feedEntries[].lines[]` flattened; id = `entry.id * 1000 + lineIndex`
- `event_feed_residual_checks` — `ev.feedResidualChecks[]`
- `event_npk_deposits` — `ev.npkLedger[]`

**`flushToSupabase()`** drains the queue best-effort:
- Continues on upsert failure — failed items stay in queue, unrelated tables don't block
- On full success: removes `gthy-sync-queue` key, sets sync status `ok`
- On partial failure: writes failed items back, sets sync status `error`
- Called by `supabaseSyncDebounced()` (after saves) and `visibilitychange` → visible (PWA resume)

**`mergeData()`** is still present — used by `importDataJSON()` restore flow. Drive removal does not touch merge logic.

---

## Architecture Patterns

**Save pattern:** `S.*` mutation → `queueWrite`/`queueEventWrite` → `save()` → render. `save()` calls `saveLocal()` then (if `_sbSession`) `supabaseSyncDebounced()`. Exception: restore flow uses `saveLocal()` directly.

**Sheet pattern:** Add `.open` to `-wrap` div to show; remove to hide. All sheet HTML is at the bottom of the file (~L11100+).

**Render pattern:** One authoritative render function per screen. Rebuilds entire screen `innerHTML`. Never modify screen content outside that function.

**Desktop layout:** 220px fixed left sidebar. Sheet centering: `calc(220px + ((100vw - 220px) / 2))` at desktop breakpoint.

---
**`mergeData()` conflict resolution for arrays (as of b20260324.0910):**

| Condition | Winner |
|---|---|
| `x.status==='closed'` and `ex.status==='open'` | Remote (closed beats open) |
| Both have `updatedAt`, remote is newer | Remote |
| Both have `updatedAt`, **equal timestamps** | Union-merge `groups`, `paddocks`, `subMoves`; scalar fields keep local |
| Both have `updatedAt`, local is newer | Local |
| Only local has `updatedAt` | Local |
| Only remote has `updatedAt` | Remote |
| Neither has `updatedAt` | Longer `feedEntries` or `subMoves` wins; otherwise local |

**`updatedAt` coverage — functions that stamp before `save()` (as of b20260324.0910):**

*Events:*
- `saveQuickFeed` — feedEntries push
- `addEeFeedEntry` — feedEntries push (event edit sheet)
- `deleteEeFeedEntry` — feedEntries delete
- `wizCloseEvent` — event close
- `saveSubMove` — subMoves push
- `saveSmClose` — subMove close (durationHours write)
- `deleteSubMove` — subMoves filter
- `saveEventEdit` — groups/paddocks/head/wt/dates edit
- `applyEeGroupMoveActions` — group pushed to destination event

*Animals:*
- `saveAnimalEdit` (edit path)
- `saveAnimalWeight`
- Health event save / `deleteAnimalEvent`
- `saveSplit` forEach loops (split-from and moved-to notes)
- `logGroupChange` helper in `saveAnimalMove`
- `saveCalving` (dam record)

**Sub-move ↔ Paddock chip linkage (b20260326.0757):**
- `saveSubMove()` (add mode) **automatically adds the sub-move location to `ev.paddocks[]`** so the event edit chip list and `evDisplayName()` stay in sync without a manual paddock selector step.
- `saveSmClose()` **stamps `dateRemoved` on the matching `ev.paddocks[]` entry** when a return is recorded. This makes the K-5 chip turn red ("Closed") in the event edit sheet automatically — no separate "Close Paddock" button click required.
- `evDisplayName()` **filters `ev.paddocks[]` to active entries only** (`!p.dateRemoved`) so the home card title shows where the animals actually are, not every paddock they have visited. Falls back to all paddocks if all are removed (closed event).
- `renderLocationCard()` shows a **"📍 Currently at: [location]"** teal line below the card subtitle whenever there is an active sub-move (`!sm.durationHours`). This is the first-class answer to "where are my cattle right now?"

**Record Return form — time handling (b20260326.0859):**
- Move-in date/time (`sm.date` / `sm.time`) are **read-only** in the form — displayed as a grey pill. Not editable directly to prevent accidental changes.
- An **✏ Edit button** alongside the pill opens the correction sub-dialog (`sm-close-timein-correct`). Same dialog auto-opens if `sm.time` is null (exceptional case — e.g. a record saved without a time-in).
- **Correction sub-dialog:** date-in + time-in inputs + Confirm. On confirm, updates a hidden `sm-close-time-in` field and a `sm._correctedDate`/`sm._correctedTime` in-memory flag. On save, corrected values are written back to `sm.date`/`sm.time` permanently.
- **Duration** is always derived by `_smCloseCalcHrs()` — never manually entered. Requires both time-in and time-out. No date-only fallback.
- `calcSmCloseDuration()` reads `sm-close-time-in` (confirmed value) + `sm._correctedDate` for the proxy, then calls `_smCloseCalcHrs()`. Displays "⏱ Xd Yh" in teal or an error in red.
- `saveSmClose()` requires `dateOut` + `timeOut`. Blocks save with a clear message if time-in is still missing after the correction prompt.

### Sub-Move Time-In Required — OI-0072 (Fixed b20260329.1816)
**Root cause:** `sm-time` field was optional (labelled "optional") and `saveSubMove()` add-mode had no validation guard. Sub-moves could be saved without a time-in, breaking the Record Return duration calculation — the only recovery path was the correction sub-dialog, a workaround.
**Fix:** Label changed to required (no qualifier). `sm-time-out` label changed to "if returned" (it remains optional). `saveSubMove()` add-mode now validates `sm-time` before creating the `sm` object — alerts with message and focuses the field. Edit mode is exempt so existing records can be corrected.

### Pasture Survey ID Type Mismatch — OI-0086 (Fixed b20260329.1816)
**Root cause:** `renderPastures()` generates `onclick="openSurveySheet('${p.id}')"` — the template literal wraps `p.id` in single quotes, making it a string. Supabase returns `pastures.id` as `bigint` (JS number). Strict `===` in `renderSurveyPaddocks()` and the title lookup in `openSurveySheet()` always failed (string ≠ number) → empty pastures array → "No pasture Location Defined."
**Fix:** Both comparisons use `String()` coercion on both sides: `String(p.id)===String(surveyFocusPastureId)`.

### Home Todos Always Empty — OI-0087 (Fixed b20260329.1816)
**Root cause:** `renderHome()` filters todos by `(t.assignedTo||[]).includes(activeUserId)`. In the Supabase-only world (M6 not yet landed) `activeUserId` is `null` — no legacy `gthy-user` key is set. No `assignedTo` array includes `null`, so the card always rendered "No open tasks assigned to you" even with open todos present.
**Fix:** When `activeUserId` is null, `renderHome()` falls back to showing all open todos (`S.todos.filter(t=>t.status!=='closed')`).


### Desktop Loads in Mobile View — OI-0088 (Fixed b20260329.1831)
**Root cause:** `detectMode()` and `applyFieldMode()` were called at end of startup, after `renderHome()`. The `body.desktop` class was not set on first render — app always painted in mobile layout, then re-rendered after `detectMode()` fired.
**Fix:** Moved both calls to immediately after `updateHeader()`, before `sbInitClient()` and `renderHome()`. The `body.desktop` class is now correct on first paint. The comment "must run last — reads DOM" was written before Supabase — DOM is fully available at any point in the inline script at bottom of body.

### Sync Queue Accumulation (36 items pending) — OI-0089 (Fixed b20260329.1831)
**Root cause:** `migrateM0aData()` runs at startup before `sbInitClient()`, so `_sbOperationId` is null. Every `_writePaddockObservation()` call queued a `paddock_observations` row with `operation_id: null`. Supabase rejects these (NOT NULL constraint) → items stay in queue → count grows each reload. `Date.now()`-based IDs bypass queue dedup so each load added ~36 items.
**Fix (two parts):** (1) `_writePaddockObservation()` guards `if(_sbOperationId)` before `queueWrite` — skips write during startup migration (canonical rows come from `loadFromSupabase()`). (2) `flushToSupabase()` strips items with `operation_id == null` from queue before flushing, clearing accumulated stale entries from prior loads.
**Pattern:** Any function that calls `queueWrite` and may be invoked before `sbInitClient()` must guard on `_sbOperationId`. Migration functions run at startup and must never queue writes directly.


### Supabase SDK Not Initialised on Sign-In — OI-0090 (Fixed b20260329.1838)
**Root cause:** Supabase SDK CDN script can fail to load on first load after a SW cache update. The SW `fetch` handler returns early for cross-origin requests (`if (!req.url.startsWith(self.location.origin)) return`) without calling `event.respondWith()`. `sbInitClient()` silently returns when `typeof supabase === 'undefined'`. Both `sbSendCode()` and `sbVerifyOtp()` hit their `if(!_sbClient)` guard and showed a bare "Supabase not initialised" alert.
**Fix:** Both functions now call `sbInitClient()` on the spot — if the global became available since startup this recovers silently. If still unavailable, a `confirm()` offers a page reload. This covers the common case where a reload resolves the CDN load failure.


### Stale Sync Indicator + Data Loss on Reconnect — OI-0096 (Fixed b20260329.2010)
**Root cause (indicator):** `save()` never called `setSyncStatus` when `_sbSession` was null — dot stayed green from last successful sync indefinitely.
**Root cause (data loss):** `onAuthStateChange` fired `loadFromSupabase()` immediately on `SIGNED_IN`, overwriting `S.*` from Supabase before the pending write queue was flushed. Data entered while signed out was queued with valid operation IDs but never reached Supabase before the load erased it from memory.
**Fix:** `save()` now calls `setSyncStatus('off', 'Not signed in — saved locally')` when no session. `onAuthStateChange` for `SIGNED_IN` now calls `flushToSupabase()` first, then chains `loadFromSupabase()` in `.then()`. `INITIAL_SESSION` path is unchanged.
**Pattern:** On any reconnect (`SIGNED_IN`), always flush the write queue before loading from the remote — local state takes precedence over remote state during the reconnect window.

### `paddock_observations` `source_id` type mismatch — OI-0099 (Fixed b20260329.2134)
**Root cause:** `_paddockObservationRow()` sent `source_id: String(obs.sourceId)` — Supabase column is bigint; PostgREST rejected the string type.
**Fix:** `source_id: obs.sourceId ?? null` — pass the number directly.
**Pattern:** When building shape functions, never convert numeric IDs to strings unless the Supabase column is explicitly `text`. Check the migration script for the canonical type.

### `feedback` 400 — extra columns not in schema (Fixed b20260329.2116)
**Root cause:** `_feedbackRow()` sent `resolved_at`, `confirmed_by`, `confirmed_at` — not in the Supabase `feedback` table. PostgREST rejected every write.
**Fix:** Three fields removed from `_feedbackRow()`. JS objects keep them for local use.
**If columns needed later:** `ALTER TABLE feedback ADD COLUMN resolved_at timestamptz; ADD COLUMN confirmed_by text; ADD COLUMN confirmed_at timestamptz;` then restore to `_feedbackRow`.

### `activeSmGC` ReferenceError in `renderGroupCard` — OI-0097 (Fixed b20260329.2112)
**Root cause:** `const activeSmGC` declared inside `if(ae){...}` block but referenced in `return` template outside that block. `const` is block-scoped.
**Fix:** Hoist to `let activeSmGC = null` before the `if(ae)` block; assign (not re-declare) inside.
**Pattern:** Variables used in a function's `return` template must be declared at function scope, not inside conditional blocks. Watch for this in any `renderXxx` function with conditional display logic.

### `paddock_observations` 400 — missed by OI-0095 audit (Fixed b20260329.2112)
**Root cause:** JS `pastureName` field → `_sbToSnake` → `pasture_name` — no column in `paddock_observations` schema. PostgREST rejected every write.
**Fix:** `_paddockObservationRow(obs, opId)` shape function added at ~L2512 with other shape functions.
**Audit lesson:** The OI-0095 audit built JS_FIELDS from memory, not from source. Always read the actual object construction code to get the canonical field list.

### Supabase Write-Path Schema Mismatch — OI-0095 (Fixed b20260329.1950)
**Root cause:** `_sbToSnake` is a generic camelCase→snake_case converter with no schema awareness. When JS object field names differ from Supabase column names (e.g. `tagNum`→`tag`, `dm`→`dm_pct`, `cpu`→`cost_per_unit`, `active`→`status`), PostgREST rejects the entire upsert on encountering the first unknown column. The write fails silently, the item stays in `gthy-sync-queue` forever, and Realtime reloads from Supabase erase locally-entered data that never reached the cloud.
**Fix:** 12 shape functions (one per affected table) map JS fields to exact Supabase column names and exclude JS-only fields (`animalIds`, `weightHistory`, `calvingRecords`, etc.). All `queueWrite` call sites for these tables updated.
**Pattern:** Every table that has any field name divergence between JS and Supabase MUST use a shape function — never `_sbToSnake` directly. `_pastureRow()` is the reference implementation. When adding a new table to the write path, always cross-reference field names against the migration script (`migrate-to-supabase.js`) which is the ground truth for Supabase column names.
**Safe tables** (schema matches JS exactly, `_sbToSnake` still fine): `manure_batches`, `paddock_observations`, `input_application_locations`.
**Shape functions:** `_animalRow`, `_batchRow`, `_feedTypeRow`, `_animalClassRow`, `_animalGroupRow`, `_aiBullRow`, `_inputProductRow`, `_todoRow`, `_treatmentTypeRow`, `_animalGroupMembershipRow`, `_animalWeightRecordRow`, `_manureBatchTransactionRow` — all at ~L2512 alongside `_pastureRow`.


### Todos `assignedTo` String Crash — OI-0091 (Fixed b20260329.1855)
**Root cause:** Migration script stored `assigned_to` as `JSON.stringify(array)` — a JS string literal `"[123]"`. PostgREST returns this JSONB as a string, not a parsed array. `(t.assignedTo||[])` evaluates to the non-empty string (truthy), so the `||[]` fallback never fires. `.map`/`.includes`/`.some` on a string throws `TypeError`. Crashed `todoCardHtml`, `renderHome`, `renderTodos`, and `openTodoSheet`.
**Fix:** Assembly layer in `loadFromSupabase()` — todos rows detect `typeof t.assignedTo === 'string'`, JSON-parse it, and normalise non-array values to `[]`. Render code unchanged.
**Pattern:** JSONB columns stored via `JSON.stringify()` in migration scripts must be parsed back at assembly time. The assembly layer is the correct place — not render functions.
**Supabase repair SQL:** `UPDATE todos SET assigned_to = assigned_to::text::jsonb WHERE jsonb_typeof(assigned_to) = 'string';`


## ⚠️ Dead Code — Removed (Do Not Re-Add)

| What | Why |
|---|---|
| `renderAnimalList()` | Targeted `#animal-list` — DOM element never existed. Animals screen uses `renderAnimalsScreen()`. |
| Legacy hidden feed form HTML (`#feed-form`, `#ff-batch-sel`, etc.) | `display:none` block kept "so refs don't break" — refs were never called from live UI. |
| `renderFFBatches()`, `renderFFQtyLines()`, `toggleFFBatch()`, `adjFF()`, `calcFFTotals()`, `saveFeedEntry()`, `renderFFHistory()` | Companion functions to removed feed form. Replaced by Quick Feed sheet flow. |

---

## ⚠️ Known Issues → OPEN_ITEMS.md

Known issues are now tracked in `OPEN_ITEMS.md` (the project punch list), not here.
See `OPEN_ITEMS.md` for all open bugs, polish items, enhancements, and debt.

The punch list receives items from two streams:
- **Claude observations** — spotted during sessions, logged as `OI-XXXX` entries
- **In-app feedback** — imported from `S.feedback` via `exportFeedbackJSON()` at session start

**For reference:** The issue previously listed here (`saveSmQuickLocation()` calling `saveLocal()` instead of `save()`) has been moved to OPEN_ITEMS.md as **OI-0001**.

---

## Dual Feedback Loop

GTHO operates two parallel issue streams that feed into `OPEN_ITEMS.md`:

### Stream 1 — In-App Feedback (S.feedback)
Farmer-reported observations captured through the in-app feedback sheet (`openFeedbackSheet()`).
- Stored in `S.feedback[]` with fields: `id`, `cat`, `status`, `note`, `tester`, `version`, `ts`, `ctx`, `resolvedInVersion`, `resolutionNote`, `linkedTo`
- Status lifecycle: `open` → `resolved` (developer marks fix applied) → `closed` (farmer confirms fixed) or reopened as regression
- **Export for session import:** `exportFeedbackJSON()` → `gthy-feedback-YYYY-MM-DD-HHMM.json`
- At session start, upload the latest feedback JSON and Claude imports new items into OPEN_ITEMS.md

**Feedback categories (`f.cat`)** — defined in `CAT` object (~L6274):

| Key | Label | Badge class | Dev brief priority |
|---|---|---|---|
| `roadblock` | 🚧 Roadblock | `br` (red) | **1st — HIGH PRIORITY** |
| `bug` | Bug | `br` (red) | 2nd |
| `calc` | Calculation | `bt` (teal) | 3rd |
| `ux` | UX friction | `ba` (amber) | 4th |
| `feature` | Missing feature | `bp` (purple) | 5th |
| `idea` | Idea | `bg` (green) | 6th |

**Feedback areas (`f.area`)** — defined in `AREA` object (~L7142): `home` · `animals` · `events` · `feed` · `pastures` · `reports` · `todos` · `settings` · `sync` · `other`. Auto-suggested from current screen via `SCREEN_AREA` map. Stored as flat `area` column in Supabase `feedback` table.

**`_feedbackRow(f, opId)`** (~L7148) — builds a Supabase-safe feedback row with only known schema columns. All feedback `queueWrite` calls must use this helper — never `_sbToSnake` on a raw feedback item (the nested `ctx` object has no Supabase column).

**Assembly note:** Supabase `feedback` rows have no `ctx` JSONB column — migration stored `ctx.screen` as a flat `screen` column. Assembly layer in `loadFromSupabase()` reconstructs `f.ctx = { screen: f.screen||'?', activeEvent: null }` so all render/export code continues to work unchanged.

### Stream 2 — Claude Observations (Session Notes)
Developer-level observations made by Claude during coding sessions — things noticed off the current task.
- Logged directly into `OPEN_ITEMS.md` as `OI-XXXX` entries during the session
- Source field: `Claude observation — build bYYYYMMDD.HHMM`
- Includes architectural debt, potential bugs, migration coupling notes

### The Two Exports
| Export | Function | File format | Purpose |
|---|---|---|---|
| Full backup | `exportDataJSON()` | `gthy-backup-YYYY-MM-DD-HHMM.json` | Data restore |
| Feedback export | `exportFeedbackJSON()` | `gthy-feedback-YYYY-MM-DD-HHMM.json` | Session import into punch list |

These two exports serve completely different purposes and must never be combined.
The backup is for disaster recovery. The feedback export is for the development workflow.

---

## Field Mode

A stripped-down layout for focused phone use in the field. Activated by any of three sources (priority order):

| Source | Mechanism | Persistent? |
|---|---|---|
| URL param `?field=*` | `URLSearchParams` at init | No — one-shot |
| User profile `user.fieldMode: true` + mobile | Read in `applyFieldMode()` at init | Yes — survives reload |
| In-app toggle button | `toggleFieldMode()` writes `user.fieldMode`, re-applies | Yes |

**CSS gate:** `body.field-mode` class. All field-mode layout changes are gated on this selector — nothing else in the codebase needs to know about field mode.

**What the class hides:** `.dsk-sidebar`, `.bnav`, `#sync-indicator`, `#ver-tag`, `.hdr-sub`. On desktop it collapses the grid to a single column.

**Toggle button:** `#field-mode-toggle` in `.hdr-right`. Label is "⊞ Field" in normal mode, "← Detail" in field mode. Set by `setFieldModeUI(active)`.

**Routing on `?field=feed`:** `applyFieldMode()` calls `nav('feed',…)` then `setTimeout(openQuickFeedSheet, 180)`.

**Home screen branching:** `renderHome()` checks `body.field-mode` and delegates to `renderFieldHome()` when active. `renderFieldHome()` is currently a stub — see **OI-0006** for full tile grid implementation.

**User schema addition:** `user.fieldMode: false` added to `addUser()`. Field is optional on existing user objects — `getActiveUser().fieldMode` falsy = detail mode.

**PWA manifest shortcut:** `/?field=feed` → "Log Feed" — appears on long-press of the home screen icon after PWA install.

---

## Deploy Process

1. Edit `get-the-hay-out.html`
2. Bump build stamp at line 8: `<meta name="app-version" content="bYYYYMMDD.HHMM">`
3. Run `deploy.py` — auto-stamps build version into the HTML
4. Push to GitHub → GitHub Pages serves at getthehayout.com
5. `sw.js` handles caching; update banner prompts user to reload on new version
6. After deploying, upload the new HTML to the Claude Project to keep the base file current
