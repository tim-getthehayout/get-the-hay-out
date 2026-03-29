# Get The Hay Out — Project Changelog
**Managed by Claude.** Do not edit manually.

| Build | File | Change |
|---|---|---|
| b20260329.2139 | HTML | Full shape-function type audit: cross-referenced all 15 shape functions against migration script column types. All clean. Two JSONB columns (`todos.assigned_to`, `manure_batch_transactions.pasture_names`) confirmed correct — native arrays to JSONB via Supabase JS SDK are handled correctly; `JSON.stringify` in migration script was a migration-time artifact, not a schema requirement. |
| b20260329.2139 | HTML | Enhancement: Sync queue inspector added to Settings → Sync queue card. Shows pending item count grouped by table, signed-in status, Refresh/Export/Clear buttons. Auto-renders on Settings open. Export button downloads `gthy-sync-queue-YYYY-MM-DD-HHMM.json` for analysis. |
| b20260329.2134 | HTML | Bug fix (OI-0099): `paddock_observations` 400 persisting after OI-0097 fix. Root cause: `_paddockObservationRow()` sent `source_id` as `String(obs.sourceId)` — a quoted string. The Supabase `source_id` column is numeric (bigint); PostgREST rejected the type mismatch. Migration script sends it as a raw number. Fix: `source_id: obs.sourceId ?? null` (no String conversion). |
| b20260329.2134 | HTML | Includes all fixes from b20260329.2112: OI-0097 (activeSmGC crash, paddock_observations schema), OI-0098 (feedback 400), password sign-in. |
| b20260329.2112 | HTML | Bug fix (OI-0097): `ReferenceError: Can't find variable: activeSmGC` crashing `renderGroupCard` and all home screen navigation. Root cause: `const activeSmGC` declared inside `if(ae){...}` block at ~L3777 but referenced in `return` template at ~L3853, outside that block. `const` is block-scoped. Fix: hoisted to `let activeSmGC = null` before the `if(ae)` block; inner assignment changed to bare `activeSmGC = ...`. |
| b20260329.2112 | HTML | Bug fix (OI-0097): `paddock_observations` 400 error on every observation write. Root cause: JS object includes `pastureName` which `_sbToSnake` converts to `pasture_name` — no such column in Supabase schema. Missed by OI-0095 audit. Fix: new `_paddockObservationRow(obs, opId)` shape function strips `pastureName` and maps all fields correctly. `_writePaddockObservation` and `pushAllToSupabase` loop both updated. |
| b20260329.2112 | HTML | Enhancement: password sign-in added to Settings sign-in card. New `sbSignInStep1()` dispatcher checks if password field is filled — routes to `sbSignInWithPassword()` (instant, `signInWithPassword`) or `sbSendCode()` (OTP). Password field added to step-1 HTML with "leave blank to use email code" hint. OTP path fully preserved as fallback. |
| b20260329.2010 | HTML | Bug fix (OI-0096): Two bugs causing data loss and false green sync indicator when Supabase session expires. Bug A: `save()` never called `setSyncStatus` when `_sbSession` was null — sync dot stayed green from the last successful sync even though every subsequent save was localStorage-only. Fix: `save()` now calls `setSyncStatus('off', 'Not signed in — saved locally')` when no session. Bug B: On `SIGNED_IN`, `loadFromSupabase()` fired before the pending write queue was flushed — data entered while signed out was overwritten by the Supabase load before it could be sent. Fix: `onAuthStateChange` for `SIGNED_IN` now calls `flushToSupabase()` first (showing "Saving local changes…"), then chains `loadFromSupabase()` in the `.then()`. `INITIAL_SESSION` path is unchanged (flush-first only needed when reconnecting, not on normal page load with existing session). |
| b20260329.1950 | HTML | Write-path audit: full schema-mismatch fix across all affected tables. Root cause: `_sbToSnake` is a mechanical camelCase→snake_case converter — it does not know the Supabase schema. Every table where JS field names differ from Supabase column names was silently failing: PostgREST rejects any upsert containing unknown columns, so the entire write was dropped and the item remained in the sync queue indefinitely. 8 tables were Critical (upsert rejected outright): `animals`, `batches`, `animal_classes`, `animal_groups`, `ai_bulls`, `feed_types`, `input_products`, `todos`. 4 tables were Missing-field (write succeeded but columns were null): `treatment_types`, `animal_group_memberships`, `animal_weight_records`, `manure_batch_transactions`. Fix: 12 new shape functions added (`_animalRow`, `_batchRow`, `_feedTypeRow`, `_animalClassRow`, `_animalGroupRow`, `_aiBullRow`, `_inputProductRow`, `_todoRow`, `_treatmentTypeRow`, `_animalGroupMembershipRow`, `_animalWeightRecordRow`, `_manureBatchTransactionRow`) — each maps JS fields to the exact Supabase column names, excluding JS-only fields (e.g. `animalIds`, `weightHistory`, `calvingRecords`), handling semantic transforms (e.g. `active` bool → `status` string, `tagNum` → `tag`, `dm` → `dm_pct`), and aligning renamed fields (e.g. `cpu` → `cost_per_unit`, `typeId` → `feed_type_id`). All 38 `queueWrite` call sites for these tables updated. `pushAllToSupabase()` flat-tables loop rewritten to use shape functions. XLSX bulk import block (`importSetupFile`) updated. `loadFromSupabase` input_products assembly updated to alias `npk_n/npk_p/npk_k` → `nPct/pPct/kPct` and `type` → `cat` and `cost_per_unit` → `cpu` so render code continues to work unchanged. Console command to clear accumulated stale queue: `localStorage.removeItem('gthy-sync-queue')`. |
| b20260329.1950 | OPEN_ITEMS | OI-0095 added and closed: full write-path audit — 8 critical tables, 4 missing-field tables. 12 shape functions written. |
| b20260329.1841 | HTML | Bug fix (OI-0091): `todoCardHtml()` and `renderTodos()` crashed with `TypeError: (t.assignedTo||[]).map is not a function`. Root cause: migration script stored `assigned_to` via `JSON.stringify(array)` so it was persisted as a text string inside the JSONB column. PostgREST returned it as a JS string; `.map/.includes/.some` all fail on strings. Fix: todos assembly in `loadFromSupabase()` now checks `typeof t.assignedTo === 'string'`, parses it with `JSON.parse`, and falls back to `[]` on failure. Also normalises null/undefined to `[]`. Fix is at the assembly layer — no render code changed. |
| b20260329.1855 | HTML | Bug fix (OI-0091): `(t.assignedTo||[]).map is not a function` crash on every todos render. Root cause: migration script stored `assigned_to` as `JSON.stringify(array)` (a string literal). PostgREST returns JSONB stored as string back as a JS string, not a parsed array. All downstream `.map`/`.includes`/`.some` calls crashed. Fix at assembly layer in `loadFromSupabase()`: todos rows now detect `typeof t.assignedTo === 'string'`, JSON.parse it back to an array, and normalise any other non-array value to `[]`. Render code unchanged. |
| b20260329.1841 | HTML | Bug fix (OI-0090): `sbSendCode()` and `sbVerifyOtp()` showed "Supabase not initialised" alert when SDK CDN script failed to load on first paint after SW cache update. Both functions now call `sbInitClient()` on the spot — if the global became available this recovers silently; otherwise a `confirm()` prompts a page reload. |
| b20260329.1831 | HTML | Bug fix (OI-0088): Desktop app loaded in mobile view on first paint. Root cause: `detectMode()` and `applyFieldMode()` were called at end of startup sequence (lines 15130–15131), after `renderHome()` (line 15124). First render always used mobile layout. Fix: moved both calls to run immediately after `updateHeader()`, before `sbInitClient()` and `renderHome()`, so the `body.desktop` class is set before any screen renders. |
| b20260329.1831 | HTML | Bug fix (OI-0089): Sync showed "36 items pending" and sync errors on every load with no new data entered. Root cause: `migrateM0aData()` runs at startup before `sbInitClient()`, so `_sbOperationId` is null when `_writePaddockObservation()` calls `queueWrite`. Items entered queue with `operation_id: null` — Supabase rejects them (NOT NULL constraint), they persist in queue, count grows on each reload. Two-part fix: (1) `_writePaddockObservation()` now guards `if(_sbOperationId)` before queueing — skips write during startup migration. (2) `flushToSupabase()` strips any items with `operation_id == null` from the queue before flushing, clearing accumulated stale entries from prior loads. |
| b20260329.1816 | HTML | OI-0072: Sub-move time-in made required. (1) Label on `sm-time` field changed from "optional" to required (no qualifier). (2) `sm-time-out` label changed to "if returned" (it remains optional). (3) `saveSubMove()` add-mode: validation guard added before `const sm = {}` — if `sm-time` is empty, alerts with message "Time moved in is required." and focuses the field. Edit mode is exempt (allows correcting time on existing records). Closes OI-0072. |
| b20260329.1816 | HTML | Bug fix (OI-0086): Individual pasture survey button showed "No pasture Location Defined" instead of the paddock form. Root cause: `renderPastures()` passes `p.id` as a string in `onclick="openSurveySheet('${p.id}')"` but Supabase returns `pastures.id` as a bigint (number). Strict `===` comparison in `renderSurveyPaddocks()` and the title lookup in `openSurveySheet()` always failed (string ≠ number). Fix: both comparisons now use `String(p.id)===String(surveyFocusPastureId)`. |
| b20260329.1816 | HTML | Bug fix (OI-0087): Home "My open tasks" card was always empty; Todos screen badge showed correct count but form appeared blank. Root cause: home filter used `(t.assignedTo||[]).includes(activeUserId)` but `activeUserId` is `null` in the Supabase-only world (M6 not yet landed, no legacy `gthy-user` key set). Fix: when `activeUserId` is null, home card falls back to showing all open todos instead of filtering by assignee. |
| b20260329.1708 | HTML | OI-0060: Rotation calendar active-event highlighting. (1) Added `@keyframes cal-active` to CSS block (opacity 1→0.8 pulse, 2s). (2) `isCurrentlyActive` computed per cell: `isOpen && win.start ≤ today && win.end ≥ today` — correctly marks only the window that actually reaches today, so clipped prior-paddock windows on sub-move events are NOT treated as active. (3) Invisible same-color `outline` replaced with `box-shadow: 0 0 0 2px white, 0 0 0 3.5px ${color}` (white ring — visible against any background). (4) Pulsing animation applied to active cells only. (5) `NOW` badge rendered when isCurrentlyActive and span ≥ 3. (6) "Active now" swatch added to legend (conditional on openEvs.length). (7) Footer hint updated: "White ring = actively occupied now." (8) Hover title appends "· ACTIVE NOW" for active cells. Closes OI-0060. |
| b20260329.1630 | HTML | M4.5-F: Stale "Drive" label cleanup (6 edits). App update banner → "Supabase-connected users are already synced." Desktop `#dsk-sync-label` and mobile `#sync-label` default text → `Sync`. Email field label → `Email`. `syncSidebarSync()` default label arg → `'Sync'`. Reset sheet static HTML → "If signed in to Supabase, cloud data will also be erased." |
| b20260329.1630 | HTML | M4.5-E: `importSetupFile()` XLSX bulk import — added 6 `queueWrite` calls after `migrateSystemIds()` assigns IDs. All 6 imported arrays (pastures, feedTypes, batches, animalClasses, animalGroups, animals) now queue to Supabase. |
| b20260329.1630 | HTML | M4.5-C: `pushAllToSupabase()` — new function iterates all S arrays, queues every record (pastures via `_pastureRow`, events via `queueEventWrite`, all others via `_sbToSnake`), then calls `flushToSupabase()` immediately. `importDataJSON()` now async; calls `pushAllToSupabase()` when signed in. Status message: "Restoring to cloud…" → "✓ Restored & synced to cloud." |
| b20260329.1630 | HTML | M4.5-B: `executeReset()` — Supabase delete in FK-safe order before local state clear. Events-mode: deletes 12 tables (events + children + manure/input/todos). Full-mode: deletes all 27 non-auth tables. Both modes clear `gthy-sync-queue` to prevent re-population from queued writes. `openResetSheet()` warning text dynamically appends cloud erasure notice when `_sbOperationId` set. |
| b20260329.1630 | HTML | M4.5-A: `saveSettings()` write path — added two `queueWrite` calls before `save()`: `operations` (herd name + updated_at) and `operation_settings` (full S.settings JSONB, `conflictKey='operation_id'`). Settings changes now reach Supabase. |
| b20260329.1630 | HTML | M4.5-A: `queueWrite` — new optional `conflictKey='id'` param. Dedup uses `record[conflictKey]`; queue entry stores `conflictKey`. `flushToSupabase` uses `op.conflictKey \|\| 'id'` per upsert call. Fixes `operation_settings` whose PK is `operation_id`, not `id`. |
| b20260329.1630 | OPEN_ITEMS | OI-0084 logged: `importEventsFile()` missing `queueWrite` — 3 insertion points needed (new pastures + `generatePastureId()`, new groups, events). Low priority. |
| b20260329.1630 | OPEN_ITEMS | OI-0085 logged: `recalcNpkValues()` bulk mutation missing per-row `queueWrite`. NPK price recalculations only persist to localStorage. Low priority. |
| b20260328.2324 | HTML | Fix: `assembleEvents()` sub-move field aliases (Bug A). Five Supabase→JS name mismatches: `dateIn`→`date`, `timeIn`→`time`, `pastureName`→`locationName`, `recoveryDaysMin`→`recoveryMinDays`, `recoveryDaysMax`→`recoveryMaxDays`. All sub-move display, close sheet, duration calc, and recovery windows were broken for Supabase-loaded events. Closes OI-0080. |
| b20260328.2324 | HTML | Fix: `assembleEvents()` — `ev.pasture` alias. `pasture_name`→`pastureName` via `_sbToCamel` but ~20 render paths read `ev.pasture`. Added `if (!ev.pasture && ev.pastureName) ev.pasture = ev.pastureName`. Closes OI-0081. |
| b20260328.2324 | HTML | Fix: pasture `recoveryMinDays`/`recoveryMaxDays` read alias. Supabase `min_days`/`max_days`→`minDays`/`maxDays` via camel; app reads `recoveryMinDays`/`recoveryMaxDays`. Per-paddock recovery windows were always falling back to settings defaults. Aliases added in flat pasture assembly. Closes OI-0082. |
| b20260328.2324 | HTML | Fix: pasture write path. `queueWrite('pastures', _sbToSnake({...p}))` was sending `recovery_min_days`, `recovery_max_days`, `location_type` — none of which are valid `pastures` table columns (`min_days`, `max_days`, `type`). New `_pastureRow(p, opId)` helper builds the correct schema row. All 3 `queueWrite('pastures',...)` sites updated. Closes OI-0082. |
| b20260328.2324 | HTML | Fix: `loadFromSupabase()` — auto-rebuild `ev.totals` for closed events. `totals` is never stored in Supabase; closed events loaded with `totals===undefined` caused blank cost/pasture%/NPK in events log, pasture screen, reports, CSV export. Added post-migration pass calling `recalcEventTotals(ev)` for each closed event missing totals. Try/catch per-event — non-fatal. Closes OI-0083. |
| b20260328.2258 | HTML | Fix: `assembleEvents()` — Event Edit sheet fields (head, avg weight, height in/out, forage cover in/out, recovery min/max) were all blank for Supabase-loaded events. Root cause: `events` table has minimal schema; these values live in child tables. Added three derivations: (1) `ev.head`/`ev.wt` summed/averaged from `ev.groups[].headSnapshot`/`weightSnapshot` across active groups; (2) `ev.heightIn`/`ev.forageCoverIn` from `S.paddockObservations` where `sourceId===ev.id` and `source==='event_open'`; (3) `ev.heightOut`/`ev.forageCoverOut`/`ev.recoveryMinDays`/`ev.recoveryMaxDays` from `source==='event_close'`. `S.paddockObservations` is populated before `assembleEvents()` runs so lookup is safe. Closes OI-0079. |
| b20260328.2258 | HTML | Fix: `queueEventWrite()` — group membership rows written with `headSnapshot: g.head` but Supabase-assembled group objects carry `g.headSnapshot`/`g.weightSnapshot`. Fixed to `g.headSnapshot ?? g.head ?? ev.head` / `g.weightSnapshot ?? g.wt ?? ev.wt` covering all three cases: Supabase-assembled groups, legacy localStorage groups, newly created events. |
| b20260328.2241 | HTML | Fix: batch assembly — removed `b.wt = null` override. `wt` now read directly from Supabase `batches.wt` column via `_sbToCamel` (no conversion needed). DMI calculations now correct: `qty × wt × dm%` instead of `qty × dm%`. Closes OI-0078. |
| b20260328.2241 | HTML | Fix: `saveBatchAdj` — added `queueWrite('batches', _sbToSnake({...b, operationId: _sbOperationId}))` before `save()`. Batch edits (remaining adjustments, weight corrections, label changes) were previously persisted to localStorage only — never written to Supabase. |
| b20260328.2241 | Supabase | Schema: `alter table batches add column wt numeric`. Populated existing rows: Peanut Hay / Oak Field Barn / Tarped = 750 lbs; Alfalfa Small Squares = 50 lbs. |
| b20260328.2219 | HTML | Fix: `animals` nested select — added FK hint `!animal_health_events_animal_id_fkey` to disambiguate join. `animal_health_events` has two FKs to `animals` (`animal_id` + `calving_calf_id`); without the hint Supabase returns undefined for the entire animals fetch. Animals now load correctly (77 records). |
| b20260328.2219 | Supabase | Fix: `paddock_observations` 400 on realtime subscription — ran `alter table paddock_observations replica identity full` in SQL Editor. Realtime requires REPLICA IDENTITY FULL on all watched tables. |
| b20260328.2219 | Supabase | Fix: duplicate calving rows from multiple migration script runs — deleted duplicates with `delete from animal_health_events where type='calving' and id not in (select min(id) from animal_health_events where type='calving' group by animal_id, date)`. Root cause: `nextId()` generates different IDs each run so upsert creates new rows instead of updating. |
| b20260328.2211 | HTML | Fix: `assembleGroups` — `animalIds[]` was hardcoded `[]`. Now derived from `S.animalGroupMemberships` open rows (`dateLeft` null) filtered by `groupId`. `getAnimalGroup()` and group chip filters now work correctly. |
| b20260328.2211 | HTML | Fix: pasture flat-map — `p.locationType` alias added (`p.type` → `p.locationType`). App reads `locationType` everywhere; Supabase schema stores it as `type`. Without this, confinement detection failed for all paddocks. |
| b20260328.2211 | HTML | Fix: batch flat-map — field aliases: `name`→`label`, `feedTypeId`→`typeId`, `dmPct`→`dm`, `costPerUnit`→`cpu`. `remaining` seeded from `quantity`. `wt` set to `null` (not in Supabase schema — OI-0078 logged). |
| b20260328.2211 | HTML | Fix: `assembleAnimals` — additional field aliases: `tag`→`tagNum`, `status:'culled'`→`active:false`, `{cullDate,cullReason}`→`cullRecord{}`. `weightLbs` derived from latest `S.animalWeightRecords` entry. |
| b20260328.2211 | OPEN_ITEMS | OI-0078 logged: `batches.wt` not in Supabase schema — bale weight missing, DMI calculations using qty directly instead of qty×wt. |
| b20260328.2204 | HTML | Fix: `assembleAnimals` — `calvingRecords` was hardcoded `[]`. Now reconstructs from `animal_health_events` where `type='calving'`. Maps `calvingCalfId`→`calfId`, `sireName`→`sireTag`, `calvingStillbirth`→`stillbirth`. Non-calving events go into `healthEvents[]`. Closes OI-0075 (bug 2). |
| b20260328.2200 | HTML | Fix: `assembleEvents` — `feedEntries` was flat `event_feed_deliveries` rows; render functions expect `fe.lines[]`. Now groups by date, producing `{id, date, lines:[{batchId, qty}]}`. Sub-move feed deliveries filtered by `sub_move_id` and assembled separately. `ev.locationType` now derived from `S.pastures` name/id lookup (not stored in `events` table). Paddock entries get `locationType:'pasture'` fallback. Closes OI-0075 (bug 1). |
| b20260328.1801 | HTML · ARCHITECTURE · OPEN_ITEMS · MIGRATION_PLAN | M4 complete: data migration script produced and validated; pre-M4 guard removed from `loadFromSupabase`; Supabase is now source of truth. |
| b20260328.1801 | Node.js script | `migrate-to-supabase.js` produced — standalone Node.js migration script. Reads `gthy-backup-2026-03-28-1327.json`, maps all S-object arrays to normalized Supabase tables, upserts 457 rows across 20 tables using service role key (bypasses RLS). Pasture string IDs (`PSTR-00001`) converted to bigints. Feed type mixed IDs cast to text. Sub-move `locationName` resolved to `pastureId` via name lookup. `ev.feedEntries[].lines[]` flattened to one `event_feed_deliveries` row each. `animal.calvingRecords[]` folded into `animal_health_events` as `type=calving`. `S.surveys` folded into `paddock_observations`. Orphan group ID `1773607143162` (deleted "Cow-Calf Herd") remapped to current Cow-Calf Herd `1773829317829` to satisfy FK constraint. Chunked upsert (500 rows/call) for safety. |
| b20260328.1801 | HTML | Pre-M4 guard removed from `loadFromSupabase()`. Guard block (5 lines checking for empty pasture rows and bailing to localStorage) removed. `const safePassureRows` replaced with direct `(pastureRows \|\| []).map(_sbToCamel)`. Comment updated: "short-circuits before assembly when tables are empty (pre-M4)" → "assembles all S arrays from Supabase tables. M4 complete." |
| b20260328.1801 | Migration | Expected record counts: pastures 34, animal_classes 9, animal_groups 5, feed_types 3, batches 4, treatment_types 2, animals 79, animal_weight_records 77, animal_health_events 46, animal_group_memberships 77, events 8, event_group_memberships 12, event_paddock_windows 10, event_sub_moves 2, event_feed_deliveries 12, event_feed_residual_checks 6, event_npk_deposits 4, paddock_observations 4, todos 3, feedback 60. Total: 457 rows. |
| b20260328.1623 | HTML | M3 complete: write path + Drive removal. |
| b20260328.1623 | HTML | M3-A: Write infrastructure added. `_sbToSnake(obj)` — shallow camelCase→snake_case converter. `queueWrite(table, record)` — append/replace in `gthy-sync-queue` localStorage key. `queueEventWrite(ev)` — queues parent event + all 6 child tables (event_paddock_windows, event_group_memberships, event_sub_moves, event_feed_deliveries, event_feed_residual_checks, event_npk_deposits) in one call; assigns synthetic ids to paddock/group entries if missing (write-once). `flushToSupabase()` — best-effort drain loop; failed items stay in queue; unrelated tables don't block each other. `supabaseSyncDebounced()` — 800ms debounce, replaces `driveSyncDebounced`. `save()` patched: `if(_sbSession)supabaseSyncDebounced()` replaces Drive branch. |
| b20260328.1623 | HTML | M3-B: Mutation instrumentation — 68 `queueWrite`/`queueEventWrite` calls added. All 10 event mutation sites instrumented: `wizSaveNew`, `wizCloseEvent`, `saveQuickFeed`, `saveEeFeedEntry`, `deleteEeFeedEntry`, `saveSubMove` (edit+add), `saveSmClose`, `deleteSubMove`, `saveEventEdit`, `applyEeGroupMoveActions`. All flat array tables instrumented: pastures, feed_types, batches, animal_groups, animals, animal_classes, treatment_types, ai_bulls, todos, feedback, manure_batches, input_products. Archive/unarchive branches for all 6 archivable types instrumented. M0 ledger helpers instrumented: `_recordAnimalWeight` → `animal_weight_records`; `_openGroupMembership` / `_closeGroupMembership` → `animal_group_memberships`; `addToManureBatch` → `manure_batch_transactions` + `manure_batches`; `_writePaddockObservation` → `paddock_observations`; `saveApplyInput` → `input_application_locations` + `manure_batch_transactions`. |
| b20260328.1623 | HTML | M3-C: Google Drive removal. Entire `// ─── GOOGLE DRIVE ───` JS block removed (~356 lines). `let driveState`, `if(!driveState.clientId)` init line, `function saveDriveState()` removed. `importDataJSON()` Drive branch replaced with simple "Restore successful. Sign in to sync to other devices." `generateBrief()` Drive context line removed. `resetData()` Drive write blocks removed from both events-reset and full-reset paths. Settings nav path: `updateDriveUI()` call removed. End-of-file: `updateDriveUI()`, `maybeResumeTokenRefresh()`, Drive `if` + `setInterval` calls removed. `visibilitychange` listener updated to call `flushToSupabase()` instead of `onAppResume()`. GIS script tag not present (already absent). Google Drive HTML card in Settings removed. Section TOC comment updated. |
| b20260328.1623 | HTML | M3-D: `setSyncStatus` restored as clean M3 version — Drive action branches (`reconnect`/`recreate`/`retry`) removed; 4 states only: `off · pending · ok · error`. Calls `syncSidebarSync` to keep desktop dot in sync. |
| b20260328.1623 | HTML | OI-0074 resolved: Display name input added to `#sb-signed-in` Settings block. `sbSaveDisplayName()` function added — saves to `gthy-identity` cache via `sbCacheIdentity()` and calls `updateHeader()`. `sbUpdateAuthUI()` populates the input from cached identity on sign-in. |
| b20260328.1521 | SESSION_BRIEF | M3 planning session: M2 fully verified (all 3 console checks passed). Full M3 architecture designed — write infrastructure (`queueWrite`, `queueEventWrite`, `flushToSupabase`, `supabaseSyncDebounced`), complete mutation audit (95 save() call sites categorized), Drive removal plan, OI-0074 fix (display name input). No HTML changes. SESSION_BRIEF produced as implementation handoff. |
| b20260328.1221 | ARCHITECTURE · OPEN_ITEMS · MIGRATION_PLAN | M2 testing: discovered and fixed three Supabase RLS policy bugs that blocked bootstrap on first sign-in. No HTML changes — all fixes are Supabase Dashboard SQL. Docs updated to record correct policy set. |
| b20260328.1221 | Supabase Dashboard | RLS fix 1: `operation_members` SELECT policy was self-referential (`operation_id in (select operation_id from operation_members where user_id = auth.uid())`). Caused infinite recursion → 500 on every read. Fixed by dropping the policy and replacing with `using (user_id = auth.uid())` for SELECT and UPDATE. |
| b20260328.1221 | Supabase Dashboard | RLS fix 2: `operation_members` had no INSERT policy. New user bootstrap insert was blocked. Fixed by adding `create policy "self insert" on operation_members for insert with check (user_id = auth.uid())`. |
| b20260328.1221 | Supabase Dashboard | RLS fix 3: `operations` had no owner-based SELECT policy. `sbBootstrapOperation` chains `.insert().select().single()` — after insert succeeded, the chained select was blocked because no `operation_members` row existed yet (chicken-and-egg). Fixed by adding `create policy "owner select" on operations for select using (owner_id = auth.uid())`. |
| b20260328.1221 | Supabase Dashboard | RLS fix 4: `operations` had no INSERT policy. Bootstrap insert was blocked. Fixed by adding `create policy "owner insert" on operations for insert with check (owner_id = auth.uid())`. |
| b20260328.1221 | Note | Supabase free tier OTP email rate limit: 2 emails per hour per address. Hitting the limit during testing returns "email rate limit exceeded" from `sbSendCode`. Not an app bug — wait ~1 hour for reset. Signed-in sessions persist across reloads via `sb-*` localStorage; rate limit only affects new sign-in attempts. |
| b20260328.1211 | HTML | Fix: replaced magic-link auth with 6-digit OTP code flow to resolve PWA standalone mode cross-context storage problem |
| b20260328.1211 | HTML | Root cause: magic link clicks open in regular Safari, not the PWA. PWA and Safari have isolated localStorage contexts — Supabase writes the session token to Safari's storage; the PWA never sees it. Result: `sb-*` keys never written in PWA context; `onAuthStateChange` never fires; load chain never runs. |
| b20260328.1211 | HTML | Fix: `sbSignIn()` replaced by two-step OTP flow. Step 1: `sbSendCode()` calls `signInWithOtp({ email })` with no `emailRedirectTo` — sends a 6-digit code to email instead of a redirect link. Step 2: `sbVerifyOtp()` calls `verifyOtp({ email, token, type: 'email' })` — verifies the code in-app, within the PWA context. `onAuthStateChange` fires `SIGNED_IN` in PWA context; M2 load chain runs normally. |
| b20260328.1211 | HTML | Settings card redesigned as two steps: step-1 div (email input + Send code button + error status), step-2 div (code input + Verify button + Use different email link + status). Step-2 hidden until code sent. Code input: `inputmode="numeric"`, `autocomplete="one-time-code"` (iOS autofill from email), `maxlength="6"`, large font for readability. |
| b20260328.1211 | HTML | Helpers added: `_sbStep1Status(msg, isError)`, `_sbStep2Status(msg, isError)` for inline feedback without alerts. `sbResetToStep1()` resets to email entry. `sbSignIn()` kept as no-op alias to avoid stale-call errors. |
| b20260328.1211 | HTML | Requires Supabase Dashboard change: Authentication → Email Templates → Magic Link → replace `{{ .ConfirmationURL }}` with `{{ .Token }}` in email body. Without this, Supabase still sends a redirect link instead of a code. |
| b20260328.1140 | HTML · ARCHITECTURE · OPEN_ITEMS · MIGRATION_PLAN | M2: Load path — Supabase identity system, operation bootstrap, loadFromSupabase, subscribeRealtime, assembly functions, home nudge banner |
| b20260328.1140 | HTML | M2: Identity system (Option B — clean break). `getActiveUser()` now reads Supabase session then `gthy-identity` localStorage cache then guest fallback. Always returns non-null `{id, name, email, color, role, fieldMode}`. `_sbLoadCachedIdentity()` / `sbCacheIdentity()` manage the cache. `S.users[]` retained for todo assignment compat but no longer the identity source. `maybePromptUserSelect()` converted to no-op. |
| b20260328.1140 | HTML | M2: Module vars `_sbOperationId` + `_sbRealtimeChannel` added. `_sbOperationId` persisted to `gthy-operation-id` localStorage key and cached across page loads. |
| b20260328.1140 | HTML | M2: `sbGetOperationId()` — queries `operation_members` for signed-in user. Returns cached `_sbOperationId` if set. Calls `sbBootstrapOperation()` if no operation found. |
| b20260328.1140 | HTML | M2: `sbBootstrapOperation()` — auto-creates `operations` + `operation_members` rows on first sign-in using `S.herd` data. Runs silently. Caches operation_id and writes `gthy-identity`. |
| b20260328.1140 | HTML | M2: `onAuthStateChange` updated — handles both `SIGNED_IN` and `INITIAL_SESSION`. On either with a session: calls `sbGetOperationId()` then `loadFromSupabase(opId)` then `subscribeRealtime(opId)`. On `SIGNED_OUT`: clears `_sbOperationId`, removes cache key, re-renders to show nudge. |
| b20260328.1140 | HTML | M2: `_sbToCamel(obj)` helper — converts snake_case Supabase row keys to camelCase. Shallow convert; values unchanged. |
| b20260328.1140 | HTML | M2: `_sbFetch(table, opId)` helper — safe per-table fetch returning `[]` on error (logged, not thrown). Used for flat tables with direct `operation_id` FK. |
| b20260328.1140 | HTML | M2: Assembly functions added: `assembleEvents`, `assembleAnimals`, `assembleGroups`, `assembleManureBatches`, `assembleInputApplications`. Re-nest Supabase nested-select rows back into S object shape. Dead code until M4 (guard fires first on empty tables). |
| b20260328.1140 | HTML | M2: `loadFromSupabase(operationId)` — parallel-fetches all tables via nested select (hierarchical) and `_sbFetch` (flat). Guard: if 0 pastures returned and localStorage has data, bails early — pre-M4 state. Assembles S, runs all migrate guards, `saveLocal()`, re-renders. `S.surveys` kept from localStorage (no Supabase surveys table). |
| b20260328.1140 | HTML | M2: `subscribeRealtime(operationId)` — one Supabase channel per operation; `postgres_changes` listener per watched table; any change triggers full `loadFromSupabase()` reload (granular merge is M5+ optimisation). Unsubscribes previous channel on call. |
| b20260328.1140 | HTML | M2: Home screen nudge banner. `<div id="sb-home-nudge">` added to home screen HTML. `renderHome()` injects green cloud-sync strip with "Sign in" button when `_sbSession` is null; clears when signed in. |
| b20260328.1140 | HTML | M2: Settings Farm users card description updated — notes Supabase is now primary identity and local user list is legacy (retired at M4). |
| b20260328.0316 | HTML · ARCHITECTURE | Fix: removed orphaned old `renderEeGroupChips` body that was causing a JS syntax error (unclosed template literal contaminating downstream functions); `renderEeGroupChips` now produces clean list-row layout (dot + name + status pill + joined/head sub-line + Move group/Undo/× button) matching approved mockup — all existing move/undo/destination-picker logic preserved |
| b20260328.0316 | HTML | Fix: `renderEeSubMoves` — active sub-moves now show "Close paddock" button (teal, calls `openSubMoveSheetFromEdit`); all sub-moves show "Edit" button; sorted active-first then date-desc; recovery window shown in sub-line; returned entries at 0.75 opacity |
| b20260328.0316 | HTML | Fix: "Record return" → "Close paddock" on active sub-move rows in the active paddocks block (`renderEeActivePaddocks`) |
| b20260328.0119 | HTML · ARCHITECTURE | UX: Forage cover slider+number added to event edit (pre + post graze); forage cover slider+number added to sub-move pre-graze section; forage cover slider+number added to sub-move close (moveback) section; "at return" → "at closure" on sub-move feed residual label |
| b20260328.0119 | HTML | New fields `ev.forageCoverIn` / `ev.forageCoverOut` — optional 0–100% forage cover at event open/close. Read by `openEventEdit`, saved by `saveEventEdit`. Passed through to `paddock_observations` via `_writePaddockObservation` in `wizCloseEvent`. |
| b20260328.0119 | HTML | New fields `sm.forageCoverIn` / `sm.forageCoverOut` — optional forage cover on sub-move. `forageCoverIn` read by `saveSubMove`, passed to sub_move_open observation. `forageCoverOut` read by `saveSmClose`, passed to sub_move_close observation. Both loaded by `openSmEditForm`, reset by `resetSmForm`, pre-populated in `openSmCloseForm`. |
| b20260328.0119 | HTML | Slider+number pattern: range input and number input are kept in sync via `oninput` — slider updates number, number updates slider. Consistent pattern applied across all 6 new forage cover inputs (ee-cover-in, ee-cover-out, sm-cover-in, sm-cover-in-slider, sm-cover-out, sm-cover-out-slider). |
| b20260328.0008 | HTML · ARCHITECTURE · OPEN_ITEMS · MIGRATION_PLAN | M0b: Pre-migration data model prep — isCloseReading flag (L), npkLedger source fields (K), feed type NPK analysis (J), animalWeightRecords (F), animalGroupMemberships (G), inputApplicationLocations (H), manureBatchTransactions (I) |
| b20260328.0008 | HTML | M0b-L: `ev.feedResidualChecks[]` entries now carry `isCloseReading: bool`. `true` on entries written at event close (`wizCloseEvent`) and sub-move close (`saveSmClose`). `false` on intermediate checkpoint entries (reserved for future mid-event logging UI). `migrateM0aData()` backfill sets `isCloseReading:true` on all migrated scalar entries (scalar = close reading by definition). |
| b20260328.0008 | HTML | M0b-K: `ev.npkLedger[]` entries now carry `source: 'livestock_excretion' \| 'feed_residual'`. Feed residual entries additionally carry `dmLbsDeposited` (lbs DM left as uneaten bales). Written by `wizCloseEvent` after livestock entries when `_residOM > 0`. `migrateM0aData()` backfill adds `source:'livestock_excretion'` to all existing ledger entries (both paddockNPK path and single-paddock fallback path). No `feed_residual` backfill — historical data cannot be reconstructed without per-delivery residual series. |
| b20260328.0008 | HTML | M0b-J: `S.feedTypes[]` records gain optional `nPct`, `pPct`, `kPct` fields (hay analysis N/P/K percentages from lab test). Null on existing records; new records accept values from three new inputs in the Feed Types sheet ("Hay analysis — optional" section). `renderFeedTypes()` shows `N/P/K` teal badge when any value is set. `addFeedType()` reads inputs and clears them on add. No migration needed — new fields default null. |
| b20260328.0008 | HTML | M0b-F: Added `S.animalWeightRecords[]` top-level weight time series. Entry: `{id, animalId, recordedAt, weightLbs, note, source}`. `_recordAnimalWeight(a, date, wt, note, source)` helper writes to both `animal.weightHistory[]` (backward compat) and `S.animalWeightRecords[]`. All three live weight-write paths updated: `saveAnimalWeight()` (manual weight sheet), `saveAnimalEdit()` (weight change on edit), `commitWeightUpdates()` (group bulk weight update). `migrateM0aData()` backfills from `animal.weightHistory[]` on all animals; stable dedup id derived from `animalId * 1000 + (timestamp % 1000000)`. |
| b20260328.0008 | HTML | M0b-G: Added `S.animalGroupMemberships[]` top-level membership ledger. Entry: `{id, animalId, groupId, dateJoined, dateLeft}`. `_openGroupMembership()` / `_closeGroupMembership()` helpers. All seven animal lifecycle mutation paths updated: `addAnimal()` (new animal to group), `saveAnimalEdit()` (group change), `deleteAnimal()` (remove from groups), `saveCull()` (remove from groups), `calving saveCalving()` (calf to dam's group), `saveGroupFromSheet()` (bulk edit diff — detects joins and leaves), `saveAnimalMove()` both paths (existing group + new group). `migrateM0aData()` backfills all current `group.animalIds[]` as open-ended rows (dateJoined:null, dateLeft:null); dedup by `animalId:groupId` key. |
| b20260328.0008 | HTML | M0b-H: Added `S.inputApplicationLocations[]` top-level amendment location ledger. Entry: `{id, applicationId, pastureId, pastureName, acres, nLbs, pLbs, kLbs, costShare}`. Written by `saveApplyInput()` after saving the application record. `migrateM0aData()` backfills from `inputApplication.locations[]`; dedup by `applicationId:pastureName` key. Enables the unified fertility query: `event_npk_deposits UNION ALL input_application_locations`. |
| b20260328.0008 | HTML | M0b-I: Added `S.manureBatchTransactions[]` top-level transaction ledger. Entry: `{id, batchId, type, date, volumeLbs, nLbs, pLbs, kLbs, sourceEventId, applicationId, pastureNames, notes}`. Types: `'input'` (from confinement event) and `'application'` (spread). Written by `addToManureBatch()` (input path) and `saveApplyInput()` + `saveSpreadEvent()` (application paths). `migrateM0aData()` backfills from `manureBatch.events[]`; stable dedup id from `batchId * 10000 + eventIndex`. `getBatchRemaining()` still reads `batch.events[]` — will switch to transactions at M4. |
| b20260328.0008 | HTML | M0b plumbing: `ensureDataArrays()` guarantees all five new arrays (`animalWeightRecords`, `animalGroupMemberships`, `inputApplicationLocations`, `manureBatchTransactions` + existing `paddockObservations`). `mergeData()` union-merges all new arrays by id. |
| b20260327.2332 | HTML · ARCHITECTURE · OPEN_ITEMS · MIGRATION_PLAN | M0a: Pre-migration data model prep — feedResidualChecks series (A), npkLedger (B), paddockObservations (C) |
| b20260327.2332 | HTML | M0a-A: Added `ev.feedResidualChecks[]` series to data model. Each entry: `{id, date, residualPct, balesRemainingPct, notes}`. Written by `wizCloseEvent` (final close) and `saveSmClose` (sub-move close when feed delivered). `getEffectiveFeedResidual(evOrSm)` helper reads last entry in series or falls back to scalar `ev.feedResidual` for pre-M0a events. Old scalar retained for display/CSV backward compat. |
| b20260327.2332 | HTML | M0a-A: `migrateM0aData()` backfills `feedResidualChecks` from existing scalar `feedResidual` on events and sub-moves (single-entry array, source=`migrated_from_scalar`). Runs at init after `migrateWeaningFields()`. |
| b20260327.2332 | HTML | M0a-A: All DMI computation callers updated to use `getEffectiveFeedResidual()`: `calcEventTotalsWithSubMoves`, `calcGrassDMIByWindow`, `calcResidualOM`, event-edit recalc, reports DMI variance, rotation calendar, home card DMI lines. |
| b20260327.2332 | HTML | M0a-B: Added `ev.npkLedger[]` array. Written by `wizCloseEvent` from `totals.paddockNPK` after close computations. Each entry: `{id, paddockName, pastureId, periodStart, periodEnd, head, avgWeight, days, acres, nLbs, pLbs, kLbs}`. `migrateM0aData()` backfills from `totals.paddockNPK` on all existing closed events. Enables M4 migration script to import real NPK history without recomputation. |
| b20260327.2332 | HTML | M0a-C: Added `S.paddockObservations[]` top-level array. Written by `wizSaveNew` (event_open), `wizCloseEvent` (event_close), `saveSubMove` (sub_move_open when heightIn present), `saveSmClose` (sub_move_close), `saveSurvey` (survey). Each entry: `{id, pastureId, pastureName, observedAt, source, sourceId, confidenceRank, vegHeight, forageCoverPct, forageQuality, recoveryMinDays, recoveryMaxDays, notes}`. `_writePaddockObservation()` helper deduplicates by source+sourceId+pastureId. |
| b20260327.2332 | HTML | M0a-C: `lastGrazingRecordForPasture()` rewritten to query `S.paddockObservations` first (filtering to event_close, sub_move_close, survey sources; sorted by observedAt desc then confidenceRank desc). Full legacy event/sub-move scan retained as fallback for pre-M0a data with empty observations array. |
| b20260327.2332 | HTML | M0a-C: `migrateM0aData()` backfills `S.paddockObservations` from all existing events (heightIn→event_open, heightOut+dateOut→event_close, sub-move heightIn→sub_move_open, sub-move dateOut→sub_move_close) and all existing `S.surveys[]` ratings. |
| b20260327.2332 | HTML | M0a-C: `ensureDataArrays()` — `paddockObservations` added to guaranteed arrays list. |
| b20260326.0859 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: sub-move isActive now checks paddock dateRemoved as fallback; groups section moved to bottom of event edit |
| b20260326.0859 | HTML | Fix: renderEeSubMoves() + renderSmExistingList() — isActive = !sm.durationHours && !sm.dateOut && !paddockClosed; paddockClosed checks ev.paddocks for matching locationName with dateRemoved set; prevents K-5 showing active when its paddock was manually closed |
| b20260326.0859 | HTML | Fix: renderSmExistingList() returned badge — shows durationHours if set, or "returned (paddock closed)" when paddock.dateRemoved is the authority and durationHours is 0 |
| b20260326.0859 | HTML | UX: Event edit sheet — Groups section moved from top-right two-column to bottom of sheet below Sub-moves; paddocks now full-width at top; ee-group-chips and ee-group-sel IDs unchanged so all group JS functions work without modification |
| b20260326.0859 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: groups view home card now shows "Currently at" for active sub-move; collapsed header shows current location; evDisplayName falls back to active sub-move when paddocks list empty |
| b20260326.0859 | HTML | Fix: renderGroupCard() — added activeSmGC = active sub-move lookup; currentAtLineGC renders "📍 Currently at: K-2 · since [date]" in teal inside the location bar when an active sub-move exists; sub-move count line unchanged |
| b20260326.0859 | HTML | Fix: renderGroupCard() collapsed header — now shows activeSmGC.locationName (current sub-move location) or evDisplayName(ae) (active paddocks) instead of raw ae.pasture string |
| b20260326.0859 | HTML | Fix: evDisplayName() — added third fallback: if paddocks list is empty or all removed and no name found, checks ev.subMoves for an active sub-move (durationHours=0) and returns its locationName; ensures cards always show where cattle currently are even if paddocks[] is stale |
| b20260326.0859 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: Record Return form — move-in date/time read-only with Edit button; correction sub-dialog for missing time-in; duration always auto-calculated; no manual hours entry; no date-only fallback |
| b20260326.0859 | HTML | Fix: `openSmCloseForm()` — populates read-only move-in pill from `sm.date`/`sm.time`; auto-shows correction sub-dialog (`sm-close-timein-correct`) with amber warning when `sm.time` is null; sets hidden `sm-close-time-in` from stored value |
| b20260326.0859 | HTML | New: `openSmCloseTimeInCorrect()` — opens the correction sub-dialog explicitly (called by ✏ Edit button); sets label to "✏ Correct move-in date / time" |
| b20260326.0859 | HTML | New: `confirmSmCloseTimeIn()` — reads correction inputs, validates both date and time present, updates hidden `sm-close-time-in` + `sm._correctedDate`/`sm._correctedTime`, updates read-only display to show "(corrected)", hides sub-dialog, triggers `calcSmCloseDuration()` |
| b20260326.0859 | HTML | Fix: `calcSmCloseDuration()` — reads `sm-close-time-in` (confirmed time-in) and `sm._correctedDate`; builds proxy object for `_smCloseCalcHrs()`; shows descriptive error in red when time-in missing; shows "⏱ Xd Yh" in teal on success |
| b20260326.0859 | HTML | Fix: `_smCloseCalcHrs()` — requires both time-in and time-out; date-only fallback removed entirely; uses ISO datetime strings for correct multi-day calculation |
| b20260326.0859 | HTML | Fix: `saveSmClose()` — requires `timeOut` (time returned is no longer optional); reads confirmed time-in from hidden field; persists any `_correctedDate`/`_correctedTime` back to `sm.date`/`sm.time`; duration derived from `_smCloseCalcHrs()` — manual hours input removed |
| b20260326.0859 | HTML | Removed: manual `sm-close-hours` input field from Record Return form; replaced with read-only `sm-close-duration-disp` div and hidden `sm-close-time-in` confirmed field |
| b20260326.0757 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: sync merge now union-merges feedEntries + subMoves on timestamp-win; sub-move return stamps paddock dateRemoved; saveSubMove auto-adds paddock; home card "Currently at" line; evDisplayName shows active paddocks only |
| b20260326.0757 | HTML | Fix: `mergeData()` → `ma()` — introduced `_mergeEventArrays(winner, loser)` helper called by all timestamp-resolution paths; feedEntries are union-merged by id from both sides regardless of which side wins updatedAt comparison; subMoves are union-merged by id with closed-state preference (durationHours>0 beats 0) so a "Record return" on one device cannot be silently reverted by the other device's stale open record |
| b20260326.0757 | HTML | Fix: `saveSmClose()` — after writing durationHours/dateOut to the sub-move record, now also finds the matching entry in `ev.paddocks[]` by `locationName` and sets `dateRemoved = dateOut`; the event edit chip for that paddock now automatically turns red ("Closed") when a return is recorded — no separate "Close Paddock" click needed |
| b20260326.0757 | HTML | Fix: `saveSubMove()` add-mode — automatically pushes the sub-move location to `ev.paddocks[]` if not already present; paddock record includes pastureId, acres, dateAdded/timeAdded from sm fields; eliminates the need to manually add the paddock via event edit after recording a sub-move |
| b20260326.0757 | HTML | Fix: `evDisplayName()` — now filters `ev.paddocks[]` to active entries only (`!p.dateRemoved`) before joining names; home card title reflects where animals actually are now, not every paddock they have visited; falls back to all paddocks if all are removed (closed event edge case) |
| b20260326.0757 | HTML | Enhancement: `renderLocationCard()` — added "📍 Currently at: [location] · sub-move since [date]" teal line below card subtitle when an active sub-move exists (`!sm.durationHours`); first-class answer to "where are my cattle right now?" on the home locations view |
| b20260325.1936 | HTML | Fix: Pasture survey recovery window — min/max inputs now mean "days from survey date" not "days from last event date"; saves adjusted back to event-date-relative on write; affects both multi and single-pasture modes |
| b20260325.1918 | HTML · ARCHITECTURE · OPEN_ITEMS | Enhancement: Pasture survey — consolidated per-card layout, veg height + forage cover fields, OI-0010 resolved |
| b20260325.1918 | HTML | Enhancement: Multi-pasture survey (`renderSurveyPaddocks`) — collapsed two-pass layout (rating list + separate recovery list) into a single consolidated per-card layout; each pasture card now shows: forage quality slider → avg veg height (in) → avg forage cover (%) → recovery min/max days + live graze window preview; no more scrolling between sections |
| b20260325.1918 | HTML | Enhancement: Single-pasture survey — added avg veg height (inches) and avg forage cover (%) fields between the forage quality rating block and the recovery window section |
| b20260325.1918 | HTML | Data model: `S.surveys[].ratings[]` entries now include optional `vegHeight` (float, inches) and `forageCover` (float, %) fields; fully backward-compatible — existing entries without these fields are unaffected; survey report is unaffected (additive fields) |
| b20260325.1918 | HTML | New state vars: `surveyVegHeight` and `surveyForageCover` (pastureId → value dicts); reset in `openSurveySheet()`; written to data model in `saveSurvey()` |
| b20260325.1918 | HTML | OI-0010 resolved: expected graze dates now appear inline in every pasture card as a live `rec-preview-` block (reactive to min/max input changes); supersedes old static `gdHtml` approach that was separate from the recovery inputs |
| b20260325.0037 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: Drive sync robustness — persistent import failure alert, drivePushLocal(), re-read-before-write |
| b20260325.0037 | HTML | Fix: `importDataJSON` Drive write failure now shows a persistent red error card (not a 5-sec toast) with a "Retry Drive push" button; card does not auto-dismiss until push succeeds — root cause of mobile backup restore silently not reaching Drive |
| b20260325.0037 | HTML | New: `drivePushLocal()` — force-push local state to Drive; reads Drive first to union-merge any remote-only data, then writes; called by import retry button and available globally |
| b20260325.0037 | HTML | Fix: `driveSync()` re-reads Drive immediately before the final write; if the remote file changed between the initial read and the write (concurrent write from another device), it merges again before writing; prevents last-writer-wins data loss in the race where two devices both read stale state |
| b20260325.0013 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: Drive sync — treatmentTypes and aiBulls added to mergeData(); periodic 5-min sync poll added; migration flags added to merge return |
| b20260325.0013 | HTML | Fix: `mergeData()` — `treatmentTypes` and `aiBulls` were completely absent from the merge return object; any treatment types or AI bulls created on one device were silently dropped on every sync; now union-merged by `id` alongside `todos` and `feedback` |
| b20260325.0013 | HTML | Fix: `mergeData()` — `_groupsMigrated` and `_paddocksMigrated` flags added to merge return (OR'd booleans, same pattern as `_herdMigrated`); previously absent, so migration state could diverge between devices |
| b20260325.0013 | HTML | Fix: 5-minute periodic Drive sync poll added to init block (`setInterval`, 300000ms); fires `driveSync()` when token is valid; root cause of feedback/todos/events not reaching desktop — tab stays open all day, `visibilitychange` never fires, Drive changes made on mobile are never pulled |
| b20260324.1945 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: recalcEventTotals aligned with calcEventTotalsWithSubMoves logic |
| b20260324.1945 | HTML | Fix: `recalcEventTotals` — replaced hard `if(ev.noPasture) pastureDMI=0` guard with `effectivelyNoPasture = ev.noPasture && !hasGrazingSubMoves`; mixed bale-graze+grazing events now correctly infer pasture DMI on Save & recalculate |
| b20260324.1945 | HTML | Fix: `recalcEventTotals` — storedDMI now computed per-sub-move (each sm uses its own feedResidual) instead of pooling all entries with ev.feedResidual |
| b20260324.1945 | HTML | Fix: `recalcEventTotals` — pFraction now recomputed from actual sub-move hours instead of carrying forward stale ev.totals.pFraction |
| b20260324.1945 | HTML | Fix: `recalcEventTotals` — now calls calcSubMoveNPKByAcres and calcGrassDMIByWindow; results stored in ev.totals on every Save & recalculate |
| b20260324.1945 | HTML | Fix: `dmiVariance` in recalcEventTotals now computed on effectivelyNoPasture condition (not raw ev.noPasture) |
| b20260324.1930 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: sheet vertical centering (global) + sub-move edit return path |
| b20260324.1930 | HTML | CSS: `.sheet-wrap.open` changed from `display:block` to `display:flex;align-items:center;justify-content:center`; `.sheet` changed from `position:absolute;bottom:0` to `position:relative`; border-radius all 4 corners; desktop override uses `padding-left:220px` on wrap to shift flex center into content area |
| b20260324.1930 | HTML | Fix: `smFromEventEdit` flag added; `closeSubMoveSheet()` checks flag and calls `openEventEdit(evId)` on return; `openSubMoveSheetFromEdit()` sets flag after `openSubMoveSheet()` resets it; edit save path uses `closeSubMoveSheet()` instead of manual `renderHome()` |
| b20260324.1900 | HTML · ARCHITECTURE · OPEN_ITEMS | Fix: sub-moves shown inline in Event Edit sheet with per-row Edit buttons |
| b20260324.1900 | HTML | New `renderEeSubMoves(ev)` — sub-move list inside Event Edit; each row has location, status, type badge, dates, Edit button |
| b20260324.1900 | HTML | `openSubMoveSheetFromEdit(smId)` now accepts optional smId; calls `openSmEditForm` via 80ms timeout after sheet opens |
| b20260324.1900 | HTML | Event Edit HTML — `ee-submoves-wrap` / `ee-submoves-list` added; standalone Manage button replaced by inline section |
| b20260324.1830 | HTML · OPEN_ITEMS · ARCHITECTURE | Bug fix: `openSmEditForm` — visibility now driven directly from `sm` data, not from dropdown `.value` read; noPasture row, height section, and moveback section all correctly shown/hidden regardless of dropdown state or archived location status |
| b20260324.1830 | HTML | Bug fix: `openSmEditForm` — archived locations now included in edit dropdown so historical sub-moves to since-archived paddocks can still be edited; `[archived]` note appended to label |
| b20260324.1830 | HTML | Enhancement: `sm-add-header` ID added to "Add sub-move" section header; `openSmEditForm` changes text to "Edit sub-move — [locationName]"; `resetSmForm` restores "Add sub-move" |
| b20260324.1800 | HTML | Enhancement (OI-0044-A): `sm.noPasture` field added to sub-move data model; `saveSubMove()` writes it; confinement locations auto-set `true`; "100% stored feed" toggle shown for non-confinement locations in sub-move sheet |
| b20260324.1800 | HTML | Enhancement (OI-0044-A): `updateSmHeightRecoveryVisibility()` — height/recovery fields now hidden when `sm.noPasture` checkbox is checked (not just for confinement); noPasture toggle row shown/hidden based on location type |
| b20260324.1800 | HTML | Enhancement (OI-0044-B): `calcEventTotalsWithSubMoves()` — replaced hard `ae.noPasture → pdmi=0` guard with `effectivelyNoPasture = ae.noPasture && !hasGrazingSubMoves`; bale-grazing parent with at least one grazing sub-move now unlocks pasture DMI inference via mass balance |
| b20260324.1800 | HTML | Enhancement (OI-0044-B): `calcEventTotalsWithSubMoves()` — `subMoveNPK` now computed by `calcSubMoveNPKByAcres()` instead of time-fraction; acres-weighted, time-windowed attribution replaces `sm.durationHours / totalHrs` approach |
| b20260324.1800 | HTML | Enhancement (OI-0044-C): `sm.parentFeedCheckpointPct` field added to sub-move data model; "Bales remaining right now (%)" slider added to Record Return close form; shown only when parent event has bale feed entries and sub-move is grazing |
| b20260324.1800 | HTML | Enhancement (OI-0044-C): `openSmCloseForm()` — reads parent event feed entries to decide whether to show checkpoint row; pre-fills slider from existing `sm.parentFeedCheckpointPct` if already recorded |
| b20260324.1800 | HTML | Enhancement (OI-0044-C): `saveSmClose()` — reads checkpoint slider value and writes `sm.parentFeedCheckpointPct` when row is visible |
| b20260324.1800 | HTML | New function `feedDMIPutOutToDate(entries, cutoffDate)` (~L9830) — date-filters feed entries, sums gross DMI put out on or before cutoff; used by `calcGrassDMIByWindow` |
| b20260324.1800 | HTML | New function `calcGrassDMIByWindow(ae, outDate, feedRes)` (~L9845) — checkpoint-driven grass DMI attribution; builds checkpoint timeline from sub-move closes + event close; infers grass DMI per window by mass balance (expected DMI − bale consumed); credits each window to the closing paddock; falls back to whole-event balance on primary paddock if no checkpoints; result stored as `ae.totals.grassDMIByPaddock` |
| b20260324.1800 | HTML | New function `calcSubMoveNPKByAcres(ae, outDate)` (~L9910) — acres-weighted NPK attribution for sub-move locations; builds window breakpoints from sub-move open/close dates; distributes each window's NPK across active paddocks (primary + sub-moves) by acreage; returns sub-move locations' shares only |
| b20260324.1800 | HTML | Enhancement (OI-0044): `wizCloseEvent()` — stores `ae.totals.grassDMIByPaddock` from `calcGrassDMIByWindow()` result |
| b20260324.1800 | HTML | Enhancement (OI-0055): `renderSmExistingList(ev)` — Edit button added to every sub-move row (active and closed) |
| b20260324.1800 | HTML | New function `openSmEditForm(smId)` — pre-fills sub-move add form with all fields from the selected record (date, time, location, noPasture, height, recovery, feed lines); swaps button label to "Save changes"; shows amber "Cancel edit" button |
| b20260324.1800 | HTML | New function `resetSmForm()` — clears form fields, hides sections, resets `smEditingId = null`, restores "Record sub-move" label, hides cancel-edit button |
| b20260324.1800 | HTML | Enhancement (OI-0055): `saveSubMove()` — edit path added; when `smEditingId !== null`, updates existing sub-move record in place instead of pushing new; calls `resetSmForm()` after save |
| b20260324.1800 | HTML | New function `openSubMoveSheetFromEdit()` — bridge from Event Edit sheet to sub-move sheet; closes Event Edit, opens sub-move sheet for same event ID; enables sub-move editing on closed/historical events |
| b20260324.1800 | HTML | Enhancement (OI-0055): Event Edit sheet — "⇢ Manage sub-moves" button added alongside Delete event; calls `openSubMoveSheetFromEdit()` |
| b20260324.1800 | HTML | Module variable `smEditingId` added — `null` in add mode, `string` of sub-move ID in edit mode; reset by `openSubMoveSheet()` and `resetSmForm()` |
| b20260324.1730 | HTML | Bug fix (OI-0051): `eventAUDs()` inside `renderRotationCalendar()` — group-totals fallback now applies to ALL events (open and closed), not just open; closed multi-group events with unstamped `ev.head`/`ev.wt` now produce correct AUD season totals |
| b20260324.1730 | HTML | Bug fix (OI-0048): `qfShowEventStep()` rebuilt — event picker is now location-centric (location name + type badge primary, group names secondary); uses `evGroups()` and `allFeedEntries()` instead of legacy `ev.groupId` |
| b20260324.1730 | HTML | Bug fix (OI-0048): Cancel button added to Quick Feed step-1 event picker (`#qf-step1-cancel`) — shown when step-1 is displayed, hidden on step-2; backdrop tap already closed correctly |
| b20260324.1730 | HTML | Bug fix (OI-0048): `qfSelectEvent()` updated — form title now shows location name, subtitle shows group names; uses `evGroups()` for group name list |
| b20260324.1730 | HTML | Enhancement (OI-0049): `renderLocationCard()` — added event-level DMI summary line: total DMI target across all groups, stored-vs-pasture % split, progress bar; rendered between group rows and NPK line |
| b20260324.1730 | HTML | Bug fix (OI-0049): `renderLocationCard()` — `totalBW` aggregation corrected; was using `ae2.head * ae2.wt` (event-level snapshot, wrong for multi-group); now uses `getGroupTotals(g).totalHead * avgWeight` per group |
| b20260324.1730 | HTML | Enhancement (OI-0050): `renderGroupCard()` — NPK calculation corrected to use this group's own `getGroupTotals()` head/weight (`grpBW`) instead of `ae.head * ae.wt` (whole-event aggregate) |
| b20260324.1730 | HTML | Enhancement (OI-0052): `openSubMoveSheet()` — event label now uses `evGroups()` + `evDisplayName()` instead of legacy `ev.groupId` / `ev.pasture` |
| b20260324.1730 | HTML | Enhancement (OI-0052): `openSubMoveSheet()` location dropdown now excludes ALL paddocks in the event via `evPaddocks(ev)` (not just `ev.pasture`); archived pastures also excluded |
| b20260324.1730 | HTML | Feature (Roadblock): `CAT` object — `roadblock` entry added (`cls:'br'`, red badge, `pillCls:'cp-roadblock'`) |
| b20260324.1730 | HTML | Feature (Roadblock): Feedback sheet — `🚧 Roadblock` pill added as first option in category picker; `.cp-roadblock` CSS — bold weight + red selected state |
| b20260324.1730 | HTML | Feature (Roadblock): Feedback filter dropdown — `Roadblocks` option added |
| b20260324.1730 | HTML | Feature (Roadblock): `renderFeedbackList()` — `roadblock` added to category filter list |
| b20260324.1730 | HTML | Feature (Roadblock): `generateBrief()` — roadblocks listed first in brief with `← HIGH PRIORITY — FIX BEFORE ANYTHING ELSE` label; each item prefixed `🚧`; footer hint updated |
| b20260324.0955 | HTML · OPEN_ITEMS · ARCHITECTURE · CHANGELOG | OI-0041 cancel fix · OI-0040 home screen button redesign · 10 new OI entries imported |
| b20260324.1030 | HTML · OPEN_ITEMS · ARCHITECTURE · CHANGELOG | OI-0028 mobile header two-row layout · OI-0019 animal screen compact chips + sticky header |
| b20260324.1100 | HTML · OPEN_ITEMS · ARCHITECTURE · CHANGELOG | OI-0043 feed type parseInt bug + unarchive onclick fix · OI-0046–0053 feedback import |
| b20260324.1130 | HTML · OPEN_ITEMS · ARCHITECTURE · CHANGELOG | OI-0053 primary group label removed · last-group-out closes event |
| b20260324.0910 | HTML | Bug fix (OI-0032): `mergeData()` — equal-timestamp tie-break changed from silent local-win to union-merge of `groups`, `paddocks`, `subMoves` sub-arrays; new IDs from remote appended, existing IDs kept from local |
| b20260324.0910 | HTML | Bug fix (OI-0032): `wizCloseEvent` — `ae.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `saveSubMove` — `ev.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `saveSmClose` — `ev.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `deleteSubMove` — `ev.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `saveEventEdit` — `ev.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `applyEeGroupMoveActions` — `targetEv.updatedAt` stamped when group is pushed to destination event |
| b20260324.0910 | HTML | Bug fix (OI-0032): `saveAnimalEdit` (edit path) — `a.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `saveAnimalWeight` — `a.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): health event save — `a.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `deleteAnimalEvent` — `a.updatedAt` stamped before `save()` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `saveSplit` loop 1 (split-from note) — `a.updatedAt` stamped inside `forEach` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `saveSplit` loop 2 (moved-to note) — `a.updatedAt` stamped inside `forEach` |
| b20260324.0910 | HTML | Bug fix (OI-0032): `logGroupChange` helper in `saveAnimalMove` — `a.updatedAt` stamped inside helper; covers both existing-group and new-group move paths |
| b20260324.0910 | HTML | Bug fix (OI-0032): `saveCalving` — `dam.updatedAt` stamped before `save()` |
| b20260324.0910 | OPEN_ITEMS | OI-0032 and OI-0033 added and closed; status summary updated (Closed 19→21); 8 new Mobile feedback items added to import log (2 flagged as likely bugs) |
| b20260324.0910 | ARCHITECTURE | Drive Sync section updated — mergeData conflict resolution documented; updatedAt coverage table added |
| b20260324.0112 | ARCHITECTURE | OI-0031: File header updated — line count `~13,872` → `~14,392`, size `~695KB` → `~720KB`, last-updated date fixed |
| b20260324.0112 | ARCHITECTURE | OI-0031: File Structure Table — all section line ranges recalibrated to grep-verified actuals; weaning system extracted from Reports row into its own line; sheet HTML range documented (~L12840–14300) |
| b20260324.0112 | ARCHITECTURE | OI-0031: Screen Map — `renderEventsLog` ref `~5013` → `~5805`; `renderRotationCalendar` ref `~L11782` → `~L11971`; duplicate warning block removed; events row line refs corrected |
| b20260324.0112 | ARCHITECTURE | OI-0031: Data Model — `S.treatmentTypes` documents `category` field; `S.testerName` and legacy `S.version` added; `S.settings` expanded to full 14-field sub-table |
| b20260324.0112 | ARCHITECTURE | OI-0031: Key Utility Functions — `closeGroup()` (non-existent) replaced with `startMoveGroup()`; `setMoveGroupExisting()`, `setMoveGroupWizard()`, `cancelGroupMove()` added; `editTreatmentType()`, `cancelEditTreatment()`, `_mtResetForm()` added |
| b20260324.0112 | ARCHITECTURE | OI-0031: Critical Behavioral Notes — new section: Treatment Type Categories (TREATMENT_CATEGORIES, _editingTreatmentId state, dual list renderer note) |
| b20260324.0112 | ARCHITECTURE | OI-0031: Critical Behavioral Notes — new section: Multi-Group Event Departure Flow (_moveAction state machine with all values; closeGroup() tombstone warning; _isNew flag note corrected) |
| b20260324.0112 | HTML | Build stamp bump only — no functional changes; aligns HTML version with documentation baseline |
| b20260324.0112 | OPEN_ITEMS | OI-0031 closed; session queue updated (OI-0031 removed, priorities renumbered 1–5); status summary updated (Debt 2→1, Closed 18→19) |
| b20260324.0054 | HTML | Feature (OI-0030): `renderSmExistingList(ev)` — renders existing sub-moves at top of sheet; active badge (durationHours===0) vs closed badge (hours shown) |
| b20260324.0054 | HTML | Feature (OI-0030): `openSmCloseForm(smId)` — reveals inline close form pre-filled with location, existing recovery values |
| b20260324.0054 | HTML | Feature (OI-0030): `cancelSmClose()` — hides close form, clears `sm-close-sm-id` |
| b20260324.0054 | HTML | Feature (OI-0030): `calcSmCloseDuration()` — auto-calculates hours from original `sm.time` in + close form time-out; handles overnight crossing midnight |
| b20260324.0054 | HTML | Feature (OI-0030): `saveSmClose()` — writes `durationHours`, `dateOut`, `timeOut`, `heightOut`, recovery fields to sub-move; stamps recovery on location record |
| b20260324.0054 | HTML | Feature (OI-0030): `deleteSubMove(evId, smId)` — removes sub-move with confirm guard; re-renders list and home |
| b20260324.0054 | HTML | Feature (OI-0030): `sm.dateOut` — new optional field on sub-move records for multi-day return date |
| b20260324.0054 | HTML | Feature (OI-0030): `openSubMoveSheet` updated — calls `renderSmExistingList(ev)` and `cancelSmClose()` on open |
| b20260324.0054 | HTML | Feature (OI-0030): Sub-move sheet HTML restructured — "Recorded sub-moves" section with inline close form above existing "Add sub-move" form |
| b20260324.0054 | ARCHITECTURE | Sub-move lifecycle state machine added to Critical Behavioral Notes: anchor paddock model, durationHours state (0=active / >0=closed), all sm.* fields, all transitions with function names, display contract for calendar + cards, explicit statement of what anchor paddock is NOT |
| b20260324.0054 | OPEN_ITEMS | OI-0030 closed; session queue updated with OI-0031 at priority 1 |
| b20260323.2354 | SESSION_RULES | Doc v23 — §4a stateful system trigger + state machine documentation rule; propagated to MASTER_TEMPLATE v2.5 |
| b20260323.2354 | MASTER_TEMPLATE | v2.5 — §4a state machine rule propagated from SESSION_RULES v23 |
| b20260323.2354 | OPEN_ITEMS | OI-0030 added (sub-move close/edit UI); OI-0031 added (architecture audit); OI-0017 closed (treatments edit + categories) |
| b20260323.2354 | SESSION_RULES | Doc v23 — §4a: new trigger row for stateful systems/lifecycles; state machine documentation rule added with required fields; why-it-matters note referencing sub-move root cause |
| b20260323.2354 | MASTER_TEMPLATE | v2.5 — same §4a state machine trigger propagated from SESSION_RULES v23 |
| b20260323.2354 | OPEN_ITEMS | OI-0030 added: sub-move close/edit UI (Bug) — active sub-moves have no close path; anchor paddock model documented |
| b20260323.2354 | OPEN_ITEMS | OI-0031 added: architecture audit (Debt) — systematic drift from missing documentation rules; two root causes documented; audit scope defined |
| b20260323.2354 | OPEN_ITEMS | OI-0017 closed: treatments edit + categories implemented (b20260323.2354) |
| b20260323.2354 | OPEN_ITEMS | Session Queue updated: OI-0030 priority 1, OI-0031 priority 2 |
| b20260323.2354 | HTML | Feature (OI-0017B/C): Treatment types now editable — `editTreatmentType(id)`, `cancelEditTreatment()`, `_mtResetForm()` added; `_editingTreatmentId` state variable; edit mode updates existing record, add mode creates new |
| b20260323.2354 | HTML | Feature (OI-0017C): `TREATMENT_CATEGORIES` constant added; category `<select>` in treatments sheet; `t.category` field on treatment type records; category badge in manage list |
| b20260323.2354 | HTML | Fix: `archiveTreatmentType()` and `unarchiveTreatmentType()` now call `renderMtTypesList()` in addition to `renderTreatmentTypesList()` |
| b20260323.2336 | SESSION_RULES | Doc v22 — §4a strengthened: ARCH UPDATES list must be written in response before present_files; §8e soft checklist replaced with mandatory written Delivery Gate block |
| b20260323.2336 | MASTER_TEMPLATE | v2.4 — same §4a and §8e changes propagated from SESSION_RULES v22 |
| b20260323.2336 | HTML | Bug fix (OI-0016): Removed `×` delete button and `onclick="deleteAnimalFromScreen()"` from animal row template in `renderAnimalsScreen()` — cull action accessible only from edit sheet |
| b20260323.2336 | HTML | Bug fix (OI-0018): `closeAnimalEdit()` now calls `renderAnimalsScreen()` when `curScreen==='animals'` — list refreshes immediately on sheet close |
| b20260323.2336 | HTML | Bug fix (OI-0020): Active group filter chip in `renderGroupsList()` now shows `✕ clear filter` green badge — makes tap-to-deselect discoverable |
| b20260323.2336 | HTML | Bug fix (OI-0024): `eventAUDs()` inside `renderRotationCalendar()` falls back to live `evGroups()`+`getGroupTotals()` for open events where `ev.head`/`ev.wt` not stamped — season total AUDs now populate correctly |
| b20260323.2336 | HTML | Bug fix (OI-0026): `renderRotationCalendar()` now collects `subMovePaddockNames` from `ev.subMoves[].locationName` and merges into `paddockNames` — sub-move-only paddock rows now appear in calendar; week-map rewritten as `windows[]` objects with clipped main-paddock end dates and sub-move windows |
| b20260323.2336 | HTML | Polish (OI-0025): `renderRotationCalendar()` replaced group-color coding with semantic `evCalColor(ev)` — green (#639922) for pasture, tan (#C4A882) for stored-feed/confinement; legend updated to match |
| b20260323.2336 | HTML | Bug fix (OI-0027): `saveSubMove()` alert no longer shows "Duration not set — edit to add hours later." when `hrs===0` — duration is not required at sub-move creation time |
| b20260323.2336 | ARCHITECTURE | Line ref: `renderRotationCalendar` noted at actual ~L11782 in new build |
| b20260323.2336 | ARCHITECTURE | Critical behavioral notes added for all 6 fixes: sub-move calendar windows, season totals fallback, semantic colors, sub-move toast, animal list delete removal, `closeAnimalEdit` refresh |
| b20260323.2336 | ARCHITECTURE | Animals Screen Layout note updated: `closeAnimalEdit()` refresh behavior + clear-filter badge documented |
| b20260323.2336 | OPEN_ITEMS | Feedback import: 14 new items (OI-0016 through OI-0029) from gthy-feedback-2026-03-23-1921.json; import log back-filled with real IDs for all prior CSV items |
| b20260323.2336 | OPEN_ITEMS | Closed: OI-0016, OI-0018, OI-0020, OI-0024, OI-0025, OI-0026, OI-0027 |
| b20260322.2207 | SESSION_RULES | Doc v21 — §8d write-first rule added; §8e checklist reordered; propagated to MASTER_TEMPLATE v2.3 |
| b20260322.2207 | HTML | Feature: home screen view toggle — `S.settings.homeViewMode` setting added (`'groups'` default \| `'locations'`); persists via `save()` |
| b20260322.2207 | HTML | New function: `renderHomeViewToggle(active)` — segmented pill control; renders "View: Groups \| Locations" at top of home groups area |
| b20260322.2207 | HTML | New function: `setHomeViewMode(mode)` — sets `S.settings.homeViewMode`, saves, re-renders home |
| b20260322.2207 | HTML | New function: `renderLocationsView(grpsEl, groups)` — event-centric home screen orchestrator; one card per open event + unplaced groups section |
| b20260322.2207 | HTML | New function: `renderLocationCard(ev)` — location card with type badge, day count, cost, sub-move summary, per-group action rows (Feed/Move/⚖/Split), NPK line, Sub-move + Edit event buttons |
| b20260322.2207 | HTML | New function: `renderUnplacedGroupsSection(unplaced)` — compact "NOT PLACED" card listing groups with no active event; each row has a Place button |
| b20260322.2207 | HTML | `renderHome()` — updated to branch on `homeViewMode`; groups view gets toggle injected at top; locations view delegates to `renderLocationsView()` |
| b20260322.2207 | ARCHITECTURE | File structure table: locations view functions block added (~L2627) |
| b20260322.2207 | ARCHITECTURE | Screen Map: `renderHome()` entry updated to note `homeViewMode` branch |
| b20260322.2207 | ARCHITECTURE | `S.settings.homeViewMode` documented in build versioning section |
| b20260322.2207 | OPEN_ITEMS | Header stamps updated to b20260322.2207 |

## b20260324.1130

**Session goal:** OI-0053 — remove primary group designation, all groups as peers

### OI-0053 — Primary group label removed; last-group-out closes event
`renderEeGroupChips()`: removed `i===0 && !g._isNew` special case. All committed groups now render with a Move Group button. "primary" label removed. Paddock "primary" labels untouched — paddock hierarchy has different semantics.

`saveEventEdit()`: after `applyEeGroupMoveActions()`, checks whether any active groups remain. If zero remain and the event is still open, auto-closes with `status='closed'`, `dateOut=today`, and recalculates totals. Handles both wizard and direct-move departure paths.

## b20260324.1100 (feedback import addendum)

**Feedback import:** 8 new items from gthy-feedback-2026-03-24-0649.json

OI-0046 through OI-0053 created. Session queue updated. All prior triage items now have OI numbers.

## b20260324.1100

**Session goal:** OI-0043 feed type validation bug

### OI-0043 — Feed type validation fires despite valid selection (fixed)
`addBatch()` used `parseInt()` on the feed type select value. Feed type IDs are strings (`"FT-00001"`) — `parseInt("FT-00001")` returns `NaN`, causing the `find()` match to always fail and triggering the "Select a feed type" alert even when a type was selected.

**Fix:** Removed `parseInt()`. `typeId` is now the raw string value from the select element.

**Secondary fix:** `renderFeedTypes()` Unarchive button onclick rendered the string ID unquoted in JS (`unarchive('feedType',FT-00001)`), which would cause a ReferenceError. Fixed by quoting the ID: `unarchive('feedType','${ft.id}')`.

**Data note:** The b20260324.0621 backup shows only one feed type (Alfalfa) and zero batches. Batches and additional feed types from prior sessions were lost — likely a `setupUpdatedAt` sync merge where a device with a newer setup timestamp but stale feedTypes array won wholesale. Feed types will need to be re-entered.

## b20260324.1030

**Session goal:** OI-0028 home header layout · OI-0019 animal screen chips

### OI-0028 — Mobile header two-row layout
`.hdr` CSS changed to `flex-direction:column` on mobile. Row 1: "Get The Hay Out" title + operation name (full width). Row 2: sync indicator, build tag, Field button, avatar. Desktop overrides back to `flex-direction:row` via `body.desktop .hdr`. Operation name in `updateHeader()` now shows farm name only — head count and group count removed.

### OI-0019 — Animal screen compact group chips + sticky header
Group filter `<select>` replaced with `.agc-chips` pill chip row. Chips: All · one per group (color dot + name) · Unassigned. Active chip highlighted green. Chips wrap horizontally. Search bar moved below chips. Entire filter area wrapped in `.agc-wrap { position:sticky; top:0 }` so it stays anchored while animal list scrolls. Hidden `<select>` retained for `filterAnimalsByGroup()` state compatibility.

## b20260324.0955

**Session goal:** Feedback import + home screen button redesign

### OI-0041 — Quick feed cancel returns to home screen (fixed)
`closeQuickFeedSheet()` now snapshots `qfFromHome` before resetting it. If the sheet was opened via home screen group card (Feed button), Cancel and backdrop-tap both navigate back to home via `nav('home',...)`. Previously cancel always left the user on the Feed screen. The closed-event guard path also benefits — it now returns home when appropriate.

### OI-0040 — Home screen button redesign: location view vs group view (fixed)
Implemented consistent, context-appropriate action buttons across both home screen views.

**Location view (`renderLocationCard`) — event-centric:**
- Per-group rows: **Move** (opens Event Edit for single-group departure) + **⚖** (weights). Feed, Split removed from rows.
- Card-level buttons: **Feed** (entire event via `goFeedEvent`) · **Move All** (closes event for all groups via `moveAllGroupsInEvent`) · **Sub-move** · **Edit event**

**Group view (`renderGroupCard`) — group-centric:**
- Buttons: **Move** (placed → opens Event Edit; unplaced → Place wizard) · **Split** · **Weights** · **Edit** (opens `openEditGroupSheet`)
- Removed: Feed, Sub-move, Edit event

**New helper functions:**
- `goFeedEvent(evId)` — finds first active group in event, delegates to `goFeedGroup`. Routes the `qfFromHome` flag correctly so cancel/save both return to home.
- `moveAllGroupsInEvent(evId)` — collects all active group IDs from event, sets `wizGroupIds`, launches Move Wizard. Guards against closed events and empty group lists.

### Feedback import — 10 new OI entries
OI-0036 through OI-0045 created from triage of items imported at b20260324.0910 (8 items) plus 2 new items from this session's feedback JSON (IDs 1774310373305, 1774310457328). See OPEN_ITEMS.md for full detail.


---

## b20260328.0140

**Session goal:** Event Edit full layout rebuild — active paddocks block, feed checks section, close-paddock inline flow, anchor close sequence.

### Changes

**Event Edit — Active Paddocks Block (`renderEeActivePaddocks`)**
New function replaces the flat chip list for active paddocks. Renders each active paddock as a color-coded card (green-bordered for grazing, amber-bordered for stored feed). Anchor paddock labelled. Active sub-moves also appear in this block with a "Record return" shortcut. Called from `openEventEdit`, `addEePaddock`, `removeEePaddock`, `closePaddock`, `reopenPaddock`, `openEePaddockClose`, `cancelEePaddockClose`, `saveEePaddockClose`, `addEeNextPaddock`, `dismissEeNextPaddock`.

**Inline Close Form (`openEePaddockClose`, `saveEePaddockClose`, `cancelEePaddockClose`)**
Each active paddock card has a "Close paddock" button. Tapping expands an inline form within the card: date out, time out (opt), post-graze cover % (slider+number), recovery min/max days (for grazing events), feed residual % (for stored-feed events). Save writes `dateRemoved`, `timeRemoved`, `forageCoverOut`, `recoveryMinDays`, `recoveryMaxDays`, `feedResidualPct` onto `eePaddocks[idx]` and transitions the card to the closed chips section.

**"Open next paddock" shortcut (`addEeNextPaddock`, `dismissEeNextPaddock`)**
After `saveEePaddockClose()` runs, a teal dashed card appears immediately below the just-closed paddock showing the inherited date-in and a paddock selector. Tapping "Open →" adds the selected paddock to `eePaddocks[]` with `dateAdded` pre-filled from the close date/time. "Skip" dismisses without adding. State held in `eePaddockJustClosed {dateOut, timeOut, name, _fromIdx}`.

**Closed paddocks — chips-only (`renderEePaddockChips` updated)**
`renderEePaddockChips()` now filters to `dateRemoved` entries only. Active paddocks are no longer rendered here. The closed chip shows a compact Reopen button and editable moved-on / moved-off date fields as before.

**`addEePaddock` guard updated**
Duplicate guard now only blocks adding a paddock that's already active (`!p.dateRemoved`). Previously-closed paddocks may be re-added as new entries (multi-rotation re-use of same paddock).

**Feed Checks section (`renderEeFeedChecks`, `openEeFeedCheck`, `editEeFeedCheck`, `closeEeFeedCheck`, `saveEeFeedCheck`, `deleteEeFeedCheck`)**
New section in the event edit sheet — hidden by default, shown when `ev.noPasture=true` or existing `feedResidualChecks[]` with `isCloseReading:false` are present. Also revealed when user checks the 100% stored-feed flag (`onEeNoPastureChange` updated). Inline add/edit form: date + bales-remaining % slider+number + notes. Saves to `ev.feedResidualChecks[]` with `isCloseReading:false`. These checkpoints drive `calcGrassDMIByWindow()` attribution.

**Anchor Close Sequence (`openEeAnchorClose`, `cancelEeAnchorClose`, `saveAndCloseFromEdit`)**
New amber "⬇ Close this event & move groups" button appears at bottom of sheet for open events only. Tapping reveals a pre-flight checklist block with step completion indicators: head/weight recorded, close date set, feed entries present (for stored-feed events). Final action is "Save & open Move Wizard →" which calls `saveEventEdit()` then `moveAllGroupsInEvent(evId)` via 100ms timeout.

**Sheet HTML rebuilt**
New section order:
1. Active paddocks block (`#ee-active-paddocks` → `#ee-paddock-chips` chips → `#ee-paddock` selector)
2. Core fields (date in/out, head/wt, ht in/out, cover in/out)
3. 100% stored feed flag
4. Feed checks section (`#ee-feed-checks-section` — conditional)
5. Closed event fields (residual slider, DMI variance)
6. Feed entries (`#ee-feed-list` + inline form)
7. Notes
8. Groups (`#ee-group-chips` + selector)
9. Sub-move history (`#ee-submoves-wrap`)
10. Recalc preview (`#ee-preview`)
11. Anchor close sequence (`#ee-anchor-close-wrap`)
12. Save / Cancel buttons
13. Close event button (`#ee-close-event-btn-wrap` — open events only)
14. Delete button

**New state vars:** `eePaddockCloseIdx` (index of paddock showing inline close form, `null` when none), `eePaddockJustClosed` (object with close details for "next paddock" shortcut, `null` when none). Both reset to `null` on `openEventEdit`.

---

## b20260328.0157

**Session goal:** OI-0056 (per-animal quick to-do — roadblock) + OI-0062 (todo paddock defaulting to G2).

### Changes

**OI-0056 — Per-animal quick to-do (`openAnimalTodoSheet`, `openTodoSheet`, `renderAnimalsScreen`)**

Three changes together implement the full feature:

1. `openTodoSheet(id, fromWiz, animalId)` — added optional third parameter `animalId=null`. When provided, passed directly to `populateTodoAnimal()` so the animal is pre-selected when the sheet opens.

2. `openAnimalTodoSheet(animalId)` — new thin wrapper that calls `openTodoSheet(null, false, animalId)`. Called from the animal row button.

3. Animal row in `renderAnimalsScreen()` — two additions: (a) a 📋 `N` amber badge in the name line when the animal has open todos (`S.todos.filter(t=>t.animalId===a.id&&t.status!=='closed').length > 0`); (b) a 📋 **Todo** button (amber-bordered) in the action buttons row, calling `openAnimalTodoSheet(a.id)`.

The todo data model already supported `animalId` — `saveTodo()` writes it and the `td-animal` select existed. This feature was purely a missing entry point.

**OI-0062 — Todo paddock defaulting to G-2 (`openTodoSheet`)**

Root cause: `openTodoSheet` called `getActive()` → `getAnyActiveEvent()` which returns `S.events.find(e=>e.status==='open')` — the first open event in the array regardless of user context. If that event happened to be for G-2, G-2 was pre-filled in the paddock field every time a new todo was created from the Todos screen.

Fix: removed the `getActive()` call entirely from the new-todo path. Paddock is now only pre-filled when `fromWiz && wizPaddockForTodo` (i.e. the user explicitly launched the todo from the Move Wizard with a paddock context). Default for all other entry points is blank (`''`). Existing edit path is unchanged — it still reads `t.paddock` from the saved todo record.

---

## b20260328.0243

**Session goal:** M1 — Supabase foundation. SDK added, auth plumbing wired, Settings UI updated. No data moves yet.

### Changes

**Supabase JS SDK (M1)**
CDN script tag added to `<head>` before `</head>`: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/dist/umd/supabase.min.js`. UMD bundle — loads synchronously, no build tooling required. Exposes `supabase` global used by `sbInitClient()`.

**Supabase globals and auth constants (~L1745)**
`SUPABASE_URL` and `SUPABASE_KEY` constants added immediately after the `driveState` init block. Two module-level vars: `_sbClient` (null until `sbInitClient()` runs) and `_sbSession` (null until first auth state event).

**`sbInitClient()` (~L1780)**
Creates the Supabase client via `supabase.createClient()`. Registers `onAuthStateChange` listener — fires on every page load (session restore), sign-in, sign-out, and token refresh. On `SIGNED_IN`: calls `sbUpdateAuthUI()` and `setSyncStatus('ok','Supabase')`. On `SIGNED_OUT`: calls `setSyncStatus('off','Not signed in')`. Called once at app init after `updateDriveUI()`. Safe to call multiple times — guards against double-init.

**`sbSignIn(email)` (~L1803)**
Async. Calls `_sbClient.auth.signInWithOtp({ email, options: { emailRedirectTo: window.location.origin } })`. Disables the send button with "Sending…" while in-flight. On success, shows a green confirmation line below the button. On error, alerts the message and re-enables the button. Accepts email from the `#sb-email-input` field or as a direct argument.

**`sbSignOut()` (~L1825)**
Async. Calls `_sbClient.auth.signOut()`. Clears `_sbSession`. Calls `sbUpdateAuthUI()`.

**`sbUpdateAuthUI()` (~L1833)**
Synchronous. Reads `_sbSession?.user`. Shows `#sb-signed-out` / hides `#sb-signed-in` when no session; reverses when session exists. Populates `#sb-user-email` with the user's email address. Called from: `onAuthStateChange`, `loadSettings()`, Settings nav handler, `sbSignOut()`.

**Settings screen — Supabase card added, Drive card demoted (~L1072)**
New primary card: "Account & sync — Supabase". Two states toggled by `sbUpdateAuthUI()`: signed-out (email input + Send magic link button + status line) and signed-in (green banner with email + Sign out button). Enter key on the email field triggers `sbSignIn()`.

Drive card retained but demoted: reduced to 0.75 opacity, section label changed to "Legacy sync — Google Drive [being replaced]". Farm code section simplified (instructions removed — will be replaced at M3). Drive functions (`driveConnect`, `driveSync`, `driveDisconnect`) all still work — Drive runs as safety net through M2.

**App init updated (~L14490)**
`sbInitClient()` called immediately after `updateDriveUI()`. The `onAuthStateChange` listener fires synchronously on init if a session exists in localStorage — session is restored without a network round-trip.

**`loadSettings()` updated**
`sbUpdateAuthUI()` called at end of function so Settings screen always reflects current auth state when opened.

**Settings nav handler updated**
`sbUpdateAuthUI()` added to the `curScreen==='settings'` branch so the card updates correctly when navigating to Settings from another screen.

---

## b20260329.1917

**Feedback system — area tagging + Supabase crash/write fixes**

**Bug: feedback items not rendering (ctx crash on Supabase-loaded rows)**
Root cause: migration script stored `ctx.screen` as a flat `screen` column; no `ctx` JSONB column in Supabase. `_sbToCamel` returned rows with `f.screen` but no `f.ctx`. Every render/export path reading `f.ctx.screen` threw `TypeError: Cannot read properties of undefined (reading 'screen')`, silently killing `renderFeedbackList()` on its first item.
Fix: assembly layer in `loadFromSupabase()` — feedback rows now reconstruct `f.ctx = { screen: f.screen||'?', activeEvent: null }` when `ctx` is absent. Render code unchanged.

**Bug: feedback queueWrite sending invalid column to PostgREST (400 errors)**
Root cause: `_sbToSnake({...f, operationId})` serialised the JS-only nested `ctx` object as `ctx: {...}` — a key with no corresponding Supabase column. PostgREST rejected all feedback writes.
Fix: new `_feedbackRow(f, opId)` helper builds an explicit column-safe row. All five write sites (`saveFeedbackItem`, `confirmFixed`, `reopenIssue` ×2, `saveResolve`) now use `_feedbackRow`.

**Feature: area tagging on feedback items**
- `AREA` constant — 10 options: Home, Animals, Events, Feed, Pastures, Reports, To-Dos, Settings, Sync/Data, Other.
- `SCREEN_AREA` map — `openFeedbackSheet()` auto-suggests the area for the current screen.
- Feedback sheet: Area `<select id="fb-area">` added between category pills and note field.
- `saveFeedbackItem()` reads and stores `f.area`; `reopenIssue()` carries area to regression item.
- `renderFeedbackList()`: second filter `<select id="fb-area-filter">` added; area badge shown on each row.
- `generateBrief()`: area appended to each item context line; ctx null crash fixed.
- `exportFeedbackCSV()`: Area column added; ctx null crash fixed.
- `exportFeedbackJSON()`: `area` field added per item; `screen` fallback uses `f.screen` for Supabase rows.
No schema changes required — `area` and `screen` columns already exist in the Supabase `feedback` table.

---

## b20260329.1751

**OI-0029 closed — Event log: parent + sub-move consolidation**

`renderEventsLog()` (~L6648) now renders sub-moves as a threaded visual unit beneath their parent event.

**Events without sub-moves:** Render unchanged.

**Events with sub-moves:**
- Parent row title gains a teal `N sub-moves` badge alongside any existing paddocks indicator.
- Parent row bottom border suppressed — the sub-move thread flows directly below with no visual gap.
- A teal left-border thread (2px solid `var(--teal)`, indented 16px) hangs beneath the parent containing one row per sub-move.
- Each sub-move row shows: `⇢ Location` name + `active`/`returned` badge + date-in → date-out (or "now" if active) · duration in hours · feed count if any.
- Sub-moves sorted chronologically by `sm.date` so the paddock sequence reads top-to-bottom.
- Clicking any sub-move row calls `openEventEdit(id)` — same as the parent row. Full sub-move management remains in the event edit sheet.
- Outer wrapper uses `margin-bottom:8px` to separate consolidated event blocks from one another.

**No data model changes.** Reads from `e.subMoves[]` (already assembled). All existing field aliases (`sm.date`, `sm.locationName`, `sm.durationHours`, `sm.dateOut`, `sm.feedEntries`) used directly.
