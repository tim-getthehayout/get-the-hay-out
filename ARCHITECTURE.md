# Get The Hay Out — Living Architecture Map
**File:** `get-the-hay-out.html` (~14,532 lines · ~724KB · single-file PWA)
**Deploy:** `deploy.py` → GitHub Pages → getthehayout.com
**Current build:** `b20260405.1932`
**Last updated:** 2026-04-05

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
| 1–460 | `<head>`: meta, PWA manifest (line 8 = build stamp), inline `<style>` CSS |
| 461–526 | `<body>`: desktop sidebar nav (220px fixed, IDs: `#dbn-*`) |
| 527–1367 | Screen divs (`#s-home` through `#s-settings`) + mobile bottom nav (`#bn-*`) |
| 1368–1452 | Global sheet overlays always in DOM: `#fb-sheet-wrap`, `#resolve-sheet-wrap`, `#todo-sheet-wrap` |
| ~1649 | Supabase JS SDK CDN `<script>` tag (moved from `<head>` to body in b20260329.2238 — `document.body` null fix) |
| ~1650 | Main app `<script>` tag + JS Section TOC comment block |
| ~1533 | App Update Banner |
| ~1594 | Data init (`S` object), localStorage keys, save helpers |
| ~1682 | **Supabase M3 write path:** `_sbToSnake`, `_pastureRow`, shape functions (`_animalRow`, `_batchRow`, `_feedTypeRow`, `_animalClassRow`, `_animalGroupRow`, `_aiBullRow`, `_inputProductRow`, `_todoRow`, `_treatmentTypeRow`, `_animalGroupMembershipRow`, `_animalWeightRecordRow`, `_manureBatchTransactionRow`, `_surveyRow`, `_inputApplicationRow`, `_manureBatchRow`), `FLUSH_TIERS`, `_FLUSH_TIER_MAP`, `_flushOneOp`, `queueWrite`, `queueEventWrite`, `ensureQueueFlushed`, `flushToSupabase`, `deleteOperationData`, `supabaseSyncDebounced`, `setSyncStatus` |
| ~1745 | **Supabase auth (M1):** `SUPABASE_URL`, `SUPABASE_KEY` constants; `_sbClient`, `_sbSession` module vars; `sbInitClient()`, `sbSignIn()`, `sbSignOut()`, `sbUpdateAuthUI()` |
| ~1984 | Export / Import JSON (including `importDataJSON` full-replace + Drive force-write) |
| ~2138 | Nav routing |
| ~2164 | User system |
| ~2238 | Desktop dashboard header + Mobile perf strip |
> **Header layout (b20260324.1030):** Mobile uses `flex-direction:column` — title/op-name on row 1, sync/build/field/avatar on row 2. Desktop overrides back to single-row via `body.desktop .hdr`. Op name in `updateHeader()` shows operation name only — head count removed.
| ~2532 | Home screen + group cards + `renderFieldHome()` (field mode: tiles + tasks + events) |
| ~2627 | Home view toggle (`renderHomeViewToggle`, `setHomeViewMode`) + Locations view (`renderLocationsView`, `renderLocationCard`, `renderUnplacedGroupsSection`) |
> **Event tile redesign (b20260403.0022):** `renderLocationCard(ev, opts)` fully rewritten — section-based layout: header (color bar, name + acreage, badge, day/date/cost, Edit + Move All buttons) → SUB-PADDOCKS (conditional, active = green dot with halo) → GROUPS (per-group Move → move wizard + ⚖ weigh) → stacked DMI bars (`_renderDMIBars()`, 3-day, green grazing / amber stored) → Feed check button (amber, conditional on stored feed) → DMI summary + progress bar → NPK (pasture only) → Feed button. `opts.compact` mode for field mode expanded cards (no ⚖, no NPK, compact action row). Badge logic: "grazing" (pure pasture), "stored feed" (noPasture/confinement), "stored feed & grazing" (has feed entries + pasture time, split gradient). Move buttons call `openMoveWizSheet()` not `openEventEdit()` (OI-0150 fix).
> **FIELD_MODULES (b20260403.0022):** Added `move` (Move Animals 🚜, `_fieldModeMoveHandler`) and `feedcheck` (Feed Check 📋, `_fieldModeFeedCheckHandler`). Default active set unchanged (`['feed','harvest','survey','animals']`).
> **Quick Feed picker (b20260324.1730):** `qfShowEventStep()` is now location-centric — shows location name + type badge as primary, group names as secondary. Cancel button (`#qf-step1-cancel`) added to step-1 picker, hidden on step-2.
> **Desktop grid fix (b20260405.0134):** `renderHomeViewToggle` and `renderUnplacedGroupsSection` now emit `grid-column:1/-1` so they span both columns of the desktop 2-column `#home-groups` grid. Previously the toggle occupied one grid cell, pushing the first location card into column 2 and leaving dead space in column 1.
| ~2921 | To-Do system |
| ~3070 | Feed screen + Quick Feed sheet + Feed Types + Feed Goal + goFeedGroup |
| ~3417 | Move Wizard (legacy full-page nav-based wizard — retained for nav-bar "Move" button; card-level moves now use `openMoveWizSheet()` sheet overlay) |
| ~3549 | Events section header + `switchEventsView()` + Rotation Calendar engine |
| ~4212 | Pasture Survey |
> **Pasture Survey (b20260325.1918):** Both multi-pasture and single-pasture survey modes now render all fields consolidated per card — forage quality slider, veg height (inches), forage cover (%), and recovery min/max with live graze window preview. Multi-pasture previously split rating cards and recovery windows into separate scrollable sections; these are now a single per-paddock card. Two new state dicts: `surveyVegHeight`, `surveyForageCover`. Data model: each rating entry in `S.surveys[].ratings[]` now includes optional `vegHeight` (inches, float) and `forageCover` (%, float). The separate `#survey-recovery-list` DOM element and `#survey-recovery-section-hdr` are retained in HTML but set to empty/hidden at render time. OI-0010 (expected graze dates) resolved — the live `rec-preview-` block in each card supersedes the old static `gdHtml` approach.
| ~4780 | Multi-paddock wizard helpers + Event Edit multi-paddock |
| ~5347 | Treatment Types, AI Bulls, Manage sheets (classes/treatments/sires) + `TREATMENT_CATEGORIES` |
| ~5598 | Batch Adjustment / Reconcile |
| ~5805 | **`renderEventsLog()`** ← displaced here by Batch Adj insertion; logically part of Events section above. Now renders consolidated parent + sub-move thread (OI-0029, b20260329.1751). **Active rotation banner (b20260405.0134):** now loops over `getActiveEvents()` (all open events) instead of `getActive()` (single event). Each active event gets its own green banner with paddock chips, day count, group names via `evGroups()`. |
| ~5954 | Pastures screen + recovery date helpers + **Survey system (OI-0115):** `openBulkSurveySheet`, `openSurveySheet(pastureId, surveyId)`, `saveSurveyDraft`, `completeBulkSurvey`, `discardSurvey`, `updateSurveyReading`, `deleteSurveyReading`, `renderSurveysTab`, `renderPastureEditHistory`, `setPasturesView`, `openBulkSurveyEdit`, `pasturesView` |
| ~6030 | Settings screen — includes Sync queue inspector card (`renderSyncQueueInspector`, `exportSyncQueue`) |
| ~6222 | **Submissions tab** (formerly Feedback) + Dev Brief + Export CSV. `renderFeedbackTab()` → `renderConfirmSection()` + `renderFeedbackStats()` + `renderFeedbackList()`. Edit sheet: `openEditSubmissionSheet(id)`, `saveEditSubmission()`, `deleteSubmission(id)`, `closeEditSubmissionSheet()`. Shape function: `_submissionRow(f,opId)`. Type system: `selTypeVal` module var; `selFbType(type,btn)`; `_fbUpdateTypeUI(type)`. |
| ~6432 | Manure system |
| ~6532 | Animal Classes & Groups + Add/Edit Group sheet + Animal Health Events |
| ~7579 | Individual Animals (add/edit/cull) |
| ~7969 | Add/Edit Group sheet (`openAddGroupSheet`, `openEditGroupSheet`, `closeAddGroupSheet`) |
| ~8311 | Setup Template Export / Import (XLSX) |
| ~8797 | Stats Engine |
| ~8901 | Calving sheet |
| ~9030 | Sub-move system (`openSubMoveSheet`, `saveSubMove`, `calcEventTotalsWithSubMoves`, `lastGrazingRecordForPasture`); **`_memberWeightedDays`** (OI-0021 — membership-weighted AUD helper, fallback for multi-group/no-data) |
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
| ~15587 | App init tail: `visibilitychange` → `flushToSupabase()`; M5-B `online`/`offline` connectivity listeners |

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
| `feedback` | `#s-feedback` | `renderFeedbackTab()` | `#dbn-feedback` (desktop only — removed from mobile bnav in b20260401.0016) |
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
| Submit feedback / Get Help | `#fb-sheet-wrap` | `openFeedbackSheet()` | `closeFeedbackSheet()` |
| Resolve feedback | `#resolve-sheet-wrap` | `openResolveSheet(id)` | `closeResolveSheet()` |
| Edit submission | `#edit-sub-wrap` | `openEditSubmissionSheet(id)` | `closeEditSubmissionSheet()` |
| To-do add/edit | `#todo-sheet-wrap` | `openTodoSheet(id)` | `closeTodoSheet()` / `deleteTodo()` |
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
| **Move wizard (3-step)** | `#move-wiz-wrap` | **`openMoveWizSheet(evId, groupId, moveAll)`** | **`closeMoveWizSheet()`** | **b20260405.0134.** 3-step flow: Step 1 Where? → Step 2a paddock picker / 2b event picker → Step 3 confirm. **Step 3 redesign (b20260405.0134):** FROM section (red accent bar) on top with close-out survey embedded (residual height + recovery min/max only — forage quality and forage cover removed); TO section (green accent bar) on bottom with arrival survey for new pasture destinations. Existing event destinations show TO header with ✎ re-pick. State: `_mwStep`, `_mwSourceEvId`, `_mwGroupIds`, `_mwMoveAll`, `_mwDestType`, `_mwDestPaddockId`, `_mwDestEventId`. |
| **Close sub-paddock** | `#close-sub-paddock-wrap` | **`openCloseSubPaddockSheet(evId, smId)`** | **`closeCloseSubPaddockSheet()`** | **b20260403.0022.** Single-screen: sub-paddock info, close date/time, pasture close-out survey (height, cover, quality, recovery min/max), anchor paddock info box. Fixes OI-0152 width. |
| **Feed check** | `#feed-check-wrap` | **`openFeedCheckSheet(evId)`** | **`closeFeedCheckSheet()`** | **b20260403.0038.** Per-feed-type dual-input dialog: stepper (−/+/direct, 2dp) + percentage + slider, all bidirectionally linked. Groups entries by feedTypeId. "Consumed since last check" amber summary. Saves `typeChecks[]` on check record + backward-compat `balesRemainingPct`. State: `_fcEvId`, `_fcTypeData[]`. |
| **Add group to event** | `#add-grp-ev-wrap` | **`openAddGroupToEventSheet(evId)`** | **`closeAddGroupToEventSheet()`** | **b20260403.1018.** Group picker launched from "+ Add group" on home event card. Shows all groups with status (already here / at location / not placed). Handles source-event removal + close-if-last. z-index:210. State: `_ageTargetEvId`. |
| **Sign-out confirmation** | `#signout-sheet-wrap` | **`openSignOutSheet()`** | **`closeSignOutSheet()`** | **OI-0171 b20260404.** Avatar, email, descriptive text, red "Sign out" button, Cancel. Triggered by `#hdr-avatar` onclick. Only opens when `_sbSession` is non-null. Confirm calls `sbSignOut()` which re-renders auth overlay. |

---

## Data Model (`S` — persisted to `localStorage['gthy']`)

| Key | Type | Description |
|---|---|---|
| `S.pastures` | Array | All locations. `locationType`: `"pasture"` or `"confinement"` |
| `S.events` | Array | Grazing events (open + closed). Core ledger. Contains `feedEntries[]` sub-records. Each event now carries `groups[]` array (group entries with `groupId`, `groupName`, `dateAdded`, `dateRemoved`). Legacy `groupId` scalar kept for backward compat — always equals `groups[0].groupId`. |
| `S.feedTypes` | Array | Feed type templates (unit, DM%, category). **M0b-J:** optional `nPct`, `pPct`, `kPct` fields (hay analysis — from lab test). **M7-E:** `forageTypeId` FK to `S.forageTypes[]`. **OI-0122:** `cuttingNum` (`null|1|2|3|4`) — which cutting this product is; `harvestActive` (`bool`) — when `true`, feed type appears as a tile in the harvest sheet. Season flip: farmer unflag 1st cut, flag 2nd cut. Feed type card shows `C1`/`C2` badge + inline toggle pill. **OI-0127:** `defaultWeightLbs` (`null|number`) — default weight per bale/unit in lbs; pre-populates weight field on new harvest field rows. |
| `S.batches` | Array | Feed batches (specific deliveries; `typeId` links to feedType) |
| `S.manureBatches` | Array | Manure batches captured from confinement events |
| `S.inputProducts` | Array | Commercial amendment products |
| `S.inputApplications` | Array | Records of input products applied to pastures |
| `S.animalClasses` | Array | Species/class definitions (default weight, DMI%) |
| `S.animalGroups` | Array | Named herd compositions. Fields: `id`, `name`, `color`, `animalIds[]`, `classes[]`, `archived` |
| `S.animals` | Array | Individual animal records |
| `S.users` | Array | Farm users (legacy shim — identity is now Supabase `operation_members`; retained for todo assignment compat) |
| `S.todos` | Array | Farm task records |
| `S.feedback` | Array | Submissions (feedback + support tickets). JS state key unchanged; Supabase table renamed to `submissions` in b20260401.2022. |
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
| `deleteTodo()` | **b20260402.0940** Deletes the currently-editing todo (`todoEditId`). Confirmation prompt → removes from `S.todos` → direct Supabase delete on `todos` table → `save()`, `closeTodoSheet()`, `updateTodoBadge()`, re-renders. Delete button visible in edit mode only (`#todo-delete-wrap`). |
| `openEeAnchorClose()` / `cancelEeAnchorClose()` | **b20260328.0140** Anchor close sequence. Reveals pre-flight checklist block (`#ee-anchor-close-wrap`) with step completion indicators. |
| `saveAndCloseFromEdit()` | **b20260328.0140** Saves event edit then calls `moveAllGroupsInEvent(evId)` via 100ms timeout to launch Move Wizard for all active groups. |
| `addEeGroup()` | Adds a group to `eeGroups[]` with `_isNew:true`. Calls `syncEeGroupTotals()`. |
| `startMoveGroup(idx)` | Initiates departure for a saved-active group: sets `dateRemoved` to today and `_moveAction = 'picking'` to show destination selector. Primary-group (idx===0) is protected. Replaces the `closeGroup()` name documented in earlier sessions — that function does not exist. |
| `setMoveGroupExisting(idx, targetEvId)` | Sets `_moveAction = 'existing'` and records the target event ID for post-save attachment. |
| `setMoveGroupWizard(idx)` | Sets `_moveAction = 'wizard'` so the wizard opens for this group after event save. |
| `cancelGroupMove(idx)` | Clears `dateRemoved` and all `_moveAction` state for a group in the edit sheet. |
| `reopenGroup(idx)` | Clears `dateRemoved` and all move state on `eeGroups[idx]`. Parallel to `reopenPaddock`. |
| `renderEeGroupChips()` | Renders group chips with four states: primary (locked), unsaved (×), saved-active (Move Group button), saved-closed (Undo button). All groups show editable `dateAdded`/`timeAdded` inputs. Moved groups additionally show editable `dateRemoved`/`timeRemoved`. (b20260402.1048: editable dates expanded from new-only to all groups.) |
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
| `exportFeedbackJSON()` | Exports `S.feedback` as `gthy-feedback-YYYY-MM-DD-HHMM.json` for Claude session import into OPEN_ITEMS.md. Distinct from the full backup — submissions only, structured for machine parsing. Includes `type` and `app` fields as of b20260401.2022. |
| `exportFeedbackCSV()` | Human-readable CSV export of submissions. For record-keeping; Claude uses the JSON export. |
| `exportDataJSON()` | Full data backup as `gthy-backup-YYYY-MM-DD-HHMM.json`. Full replacement restore — not merged. |
| `flushToSupabase()` | **OI-0175 rewrite:** Groups queue by table, flushes in 5 FK dependency tiers (`FLUSH_TIERS`). Single-item fast path skips grouping. Within each tier, fires all ops in parallel via `Promise.all`, awaits between tiers. `_delete:` prefixed entries handled by extracting real table for tier lookup. Unknown tables flush in safety-net catch-all with `console.warn`. |
| `_flushOneOp(op, failed)` | Helper for `flushToSupabase()`. Processes one queue entry — upsert (with `_sanitizeQueueRecord`) or delete. Pushes to `failed[]` on error. |
| `FLUSH_TIERS` / `_FLUSH_TIER_MAP` | 5-tier array of table names in FK dependency order. `_FLUSH_TIER_MAP` is O(1) table→tier lookup. Defined near `_SB_ALLOWED_COLS`. |
| `pushAllToSupabase()` | Full re-push of entire S state to Supabase. Uses dedicated shape functions for all tables (no more raw `_sbToSnake` for `input_applications`). Includes `manure_batches` (OI-0179). `flushToSupabase()` handles FK ordering. Called by `importDataJSON()` after `deleteOperationData()`. |
| `deleteOperationData(opId)` | **OI-0178:** Deletes all operation data from Supabase in reverse tier order (Tier 4→1). Skips Tier 0 (operation identity). Each tier deletes in parallel. Called by `importDataJSON()` before `pushAllToSupabase()` during backup restore. |
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
Events now support multiple groups via `ev.groups[]`, parallel to `ev.paddocks[]`. Each entry carries `groupId`, `groupName` (snapshot), `dateAdded`, `timeAdded`, `dateRemoved`, `timeRemoved`. The legacy `ev.groupId` scalar is kept pointing at `groups[0].groupId` for backward compat with any code that hasn't been updated.

**Date/time fields (b20260402.1017):** `timeAdded` and `timeRemoved` are optional time strings (e.g. `"14:30"`). When a group is moved to an existing event, `dateAdded`/`timeAdded` on the destination are set from `dateRemoved`/`timeRemoved` on the source. The event edit group chip UI provides editable date + time pickers for new groups (`dateAdded` + `timeAdded`) and moved groups (`dateRemoved` + `timeRemoved`). Supabase columns: `event_group_memberships.time_added`, `event_group_memberships.time_removed`.

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
- `sm.dateOut` — date returned (optional; set at close time via `saveSmClose()`, OR at creation time via `saveSubMove()` add form using `sm-date-out` field — b20260402.1017)
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
- Triggered by: `saveSubMove()` — creates with `durationHours: 0` if no hours entered
- UI path: Home → Sub-move button → "Add sub-move" form at bottom of sheet
- `sm-date-out` field (b20260402.1017): allows recording return date at creation time for completed sub-moves; `calcSmDuration()` uses full date+time math to support multi-day sub-moves

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

### wizSaveNew — Auto-Close Group Records in Old Events (b20260402.1048)
Before creating the new event, `wizSaveNew()` iterates `wizGroupIds` and for each group:
1. Finds the active event via `getActiveEventForGroup(gId)`
2. Finds the group record with `dateRemoved === null`
3. Sets `dateRemoved = inDate` and `timeRemoved = inTime` (the new event's arrival date/time)
4. Queues the old event for Supabase write

**Last-group-out rule:** If no active groups remain after the departures, the old event is auto-closed: `status='closed'`, `dateOut` set, `recalcEventTotals()` called. This mirrors the identical guard in `saveEventEdit()`.

**Root cause:** Prior to this fix, `wizSaveNew()` created a new event without closing the group's record in the old event. In multi-group events (e.g. Corral with 4 groups), `wizCloseEvent()` would close the *entire* event which is wrong when other groups remain. The only safe path was Event Edit → Move Group, but the wizard "Place" button on the home screen bypassed that flow.

### wizCloseEvent — Date/Time Inheritance to Step 2 (b20260402.1048)
After building the close summary and calling `wizGo(1)`, the function now propagates `outDate` → `w-in-date` and `ae.timeOut` → `w-in-time`. When the user clicks "Open new grazing event" in step 1, the step 2 arrival fields already reflect the departure date/time (but remain user-editable).

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

Sub-move blocks use `c.win.smNoPasture` (stored at window build time from `!!sm.noPasture`) to pick green vs tan independently of the parent event — a bale-grazing sub-move on a pasture paddock correctly renders green.

`grpColor()` is no longer called from within `renderRotationCalendar()`.

**Legend (as of b20260331.2211 — OI-0069):** Two computed flags drive all four possible legend entries:
- `hasStoredFeedSubMoves` — any `sm.noPasture=true` across all events
- `hasTanBlocks` — `hasStoredFeedSubMoves` OR any main event is stored-feed/confinement

| Swatch | Condition |
|---|---|
| Green solid — "Pasture grazing" | Always shown |
| Tan solid — "Hay / stored feed" | `hasTanBlocks` |
| Green dashed — "Pasture sub-move" | Always shown |
| Tan dashed — "Stored feed sub-move" | `hasStoredFeedSubMoves` |

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
| Project URL | `https://oihivpwftpngbhwpjsqt.supabase.co` |
| SDK | `@supabase/supabase-js@2` — UMD bundle via jsDelivr CDN |
| Auth method | Native email OTP (`signInWithOtp` + `verifyOtp`) |
| Session persistence | Supabase stores session in `localStorage['sb-*']` automatically |
| Token refresh | Handled by `onAuthStateChange` listener — no manual refresh needed |
| Client var | `_sbClient` — module-level, initialized by `sbInitClient()` at app init |
| Session var | `_sbSession` — updated by `onAuthStateChange`, read by `sbUpdateAuthUI()` |
| Operation var | `_sbOperationId` — UUID; cached in `localStorage['gthy-operation-id']` |
| Realtime var | `_sbRealtimeChannel` — active Supabase channel; replaced on re-subscribe |
| Write queue | `gthy-sync-queue` localStorage key — array of `{table, record}` ops |

**Auth flow (M2 — OTP code, b20260328.1211; overlay added OI-0171 b20260404; password-default + step 3 b20260405):**
1. App loads → inline `<script>` synchronously checks `localStorage['sb-oihivpwftpngbhwpjsqt-auth-token']`
2. If key exists → `#auth-overlay` removed from DOM before first paint (no flash for signed-in users)
3. If key missing → `#auth-overlay` stays visible; default mode is **email + password** (returning users). Toggle link "First time? Use email code instead" switches to OTP mode.
4. Password path (default): `aoSignInWithPassword()` calls `signInWithPassword()` → `onAuthStateChange` fires `SIGNED_IN` → load chain runs → `_dismissAuthOverlay()` called after `loadFromSupabase()` completes
5. OTP path (toggled): `aoSendCode()` calls `signInWithOtp({ email })` → step-2 shown → `aoVerifyOtp()` calls `verifyOtp()` → `sbPostSignInCheck()` → step-3 shown (set up account)
6. Step 3: user sets display name + password via `aoSaveAccount()` (calls `auth.updateUser({password})` + writes `operation_members.display_name`). "Skip for now →" via `aoSkipSetup()` dismisses without setting password.
7. Sign-out: `openSignOutSheet()` → confirm → `sbSignOut()` → `_renderAuthOverlay()` re-creates overlay DOM

**Auth overlay lifecycle (OI-0171, b20260404; updated b20260405):**
- `#auth-overlay` — full-screen branded overlay (z-index:500, above sheets/nav). Green gradient, GTHY logo+tagline, white card. Three steps: (1) email+password or email-only, (2) OTP code entry, (3) set up account (name + password).
- **Default mode is password** — `_aoPasswordMode = true`. Password field visible, button "Sign in". Toggle flips to OTP mode ("Continue" button, password hidden). `aoTogglePassword()` updates field visibility, button text, toggle text, and email Enter-key behaviour.
- **Rendered in static HTML** — present from first paint for unsigned users. Inline `<script>` immediately after the overlay checks `sb-*-auth-token` localStorage key and removes overlay synchronously if found. This means signed-in users never see the overlay; unsigned users see it before any JS runs.
- **Removed from DOM on auth success** — not hidden. `_dismissAuthOverlay()` calls `el.remove()`. Prevents stale DOM from interfering with sheet z-index stack.
- **Re-created on sign-out** — `_renderAuthOverlay()` builds overlay innerHTML and inserts at `document.body.firstChild`. Resets `_aoPasswordMode = true`.
- **Step 3 (set up account)** — shown after OTP verification only, not after password sign-in. `aoVerifyOtp()` advances to step 3 instead of dismissing. Pre-fills name from cached identity. `aoSaveAccount()` sets password via `auth.updateUser()`, writes display name to `operation_members`, refreshes identity cache. `aoSkipSetup()` dismisses without saving.
- **Settings card simplified** — sign-in and sign-out UI removed. Card shows: connected banner (email), display name input, sync queue inspector, operation members list.
- **Header avatar** — `#hdr-avatar` onclick is `openSignOutSheet()`. Only opens when `_sbSession` is non-null.

**`sbPostSignInCheck` bootstrap fix (b20260405):** Previously, when a new user had no `operation_members` row and no pending invite, `sbPostSignInCheck()` did nothing — relied on `onAuthStateChange` → `sbGetOperationId()` to bootstrap. This was a race condition; the concurrent paths could interfere. Now `sbPostSignInCheck()` calls `sbBootstrapOperation()` directly when `member` is null AND `_sbOperationId` is null (genuine new user). This is the authoritative bootstrap path for OTP sign-in.

**`sbBootstrapOperation` dedup guard (b20260405.1113):** Both `sbPostSignInCheck()` and `onAuthStateChange` → `sbGetOperationId()` can call `sbBootstrapOperation()` concurrently after OTP verification. A boolean flag was insufficient because both async paths could pass the check before either awaited the insert. Replaced with `_sbBootstrapPromise` — the first caller creates and stores the promise; the second caller awaits the same promise instead of starting a new bootstrap. Promise is cleared in `finally`.

**`_sbProfile` set during bootstrap (b20260405.1137):** `sbBootstrapOperation()` now sets `_sbProfile = { operation_id, role:'owner', display_name, field_mode:false }` after creating the member row. Previously `_sbProfile` was only set when `sbPostSignInCheck()` found an existing member row, so `isAdmin()` returned `false` for newly bootstrapped owners until the next page load.

**Sign-out sheet (`#signout-sheet-wrap`, OI-0171):** Bottom sheet showing avatar circle, display name, email, descriptive text ("Sign out of this device? Unsynced changes will be saved locally until you sign back in."), red "Sign out" button, Cancel. `openSignOutSheet()` dynamically renders content from `_sbSession` + `_sbLoadCachedIdentity()`. Confirm → `closeSignOutSheet()` + `sbSignOut()`.

**Why OTP instead of magic link:** Magic link clicks open in regular Safari. PWA and Safari have isolated `localStorage` contexts — Supabase writes `sb-*` session tokens to Safari's storage; the PWA never sees them. `onAuthStateChange` never fires in the PWA. OTP sidesteps this entirely — the code is verified in-app, session tokens are written directly to PWA localStorage.

**Requires Supabase Dashboard change:** Authentication → Email Templates → Magic Link → replace `{{ .ConfirmationURL }}` with `{{ .Token }}` in email body.

**M2 load chain (triggered by `SIGNED_IN` or `INITIAL_SESSION`):**
1. `sbGetOperationId()` — queries `operation_members` for the user's `operation_id`; calls `sbBootstrapOperation()` ONLY on genuine first sign-in (no row found AND no cached ID). On error or null result with cached ID, returns cached ID — never bootstraps a returning user.
2. `loadFromSupabase(opId)` — parallel-fetches all tables; assembles S from Supabase rows; calls all migrate guards; `saveLocal()`; re-renders
3. `subscribeRealtime(opId)` — opens a Supabase channel; one `postgres_changes` listener per watched table; changes are debounced 2s and respect `_sbLoadInProgress` guard

**Load concurrency guard (`_sbLoadInProgress`):** Supabase SDK fires `SIGNED_IN` on every JWT token refresh (~5 min), not just genuine sign-ins. Without this flag, token refresh during an active load would launch a concurrent second load. Auth handler sets `_sbLoadInProgress = true` before the load chain and clears it in a `finally` block. Realtime callback also checks this flag before scheduling a debounced reload. Reset on `SIGNED_OUT`.

**JWT-refresh skip guard (`_sbHasLoadedOnce` + `_sbLastLoadAt`, b20260401.0946):** Prevents repeated full reloads on every JWT refresh (~5 min). After the first successful `loadFromSupabase()`, `_sbHasLoadedOnce` is set `true` and `_sbLastLoadAt` records the timestamp. Auth handler skips the load chain if both flags indicate a load completed within the last 10 minutes — JWT-refresh SIGNED_IN events are silently ignored during this window. A >10-min gap re-allows a full reload (catches changes missed while app was backgrounded). Both flags reset on `SIGNED_OUT` so a genuine sign-in always loads fresh.

**iOS wake pre-flight probe (`loadFromSupabase`, b20260401.0946):** iOS wakes a PWA before the network stack is fully ready. Auth fires `SIGNED_IN` immediately on wake but all fetches return `TypeError: Load failed` for ~0.5–2s while the radio re-associates — producing a ~20-entry error log cascade. `loadFromSupabase()` now opens with a probe loop: one lightweight `.select('id').limit(1)` on `pastures`, retried up to 3× with 1.5s backoff. If the probe gets any Supabase-level error (has a `.code`) the network is up and the full load proceeds. If all 3 probe attempts return `"Load failed"` (transport failure), the function sets sync status to error and returns cleanly — zero cascade entries. Any other path proceeds to the 24-table `Promise.all` as before.

**Farms fetch-ok flag (`_sbFarmsFetchOk`):** Set `true` only when the `farms` table fetch succeeds (returns data or confirmed empty). Used by `migrateHomeFarm()` to distinguish "no farms in Supabase" from "network/RLS failure returned empty". Reset on `SIGNED_OUT`.

**Identity system (M2 + M6):**
- `getActiveUser()` reads: `_sbProfile` (live operation_members row) → Supabase session → `gthy-identity` localStorage cache → guest fallback
- Always returns non-null `{id, name, email, color, role, fieldMode}` — render functions never need null guards
- `sbCacheIdentity(displayName, operationId)` — writes/refreshes the `gthy-identity` cache
- `_sbProfile` — module var holding the current user's `operation_members` row `{role, display_name, field_mode}`; set by `sbGetOperationId()` and `sbPostSignInCheck()`; cleared on `SIGNED_OUT`
- `isAdmin()` — returns `true` if `_sbProfile.role === 'owner'` or `'admin'`; falls back to `true` when not signed in (offline / single-user mode)
- `S.users[]` retained as inert shim for todo assignment compat; no longer the identity source
- `openUserPicker()` redirects to Settings (no local user picker in Supabase world)

**Key functions (M2):**

| Function | Location | Purpose |
|---|---|---|
| `sbGetOperationId()` | ~L1895 | Query `operation_members` (role, display_name, field_mode); populate `_sbProfile`; cache op_id; bootstrap if none |
| `sbBootstrapOperation()` | ~L1920 | Create `operations` + `operation_members` on first sign-in |
| `sbCacheIdentity(name, opId)` | ~L1877 | Write/refresh `gthy-identity` localStorage cache |
| `getActiveUser()` | ~L2239 | M6 identity: `_sbProfile` → session → cache → guest |
| `isAdmin()` | ~L2180 | `_sbProfile.role === 'owner'\|\|'admin'`; true when offline |
| `sbInviteMember(email, role)` | ~L2185 | Insert pending `operation_members` row + send OTP to invitee |
| `sbPostSignInCheck(user)` | ~L2795 | Claim pending invite via RPC; load member row; set `_sbProfile`; load farm. **b20260405:** if no member row AND no cached `_sbOperationId`, calls `sbBootstrapOperation()` directly (fixes new-user bootstrap race). |
| `renderOperationMembersList()` | ~L3490 | Async render of members card — accepted + pending rows; admin gates |
| `sbRemoveMember(id)` | ~L3540 | Delete accepted member row (admin only) |
| `sbCancelInvite(id)` | ~L3550 | Delete pending invite row (admin only) |
| `_sbLoadCachedIdentity()` | ~L1872 | Read `gthy-identity` cache safely |
| `_sbToCamel(obj)` | ~L1958 | snake_case → camelCase converter for Supabase rows |
| `_sbFetch(table, opId)` | ~L1970 | Safe per-table fetch; returns `[]` on error |
| `_animalRow` | ~L2695 | Maps JS animal → `animals` table. Fields: id, tag (tagNum→tag), name, sex, class_id, birth/wean fields, **confirmed_bred, confirmed_bred_date** (added b20260330.1056 — were missing, silent data loss on bred flag), dam_id, status, cull_date/reason, notes, updated_at |
| `_batchRow` | ~L2716 | Maps JS batch → `batches` table. Fields: id, feed_type_id, name, quantity, unit, **wt, archived** (added b20260330.1056 — were missing, batch edits and archiving never synced), dm_pct, cost_per_unit, purchase_date, notes, updated_at |
| `_feedTypeRow` | ~L2732 | Maps JS feedType → `feed_types` table. Fields: id, name, dm_pct, unit, **cost_per_unit** (added b20260330.1056 — column in schema, never written), n/p/k_pct, archived, setup_updated_at |
| `assembleEvents(rows)` | ~L1984 | Re-nest event sub-tables. Reconstructs `feedEntries[].lines[]` from flat `event_feed_deliveries` rows (grouped by date). Reconstructs `subMoves[].feedEntries[]` per sub-move. Derives `ev.locationType` from `S.pastures` lookup. Adds `locationType` fallback to paddock entries. |
| `assembleAnimals(rows)` | ~L2001 | Re-nest `animal_health_events` (via FK hint `!animal_health_events_animal_id_fkey` — required because `calving_calf_id` also references `animals`, creating an ambiguous join). Reconstructs `calvingRecords[]` from health events with `type='calving'`. Field aliases: `tag`→`tagNum`, `status`→`active` (bool), `cullDate/cullReason`→`cullRecord{}`. Derives `weightLbs` from latest `S.animalWeightRecords` entry. |
| `assembleGroups(rows)` | ~L2011 | Re-nest `animal_group_class_compositions`. Derives `animalIds[]` from `S.animalGroupMemberships` (open rows, `dateLeft` null) — not stored as an empty array. |
| `assembleGroups(rows)` | ~L2011 | Re-nest `animal_group_class_compositions` |
| `assembleManureBatches(rows)` | ~L2021 | Re-nest `manure_batch_transactions` |
| `assembleInputApplications(rows)` | ~L2030 | Re-nest `input_application_locations` |
| `loadFromSupabase(opId)` | ~L2048 | Full parallel load; assembles S from Supabase; re-renders |
| `subscribeRealtime(opId)` | ~L2172 | Postgres realtime channel; full reload on any change |

**Auth overlay functions (OI-0171, b20260404; step 3 added b20260405):**

| Function | Purpose |
|---|---|
| `aoSignIn()` | Dispatcher — routes to `aoSendCode()` or `aoSignInWithPassword()` based on `_aoPasswordMode` (default: password) |
| `aoSendCode()` | Send OTP code via `signInWithOtp()` using overlay `#ao-email` input; advance to step 2 |
| `aoSignInWithPassword()` | Password sign-in via `signInWithPassword()` using overlay `#ao-email` + `#ao-pw` inputs |
| `aoVerifyOtp()` | Verify OTP code via `verifyOtp()` using overlay `#ao-otp` input; calls `sbPostSignInCheck()` then advances to step 3 (set up account) |
| `aoBackToStep1()` | Reset overlay back to email entry step |
| `aoTogglePassword()` | Toggle `_aoPasswordMode` — shows/hides password field, updates button/toggle labels and email Enter-key behaviour |
| `aoSaveAccount()` | Step 3: set password via `auth.updateUser({password})`, save display name to `operation_members` + identity cache, dismiss overlay |
| `aoSkipSetup()` | Step 3: dismiss overlay without setting password |
| `_aoStatus(stepId, msg, isError)` | Set status text in overlay step status divs |
| `_dismissAuthOverlay()` | Remove `#auth-overlay` from DOM. No-op if already removed. |
| `_renderAuthOverlay()` | Create `#auth-overlay` DOM element and insert at `document.body.firstChild`. No-op if already present. Resets `_aoPasswordMode = true`. |
| `openSignOutSheet()` | Render sign-out confirmation sheet with avatar, email, buttons. No-op if `_sbSession` is null. |
| `closeSignOutSheet()` | Close `#signout-sheet-wrap` |


**Correct RLS policy set (as of b20260328.1221 — post-bootstrap testing):**

The schema in §3d of MIGRATION_PLAN has recursive policies that cause 500 errors on first sign-in.
The working policy set for `operations` and `operation_members` is:

```sql
-- operation_members: own rows (direct user_id) + member access via helper
create policy "own rows"        on operation_members for select using (user_id = auth.uid());
create policy "own rows update" on operation_members for update using (user_id = auth.uid());
create policy "self insert"     on operation_members for insert with check (user_id = auth.uid());
create policy "operation_member_access" on operation_members for select using (
  operation_id = get_my_operation_id()
);

-- operations: owner-direct check + member-based access via get_my_operation_id() helper
create policy "owner select"    on operations for select using (owner_id = auth.uid());
create policy "owner insert"    on operations for insert with check (owner_id = auth.uid());
create policy "operation_member_access" on operations for select using (
  id = get_my_operation_id()
);
```

**Pattern:** Both `operations` and `operation_members` include `operation_member_access` policy using the `get_my_operation_id()` SECURITY DEFINER helper (see RLS Policy Pattern section below). This allows:
- Owners to read/insert their own operations (direct owner_id check)
- Workers to read operations and members they belong to (via helper — avoids RLS recursion)
- Pending invite rows (`user_id IS NULL`) to be claimed via `claim_pending_invite()` SECURITY DEFINER function

All other tables retain the template `operation_members` subquery policy via `get_my_operation_id()` — the recursion only occurs when `operation_members` queries itself.

**OTP rate limit note:** Supabase free tier allows 2 OTP emails per hour per address.
Exceeded limit returns "email rate limit exceeded" from `sbSendCode`. Sessions persist
across reloads via `sb-*` localStorage — rate limit only affects new sign-in attempts.

**`_SB_ALLOWED_COLS`** (~L3000) — per-table allowlist used by `_sanitizeQueueRecord` to strip unknown columns at flush time. Must be kept in sync with shape functions. **b20260330.1056:** `animals` set updated with `confirmed_bred`/`confirmed_bred_date`; `batches` set updated with `wt`/`archived`; `feed_types` set updated with `cost_per_unit`. Without these additions the shape function fixes would be silently reversed at flush time.

**`S.surveys` note — OI-0115 implemented (b20260330.2116):** `surveys` Supabase table added. `S.surveys[]` now syncs to Supabase. Each survey has `id, date, status ('draft'|'committed'), draftRatings (JSONB), notes`. Ratings live as `paddock_observations` rows — `surveys` is the parent container only. `latestSurveyRating()` and `renderSurveyReport()` rewritten to read from `S.paddockObservations` rather than `S.surveys[].ratings[]`. Legacy `ratings[]` field still supported in `migrateM0aData` backfill (filtered to surveys that have it).

**Settings UI (b20260328.1623 — M3; simplified OI-0171 b20260404):**
- `#sb-signed-out` — minimal fallback ("Not signed in. Reload the app to sign in."); normally hidden behind auth overlay
- `#sb-signed-in` — green banner with email + display name input (OI-0074) + Save name; shown when authenticated
- Sign-in UI **moved to auth overlay** (OI-0171) — `#auth-overlay` renders full-screen branded sign-in with email→OTP/password flow
- Sign-out UI **moved to header avatar** (OI-0171) — `#signout-sheet-wrap` bottom sheet with confirmation
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
- `S.surveys[]` kept from localStorage — **no Supabase surveys table; this is an architecture gap (OI-0115)** — child `paddock_observations` rows exist but parent `surveys` table was never created

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
**Root cause:** `renderHome()` filters todos by `(t.assignedTo||[]).includes(activeUserId)`. In the Supabase-only world `activeUserId` is `null` — no legacy `gthy-user` key is set. **Fix (M6):** home todos filter now uses `_sbSession?.user?.id || activeUserId` so it prefers the Supabase user id. Falls back to showing all open todos when neither is set.
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

### Supabase SDK `<script>` must be in `<body>` — OI-0104
**Root cause:** SDK was in `<head>` — `document.body` is null at that point; SDK throws on init.
**Fix:** SDK `<script>` tag moved to just before the main app `<script>` inside `<body>`.
**Rule:** The Supabase CDN tag must always be inside `<body>`, directly before the main app script. Never in `<head>`.

### `operations`/`operation_settings` 403 after main load batch — OI-0103 (Fixed b20260329.2220)
**Root cause:** Sequential fetch after 19-table `Promise.all` — JWT could refresh between execution points, leaving follow-on queries with a stale token that RLS rejected.
**Fix:** Wrapped in their own `Promise.all` in `loadFromSupabase()`.
**Pattern:** Never run sequential Supabase queries after a large parallel batch in the same function. Group all fetches into one `Promise.all` or use separate parallel mini-batches.

### Stale queue items survive schema fixes — OI-0100 (Fixed b20260329.2156)
**Root cause:** `flushToSupabase()` sent raw queued records with no schema enforcement. Pre-fix queue items with extra columns caused permanent 400s on every retry.
**Fix:** `_sanitizeQueueRecord(table, record)` at ~L2909 holds an allowed-columns allowlist for 14 tables and strips extra keys before every upsert. Self-heals stale items without a manual queue clear.
**Pattern:** Sanitize at flush time, not just write time. Queue items persist across deployments.

### `paddock_observations` `source_id` type mismatch — OI-0099 (Fixed b20260329.2134)
**Root cause:** `_paddockObservationRow()` sent `source_id: String(obs.sourceId)` — Supabase column is bigint; PostgREST rejected the string type.
**Fix:** `source_id: obs.sourceId ?? null` — pass the number directly.
**Pattern:** When building shape functions, never convert numeric IDs to strings unless the Supabase column is explicitly `text`. Check the migration script for the canonical type.

### `feedback` 400 — extra columns not in schema (Fixed b20260329.2116)
**Root cause:** `_feedbackRow()` (now `_submissionRow()`) sent `resolved_at`, `confirmed_by`, `confirmed_at` — not in the Supabase `feedback` table (now `submissions`). PostgREST rejected every write.
**Fix:** Three fields removed from shape function. JS objects keep them for local use.
**Columns available in submissions table:** `ALTER TABLE submissions ADD COLUMN resolved_at timestamptz; ...` if needed — they are now proper Supabase columns as of b20260401.2022 migration.

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



---

---

## Supabase Schema Reference (verified b20260331)

### `operations` table — actual column names
**Critical:** The column is `herd_name`, NOT `name`. Early code used `name` causing persistent 400 errors.
```
id, owner_id, herd_name, herd_type, herd_count, herd_weight, herd_dmi,
schema_version, created_at, updated_at
```
App queries: `.select('herd_name,herd_type,herd_count,herd_weight,herd_dmi')` and assembles as `op.herd_name`.
Bootstrap INSERT uses `herd_name:` not `name:`.

### RLS Policy Pattern — `get_my_operation_id()` helper function
All app tables use a `SECURITY DEFINER` helper function to avoid RLS recursion. Direct subqueries against `operation_members` inside RLS policies cause infinite recursion (operation_members policy calls itself).

```sql
CREATE OR REPLACE FUNCTION get_my_operation_id()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT operation_id FROM public.operation_members
  WHERE user_id = auth.uid() LIMIT 1;
$$;
```

All table policies use: `USING (operation_id = get_my_operation_id())`

**Note:** `get_my_operation_id()` returns NULL when called from the Supabase SQL Editor dashboard (no JWT → `auth.uid()` is null). This is expected — the function works correctly when called from the app with a valid session.

### RLS policies — current state (b20260331)
All 20+ app tables use `operation_member_access` policy with `get_my_operation_id()`. The old `"operation members"` policies (recursive subquery) have been replaced. `operation_members` itself has `own rows` (SELECT by user_id) + `operation_member_access` (SELECT by op_id via helper).

### Realtime subscription — debounce pattern
`subscribeRealtime()` debounces all postgres_changes events with a 2s window. Previously each DB change triggered an immediate reload — when the queue flushed 35 rows, 35 concurrent reloads fired. The debounce collapses rapid changes into one reload. Also respects `_sbLoadInProgress` guard.

---

## M7 — Land, Farms & Harvest (b20260331.0008)

### S.farms[]
```javascript
{ id, name, address, notes, createdAt }
```
- `id`: timestamp string (existing pattern)
- Supabase table: `farms` — RLS via `operation_members`
- Shape function: `_farmRow(f, opId)`
- UI: Settings → Farms card — add/edit/delete. Delete blocked if farm has fields assigned.
- Migration guard: `migrateHomeFarm()` — creates "Home Farm" only when genuinely needed. Guard chain: (1) **Fetch-ok gate** — if `_sbFarmsFetchOk=false` and `S.farms` empty, return immediately (don't create phantom farm on network failure). (2) **Pasture-derivation** — if `S.farms` empty but all pastures share one `farmId`, that farm exists in Supabase (FK-proven); reconstruct locally, only re-queue if fetch failed. (3) **Queue-check** — before creating, look for existing farms write in sync queue. (4) **Create** — only if all above fail. (5) **Reassign** — unconditionally set all pastures to canonical farmId.

### S.pastures[] additions (M7-B + OI-0122)
Three new fields added additively — no existing fields removed:
- `farmId`: string FK → `S.farms[].id`
- `landUse`: `'pasture'` | `'mixed-use'` | `'crop'` | `'confinement'`
- `fieldCode`: `null | string` — user-set short stable code (e.g. `07`, `B2`, `HKX`). Max ~8 chars. Used as the field segment in auto-generated harvest batch lot numbers. Set once at field setup; never auto-derived from name.

`_pastureRow()` writes `farm_id`, `land_use`, and `field_code` to Supabase.
Assembly in `loadFromSupabase` defaults: `landUse = locationType==='confinement' ? 'confinement' : 'pasture'`; `fieldCode = null`.
Field card shows `[07]` badge when code is set; faint "no code" hint otherwise.
Location edit sheet has Field code input with help text.

### Fields screen (M7-C)
- Nav labels "Pastures" renamed to "Fields" (mobile + desktop nav, AREA object, feedback selectors)
- `renderPastures()` gains: filter chips (All/Pasture/Mixed-Use/Crop/Confinement), `landUse` badge per card, farm section grouping when multiple farms exist
- Filter state: `window._fieldLandUseFilter` (default `'all'`)
- JS variable `S.pastures` and all function names unchanged — UI labels only

### S.soilTests[] (M7-D)
```javascript
{ id, landId, date, n, p, k, unit, pH, organicMatter, lab, notes, createdAt }
```
- `unit`: `'lbs/acre'` | `'kg/ha'` | `'ppm'`
- Shape function: `_soilTestRow(t, opId)`
- `latestSoilTest(landId)` — returns most recent test by date for a field
- Field card shows last-tested date + N/P/K/unit; "🧪 Soil" button opens `openSoilTestSheet(landId)`
- NPK ledger anchor: most recent soil test resets the baseline for per-field NPK replay (query-time; not yet wired to reports — Post-M7)

### S.forageTypes[] (M7-E)
```javascript
{ id, name, dmPct, nPerTonneDM, pPerTonneDM, kPerTonneDM, notes, isSeeded, createdAt }
```
- NPK values in **kg per tonne of dry matter** (harvest removal accounting)
- `isSeeded: true` for the 7 pre-populated entries (Alfalfa, Mixed Grass, Grass, Timothy, Orchardgrass, Alfalfa/Grass Mix, Corn Silage)
- Shape function: `_forageTypeRow(ft, opId)`
- Migration guard: `migrateForageTypes()` — seeds on first load if `S.forageTypes.length === 0`
- `populateForageTypeSelect()` — populates all `.forage-type-sel` selectors
- `onForageTypeSelect(selEl)` — auto-fills DM%/NPK on feed type sheet; converts nPerTonneDM→nPct via ÷10
- `feedType.forageTypeId` — FK to forage type; written by `addFeedType()`, stored via `_feedTypeRow()`
- Settings: Forage types card — add/edit/delete; delete blocked if linked to a feed type

### S.harvestEvents[] (M7-F / OI-0123)
```javascript
{
  id, date, notes, createdAt,
  fields: [{
    id, landId, landName, fieldCode, farmName,
    feedTypeId,
    batchUnit,          // from feed type unit
    quantity,           // bale count
    weightPerUnitKg,    // weight per bale (most prominent field in UI)
    dmPct,
    nPerTonneDM, pPerTonneDM, kPerTonneDM,
    batchId,            // auto-generated organic lot number (editable; dirty flag prevents regen)
    batchIdDirty,       // true if user manually edited batchId
    notes, createdAt
  }]
}
```
- Shape functions: `_harvestEventRow(ev, opId)` + `_harvestEventFieldRow(f, harvestEventId)`
- `_SB_ALLOWED_COLS['harvest_event_fields']` includes `batch_id`
- Fetched via nested select: `harvest_events` → `harvest_event_fields(*)`
- **Harvest sheet (OI-0123 rewrite):** tile-first, mobile-first. Feed types with `harvestActive:true` appear as tap-to-select tiles. Selecting a tile expands field rows beneath it. Weight per bale is the first and largest input. Batch ID auto-generated via `_generateBatchId(landId, feedTypeId, date)` → `FARM-FIELD-CUT-DATE` (e.g. `DBL-07-1-20260601`). Dirty flag prevents regeneration after manual edit.
- `saveHarvestEvent()`: tile-aware validation, flattens tile→fieldRows to `ev.fields[]`, queues parent + field rows, **auto-creates one `S.batches[]` per field** with `sourceHarvestEventId` + `sourceFieldId`
- `_harvestTiles[]` — module-level tile state (replaces `_harvestRows[]`)
- **Field mode routing (OI-0123):** `?field=harvest` → `applyFieldMode()` → `nav('pastures')` + `setTimeout(openHarvestSheet, 180)`. Same sheet, no separate variant.
- **PWA manifest shortcut (OI-0123):** "Log Harvest" (`/?field=harvest`) added alongside "Log Feed" — appears on long-press of home screen icon after PWA install.
- **Harvest log per field card (OI-0124):** `fieldHarvestSection(pId)` (defined inside `renderPastureCard`) queries `S.harvestEvents[].fields` for records matching `landId`. Shows compact rows: `[BatchID] C1 · 47 bales · Jun 1`. Tap `<details>` to expand. Nested "Reconcile by year" `<details>` shows cuts grouped by year with all batch IDs as a scannable list — printable reference for organic audit.
- **Feed types button access (OI-0126, b20260331.2224):** `openFeedTypesSheet()` now accessible from three places: Feed screen (original), Fields screen header button row, and inside the Harvest sheet (btn-xs in subtitle row). Closing feed types from inside the harvest sheet auto-calls `_renderHarvestTileGrid()` so newly activated tile types appear without re-opening the sheet.

### Harvest — weight units clarification (OI-0127, b20260331.2335)
⚠️ **Known naming mismatch:** `weightPerUnitKg` (JS field name) and `weight_per_unit_kg` (Supabase column) are named as kg but the **entire app treats the value as lbs** — `batch.wt` downstream uses `b.wt ? l.qty*b.wt : l.qty` to compute lbs as-fed, and the XLSX template comment confirms "weight of one unit in lbs (round bale ~850)". A schema rename would require a migration; deferred. Tracked under OI-0059 (calculation audit).

UI labels corrected to lbs: harvest sheet field label "Weight / bale (kg)" → "Weight / bale (lbs)"; field card display "· kg/bale" → "· lbs/bale".

`_harvestAddFieldRow(tileIdx)` now pre-populates `weightPerUnitKg` from `ft.defaultWeightLbs` when the feed type has a default set.

### Harvest — batch ID sanitization (OI-0127, b20260331.2335)
`_generateBatchId()` now strips non-alphanumeric characters from `p.fieldCode` before using it as the field segment. Previously `fieldCode = "E-3"` produced `HOM-E-3-1-20260331` (5 dash-separated segments, broken). Now strips to `E3` → `HOM-E3-1-20260331` (4 segments, correct). Same strip already applied to the fallback name path; now consistent.

**SQL required before pushing harvest builds:**
```sql
ALTER TABLE harvest_events ALTER COLUMN id TYPE text;
ALTER TABLE harvest_event_fields ALTER COLUMN id TYPE text;
ALTER TABLE harvest_event_fields ALTER COLUMN harvest_event_id TYPE text;
ALTER TABLE feed_types ADD COLUMN IF NOT EXISTS default_weight_lbs numeric;
```

### Feed Types Sheet — Edit mode + inline toggle (OI-0126/0127, b20260331.2224/2335)
Form layout reversed: create form at top, existing types list at bottom (was list-then-form).

**Inline harvest-active toggle (OI-0127):** Each non-archived feed type row in the list now has a pill toggle button: green `🌾 Active` / gray outline `○ Inactive`. Calls `toggleFeedTypeHarvestActive(idx)` — flips `ft.harvestActive`, queues Supabase write, saves, re-renders list, and re-renders harvest tile grid if that sheet is currently open. No need to open Edit just to flip the season.

**`defaultWeightLbs` field (OI-0127):** "Default weight (lbs) per bale/unit" input (`ft-default-weight`) added between the Cutting # row and the Hay analysis section. Badge shown in list row when set.

**New functions:**
- `openEditFeedType(idx)` — fills form with existing feed type values, swaps button rows to edit mode, scrolls form into view
- `saveEditFeedType()` — writes mutated ft fields, queues Supabase write, returns to create mode
- `cancelFeedTypeEdit()` — resets form, restores create mode; called by Cancel button, `openFeedTypesSheet()`, and `closeFeedTypesSheet()`
- `_deleteFeedTypeFromEdit()` — calls `cancelFeedTypeEdit()` then `tryDeleteFeedType(idx)`; only reached via the Delete button inside edit mode
- `_clearFeedTypeForm()` — extracted helper to zero all form fields (used by both add and cancel paths)

**UI changes:**
- List rows: `×` delete button replaced with `Edit` button (`btn-outline btn-xs`)
- Delete only reachable from inside the edit form (admin-gated, same as before)
- `ft-edit-idx` hidden input tracks which index is being edited (`""` = create mode)
- `ft-form-title` div changes between "Add feed type" / "Edit feed type"
- `ft-create-btns` / `ft-edit-btns` divs toggle visibility on mode switch

### M7 complete + OI-0122/0123/0124/0125/0126 complete — b20260331.2224

### animal_health_events — No queueWrite path (debt, b20260402.0940)

Health events are loaded from the `animal_health_events` Supabase table via nested select on the animals fetch, but **no `queueWrite` path exists for writes**. `saveAnimalEvent()` calls `save()` (localStorage only) — changes never reach Supabase. Data in the table was populated by the initial migration script. This is a pre-existing gap that needs a dedicated session to wire up: `_healthEventRow()` shape function, `_SB_ALLOWED_COLS` entry, and `queueWrite` calls in `saveAnimalEvent()` and `deleteAnimalEvent()`.

**BCS `likelyCull` field (OI-0022, b20260402.0940):** Added `evt.likelyCull` boolean to BCS health events. Stored on the in-memory event object and persisted to localStorage. The `animal_health_events` table needs `ALTER TABLE animal_health_events ADD COLUMN likely_cull boolean DEFAULT false;` when the write path is wired up. Badge shown in health event list: red "likely cull" pill on BCS rows where `e.likelyCull === true`.

### Sub-move recovery section hidden (OI-0143, b20260402.0940)

The recovery min/max input section in the sub-move sheet has been wrapped in `display:none`. Recovery estimates are only meaningful at survey time — showing them at move time implied the pre-filled values (from the destination paddock's last survey) were a decision aid, which they are not. DOM elements preserved for safe null reads in `saveSubMove()`. Recovery data continues to be set via the survey sheet.

### Move wizard sheet — two move systems coexist (b20260403.0022)

**Card-level moves** (Move button on group row, Move All in header, Place for unplaced groups) now open `#move-wiz-wrap` — a 3-step sheet overlay. **Nav-bar moves** (bottom nav "Move" button) still use the legacy full-page wizard (`nav('move')` → `initWiz()`). Both systems coexist. `moveGroup()` and `moveAllGroupsInEvent()` have been rewired to call `openMoveWizSheet()`.

**Move wizard state:** `_mwStep` (1/2/3), `_mwSourceEvId`, `_mwGroupIds[]`, `_mwMoveAll`, `_mwDestType` ('new'|'existing'), `_mwDestPaddockId`, `_mwDestEventId`, `_mwCloseOutData`. All state is reset on open. **Step 3 (b20260405.0134):** FROM/TO no longer side-by-side — FROM section (red bar) on top with close-out, TO section (green bar) on bottom with arrival survey. Close-out removed forage quality and forage cover fields. `_mwSetQuality` still exists but is no longer called from step 3 UI. `_mwSave()` gracefully handles missing `mw-co-cover` element (optional chaining returns undefined, field not written).

**Close-out at move:** When the move wizard closes an event (last group leaving a pasture location), it writes close-out survey data (`heightOut`, `coverOut`, `qualityOut`) to the source event and updates the paddock's `recoveryMin`/`recoveryMax`. Same fields used by the survey sheet — no duplication.

**Paddock picker (Step 2a):** Classifies paddocks into Nearby (±4 from current in pasture list), Ready, Recovering (with progress bar), In Use (dimmed), Confinement. Tapping a ready paddock auto-advances to Step 3.

**Event edit integration (b20260403.0934):** "Move group" button in event edit (`startMoveGroup`) now closes the editor and launches `openMoveWizSheet(evId, groupId)`. Sub-move "Close paddock" / "Record return" buttons in event edit and sub-move sheet both rewired to `openCloseSubPaddockSheet()`. The old inline `openSmCloseForm()` and `startMoveGroup` destination-picker flows are no longer reachable from any button.

### Sub-paddock close — ID type coercion (b20260403.0934)

`_cspSave()` and `openCloseSubPaddockSheet()` now use `String()` coercion on all event/sub-move ID comparisons. Root cause of dialog-won't-close bug: `e.id===_cspEvId` used strict equality between number and string — the find returned `undefined`, the function bailed before reaching `closeCloseSubPaddockSheet()`. Data was saved (by the onclick propagating to a parent save path) but the dialog stayed open. Fix: `String(e.id)===String(_cspEvId)` + dialog always closes on bail-out paths.

### Event edit paddock deduplication (b20260403.0934)

`renderEeActivePaddocks()` now filters out paddock windows whose `pastureName` matches an active sub-move's `locationName`. Without this, a sub-move to paddock K-5 would render K-5 three times: once as a paddock window card, once as a sub-move card, and once in the bottom chips section. The anchor paddock (index 0) always renders regardless. The paddock window entry still exists for NPK acreage-split accounting — only the visual rendering is filtered.

### Pasture ID type mismatch — String coercion required everywhere (b20260403.0958)

Pasture IDs from Supabase are strings (`"34"`) but template-literal interpolation in `onclick="_mwPickPaddock(${p.id})"` converts to number (`34`). Strict equality `p.id === _mwDestPaddockId` then fails (`"34" !== 34`), causing "Destination paddock not found" on the move wizard confirm step. **Fix:** All `_mwDestPaddockId` lookups now use `String(p.id)===String(_mwDestPaddockId)`, and the paddock picker onclick quotes the ID: `_mwPickPaddock('${p.id}')`. **Pattern reminder:** any ID passed through a template-literal onclick must be quoted to preserve its type, or the find must use String coercion.

### iOS button activation in dynamic innerHTML / z-index stacking (b20260403.0958, b20260403.1008)

Buttons rendered via `innerHTML` inside sheet overlays need explicit `type="button"`. Additionally, when a sheet opens ON TOP of another open sheet (e.g. close-sub-paddock over event-edit), both at `z-index:200`, iOS Safari's scrollable container in the underlying sheet intercepts touch events from the sheet layered on top. **Fix:** `#move-wiz-wrap`, `#close-sub-paddock-wrap`, `#feed-check-wrap` elevated to `z-index:210` — they can all open while event-edit is open. **Belt-and-suspenders:** `_cspSave` button also gets `addEventListener('click')` attached after innerHTML render (50ms setTimeout), and the function is wrapped in try/catch with `closeCloseSubPaddockSheet()` guaranteed outside the try block.

### Move wizard — TO tile re-pick (b20260403.0958)

The TO card on step 3 is now clickable — tapping it calls `_mwChangeDest()` which sets `_mwStep=2` and re-renders, returning the user to the paddock picker (step 2a) or event picker (step 2b) with their prior `_mwDestType` preserved. A pencil icon (✎) next to the "TO" label signals editability.

### Floating feedback FAB restored on mobile (OI-0162, b20260403.0022)

The FAB was hidden on mobile by OI-0147 to fix a badge z-index/overflow issue. Root fix: `z-index` raised to 150 (above nav bar's ~100, below sheets at 200), `overflow:visible` added so badge renders properly, slightly smaller on mobile (44px vs 48px desktop). Field mode still hides FAB via `body.field-mode .fab{display:none !important}`.

### Feed check dialog — per-type tracking with backward compat (OI-0159, b20260403.0038, b20260403.1023)

`openFeedCheckSheet(evId)` groups all feed entries by feedTypeId (via batch lookup) and renders one card per feed type. Each card has a stepper (−/+/direct entry, 2 decimal places), a percentage display, and a horizontal slider — all three bidirectionally linked. "Consumed since last check" amber bar shows units consumed + estimated DMI in lbs.

**Date + time (b20260403.1023):** Form includes date picker (default today) and time picker (default now). Allows backdating or recording exact check time for chronological tracking. Saved as `date` + `time` on the check record. Last check display shows time when available.

**Data model bridge:** The existing `feedResidualChecks[]` model stores a single `balesRemainingPct` per check. The new dialog saves both the backward-compatible overall percentage (weighted by lbs value across types) AND a `typeChecks[]` array on the check record with per-type `{feedTypeId, remaining, total}`. This allows the existing `calcConsumedDMI()` to continue working unchanged while per-type data is available for future use.

**Supabase schema (b20260403.1023):** `event_feed_residual_checks` table has `check_date` (text), `check_time` (text, nullable), `residual_pct`, `bales_remaining_pct`, `is_close_reading`, `notes`, and `type_checks_json` (jsonb, nullable). The `type_checks_json` column stores the per-type breakdown as a JSON array. Assembly layer parses it back via `JSON.parse()`. **SQL migration required:** `ALTER TABLE event_feed_residual_checks ADD COLUMN IF NOT EXISTS check_time text; ALTER TABLE event_feed_residual_checks ADD COLUMN IF NOT EXISTS type_checks_json jsonb;`

**Last check seeding:** If a prior check has `typeChecks[]`, per-type remaining values are restored. Otherwise, the overall `balesRemainingPct` is apportioned equally across types. This handles pre-migration checks gracefully.

### Feed disposition at close (OI-0155, b20260403.0047)

When the move wizard closes an event (last group leaving) and stored feed is present, step 3 shows two additional sections below the pasture close-out survey:

**FINAL FEED CHECK** — same per-feed-type stepper+slider cards as standalone feed check, rendered inline via `_mwRenderInlineFeedCheck()`. Reuses `_fcTypeData[]` and all `_fc*` interaction handlers (wizard and standalone never open simultaneously).

**FEED DISPOSITION** — per-feed-type prompt: "X units remaining — move feed?" with two buttons: "Record as residual" (default) or "Move to destination". State: `_mwFeedDisposition{}` (feedTypeId → 'residual'|'move'). On save: close-reading feed check saved to source event; for each type with disposition 'move', a new feedEntry is created on the destination event with the remaining quantity. **NPK note:** feed transfer is inventory movement only — no NPK deposit. The existing livestock excretion path handles NPK.

**Live refresh (b20260403.0934):** Disposition cards now update in real-time when the inline feed check stepper/slider values change. `_fcUpdateUI()` detects `_mwStep===3` and calls `_mwRenderDispositionCards()` to refresh `#mw-feed-disposition`. The `_mwSetDisposition()` handler also uses targeted DOM update instead of full step re-render, preserving stepper/slider input state.

### DMI interpolation — getDailyStoredDMI (b20260403.1749)

`getDailyStoredDMI(ev, dateStr)` computes the estimated daily stored-feed DM consumption for a given date using a cumulative delivery timeline approach.

**Algorithm:**
1. Builds per-delivery DM amounts with dates from `allFeedEntries(ev)`. Each delivery's DM = `qty × wt × (dm/100)`.
2. `cumDMAt(date)` — helper returning cumulative DM delivered up to and including a given date. This allows mid-event deliveries (e.g. feed transferred from another event) to be correctly accounted for.
3. Feed checks are converted from percentages to actual remaining lbs: `remainingLbs = (pct/100) × cumDMAt(checkDate)`. This prevents the baseline inflation bug where a new delivery changed `totalDMLbs` retroactively.
4. Anchor points: `[{date: startDate, remainingLbs: cumDMAt(startDate)}, ...checkPoints]`
5. Per-segment rate: `consumed = startRemaining + midSegDeliveries − endRemaining; rate = consumed / segDays`
6. **Same-% fallback:** If a segment's rate is 0 (e.g. two consecutive checks with identical remaining %) but overall consumption across all segments is positive, the function returns the overall average rate instead of 0.
7. After the last check, the last computed segment rate is carried forward. If it was 0, the overall average is used.
8. No checks path: total DM spread evenly from first delivery to today.

Returns `{storedDMI: number, hasCheck: boolean}`.

`_renderDMIBars()` calls `getDailyStoredDMI()` for each of the 3 bar days, producing per-day grazing/stored splits. Bars scale relative to each other (`maxTotal` normalization) so consumption changes are visually apparent. The `isMixed` flag and `todayDMI` now reflect actual per-day values rather than event averages.

---

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

## Submissions System (b20260401.2022)

GTHY captures two types of user input through a unified `submissions` Supabase table (renamed from `feedback`). JS state key remains `S.feedback[]` for backward compatibility.

### Submission types (`f.type`)
| Value | UI label | Use case |
|---|---|---|
| `feedback` | 💬 Feedback | Developer observations, ideas, bugs — one-way |
| `support` | 🆘 Get Help | User needs a response — threaded, has priority |

### Status lifecycle
`open` → `planned` (imported to OPEN_ITEMS, OI number assigned) → `resolved` (developer marks fix) → `closed` (user confirms) · or reopened as `regression` via `reopenIssue()`

| Status | Badge | Meaning |
|---|---|---|
| `open` | `ba` amber "open" | Submitted, not yet reviewed |
| `planned` | `bg` green "📋 OI-XXXX" | Imported into OPEN_ITEMS, OI number assigned — shows `oiNumber` when present |
| `resolved` | `bt` teal "awaiting" | Fix deployed, awaiting user confirmation |
| `closed` | `bb` blue "closed" | Confirmed fixed, won't fix, duplicate, or out of scope |

### Categories (`f.cat`) — defined in `CAT` object
| Key | Label | Badge | Dev brief priority |
|---|---|---|---|
| `roadblock` | 🚧 Roadblock | `br` red | **1st** |
| `bug` | Bug | `br` red | 2nd |
| `calc` | Calculation | `bt` teal | 3rd |
| `ux` | UX friction | `ba` amber | 4th |
| `feature` | Missing feature | `bp` purple | 5th |
| `idea` | Idea | `bg` green | 6th |
| `question` | Question | `bt` teal | 7th |

### Priority (`f.priority`) — support tickets only
`normal` · `high` · `urgent` · `low`

### Supabase schema (`submissions` table)
Full column set in `_SB_ALLOWED_COLS['submissions']`. New columns added b20260401.2022: `app`, `type`, `priority`, `submitter_id`, `dev_response`, `dev_response_ts`, `first_response_at`, `thread` (jsonb), `oi_number`. Legacy `feedback` rows backfilled with `app='gthy'`, `type='feedback'`.

**`_submissionRow(f, opId)`** — shape function for all `queueWrite('submissions',...)` calls. `thread` is JSON-stringified before write; parsed back at assembly. Never use `_sbToSnake` on a raw feedback item — the nested `ctx` has no Supabase column.

**Assembly note:** `screen` flat column → `f.ctx.screen` reconstructed at assembly. `thread` JSONB string → parsed to `[]` at assembly. New fields default at assembly: `app='gthy'`, `type='feedback'`, `priority='normal'` for legacy rows.

**Dev response display:** When `f.devResponse` is set, a teal banner shows the latest message. Thread (if >1 message) is collapsed; "▸ See full thread" toggles it open inline.

**Edit permissions (RLS):** Admin role can UPDATE any submission. Regular members can only UPDATE rows where `submitter_id = auth.uid()`. Legacy rows (`submitter_id IS NULL`) are admin-only. Delete is gated identically. In-app delete calls Supabase directly (not via queue) and removes from `S.feedback[]` in one step.

### Areas (`f.area`)
`home` · `animals` · `events` · `feed` · `pastures` · `harvest` · `field-mode` · `reports` · `todos` · `settings` · `sync` · `other`. Auto-suggested from `SCREEN_AREA` map. `harvest` and `field-mode` added b20260401.2240.

### Feedback screen filters
Status/category filters plus area filter and a `has-response` pseudo-filter — shows items where `f.devResponse` or `f.dev_response` is set. Added b20260401.2240.

### Admin console (delivered b20260401.2037)
Standalone `gthy-admin-console.html` — open locally in any browser, no deployment needed. Connects to Supabase via a Deno Edge Function (`admin-submissions`) deployed to the GTHY Supabase project. Edge Function holds the service role key server-side as an env var; console authenticates with a lightweight `ADMIN_SECRET` UUID pasted at session open.

**Edge Function** (`supabase/functions/admin-submissions/index.ts`): actions `list` (GET, filterable), `respond` (PATCH — dev_response + thread), `update` (PATCH — cat/type/status/area/priority/oi_number), `delete` (DELETE). JWT verification disabled on function — auth handled by `x-admin-secret` header check only.

**Console features:** filter by type/status/cat/priority/area/operation, two-pane list+detail, edit all fields, send dev responses, full thread view, AI triage (Claude Haiku via Anthropic API — key pasted into toolbar), export JSON in standard session-import format.

### Stream 2 — Claude Observations (Session Notes)
Developer-level observations made by Claude during coding sessions — things noticed off the current task.
- Logged directly into `OPEN_ITEMS.md` as `OI-XXXX` entries during the session
- Source field: `Claude observation — build bYYYYMMDD.HHMM`
- Includes architectural debt, potential bugs, migration coupling notes

### The Two Exports
| Export | Function | File format | Purpose |
|---|---|---|---|
| Full backup | `exportDataJSON()` | `gthy-backup-YYYY-MM-DD-HHMM.json` | Data restore |
| Submissions export | `exportFeedbackJSON()` | `gthy-feedback-YYYY-MM-DD-HHMM.json` | Session import into punch list |

These two exports serve completely different purposes and must never be combined.
The backup is for disaster recovery. The submissions export is for the development workflow.

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

**Toggle button:** `#field-mode-toggle` in `.hdr-right`. Label and behaviour are context-sensitive (set by `setFieldModeUI` + `_updateFieldModeBtn`, called from `nav()` on every screen change):

| State | Label | Action |
|---|---|---|
| Not in field mode | ⊞ Field | `toggleFieldMode()` — enters field mode, goes to home tile grid |
| Field mode, on home screen | ← Detail | `toggleFieldMode()` — exits field mode |
| Field mode, on any other screen | ⌂ Home | `_fieldModeGoHome()` — navigates to home **without exiting** field mode |

`_updateFieldModeBtn()` is called from `nav()` after every screen transition so the button always reflects the current context. `_fieldModeGoHome()` calls `nav('home',...)` which triggers `renderHome()` → `renderFieldHome()` because `body.field-mode` is still set.

**Routing on `?field=feed`:** `applyFieldMode()` calls `nav('feed',…)` then `setTimeout(openQuickFeedSheet, 180)`.

**Routing on `?field=harvest` (OI-0123):** `applyFieldMode()` calls `nav('pastures',…)` then `setTimeout(openHarvestSheet, 180)`. Lands on Fields screen so closing the sheet goes somewhere sensible.

**Routing on `?field=home` (OI-0006, b20260331.2335):** `applyFieldMode()` calls `nav('home',…)`. `renderHome()` detects `body.field-mode` and delegates to `renderFieldHome()`. Also triggers when `activate=true` but no specific `fieldParam` given (user-pref field mode with no URL action).

**PWA manifest shortcuts:** Three shortcuts defined inline in `<link rel="manifest">` (line 5):
- `/?field=home` → "Field Home" (⊞) — added OI-0006
- `/?field=feed` → "Log Feed" (🌾)
- `/?field=harvest` → "Log Harvest" (🚜) — added OI-0123

**⚠️ Manifest encoding (OI-0137, b20260401.1011):** The manifest is a `data:` URI embedded in an HTML `href` attribute. All double-quote characters (`"`) in the JSON body **must be `%22`-encoded** or the HTML parser terminates the `href` at the first inner quote. The fix applied in b20260401.1011 re-encodes all `"` → `%22`. If the manifest line is ever regenerated or patched, this encoding must be preserved — raw `"` in the JSON will silently break all shortcuts again.

**Re-install required:** PWA shortcuts are only registered at install time. After any manifest change, existing installs must remove and re-add the home screen icon to pick up the new manifest.

**`<link rel="apple-touch-icon">`** (b20260401.1011): Added after the viewport meta tag. Uses the same SVG data URI as the manifest icon (`%3Csvg … 🌾 …`). Required for correct icon display on iOS home screen and in the shortcut context menu.

**Field Home redesign (OI-0145, b20260403.0038):** `renderFieldHome()` fully rewritten with three sections: (1) Quick-launch tiles (2-column grid, white bg, 88px min-height), (2) Tasks section — compact todo list with inline checkbox completion (`_fhCompleteTodo`), due date/overdue labels, + Add button (max 4 shown), (3) Events section — collapsed event cards (color bar, icon+name, acreage, group names, day count, active sub-move) expand on tap to show full `renderLocationCard(ev, {compact:true})` with teal border and ⌃ collapse handle. One expanded at a time via `_fhExpandedEvId`.

| Constant / Function | Purpose |
|---|---|
| `FIELD_MODULES` | Array of `{key, icon, label, handler}` — all available modules |
| `FIELD_MODULES_DEFAULT` | `['feed','harvest','survey','animals']` — default when user has no prefs |
| `_getUserFieldModules()` | Returns `user.fieldModules[]` or default |
| `_setUserFieldModules(keys)` | Writes to `user.fieldModules`, calls `save()` |
| `toggleFieldModule(key)` | Adds/removes a module key, saves, re-renders |
| `renderFieldModules()` | Settings card — per-module on/off toggle pills |
| `renderFieldHome()` | 3-section field mode home: tiles (2-col grid) → tasks (compact todos, max 4, inline completion) → events (collapsed cards, expand-on-tap with compact renderLocationCard) |

**Module keys:** `feed` · `harvest` · `survey` · `animals`. Future modules added to `FIELD_MODULES` constant — stub with `handler:null` until implemented.

**Per-user storage:** `user.fieldModules[]` — array of active module keys. Stored in `gthy-identity` localStorage cache (alongside `fieldMode`, `role`, `color`, etc.). **Not** stored on the `getActiveUser()` return object — that is rebuilt fresh on every call and mutations to it are discarded. `_getUserFieldModules()` reads directly from `_sbLoadCachedIdentity()`. `_setUserFieldModules(keys)` writes directly into `gthy-identity` via `JSON.parse → spread → JSON.stringify`. `sbCacheIdentity()` preserves `fieldModules` when it refreshes identity on sign-in. `null` = no preference saved yet → use `FIELD_MODULES_DEFAULT`.

**Settings card:** "Field mode" card added to Settings screen (above Farm users). Shows each module as a toggle row. `renderFieldModules()` called from the settings render chain.

**Field-mode full-screen sheets (OI-0132, b20260401.0044 / regression fix b20260401.0055):** Class `field-mode-sheet` is added to `#harvest-sheet-wrap` and `#quick-feed-wrap`. Both open functions detect `body.field-mode` and configure context-sensitive UI at open time: backdrop tap-to-close disabled, handle hidden, close/cancel button labels updated.

**⚠️ CSS rule:** `body.field-mode .field-mode-sheet.open .sheet { width/height:100%; border-radius:0 }` — targets the inner `.sheet` only when the outer wrap has the `.open` class. **Do NOT** use `body.field-mode .field-mode-sheet { display:flex }` — this would force sheets visible the moment field mode activates (regression in b20260401.0044/0047, fixed in b20260401.0055).

**`#harvest-sheet-wrap` open/close mechanism (b20260401.0055):** Switched from `style.display='flex'/'none'` to `.classList.add/remove('open')` — consistent with all other sheets and required for the CSS `.field-mode-sheet.open` selector to work correctly. All `style.display==='flex'` guards updated to `.classList.contains('open')`.

**Harvest sheet in field mode:** Close/cancel → "⌂ Done". After `saveHarvestEvent()` in field mode, calls `_fieldModeGoHome()` instead of `renderPastures()`. Alert replaced with `showSurveyToast`.

**Quick Feed sheet in field mode (OI-0132):** Tile label "Log Feed" → "Feed Animals". Step 1 shows "⌂ Done" button (closes to field home); Cancel button hidden. Step 2 "← Back" returns to event picker (does NOT close sheet). After `saveQuickFeed()` in field mode, stays on event picker with toast — user can feed another group or tap "⌂ Done" to return to field home. `closeQuickFeedSheet()` in field mode always calls `_fieldModeGoHome()`.

---

## Deploy Process

1. Edit `get-the-hay-out.html`
2. Bump build stamp at line 8: `<meta name="app-version" content="bYYYYMMDD.HHMM">`
3. Run `deploy.py` — auto-stamps build version into the HTML
4. Push to GitHub → GitHub Pages serves at getthehayout.com
5. `sw.js` handles caching; update banner prompts user to reload on new version
6. After deploying, upload the new HTML to the Claude Project to keep the base file current
