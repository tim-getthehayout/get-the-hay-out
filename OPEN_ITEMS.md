# Get The Hay Out — Open Items
**Last updated:** b20260403.0958
**Reconciled against build:** b20260403.0958
**Managed by Claude.** Do not edit manually — Claude updates this file during sessions.

> **Two input streams:**
> - **Claude observations** — things noticed during coding sessions, off the current task
> - **In-app feedback** — items imported from `S.feedback` via `exportFeedbackJSON()`
>
> **At session start:** Upload latest `gthy-feedback-YYYY-MM-DD-HHMM.json` and Claude imports
> new feedback items. Claude also surfaces relevant open items before work begins.
>
> **At session end:** Claude delivers the updated file alongside HTML and ARCHITECTURE.md.

---

## Status Summary

| Status | Count |
|---|---|
| 🔴 Open — Roadblock | 0 |
| 🔴 Open — Bug | 0 |
| 🟡 Open — Polish | 2 |
| 🔵 Open — Enhancement | 18 |
| ⚪ Open — Debt | 9 |
| ✅ Closed | 119 |

---

## Session Queue

Recommended work order as of b20260403.0047. Updated after OI-0145, OI-0159 closed + feed disposition + emoji bug fix.

### 🐞 Bucket 1 — Bugs (do first)
| Priority | OI | Title | Notes |
|---|---|---|---|

### 🔧 Bucket 2 — Missing fields & quick CRUD
| Priority | OI | Title | Notes |
|---|---|---|---|

### ⚙️ Bucket 3 — Workflow completions
| Priority | OI | Title | Notes |
|---|---|---|---|
| 1 | OI-0036 | Append group to existing event in same location | Touches move wizard |
| 2 | OI-0061 | Treatment system: multi-select + from edit form + type auto-populates | 3 sub-items — one session |
| 3 | OI-0011 | Animal body condition survey (group + individual) | New survey type |

### 📅 Bucket 4 — Rotation calendar
| Priority | OI | Title | Notes |
|---|---|---|---|
| 4 | OI-0065 | Pasture status gradient (survey state as green fill) | Render-only, no data model change |
| 5 | OI-0066 | "Today" vertical line on rotation calendar | Prerequisite for OI-0065 |

### 📱 Bucket 5 — Field mode quick wins
| Priority | OI | Title | Notes |
|---|---|---|---|

### 🔁 Parallel track — admin console (enables close-the-loop UI)
| Priority | OI | Title | Notes |
|---|---|---|---|
| — | OI-0138 | Admin console artifact — submissions management | One session; enables bulk-resolve via UI |
| — | OI-0139 | Thread reply UI in-app | After OI-0138 |

### 🔭 Deferred — design first
| OI | Title |
|---|---|
| OI-0014 | Stage feed before moving group (suspended future event concept) |
| OI-0038 | Confinement NPK as lost (data model change) |
| OI-0045 | Fertility factors form in Settings |
| OI-0059 | Audit all calculation functions |
| OI-0129 | Field mode per-module streamlined UX |
| OI-0146 | Field mode Move Animals wizard |
| OI-0047 | Grass growth curve dashboard |
| OI-0046 | NWS precipitation integration |
| OI-0105 | Membership-weighted NPK for multi-group events |
| OI-0134 | Private repo + edge-function auth gate |
| OI-0135 | Vite + ES modules migration |

---

### Close-the-loop protocol (updated b20260401.2246)

When OIs are created from feedback, stamp `oi_number` and set `status = 'planned'` in one statement:
```sql
UPDATE submissions
SET status = 'planned', oi_number = 'OI-XXXX'
WHERE id IN (...);
```

When OIs are closed in a session, the §8e delivery gate includes a "mark resolved" block:
```sql
UPDATE submissions SET status = 'resolved' WHERE id IN (...);
```

Import diff at session start: only surface `status = 'open'` items. `planned` items are already in OPEN_ITEMS — skip them.

Long term: OI-0138 admin console supports `PATCH ?action=update` for status + oi_number — eliminates the SQL step once live.

> **OI-0150–0167 added** b20260402.1058 — feedback import from gthy-feedback-2026-04-02-admin.json (18 new items from 34-item export; 16 already imported). Session queue restructured: Bucket 0 created for event tile + move flow design-first session (12 high-priority items). OI-0162 elevated to Bucket 2 as field testing enabler. OI-0161 deferred.
> **OI-0037, OI-0063, OI-0101 closed** b20260402.1017 — Group date/time pickers, sub-move return date, scroll fix, todo delete confirmed implemented. Bucket 2 now empty. Session queue reprioritized.
> **OI-0144, OI-0148, OI-0141, OI-0143, OI-0022 closed** b20260402.0940 — backlog sweep session. 5 items from Bucket 2 resolved. Session queue updated. Health events Supabase write gap noted as pre-existing debt.
> **OI-0141–0147 added** b20260401.2245 — feedback import from gthy-feedback-2026-04-01-1924.json. Session queue restructured around action-first buckets.
> **OI-0140 added** b20260401.2240 — RLS owner role doc fix.
> **OI-0137 added and closed** b20260401.1011 — PWA manifest encoding bug.
> **OI-0133 closed** b20260401.0055 — CSS regression fix.
> **OI-0132 closed** b20260401.0044 — FAB, feedback nav, field mode full-screen sheets.
> **OI-0134, OI-0135, OI-0136 added** b20260401.0954 — Build evolution and IP protection.
> **Status Summary corrected** b20260401.2245 — prior counts were stale; actual open bugs (OI-0070, OI-0071) and polish items (OI-0063 + others) were miscounted.
> **Last updated:** b20260401.2245

---

## Severity & Source Reference

**Severity:** `Bug` · `Polish` · `Enhancement` · `Debt`

**Source:** `Claude observation` · `In-app feedback` · `User report` · `Session regression`

---

## Open Items

### OI-0140
**Source:** Claude observation — b20260401.2240
**Area:** Developer Tooling / RLS / Documentation
**Severity:** Debt
**Status:** ✅ Closed
**Found:** b20260401.2240
**Closed:** b20260402.0913

**RLS policy documentation for `operations` and `operation_members` was incomplete.** The original ARCHITECTURE section documented owner-direct checks but omitted the `operation_member_access` policy that allows workers to read operations via the `get_my_operation_id()` SECURITY DEFINER helper. The narrative mentioned this pattern was added in M6 but the SQL code block didn't show it.

**Fixed:** Updated ARCHITECTURE lines 785–807 to show the complete working RLS policy set:
- Both `operations` and `operation_members` tables now include the full policy triple (direct user/owner checks + helper-based member access)
- Added detailed pattern note explaining why SECURITY DEFINER is needed and what each policy enables
- Cross-referenced the RLS Policy Pattern section below for the `get_my_operation_id()` helper function

This ensures future sessions have a single authoritative reference for the correct RLS pattern without having to infer it from scattered narrative notes.

---

### OI-0147
### OI-0147
**Source:** In-app feedback — id:1775003204664 (Tim, 2026-04-01)
**Area:** Mobile Layout (`@media max-width:899px`)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260401.2245
**Closed:** b20260402.0921

"Strange feedback remnant on Home Screen on mobile." The red feedback badge ("72") was appearing in the bottom-left corner of the home screen on mobile instead of being hidden or positioned correctly.

**Root cause:** The FAB feedback button (`.fab`) had `z-index:90;` while the mobile nav bar (`.bnav`) had `z-index:100;`. The FAB was positioned behind the nav. Additionally, the feedback badge (`#fb-badge`) is absolutely positioned inside the FAB, creating visual overflow and unexpected rendering on mobile where the FAB serves no purpose (feedback access is via the mobile nav Tasks button).

**Fixed:** Added `@media (max-width:899px) { .fab { display:none !important; } }` to completely hide the FAB on mobile devices. Desktop (>900px) keeps the FAB as intended. Mobile users access feedback via the Tasks nav button instead, eliminating the z-index conflict and the orphaned badge element.

---

### OI-0146
**Source:** In-app feedback — id:1775002527928 (Tim, 2026-04-01)
**Area:** Field Mode (`applyFieldMode`, Move Wizard)
**Severity:** Enhancement
**Status:** 🔵 Open — Enhancement
**Found:** b20260401.2245
**Closed:** —

"Field mode — Move Animals: launch a streamlined move wizard that includes pickers for open events and streamlined workflow."

**Deferred — design first.** The move wizard is multi-step and field mode requires a full-screen, glove-friendly variant. Design session needed before implementation: step flow, back/cancel behaviour, event picker UX, and whether this folds into a single "log activity" workflow combining feed, move, and harvest.

**Acceptance criteria:** Design doc produced. Streamlined move sheet opens from field home "Move" tile, guides user through picking a group, picking a destination event, confirming sub-move or new event, and returns to field home on save.

---

### OI-0145
**Source:** In-app feedback — id:1775002940235 (Tim, 2026-04-01)
**Area:** Field Mode / Home Screen (`renderFieldHome()`)
**Severity:** Enhancement
**Status:** 🔵 Open — Enhancement
**Found:** b20260401.2245
**Closed:** —

Partial implementation of field home UX request. The "Feed Animals" tile label and 2-column tile grid were delivered in b20260401. Remaining actionable (non-design) items from the original feedback:

**A — To-Do list section below action tiles.** Below the FIELD_MODULES tile grid, render a compact to-do list showing open todos assigned to the active user or unassigned. Include a quick-add button (opens `openTodoSheet()`). Matches the feedback: "At section below Field mode action buttons add To Do's list. And to do quick add button."

**B — Simplified tile group info.** When field mode is active, group cards (if shown at all below tiles) should display only: group name, head count, current weight, and current location. Strip DMI, NPK, progress bars — too much detail for field use.

**Deferred (design first):** "Move Animals" tile and "Start new grazing event" tile — these require the streamlined wizard design (OI-0146) before implementation.

**Acceptance criteria:** Field home shows a to-do list section below the action tiles. Quick-add opens the todo sheet. Group info in field mode is stripped to the four essential fields.

---

### OI-0144
**Source:** In-app feedback — id:1774826500623 (Tim, 2026-03-29)
**Area:** Pastures Screen (`renderPastures()`, ~L5954)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260401.2245
**Closed:** b20260402.0940

---

### OI-0143
**Source:** In-app feedback — id:1774525756460 (Tim, 2026-03-26)
**Area:** Sub-Move Sheet (`openSubMoveSheet`, ~L9030)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260401.2245
**Closed:** b20260402.0940

Recovery min/max section in sub-move sheet wrapped in `display:none`. DOM elements preserved for safe null reads in `saveSubMove()`. Recovery data only set via survey sheet.

---

### OI-0142
### OI-0142
**Source:** In-app feedback — id:1775083774847 (Tim, 2026-04-01)
**Area:** To-Do System (`renderHome()` at ~L4500)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260401.2245
**Closed:** b20260402.0927

"To-dos not showing on home screen after sign-in." Root cause: `renderHome()` was filtering todos by `(t.assignedTo||[]).includes(_myUid)` — only showing todos assigned to the current user. If todos had empty `assignedTo` or weren't explicitly assigned to the logged-in user, they stayed hidden. This filter was overly restrictive for a home screen.

**Fixed:** Removed user assignment filter from `renderHome()`. Home screen now shows all open todos (up to 4). Detailed filtering by user/location/status remains available on the dedicated Todos screen. This matches the intended behavior: home screen is an overview, todos screen is for filtering/management.

Change: `renderHome()` line ~4500 now filters only by `t.status !== 'closed'` instead of requiring `(t.assignedTo||[]).includes(_myUid)`.

---

### OI-0141
**Source:** In-app feedback — ids:1774818588197, 1774820123822, 1775083774847 (Tim, 2026-03-29 to 2026-04-01)
**Area:** To-Do System (`openTodoSheet`, `saveTodo`, `renderTodos()`, ~L2921)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260401.2245
**Closed:** b20260402.0940

Edit path already existed via `openTodoSheet(id)` — tapping a todo card opens it in edit mode with all fields populated. Added `deleteTodo()` function with confirmation prompt, direct Supabase delete, and UI refresh. Delete button (`#todo-delete-wrap`) visible in edit mode only.

---

### OI-0148
**Source:** Claude observation + session design — b20260401.2246
**Area:** Submissions System (`renderFeedbackList()`, `renderFeedbackTab()`, `_submissionRow()`, import protocol)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260401.2246
**Closed:** b20260402.0940

Implemented `planned` status across the submission system: filter dropdown (`planned` option), edit submission status dropdown, `renderFeedbackList()` filter logic and status badge (`📋 OI-XXXX` green badge), `renderFeedbackStats()` planned count. No DDL needed — text column. Admin console filter (OI-0138) not yet updated — will add `planned` when console is next touched.

---

### OI-0139
**Source:** Claude observation — b20260401.2022
**Area:** Submissions / Support
**Severity:** Enhancement
**Status:** 🔵 Open — Enhancement
**Found:** b20260401.2022
**Closed:** —

**Thread reply UI — users see dev responses but cannot reply in-app.** The `dev_response` and `thread` fields are written by the admin console and displayed in the app (collapsible thread banner). However there is currently no in-app UI for users to send a reply to a thread. Users who receive a dev response on a support ticket can only read it. A "Reply" button below the thread banner would append a `{role:'user', text, ts, author}` entry to the thread array and `queueWrite('submissions',...)` the updated row.

**Depends on:** OI-0138 (admin console must be working so dev can see replies)

**Acceptance criteria:** Tapping "Reply" on a support ticket with a dev response opens a small text input inline. Submitting appends to `f.thread[]`, queues write. Dev sees the reply in the admin console thread view.

---

### OI-0138
**Source:** Claude observation — b20260401.2022, redesigned b20260401.2037
**Area:** Developer Tooling / Admin Console
**Severity:** Enhancement
**Status:** 🔵 Open — Enhancement
**Found:** b20260401.2022
**Closed:** —

**Admin console — Edge Function + admin secret architecture.** A two-part system: a Supabase Edge Function that holds the service role key server-side, and a standalone React artifact (runs in Claude.ai) that calls it via a lightweight admin secret.

**Why not service role key in the artifact:** The service role bypasses all RLS. Exposing it in a browser artifact risks full-project compromise if the session is screenshotted or leaked. The Edge Function keeps it server-side permanently.

**Why not a dedicated admin user per operation:** Requires adding the user to every operation manually — clunky at scale, pollutes the member list.

**Architecture:**
```
React artifact (browser)
  → POST /functions/v1/admin-submissions
    Header: X-Admin-Secret: <uuid you generate once>
  → Edge Function validates secret (env var ADMIN_SECRET)
  → Queries submissions with internal service role client
  → Returns results — only submissions data, nothing else
```

**Edge Function actions:**
- `GET ?action=list` — all submissions, cross-tenant, with optional query filters
- `PATCH ?action=respond` — write `dev_response`, append to `thread[]`, set `first_response_at`
- `PATCH ?action=update` — edit `cat`, `type`, `status`, `area`, `priority`, `oi_number`
- `DELETE ?action=delete` — hard delete by id

**Console config (one entry per Supabase project):**
```js
{ name: "Get The Hay Out", fnUrl: "https://…supabase.co/functions/v1/admin-submissions", adminSecret: "paste-at-session-start" }
```
Admin secret is pasted into the artifact's React state — never written to a file or committed.

**Console features:**
- Filter by: type, status (`open` / `planned` / `resolved` / `closed`), cat, priority, area, operation (cross-tenant). Default view shows `open` + `planned` together as the active triage queue. `planned` items display their `oi_number` badge.
- Full thread view + dev reply input
- Edit cat/type/status/area/priority inline
- Link `oi_number` to any item
- AI triage: batch uncategorized items to Claude Haiku for category suggestions (approve/reject per item)
- Export: `gthy-feedback-YYYY-MM-DD-admin.json` in standard session-import format

**One-time setup before first use:**
1. Supabase Dashboard → Edge Functions → New function `admin-submissions`
2. Set env vars: `ADMIN_SECRET` (run `uuidgen` in Terminal), `SUPABASE_SERVICE_ROLE_KEY` (from Dashboard → Settings → API)
3. Deploy function code (delivered this session as `admin-submissions_index.ts`)
4. At console open: paste function URL + admin secret

**Acceptance criteria:** Console renders all submissions from GTHY operation. Writing `dev_response` is reflected in app on next load. Filter/sort works. OI number linkage persists. AI triage approvals write to Supabase and refresh the list.

---
**Source:** Claude observation — b20260401.1011
**Area:** PWA / Manifest
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260401.1011
**Closed:** b20260401.1011

**PWA manifest `href` encoding bug — shortcuts never loaded.** The `<link rel="manifest">` data URI on line 5 embedded raw JSON containing unescaped double-quote characters (`"`) inside an HTML attribute that is itself double-quote delimited. The HTML parser terminated the `href` attribute value at the first `"` inside the JSON, so the browser received `data:application/manifest+json,{` — a broken, invalid URI. The manifest never loaded. All three PWA shortcuts (Field Home, Log Feed, Log Harvest) were silently non-functional since they were first implemented. Fix: all `"` characters in the JSON body replaced with `%22`. Simultaneously fixed: viewport meta tag missing `/>` (line 6); added `<link rel="apple-touch-icon">` for correct iOS home screen icon.

**⚠️ Re-install required:** The shortcuts will not appear on any device where the PWA is already installed with the broken manifest. User must remove and re-add the home screen icon to pick up the corrected manifest.

**Acceptance criteria:** Chrome DevTools → Application → Manifest shows all three shortcuts. Long-pressing the home screen icon on Android shows shortcut context menu. iOS: re-adding to home screen and long-pressing shows shortcuts (iOS 16.4+ only).

---

### OI-0136
**Source:** Claude observation — design session b20260401.0954
**Area:** Infrastructure / Distribution
**Severity:** Debt
**Status:** ⚪ Open — Debt
**Found:** b20260401.0954
**Closed:** —

**Capacitor native app wrapper for App Store / Play Store distribution.** Once the Vite migration (OI-0135) is stable, Capacitor can wrap the build output as a native iOS/Android app. This enables App Store distribution — relevant if commercializing or distributing GTHY to other farm operations. GTHY already has the required `manifest.json` and `sw.js` in place. Capacitor adds native APIs (camera, file system, push notifications) progressively without requiring UI changes.

**Depends on:** OI-0135 (Vite migration must be stable first)

**Acceptance criteria:** App builds and runs as a native iOS app via Xcode without functional regressions. Existing PWA install path on Safari continues to work.

---

### OI-0135
**Source:** Claude observation — design session b20260401.0954
**Area:** Infrastructure / Build Pipeline
**Severity:** Debt
**Status:** ⚪ Open — Debt
**Found:** b20260401.0954
**Closed:** —

**Vite + ES modules migration — structural refactor, no feature changes.** The single-file HTML monolith (~14,500 lines, ~724KB) is approaching the point where splitting into proper ES modules is warranted for maintainability, testability, and AI session context limits. This is a structural refactor, not a rewrite — all logic stays identical; Vite bundles it back into a deployable artifact. Key outcomes: tree-shaking, proper npm imports (no CDN script tags), automatic minification/obfuscation as a build side-effect, and a foundation for Capacitor (OI-0136). `deploy.py` updated to run `vite build` before stamping and committing. `node --check` validation step replaced by `vite build` as the delivery gate (closes OI-0073 gap). Optional: `vite-plugin-singlefile` can preserve single-file output during transition.

**Key constraint:** `_SB_ALLOWED_COLS` allowlist and all assembly-layer field aliasing patterns must survive unchanged. Acceptance criterion: app behaves identically before and after — no feature delta.

**Depends on:** OI-0134 (repo private first is recommended but not strictly required)

**Acceptance criteria:** `vite build` passes cleanly. Deployed app at getthehayout.com is functionally identical to pre-migration. All Supabase auth flows, realtime subscriptions, and sync queue behaviour verified.

---

### OI-0134
**Source:** Claude observation — design session b20260401.0954
**Area:** Infrastructure / Security
**Severity:** Debt
**Status:** ⚪ Open — Debt
**Found:** b20260401.0954
**Closed:** —

**Private repo + edge-function auth gate — near-term IP protection.** Move the GitHub repo to private. Add a Cloudflare Worker (or Netlify Edge Function) that requires a valid session before serving `index.html` — so the source is not freely downloadable. The existing `push.command` + `deploy.py` workflow and GitHub Pages deployment are unchanged. This is a pure infrastructure change; no app code changes required. Note: Supabase RLS + Auth already protects all farm data — anyone who obtains the HTML gets a useless shell. This change closes the source code view-source exposure only.

**Key constraint:** The edge-function gate must not interfere with Supabase OTP / magic-link auth flows, which use direct Supabase SDK calls that bypass the served HTML.

**Acceptance criteria:** GitHub repo is private. `index.html` is not accessible without authentication at the CDN layer. Supabase OTP sign-in flow continues to work end-to-end.

---

### OI-0133
**Source:** Session regression — b20260401.0055
**Area:** Field mode CSS · Harvest sheet
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260401.0047
**Closed:** b20260401.0055

CSS regression introduced in b20260401.0044: `body.field-mode .field-mode-sheet { display:flex !important }` forced any element with class `field-mode-sheet` visible the instant `body.field-mode` was set — before any sheet was opened. Since `#quick-feed-wrap` carries that class, it became permanently visible on field mode entry, overriding its `display:none` state with `!important`.

**Fix A — CSS rule corrected.** Changed to `body.field-mode .field-mode-sheet.open .sheet { ... }` — only resizes the inner `.sheet` when the outer wrap already has the `.open` class. Never forces visibility.

**Fix B — Harvest sheet switched to `.open` class.** `#harvest-sheet-wrap` was opened/closed via `style.display='flex'/'none'` (inline style), making it invisible to the `.field-mode-sheet.open` CSS selector. Switched `openHarvestSheet()` to `.classList.add('open')` and `closeHarvestSheet()` to `.classList.remove('open')` — consistent with all other sheets. All three `style.display==='flex'` guards updated to `.classList.contains('open')`. Redundant `style="display:none"` removed from HTML (`.sheet-wrap` base CSS already provides `display:none`).

---

### OI-0132
**Source:** User report — b20260401.0044
**Area:** FAB · Feedback · Field mode sheets · Quick Feed · Harvest
**Severity:** Bug + Enhancement
**Status:** ✅ Closed
**Found:** b20260401.0023
**Closed:** b20260401.0044

Five fixes in one session:

**A — FAB restored to green + cross.** Chat-bubble SVG replaced with explicit `22×22` `+` cross SVG. `body.field-mode .fab { display:none !important }` added — FAB hidden in field mode (not a field-mode action). FAB base CSS uses `right:16px` — confirmed bottom-right positioning.

**B — Settings "Feedback log" button.** Changed from `openFeedbackSheet()` (opens the add-feedback form) to `nav('feedback', ...)` — correctly navigates to the full feedback screen with the list.

**C — Harvest sheet full-screen in field mode.** `field-mode-sheet` class added to `#harvest-sheet-wrap`. `openHarvestSheet()` detects field mode: backdrop tap-to-close disabled, handle hidden, close button → "⌂ Done", cancel → "⌂ Done". `closeHarvestSheet()` calls `_fieldModeGoHome()` in field mode. `saveHarvestEvent()` calls `_fieldModeGoHome()` after save in field mode (instead of `renderPastures()`). Alert replaced with `showSurveyToast`.

**D — Quick Feed "Feed Animals" full-screen flow.** `field-mode-sheet` class added to `#quick-feed-wrap`. Tile label "Log Feed" → "Feed Animals". `openQuickFeedSheet()` in field mode: backdrop disabled, handle hidden, step-1 "⌂ Done" button shown, Cancel hidden, step-2 cancel → "← Back". `qfShowEventStep()` respects field mode (cancel hidden, done shown). Step-2 "← Back" returns to event picker (not close). `saveQuickFeed()` in field mode: stays on event picker with toast — user feeds more groups or taps "⌂ Done". `closeQuickFeedSheet()` in field mode: always `_fieldModeGoHome()`.

---

### OI-0131
**Source:** User report — b20260401.0016
**Area:** Field mode header · Bottom nav · SW update
**Severity:** Bug + Enhancement
**Status:** ✅ Closed
**Found:** b20260401.0000
**Closed:** b20260401.0016

Four fixes in one session:

**A — Field mode context-sensitive header button.** When in field mode and not on the home screen, the toggle button now shows "⌂ Home" and calls `_fieldModeGoHome()` — navigates back to the tile grid without exiting field mode. Only on the home screen does it show "← Detail" to exit. `_updateFieldModeBtn()` called from `nav()` on every screen transition to keep it current. New functions: `_updateFieldModeBtn()`, `_fieldModeGoHome()`.

**B — Bottom nav overflow/corruption fix.** The Fields and Feed nav buttons had their HTML corrupted (closing `</button>` and opening `<button` merged into garbled text that rendered as literal `onclick=...` content on screen). Both buttons rebuilt cleanly. Feedback removed from the 7-item mobile nav — was causing overflow on narrow phones. Nav items: Home, Animals, Tasks, Events, Fields, Feed, Settings.

**C — Feedback access after nav removal.** FAB button updated to use chat bubble icon and now carries the `fb-badge` unread count. "💬 Feedback" button added to Settings bottom action row. Desktop sidebar `#dbn-feedback` unchanged.

**D — SW update hardening for iOS PWA.** `checkForAppUpdate()` now polls for `reg.installing` when `reg.waiting` is null (iOS installs asynchronously after `reg.update()` resolves). Polls every 500ms up to 10s. `applyAppUpdate()` nuclear fallback: when no waiting worker found, unregisters SW + clears all caches + hard reload — forces iOS to fetch fresh HTML.

---

### OI-0130
**Source:** User report — b20260331.2356
**Area:** Field Mode — module toggle persistence + `toggleFieldMode` navigation
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260331.2335
**Closed:** b20260331.2356

Two field mode bugs fixed together:

**A — Module toggles not persisting.** `_setUserFieldModules()` was mutating the object returned by `getActiveUser()`, which is rebuilt fresh from `_sbProfile` + `gthy-identity` on every call — mutations to it are discarded immediately. Fix: `_getUserFieldModules()` now reads directly from `_sbLoadCachedIdentity()`; `_setUserFieldModules(keys)` writes directly into `gthy-identity` via `{...cachedIdentity, fieldModules: keys}`. `sbCacheIdentity()` updated to preserve `fieldModules` when refreshing identity on sign-in. `null` stored value = no preference yet → use `FIELD_MODULES_DEFAULT`. `getActiveUser()` return object now includes `fieldModules` for read-only reference.

**B — ⊞ Field button landing on feed sheet instead of tile grid.** `toggleFieldMode()` had a hardcoded `nav('feed')` from before the field home existed. Changed to `nav('home')` so tapping ⊞ Field always lands on `renderFieldHome()` when entering field mode.

---

### OI-0129
**Source:** User report / design session — b20260331.2335
**Area:** Field Mode — per-module sheets
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260331.2335
**Closed:** —

Each field mode tile currently calls the existing full-featured sheet (Quick Feed, Harvest, Survey, Animals). For true field-optimized UX, each module may benefit from a simplified sheet variant: larger tap targets, fewer secondary actions, single-task flow. Deferred until field mode is used in practice and specific friction points are identified.

**Acceptance criteria:** At least one module has a documented streamlined variant that differs meaningfully from the existing sheet. Design session required first.

---

### OI-0128
**Source:** User report — b20260331.2335
**Area:** Field Mode / Home Screen (`renderFieldHome`, `applyFieldMode`, PWA manifest)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.1353 (as OI-0006)
**Closed:** b20260331.2335

Field home tile grid — full implementation of OI-0006. `renderFieldHome()` now renders a 2-column grid of large tappable tiles (100px min height, glove-friendly). `FIELD_MODULES` constant defines all four modules (Feed, Harvest, Survey, Animals). Per-user `user.fieldModules[]` controls which tiles show; defaults to all four. `toggleFieldModule(key)` + `renderFieldModules()` power the Settings → Field mode card. `?field=home` routing added to `applyFieldMode()`. 3rd PWA shortcut "Field Home" (`/?field=home`, ⊞ icon) added to manifest — bookmarkable URL for farm workers to land directly in field mode. OI-0006 closed via this item.

**Future:** Each module may get a streamlined sheet variant — tracked as OI-0129.

---

### OI-0127
**Source:** User report — b20260331.2335
**Area:** Harvest sheet · Feed types sheet · `_generateBatchId` · `_SB_ALLOWED_COLS`
**Severity:** Bug + Enhancement
**Status:** ✅ Closed
**Found:** b20260331.2335
**Closed:** b20260331.2335

Four harvest module fixes shipped together:

**A — `defaultWeightLbs` on feed types.** New field on `S.feedTypes[]`. "Default weight (lbs) per bale/unit" input added to feed type form (`ft-default-weight`). Badge shown in list row. `_harvestAddFieldRow()` pre-populates `weightPerUnitKg` from `ft.defaultWeightLbs` when a new field row is added. Wired in `addFeedType()`, `openEditFeedType()`, `saveEditFeedType()`, `_clearFeedTypeForm()`. `_feedTypeRow()` and `_SB_ALLOWED_COLS['feed_types']` updated. Requires `ALTER TABLE feed_types ADD COLUMN IF NOT EXISTS default_weight_lbs numeric` before pushing.

**B — Weight label kg→lbs.** Harvest sheet field label "Weight / bale (kg)" → "Weight / bale (lbs)". Field card display "· kg/bale" → "· lbs/bale". Internal field name `weightPerUnitKg` and Supabase column `weight_per_unit_kg` intentionally left as-is (rename = migration risk); mismatch documented in ARCHITECTURE under the weight units clarification note.

**C — Batch ID fieldCode sanitization.** `_generateBatchId()` now strips non-alphanumeric characters from `p.fieldCode` before using it as the field segment. `"E-3"` → `"E3"`, preventing the 5-segment broken ID `HOM-E-3-1-20260331`.

**D — `harvest_event_fields` `_SB_ALLOWED_COLS` entry.** `queueWrite()` auto-injects `operation_id` into every record. `harvest_event_fields` has no `operation_id` column (child table — `harvest_event_id` FK suffices). The missing `_SB_ALLOWED_COLS` entry meant the injected `operation_id` reached Supabase → Error [1] "Could not find the 'operation_id' column". Fix: added `harvest_event_fields` entry to `_SB_ALLOWED_COLS` without `operation_id`.

**E — Inline harvest-active toggle.** `toggleFeedTypeHarvestActive(idx)` added. Feed type list rows now show a pill toggle (green `🌾 Active` / gray `○ Inactive`) alongside the Edit button. One-tap saves immediately and re-renders the harvest tile grid if that sheet is open.

**SQL required before pushing:**
```sql
ALTER TABLE harvest_events ALTER COLUMN id TYPE text;
ALTER TABLE harvest_event_fields ALTER COLUMN id TYPE text;
ALTER TABLE harvest_event_fields ALTER COLUMN harvest_event_id TYPE text;
ALTER TABLE feed_types ADD COLUMN IF NOT EXISTS default_weight_lbs numeric;
```

---

### OI-0126
**Source:** User report — b20260331.2224
**Area:** Feed Types sheet + Harvest sheet + Fields screen
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260331.2224
**Closed:** b20260331.2224

Three related harvest module polish changes delivered together:

**A — Feed types button on Fields screen.** `openFeedTypesSheet()` button added to the Fields screen header row alongside Survey and Harvest. Visible to all users.

**B — Feed types button inside Harvest sheet.** Small `⚙️ Feed types` button added in the subtitle row of the harvest sheet. Closing the feed types sheet from this context auto-calls `_renderHarvestTileGrid()` so newly activated types appear immediately as tiles without reopening the harvest sheet.

**C — Feed types sheet redesign.** Form layout reversed (create form at top, existing types list at bottom). Edit button per row replaces `×` delete. Delete now only reachable inside the edit form (admin-gated). New functions: `openEditFeedType(idx)`, `saveEditFeedType()`, `cancelFeedTypeEdit()`, `_deleteFeedTypeFromEdit()`, `_clearFeedTypeForm()`. Hidden `ft-edit-idx` input + `ft-form-title` + `ft-create-btns`/`ft-edit-btns` div pair drive the create/edit mode toggle.

---

### OI-0125
**Source:** Claude observation — b20260331.2211 (session queue previously labelled "OI-0069")
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L16589)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260325.0037 (session queue carried forward as OI-0069)
**Closed:** b20260331.2211

Rotation calendar legend was missing a "Stored feed sub-move" swatch. The block colour logic (`c.win.smNoPasture`) correctly rendered stored-feed sub-move blocks in tan (`#C4A882`) and pasture sub-move blocks in green (`#639922`), but the legend only had a single green-dashed "Sub-move" entry — so tan sub-move blocks had no legend entry when no main events were stored-feed or confinement.

**Fix:** Added `hasStoredFeedSubMoves` flag (scans all sub-moves for `sm.noPasture=true`) and `hasTanBlocks` (combines main-event and sub-move checks). Legend now renders four conditional swatches: green solid (always), tan solid (`hasTanBlocks`), green dashed (always), tan dashed (`hasStoredFeedSubMoves`). Also renamed "Sub-move" → "Pasture sub-move" for clarity.

---

### OI-0124
**Source:** User report / design session — b20260331.1446
**Area:** Fields screen — harvest log, reconcile view
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260331.1446
**Closed:** b20260331.2158

Harvest log and reconcile view on the Fields screen. After OI-0122 and OI-0123 are shipped, the Fields screen harvest events log needs a dedicated view oriented around the batch ID lot number system — making it useful for organic audit and physical inventory reconcile.

**Scope:**
- Harvest events log on field card: show cutting#, batch ID, bale count, date — one row per harvest event field record
- Reconcile summary per field per year: cuts logged, total bales, batch IDs as printable list
- Batch ID appears prominently — this is the tie-out reference between the app and physical bale tags
- Filter/group by cutting number (1st/2nd/3rd/4th) within the field view
- No new data model changes — all data present after OI-0122/0123

**Depends on:** OI-0122 (schema), OI-0123 (harvest event model with batch IDs)

**Acceptance criteria:** A farmer can open a field's harvest history, see all batches with their lot numbers by cutting, and confirm the count matches physical inventory.

---

### OI-0123
**Source:** User report / design session — b20260331.1446
**Area:** Harvest sheet — full UI rewrite
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260331.1446
**Closed:** b20260331.2158

Rewrite `openHarvestSheet()` / `_renderHarvestRows()` / `saveHarvestEvent()` to implement the tile-first harvest flow designed in the b20260331.1446 design session.

**Current model (field → feed type):** User adds field rows, picks a feed type per row.
**New model (feed type tile → fields):** User taps active-tile feed types, then adds fields under each tile.

**Full spec:**

*Tile grid:*
- Renders `S.feedTypes.filter(f => f.harvestActive && !f.archived)` as large tap-target tiles
- Tile label: feed type name + cutting badge (`1st`, `2nd`, etc. from `ft.cuttingNum`)
- Tap = select/deselect tile. Selected tiles expand inline to show their field sub-record list
- If no active tiles exist: show nudge "No harvest types active — enable them in Feed Types settings"

*Per-tile field sub-records (vertical list):*
- "+ Add field" button per tile — appends a field row under that tile
- Each field row (in order of visual prominence):
  1. **Weight per bale** (large input, first — most variable field condition to field condition)
  2. Field picker (select from `S.pastures`, non-archived)
  3. Bale count / quantity
  4. Auto-generated batch ID (editable text input)
  5. Notes (optional)
- Batch ID auto-generated on field selection: `[FARM3]-[FIELDCODE]-[CUT#]-[YYYYMMDD]`
  - `FARM3`: first 3 chars of `S.farms.find(f.id === p.farmId).name`, uppercased
  - `FIELDCODE`: `p.fieldCode` if set, else first 3 chars of field name + `⚠` hint
  - `CUT#`: `ft.cuttingNum` (integer). If null on feed type: omit segment + warn in ID field
  - `YYYYMMDD`: harvest event date (from date field at top of sheet)
- Batch ID regenerates when field or date changes unless user has manually edited it (dirty flag)

*Sheet header:*
- Date field (top)
- Event notes (optional, below date)

*Save:*
- One `S.harvestEvents[]` entry per save (one event covers all tiles + fields)
- One `S.batches[]` auto-created per field sub-record (as now, but with `cuttingNum` + `batchId` populated)
- Existing `queueWrite` paths for `harvest_events` + `harvest_event_fields` + `batches`

*Launch contexts (single unified sheet — no separate implementations):*
- Fields screen "🌾 Harvest" button → `openHarvestSheet()` (existing trigger, same sheet)
- `?field=harvest` URL param → field mode → `applyFieldMode()` → `setTimeout(openHarvestSheet, 180)` (mirrors `?field=feed` pattern)
- Sheet is mobile-first by design — same layout in all contexts

**Depends on:** OI-0122 (`fieldCode`, `cuttingNum`, `harvestActive` schema + setup UI)

**Acceptance criteria:** Farmer in field mode opens harvest sheet, sees their active cut tiles, taps one, adds fields with weights, sees auto-generated batch IDs, saves — harvest event created, batches created with lot numbers, reconcile view shows the entries.

---

### OI-0122
**Source:** User report / design session — b20260331.1446
**Area:** Feed types, Pastures/Fields, Supabase schema, shape functions
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260331.1446
**Closed:** b20260331.2158

Schema groundwork for the harvest tile flow. Three new fields across two existing collections. No UX change to harvest sheet itself — that is OI-0123.

**New fields:**

`S.feedTypes[]`:
- `cuttingNum: null | 1 | 2 | 3 | 4` — integer, set at feed type setup. Drives batch ID generator and harvest analytics. `null` = not a cut hay product (e.g. silage, grain).
- `harvestActive: false` — operation-level flag. When `true`, this feed type appears as a tile in the harvest sheet. Toggled per feed type in the feed types list.

`S.pastures[]`:
- `fieldCode: null | string` — user-set short code (e.g. `07`, `B2`, `HKX`). Stable identifier for batch ID lot numbers and organic audit trail. Max ~6 chars. Set once at field setup, never auto-derived.

**SQL (three ALTERs — run before deploying OI-0122 build):**
```sql
ALTER TABLE feed_types ADD COLUMN IF NOT EXISTS cutting_num smallint;
ALTER TABLE feed_types ADD COLUMN IF NOT EXISTS harvest_active boolean DEFAULT false;
ALTER TABLE pastures ADD COLUMN IF NOT EXISTS field_code text;
```

**Shape function changes:**
- `_feedTypeRow()`: add `cutting_num`, `harvest_active`
- `_pastureRow()`: add `field_code`
- `_SB_ALLOWED_COLS['feed_types']`: add `cutting_num`, `harvest_active`
- `_SB_ALLOWED_COLS['pastures']`: add `field_code`
- Assembly layer (`loadFromSupabase`): `feedType.cuttingNum = r.cutting_num ?? null`, `feedType.harvestActive = r.harvest_active ?? false`, `pasture.fieldCode = r.field_code ?? null`

**Migration guards (in `ensureDataArrays` or assembly):**
- Existing `S.feedTypes[]` default `cuttingNum: null, harvestActive: false` — no data loss
- Existing `S.pastures[]` default `fieldCode: null` — no data loss

**UI changes:**

Feed type add/edit sheet:
- Add "Cutting #" selector: None / 1 / 2 / 3 / 4 — writes `cuttingNum`
- Add "🌾 Harvest active" toggle — writes `harvestActive`

Feed type list card (Settings):
- Show cutting badge + `🌾` indicator when `harvestActive` is true — scannable at a glance
- Toggle `harvestActive` directly from list row (no need to open full edit sheet for season flip)

Field add/edit sheet (`openLocEdit` / `openAddLocationSheet`):
- Add "Field code" text input — short, user-assigned. Placeholder: "e.g. 07, B2, HKX"
- Help text: "Used in batch lot numbers for harvest records."

Field card (Fields screen / `renderPastures()`):
- Show `fieldCode` as a small badge on the field card when set — visible without editing
- When not set: faint hint "No field code" — nudges setup but doesn't block workflow

**Acceptance criteria:** Feed types have cutting# and harvest-active flag configurable in settings. Fields have a stable field code visible on their card. All fields persist to Supabase. Existing data unaffected.

---

### OI-0111
**Source:** Migration tracking — b20260330
**Area:** M7 — Land, Farms & Harvest
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260330
**Closed:** b20260331.0100 (A–F all complete)

Adding multiple animals to a group in one save produced only 1 membership row in Supabase. Root cause: `_openGroupMembership` used `id: Date.now()` — synchronous `forEach` loop assigns the same millisecond timestamp to all membership rows. `queueWrite` deduplication matches on `id`, so each row overwrites the previous one in the queue. 10 cows added → 1 queue entry → 1 row in Supabase → after `loadFromSupabase` the group shows 1 cow. **Fix:** Changed to `id: Date.now() + S.animalGroupMemberships.length`. Since the array grows with each push, every call in the loop gets a unique value regardless of clock resolution.

---

### OI-0110
**Source:** User report + error log analysis — b20260330.1903
**Area:** New group save (~L9620), `_openGroupMembership` (~L8353)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260330.1903
**Closed:** b20260330.1903

When creating a new animal group, `_openGroupMembership()` (which calls `queueWrite('animal_group_memberships', ...)`) was called for each animal **before** `queueWrite('animal_groups', ...)` queued the parent group record. On flush, Supabase rejected the membership rows with `animal_group_memberships_group_id_fkey` FK violation because the parent group row hadn't been written yet. Confirmed in error log entries [1] and [2] at 18:54:39. **Fix:** Group record queued via `queueWrite('animal_groups', ...)` before the `animalIds.forEach` loop in the new-group branch of `saveGroupFromSheet()`.

---

### OI-0109
**Source:** User report + error log analysis — b20260330.1903
**Area:** `onAuthStateChange` (~L1843), `subscribeRealtime` (~L2635), `flushToSupabase` (~L3026)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260330.1903
**Closed:** b20260330.1903

Mobile data entered offline was lost on reconnect. Root cause: `onAuthStateChange` only flushed the pending write queue on `SIGNED_IN`, not on `INITIAL_SESSION`. On a normal mobile PWA resume — where the Supabase session token is still valid — the event fired is `INITIAL_SESSION`, so `loadFromSupabase` ran immediately without flushing, overwriting `S.*` with stale server data before local changes reached Supabase. The realtime callback had the same gap — a change from another device would trigger `loadFromSupabase` with no pre-flush. Confirmed in error log entry [4] at 18:51:48 (`INITIAL_SESSION` with no preceding flush). **Fix:** Added `ensureQueueFlushed()` helper; collapsed `SIGNED_IN`/`INITIAL_SESSION` branch so both await `ensureQueueFlushed()` before `loadFromSupabase`; realtime callback updated to `async () => { await ensureQueueFlushed(); loadFromSupabase(...) }`.

---

### OI-0108
**Source:** Claude observation — b20260330.1056
**Area:** `_feedTypeRow()` (~L2732), `_SB_ALLOWED_COLS`
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260330.1056
**Closed:** b20260330.1056

`_feedTypeRow()` was missing `cost_per_unit`. The column exists in the Supabase `feed_types` schema and is returned by `loadFromSupabase`, but was never written when a feed type was saved. Also missing from `_SB_ALLOWED_COLS['feed_types']`. **Fix:** Both added in b20260330.1056.

---

### OI-0107
**Source:** Claude observation — b20260330.1056
**Area:** `_batchRow()` (~L2716), `_SB_ALLOWED_COLS`, Supabase `batches` table schema
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260330.1056
**Closed:** b20260330.1056

`_batchRow()` was missing `wt` (unit weight in lbs) and `archived`. Editing batch unit weight or archiving a batch never persisted to Supabase — data was local-only, overwritten on next reload. `wt` and `archived` also missing from `_SB_ALLOWED_COLS['batches']`. **Fix:** Both added to shape function and allowlist. **Requires SQL:** `supabase-schema-fixes.sql` adds `wt` and `archived` columns to the live `batches` table — run before deploying this build.

---

### OI-0106
**Source:** Claude observation — b20260330.1056
**Area:** `_animalRow()` (~L2695), `_SB_ALLOWED_COLS`, Supabase `animals` table schema
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260330.1056
**Closed:** b20260330.1056

`_animalRow()` was missing `confirmed_bred` and `confirmed_bred_date`. These columns exist in the `animals` schema DDL (added as part of OI-0013) but were never included in the write path. Any animal marked confirmed-bred in the UI had the flag saved to localStorage only — on the next `loadFromSupabase()` the confirmed-bred status was silently overwritten with `false`. Also missing from `_SB_ALLOWED_COLS['animals']` meaning even a corrected shape function would have had the fields stripped at flush time. **Fix:** Both fields added to `_animalRow` and `_SB_ALLOWED_COLS['animals']`. **Requires SQL:** `supabase-schema-fixes.sql` adds `confirmed_bred` and `confirmed_bred_date` columns to the live `animals` table.

---

### OI-0105
**Source:** Claude observation — b20260329.2336
**Area:** `_memberWeightedDays`, `calcEventTotalsWithSubMoves`, `recalcEventTotals`
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260329.2336

Multi-group events (ae.groups with >1 active group) are explicitly excluded from the OI-0021 membership-weighted NPK calculation. `_memberWeightedDays` returns `null` for these events and both callers fall back to `ae.head × days` — identical to pre-OI-0021 behaviour, no regression.

The full fix requires summing weighted days across multiple groups' membership histories, accounting for each group's `dateRemoved` partial-duration window and potentially different per-animal entry/exit dates. This is a meaningfully more complex calculation and multi-group events are uncommon in practice.

**Acceptance criteria:** For multi-group events, NPK is computed by summing `_memberWeightedDays` results across each active group's membership window (clamped both by membership dates and the group's `dateRemoved` if set), using each group's average weight.

---

### OI-0104
**Source:** User report — b20260329.2238
**Area:** HTML `<head>` — Supabase SDK `<script>` tag (~L484)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.2238
**Closed:** b20260329.2238

`TypeError: null is not an object (evaluating 'document.body.scrollHeight')` thrown from `supabase.min.js` at global scope on every page load. The Supabase SDK internally touches `document.body` during initialisation for storage/CORS detection. With the script in `<head>`, `document.body` is null at execution time.

**Fix:** Moved SDK `<script>` tag from `<head>` to inside `<body>`, directly before the main app `<script>` tag. Execution order preserved — SDK loads first, then app script, both with `document.body` available.

---

### OI-0103
**Source:** User report — b20260329.2220
**Area:** `loadFromSupabase()` (~L2503)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.2220
**Closed:** b20260329.2220

`operations` and `operation_settings` returning 403 access control errors while all other tables loaded successfully. Root cause: these two fetches ran sequentially after the 19-table `Promise.all` batch. If the JWT auto-refreshed during that batch, the follow-on sequential queries ran with a stale token. RLS rejected the request.

**Fix:** Wrapped both in their own `Promise.all` so they execute concurrently and share the same token. The `operations` query uses `.eq('id', operationId)` (not `operation_id`) which is correct for the `operations` table PK — no change needed there.

**Note:** `current_uid` returning null in the Supabase SQL editor is expected — the editor runs as the postgres superuser, not as an authenticated JWT user. Not indicative of a problem.

---

### OI-0102
**Source:** In-app feedback (id: 1774818620446) — b20260329.2156
**Area:** Feedback tab — `renderFeedbackTab()`, `openFeedbackSheet()` (~L7230)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260329.2156

No way to edit a feedback item after submission. Typos, wrong category, or incorrect area can't be corrected. The resolve/reopen flow works but editing note/area/cat is not available.

**Proposed:** Edit button on open items re-opens the feedback sheet pre-populated with existing values. Save upserts the existing record.

---

### OI-0101
**Source:** In-app feedback (id: 1774818588197) — b20260329.2156
**Area:** To-do system — `renderTodos()`, `todoCardHtml()` (~L3650)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260329.2156
**Closed:** b20260402.1017 (implementation found in b20260402.0940 — `deleteTodo()` at ~L4993 with confirmation dialog, wired to `todo-delete-wrap` in HTML; was never closed in OPEN_ITEMS)

`deleteTodo()` function exists with `confirm()` prompt, Supabase direct delete via `_sbClient.from('todos').delete()`, and UI refresh. Delete button visible in todo sheet edit mode only (`todo-delete-wrap` shown when `id` is truthy).

---

### OI-0097
**Source:** User report — b20260329.2112
**Area:** `renderGroupCard` (~L3762), `_writePaddockObservation` (~L11240)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.2112
**Closed:** b20260329.2112

**Bug A — `activeSmGC` ReferenceError:** `const activeSmGC` declared inside `if(ae){...}` block but referenced in `return` template outside that block. `const` is block-scoped. Crashed `renderGroupCard` → `renderHome` on every home screen render when a group had an active event with sub-moves.
**Fix:** Hoisted to `let activeSmGC = null` before the `if(ae)` block; assignment changed from `const` to bare assignment inside the block.

**Bug B — `paddock_observations` 400:** JS `pastureName` field → `_sbToSnake` → `pasture_name` — no such Supabase column. PostgREST rejected every write. Missed by OI-0095 audit (manual JS_FIELDS dict was incomplete).
**Fix:** `_paddockObservationRow(obs, opId)` shape function added. `_writePaddockObservation` and `pushAllToSupabase` updated.

---

### OI-0096
**Source:** User report + Claude observation — b20260329.2010
**Area:** `save()` (~L2880), `onAuthStateChange` (~L1826)
**Severity:** Bug (Critical — data loss)
**Status:** ✅ Closed
**Found:** b20260329.2010
**Closed:** b20260329.2010

Two bugs working together to cause data loss when the Supabase session expires mid-use.

**Bug A — Stale green sync indicator:** `save()` branched on `_sbSession`: if truthy, debounced a Supabase flush; if falsy, called only `saveLocal()` with no call to `setSyncStatus`. The dot stayed whatever color it was from the last successful sync — permanently green even though every save after session expiry was going to localStorage only. User had no way to know the connection was gone.

**Fix A:** `save()` now calls `setSyncStatus('off', 'Not signed in — saved locally')` in the else branch.

**Bug B — Load overwrites unsynced data on reconnect:** `queueWrite` uses the cached `_sbOperationId` (persisted independently in localStorage) regardless of session state, so data entered while signed out IS queued with valid operation IDs. But `save()` never called `supabaseSyncDebounced()` while signed out, so nothing flushed. On `SIGNED_IN`, `onAuthStateChange` called `loadFromSupabase()` immediately — overwriting `S.*` from Supabase before the queue was flushed. The new records vanished from memory. `saveLocal()` at the end of `loadFromSupabase` then wrote the stale Supabase state back to localStorage, closing the window permanently.

**Fix B:** `onAuthStateChange` for `SIGNED_IN` now calls `flushToSupabase()` first (showing "Saving local changes…" status), then chains `.then(() => { loadFromSupabase(opId); subscribeRealtime(opId); })`. `INITIAL_SESSION` (normal page load with valid session) is unchanged — flush-first is only needed when re-authenticating after a signed-out period.

---

### OI-0095
**Source:** Claude observation — b20260329.1950
**Area:** Supabase write path — all `queueWrite` call sites
**Severity:** Bug (Critical)
**Status:** ✅ Closed
**Found:** b20260329.1950
**Closed:** b20260329.1950

Full write-path schema audit revealed 8 tables where `_sbToSnake` was producing records with invalid column names, causing PostgREST to reject entire upserts silently. All failed writes accumulated in `gthy-sync-queue` indefinitely (explains the "72 items pending" symptom). Additionally, on any successful write to a Realtime-watched table, `loadFromSupabase()` fires and overwrites `S.*` from Supabase — which doesn't contain the newly added records — so data appeared to vanish.

**Critical tables** (upsert rejected entirely): `animals`, `batches`, `animal_classes`, `animal_groups`, `ai_bulls`, `feed_types`, `input_products`, `todos`.

**Missing-field tables** (upsert succeeded but columns were null): `treatment_types`, `animal_group_memberships`, `animal_weight_records`, `manure_batch_transactions`.

**Fix:** 12 shape functions (`_animalRow`, `_batchRow`, `_feedTypeRow`, `_animalClassRow`, `_animalGroupRow`, `_aiBullRow`, `_inputProductRow`, `_todoRow`, `_treatmentTypeRow`, `_animalGroupMembershipRow`, `_animalWeightRecordRow`, `_manureBatchTransactionRow`) replace all `_sbToSnake` usage for these tables. 38 call sites updated. `pushAllToSupabase()` and `importSetupFile()` bulk-import block also fixed. `loadFromSupabase()` input_products assembly updated with read aliases.

**Tables confirmed clean** (no action needed): `pastures` (uses `_pastureRow`), `feedback` (uses `_feedbackRow`), `events`+children (uses `queueEventWrite`), `manure_batches`, `paddock_observations`, `input_application_locations`.

**Console command to clear stale queue:** `localStorage.removeItem('gthy-sync-queue')`

---

### OI-0094
**Source:** Claude observation — b20260329.1917
**Area:** Supabase `feedback` table
**Severity:** Polish
**Status:** 🟡 Open
**Found:** b20260329.1917

Feedback rows migrated before b20260329.1917 have `area = null` in Supabase. The app renders these without an area badge (graceful) but they won't appear in any area filter. A one-time SQL backfill could assign best-guess areas from the existing `screen` column:

```sql
UPDATE feedback
SET area = CASE
  WHEN screen IN ('feed') THEN 'feed'
  WHEN screen IN ('animals') THEN 'animals'
  WHEN screen IN ('events') THEN 'events'
  WHEN screen IN ('pastures') THEN 'pastures'
  WHEN screen IN ('reports') THEN 'reports'
  WHEN screen IN ('todos') THEN 'todos'
  WHEN screen IN ('settings') THEN 'settings'
  WHEN screen IN ('home') THEN 'home'
  ELSE 'other'
END
WHERE operation_id = '1355641a-40b7-4e82-ba3d-6cdd33e8f26d'
  AND area IS NULL;
```

Low priority — run in Supabase SQL editor when convenient.

---


**Source:** Claude observation — b20260329.1917
**Area:** `saveFeedbackItem()`, `confirmFixed()`, `reopenIssue()`, `saveResolve()` (~L7155–7190)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.1917
**Closed:** b20260329.1917

All feedback write paths were calling `queueWrite('feedback', _sbToSnake({...f, operationId}))`. `_sbToSnake` serialised the JS-only nested `ctx` object as a `ctx` key — no such column exists in the Supabase `feedback` table — causing PostgREST 400 errors on every feedback save.
Fix: new `_feedbackRow(f, opId)` helper writes only the known schema columns (`id`, `operation_id`, `cat`, `status`, `note`, `tester`, `version`, `ts`, `screen`, `area`, `resolved_in_version`, `resolution_note`, `resolved_at`, `confirmed_by`, `confirmed_at`, `linked_to`). All five write sites updated.

---

### OI-0092
**Source:** Claude observation — b20260329.1917
**Area:** `loadFromSupabase()` feedback assembly (~L2342), `renderFeedbackList()` (~L7220), `generateBrief()` (~L7242), `exportFeedbackCSV()` (~L7268)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.1917
**Closed:** b20260329.1917

Feedback items loaded from Supabase had no `ctx` property — migration stored `ctx.screen` as a flat `screen` column with no JSONB `ctx` column. `_sbToCamel` returned `f.screen` (flat) but no `f.ctx`. Every render/export path reading `f.ctx.screen` threw `TypeError: Cannot read properties of undefined (reading 'screen')`, silently killing `renderFeedbackList()` on its first Supabase-sourced item. Same crash in `generateBrief()` and `exportFeedbackCSV()`.
Fix: assembly layer — feedback rows now reconstruct `f.ctx = { screen: f.screen||'?', activeEvent: null }` when absent. All render/export code unchanged (assembly is the correct aliasing boundary).

**Follow-up (OI-0094):** Migrated rows have `area: null` — a one-time SQL backfill is needed to assign sensible areas to existing feedback data. Low priority; app is tolerant of null area.

---


**Source:** User report — b20260329.1855
**Area:** `loadFromSupabase()` todos assembly (~L2332), `todoCardHtml()` (~L3648), `renderHome()` (~L3287)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.1855
**Closed:** b20260329.1855

`TypeError: (t.assignedTo||[]).map is not a function` crash on every render involving todos. Root cause: migration script stored `assigned_to` as `JSON.stringify(array)` (a JS string `"[123]"`). PostgREST returns JSONB stored as a string literal back as a JS string — not a parsed array. `(t.assignedTo||[])` evaluates to the string `"[123]"` which is truthy, so the `||[]` fallback never fires, and `.map` on a string throws. All four downstream call sites (`.map`, `.includes`, `.some`, `new Set(...)`) were affected.

Fix: assembly layer in `loadFromSupabase()`. Todos rows now detect `typeof t.assignedTo === 'string'`, JSON-parse it back to an array, and normalise any remaining non-array value to `[]`. Render code unchanged (correct architecture — assembly is the aliasing boundary).

**Data loss note:** One todo entered during testing between builds was lost. Root cause: `saveTodo()` queued the write but the crash in `renderHome()` occurred before flush completed; next load pulled from Supabase (which didn't have it) and overwrote localStorage. This fix closes the crash window; the lost todo cannot be recovered.

**Supabase repair:** Run in SQL Editor to fix migrated rows that still hold stringified arrays:
```sql
UPDATE todos
SET assigned_to = assigned_to::text::jsonb
WHERE jsonb_typeof(assigned_to) = 'string';
```

---

### OI-0090
**Source:** User report — b20260329.1838
**Area:** `sbSendCode()` (~L1822), `sbVerifyOtp()` (~L1844)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.1838
**Closed:** b20260329.1838

"Supabase not initialised" alert appeared when attempting to sign in. Root cause: Supabase SDK CDN script (`cdn.jsdelivr.net`) can fail to load on first page load after a service worker cache update — the SW `fetch` handler returns early for cross-origin requests without calling `event.respondWith()`, which causes a race where the script tag fires before the browser's own cache for that URL is warm. `sbInitClient()` checks `typeof supabase === 'undefined'` and returns silently, leaving `_sbClient` null. Fix: both `sbSendCode()` and `sbVerifyOtp()` now call `sbInitClient()` on the spot before bailing — if the global became available this recovers silently. If still unavailable, a `confirm()` dialog prompts a page reload (which re-fetches the SDK successfully). User-facing message changed from a cryptic alert to an actionable reload prompt.

---

### OI-0089
**Source:** User report — b20260329.1831
**Area:** `flushToSupabase()` (~L2535), `_writePaddockObservation()` (~L10926), `migrateM0aData()` (~L13796)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.1831
**Closed:** b20260329.1831

Sync indicator showed "36 items pending — will retry" on every load with no new data. Each reload added ~36 more stale items. Root cause: `migrateM0aData()` runs at startup (line 15120) before `sbInitClient()` (line 15122), so `_sbOperationId` is null at that point. Every `_writePaddockObservation()` call triggered `queueWrite('paddock_observations', {..., operationId: null})`. Supabase rejected all of them (NOT NULL on `operation_id`), leaving them stuck in queue. New `Date.now()`-based IDs bypass queue dedup so count grew on every reload.

Two-part fix: (1) `_writePaddockObservation()` guards `if(_sbOperationId)` before calling `queueWrite` — skips write during startup migration, which is correct since `loadFromSupabase()` supplies the canonical rows. (2) `flushToSupabase()` strips items with `operation_id == null` before flushing, clearing accumulated stale entries from prior loads without touching valid items.

---

### OI-0088
**Source:** User report — b20260329.1831
**Area:** App startup sequence (~L15120), `detectMode()` (~L13634)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.1831
**Closed:** b20260329.1831

Desktop app loaded in mobile view (no sidebar, mobile bottom nav visible) on initial page load. Root cause: `detectMode()` and `applyFieldMode()` were called at end of the startup block (after all renders), so the `body.desktop` class was not set when `renderHome()` ran. The re-render triggered by `detectMode()` corrected it but there was a flash, and subsequent `renderCurrentScreen()` calls from `loadFromSupabase()` could race against it. Fix: moved `detectMode()` + `applyFieldMode()` to run immediately after `updateHeader()`, before `sbInitClient()` and `renderHome()`, so every render from first paint onward uses the correct layout class.

---

### OI-0087
**Source:** User report — b20260329.1816
**Area:** Home screen (`renderHome()`, ~L3262), To-do system
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.1816
**Closed:** b20260329.1816

Home "My open tasks" card was always empty even though the badge showed open todo count. Root cause: filter `(t.assignedTo||[]).includes(activeUserId)` fails silently when `activeUserId` is `null` (no legacy `gthy-user` key set in Supabase-only world — M6 not yet landed). Fix: when `activeUserId` is null, fall back to showing all open todos without user filtering.

---

### OI-0086
**Source:** User report — b20260329.1816
**Area:** Pastures screen (`renderPastures()` ~L6882, `openSurveySheet()` ~L5046, `renderSurveyPaddocks()` ~L5078)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260329.1816
**Closed:** b20260329.1816

Individual pasture "📋 Survey" button opened a dialog showing only the date field and "No pasture Location Defined." Root cause: `renderPastures()` passes `p.id` as a string in `onclick="openSurveySheet('${p.id}')"` (template literal with quotes), but Supabase returns `pastures.id` as a bigint (JavaScript number). Strict `===` comparison in `renderSurveyPaddocks()` (`p.id===surveyFocusPastureId`) and the title lookup in `openSurveySheet()` (`x.id===pastureId`) always evaluated false (string ≠ number). Fix: both comparisons now use `String()` coercion on both sides.

---

### OI-0074
**Source:** Claude observation — b20260328.1140
**Area:** Supabase M2 — identity cache (`gthy-identity`)
**Severity:** Debt
**Status:** ✅ Closed
**Found:** b20260328.1140
**Closed:** b20260328.1623

Display name input added to `#sb-signed-in` Settings block. `sbSaveDisplayName()` saves to `gthy-identity` cache via `sbCacheIdentity()`. `sbUpdateAuthUI()` populates the input from cached identity on sign-in. Sign out button retained alongside Save name button.

---

### OI-0076
**Source:** Claude observation — b20260328.1211
**Area:** Supabase auth — PWA standalone mode
**Severity:** Debt
**Status:** ✅ Closed
**Found:** b20260328.1211
**Closed:** b20260328.1211

**Root cause documented:** Magic link auth fails silently in PWA standalone mode because clicking a magic link opens regular Safari, not the PWA. PWA and Safari have isolated `localStorage` contexts — Supabase writes `sb-*` session tokens to Safari's storage; the PWA's `onAuthStateChange` listener never fires; `gthy-identity` and `gthy-operation-id` are never written; the home screen nudge never clears.

**Fix applied:** Replaced magic link flow with 6-digit OTP code (`signInWithOtp` without `emailRedirectTo` + `verifyOtp`). Code is entered directly in the app within the PWA localStorage context. Session tokens written to PWA storage. Requires Supabase email template to use `{{ .Token }}` instead of `{{ .ConfirmationURL }}`.

**Note for future auth work:** Any auth flow that requires a browser redirect (OAuth, magic links) will hit this same PWA isolation wall. OTP / password-based flows that verify in-app are safe. Keep this in mind if Google SSO or similar is ever considered for M6 multi-farmer.

---

### OI-0078
**Source:** Claude observation — b20260328.2211
**Area:** Supabase schema — `batches` table
**Severity:** Debt
**Status:** ✅ Closed
**Found:** b20260328.2211
**Closed:** b20260328.2241

`alter table batches add column wt numeric` run in Supabase SQL Editor. Existing batches populated: Peanut Hay / Oak Field Barn / Tarped → 750 lbs; Alfalfa Small Squares → 50 lbs. Batch assembly updated to read `wt` directly (no alias needed — no underscore conversion). `saveBatchAdj` also fixed: was missing `queueWrite('batches', ...)` entirely — batch edits never synced to Supabase. Both fixed in b20260328.2241.

---

### OI-0116
**Source:** Claude observation — b20260330.2039 (discovered during OI-0113 SQL fix)
**Area:** Supabase `pastures` table schema, all tables with `pasture_id bigint references pastures`
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260330.2039
**Closed:** b20260330.2116

SQL script `supabase-fix-pastures-id-cascade.sql` — dropped all FK constraints on `events`, `event_paddock_windows`, `event_sub_moves`, `event_npk_deposits`, `input_application_locations`, altered `pastures.id` and all child `pasture_id` columns to `text`, recreated `paddock_current_condition` view. Run before deploying b20260330.2116.

---

### OI-0115
**Source:** User report + Architecture gap — b20260330.2005
**Area:** `S.surveys[]`, `saveSurvey`, `paddock_observations`, pasture edit sheet
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260330.2005
**Closed:** b20260330.2116

**Architecture gap:** `S.surveys[]` is localStorage-only — no Supabase `surveys` table exists. The migration plan deferred this: "Will map to paddock_observations during M4 migration script." That mapping was never completed. As a result, surveys entered on one device never appear on another, and surveys are permanently lost if localStorage is cleared. The `paddock_observations` rows (source=`survey`) are correctly structured to be children of a `surveys` parent — the parent table is simply missing.

**What is needed (design-first before coding):**
1. **`surveys` Supabase table** — `id bigint, operation_id uuid, date date, notes text, created_at timestamptz`. Mirrors the survey container in `S.surveys[]`.
2. **Write path** — `saveSurvey()` queues a `surveys` row first (parent), then queues each `paddock_observations` row (children). `_surveyRow(sv, opId)` shape function. `loadFromSupabase` fetches and assembles `S.surveys`.
3. **Edit UI** — Re-open survey sheet pre-populated with existing ratings. Re-save updates the `surveys` row and replaces derived `paddock_observations` (delete old observations for this `source_id`, write new ones).
4. **Delete UI** — Remove `surveys` row + cascade-delete matching `paddock_observations` rows (where `source='survey' AND source_id=sv.id`).
5. **Pasture edit sheet history panel** — At the bottom of the pasture edit dialog, show a chronological list of all `paddock_observations` for this pasture with `source='survey'`: date, forage quality, veg height, forage cover, recovery windows.

**No existing data loss risk** — existing survey observations in `paddock_observations` keep their `source_id` pointing to the survey ID. Adding the `surveys` table just provides the missing parent.

---

### OI-0114
**Source:** Claude observation — b20260330.2005
**Area:** `flushToSupabase` (~L3039), `logError` (~L12976)
**Severity:** Debt
**Status:** ✅ Closed
**Found:** b20260330.2005
**Closed:** b20260330.2312

When `flushToSupabase` runs against a queue containing N permanently-stuck items (schema error or network dropout), every flush attempt logs N individual error entries. With `ensureQueueFlushed` now firing on every auth event and realtime callback, a single stuck queue generates hundreds of log entries in seconds — filling the 200-entry cap and burying useful earlier entries. Confirmed: 20 stuck queue items × ~8 reconnect cycles = 160 identical error entries at 19:51:46, pushing all earlier entries out of the log.

**Fix options:**
1. Dedup `logError` — if the last entry for the same source+message already exists, increment a counter instead of appending a new row
2. Circuit breaker in `flushToSupabase` — if all items fail with `TypeError: Load failed` (network down), suspend retries until the next `online` event
3. Schema-error detection — if a queue item fails with a Supabase schema error (400/422), move it to a permanent `failed` list rather than leaving it in the retry queue

Option 3 would have prevented the entire error storm today — the `bigint` errors were known-unflushable but kept retrying indefinitely.

---

### OI-0113
**Source:** Error log analysis — b20260330.2005
**Area:** Supabase `paddock_observations` schema, `_paddockObservationRow` (~L2854)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260330.2005
**Closed:** b20260330.2039

The `pasture_id` column in the Supabase `paddock_observations` table was created as `bigint`. The app sends string pasture IDs like `"PSTR-00017"`. Every `paddock_observations` upsert fails with `invalid input syntax for type bigint: "PSTR-00017"`. All 20 items in the phone's sync queue are permanently stuck and cannot flush.

**Immediate actions required:**
1. Go to Settings → Sync Queue → **Clear queue** on your phone (items cannot be recovered — they are duplicates anyway)
2. Run the corrected SQL script `supabase-fix-paddock-obs-pasture-id.sql` in the Supabase dashboard (see below — must drop and recreate the `paddock_current_condition` view)
3. Deploy build b20260330.2039 (not 2005 — never deployed)

**Why the second attempt failed:** After `DROP VIEW` succeeded, `ALTER COLUMN pasture_id TYPE text` was blocked by FK constraint `paddock_observations_pasture_id_fkey` — `pasture_id` references `pastures.id` which is `bigint`. Cannot create FK between text and bigint.

**Why the FK exists at all:** The migration plan DDL defined `pastures.id` as `bigint`. The app later moved to string PSTR IDs. The `paddock_observations.pasture_id` FK to `pastures.id bigint` is now a type mismatch that has silently blocked all `paddock_observations` writes since migration.

**⚠️ Side discovery:** If `pastures.id` is `bigint` in the live DB, pasture writes with PSTR string IDs have also been failing silently. The app functions from localStorage so this was invisible. This needs a separate SQL fix — see note below.

**Fix (v3 script — final):** DROP VIEW IF EXISTS → DROP CONSTRAINT IF EXISTS `paddock_observations_pasture_id_fkey` → ALTER COLUMN TYPE text → recreate view. Safe to run multiple times. FK is not recreated — app manages referential integrity at JS level.

**Additional SQL needed (OI-0113b — separate fix):**
```sql
ALTER TABLE pastures ALTER COLUMN id TYPE text;
```
This will likely also have FK dependencies from other tables (`event_paddock_windows`, `input_application_locations`, etc.) — investigate in a future session. Log as OI-0116.

---

### OI-0112
**Source:** Claude observation — b20260330.1939
**Area:** `flushToSupabase` (~L3039), `queueWrite` (~L2897), all write paths
**Severity:** Debt
**Status:** ⚪ Open
**Found:** b20260330.1939

If `_sbOperationId` is null at the moment a record is queued (edge case: queue write fires before `sbGetOperationId` has resolved on a fresh device, or on first sign-in before the operation row exists), the queued record has `operation_id: null`. `flushToSupabase` silently discards it: `const queue = rawQueue.filter(op => op.record && op.record.operation_id != null)`. The item is permanently removed from the queue with no error logged and no retry path.

Most likely to affect feedback, todos, and quick-feed entries made immediately after OTP sign-in on a new device before the operation row has been fetched.

**Fix options:**
1. Log a warning when stripping null-opId items (cheap — at minimum we should know when this happens).
2. Re-queue null-opId items after `_sbOperationId` is resolved rather than discarding them (correct but more complex — requires a "pending requeue" list and a trigger after `sbGetOperationId` sets `_sbOperationId`).
3. Guard `queueWrite` itself: if `_sbOperationId` is null, hold in a separate "pre-auth queue" that is replayed once `_sbOperationId` is set.

Option 1 is a 2-line fix that should be done immediately. Options 2/3 are design-first.

---

### OI-0085
**Source:** Claude observation — b20260329.1630 (M4.5 audit)
**Area:** Supabase write path — `recalcNpkValues()` bulk mutation
**Severity:** Debt
**Status:** ⚪ Open
**Found:** b20260329.1630

`recalcNpkValues()` (~Settings) iterates past events, updates `ev.npkValue`, then calls `save()` — no per-row `queueWrite`. Bulk NPK price recalculations only update localStorage; Supabase events retain stale `npk_value`. Low-frequency operation (triggered manually from Settings when NPK prices change).

**Fix:** After updating each event in the loop, call `queueWrite('events', _sbToSnake({...ev, operationId: _sbOperationId}))`. Can be combined with any future Settings or event edit session.

---

### OI-0084
**Source:** Claude observation — b20260329.1630 (M4.5 audit)
**Area:** Supabase write path — `importEventsFile()` historical import
**Severity:** Debt
**Status:** ⚪ Open
**Found:** b20260329.1630

`importEventsFile()` pushes new pastures (no `id` field), new groups, and new events directly into `S` arrays then calls `save()`. No `queueWrite` calls anywhere in the function. Historical imports do not reach Supabase.

**Three insertion points needed:**
1. New pastures (L~11629): call `generatePastureId()` before push, then `queueWrite('pastures', _pastureRow(loc, _sbOperationId))` after push.
2. New groups (L~11645): call `queueWrite('animal_groups', _sbToSnake({...grp, operationId: _sbOperationId}))` after push.
3. Events loop (L~11698): call `queueEventWrite(ev)` after `S.events.push(...)`.

Low priority — one-time import path. Fix alongside any historical import session.

---

### OI-0083
**Source:** Claude observation — b20260328.2324 (Supabase assembly audit)
**Area:** Supabase M4 assembly — `ev.totals` not rebuilt on load
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260328.2324
**Closed:** b20260328.2324

`ev.totals` is a computed JS object never stored in Supabase. All closed events loaded from Supabase had `ev.totals === undefined`, producing blank/zero values in the events log detail line (cost, pasture%), pasture screen NPK totals, reports screen, and CSV export — without any error thrown.

**Fix:** Added a pass in `loadFromSupabase()` after all migrations complete: `S.events.forEach(ev => { if (ev.status==='closed' && !ev.totals) recalcEventTotals(ev); })`. Try/catch per event so one bad event doesn't abort the load.

---

### OI-0082
**Source:** Claude observation — b20260328.2324 (Supabase assembly audit)
**Area:** Supabase M4 assembly + write path — pasture `recoveryMinDays`/`recoveryMaxDays`
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260328.2324
**Closed:** b20260328.2324

`pastures` table uses `min_days`/`max_days`; `_sbToCamel` produces `minDays`/`maxDays`. App reads `p.recoveryMinDays`/`p.recoveryMaxDays` in 6 places. Recovery windows on the pasture screen and expected graze dates were always showing the settings default, never the per-paddock value.

Write-path also broken: `_sbToSnake({...p})` converted `recoveryMinDays` → `recovery_min_days` and `locationType` → `location_type` — neither column exists in the `pastures` table (columns are `min_days`, `max_days`, `type`). Any pasture save would have sent PostgREST unknown-column fields.

**Fix (read):** Added `p.recoveryMinDays = p.minDays ?? null` aliases in flat pasture assembly.
**Fix (write):** New `_pastureRow(p, opId)` helper writes the exact schema column names. All three `queueWrite('pastures',...)` call sites updated.

---

### OI-0081
**Source:** Claude observation — b20260328.2324 (Supabase assembly audit)
**Area:** Supabase M4 assembly — `ev.pasture` alias missing
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260328.2324
**Closed:** b20260328.2324

`pasture_name` → `pastureName` via `_sbToCamel`. App uses `ev.pasture` (not `ev.pastureName`) in ~20 render paths: event list display, location cards home screen, manure batch summary, CSV export, wizard paddock filter, event-rename propagation. All were producing blank/undefined for Supabase-loaded events.

**Fix:** Added `if (!ev.pasture && ev.pastureName) ev.pasture = ev.pastureName;` in `assembleEvents()`.

---

### OI-0080
**Source:** Claude observation — b20260328.2324 (Supabase assembly audit)
**Area:** Supabase M4 assembly — sub-move field aliases missing
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260328.2324
**Closed:** b20260328.2324

`assembleEvents()` applied `_sbToCamel(sm)` to sub-move rows but added no field aliases. Five column-name mismatches made all sub-move data invisible to every render and calc function:

| Supabase → camelCase | App reads | Broken paths |
|---|---|---|
| `date_in` → `dateIn` | `sm.date` | Sub-move list display, close sheet, duration calc |
| `time_in` → `timeIn` | `sm.time` | Duration calc, time display |
| `pasture_name` → `pastureName` | `sm.locationName` | All sub-move name display, paddock matching |
| `recovery_days_min` → `recoveryDaysMin` | `sm.recoveryMinDays` | Recovery window after sub-move close |
| `recovery_days_max` → `recoveryDaysMax` | `sm.recoveryMaxDays` | Recovery window after sub-move close |

**Fix:** Five `if (smC.x == null) smC.x = smC.y ?? null` aliases added in the sub-move assembly block inside `assembleEvents()`.

---

### OI-0079
**Source:** User report — b20260328.2258
**Area:** Supabase M4 assembly — Event Edit sheet data population
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260328.2258
**Closed:** b20260328.2258

Event Edit sheet showed blank fields for head count, average weight, pre/post graze heights, forage cover, and recovery min/max on all events loaded from Supabase.

**Root cause:** The `events` Supabase table has a minimal schema — `head`, `wt`, `heightIn`, `heightOut`, `forageCoverIn/Out`, `recoveryMinDays/MaxDays` are not stored on the event row. They live in child tables (`event_group_memberships` for head/wt, `paddock_observations` for heights/cover/recovery). `assembleEvents()` called `_sbToCamel(r)` on the event row only, leaving all these fields undefined.

**Fix 1 — `assembleEvents()`:** Derives missing fields after assembling child arrays:
- `ev.head` / `ev.wt` — summed/averaged from `ev.groups[].headSnapshot` / `weightSnapshot` (active groups only).
- `ev.heightIn`, `ev.forageCoverIn` — from `S.paddockObservations` where `sourceId === ev.id` and `source === 'event_open'`.
- `ev.heightOut`, `ev.forageCoverOut`, `ev.recoveryMinDays`, `ev.recoveryMaxDays` — from `S.paddockObservations` where `source === 'event_close'`.

**Fix 2 — `queueEventWrite()`:** Group membership rows were being written with `headSnapshot: g.head` but assembled group objects use `g.headSnapshot`/`g.weightSnapshot`. Fixed to `g.headSnapshot ?? g.head ?? ev.head` so all three cases are covered: Supabase-assembled groups, legacy localStorage groups, and newly created events.

---

### OI-0075
**Source:** Claude observation — b20260328.1140
**Area:** Supabase M4 — assembly functions
**Severity:** Debt
**Status:** ✅ Closed
**Found:** b20260328.1140
**Closed:** b20260328.2204

Two bugs found and fixed during live verification:

**Bug 1 — feedEntries shape mismatch (b20260328.2200):** `assembleEvents` was putting flat `event_feed_deliveries` rows directly into `ev.feedEntries[]`. Every render function reads `fe.lines[]`. Fixed: rows are now grouped by date, reconstructing `{id, date, lines:[{batchId, qty}]}`. Sub-move feed deliveries handled separately per `sub_move_id`. `ev.locationType` now derived from `S.pastures` lookup. Paddock entries get `locationType` fallback.

**Bug 2 — calvingRecords always empty (b20260328.2204):** `assembleAnimals` set `calvingRecords = []` as a hardcoded empty array. Data was correctly in `animal_health_events` type=calving but never read back out. Fixed: health events now split by type — calving events mapped to `calvingRecords[]` with `{date, calfId, sireTag, stillbirth}` shape.

---

### OI-0073
**Source:** Claude observation — b20260328.0140
**Area:** Dev tooling — JS syntax check process
**Severity:** Debt
**Status:** ⚪ Open
**Found:** b20260328.0140
**Closed:** —

The app HTML contains two `<script>` blocks: the main app script (~L1453–L15142) and a service worker registration block (~L15143–L15800). The current `node --check` syntax verification step extracts only the first `<script>…</script>` match, so the service worker registration block is never syntax-checked.

In practice the SW block is short and stable, but the gap in coverage is a latent risk — a stale extraction regex could silently skip a broken block on a future session.

**Proposed fix:** Update the syntax check snippet in `deploy.py` (or the session-start check pattern) to extract and check both script blocks independently. A simple approach: use `re.findall(r'<script>(.*?)</script>', html, re.DOTALL)` and run `node --check` on each block in sequence. Flag if either fails.

---

### OI-0072
**Source:** Claude observation — b20260326.0859
**Area:** Sub-move sheet (`saveSubMove()` ~L9804, form HTML ~L14000)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260326.0859
**Closed:** b20260329.1816

`sm-time` label changed from "optional" to required (no qualifier). `sm-time-out` label changed to "if returned". `saveSubMove()` add-mode now blocks save with alert + field focus if `sm-time` is empty. Edit mode exempt.

---

### OI-0071
**Source:** Claude observation — b20260326.0757
**Area:** Feed Screen / Batch Inventory (`S.batches[]`, `renderBatchListS()`)
**Severity:** Bug
**Status:** 🔴 Open
**Found:** b20260326.0757
**Closed:** —

Batch `remaining` values are not trustworthy when a sync collision has occurred. The `remaining` field is decremented live at feed-entry-save time (`b.remaining -= l.qty`), but if a sync later overwrites the event and drops the `feedEntries[]` that caused those decrements, `remaining` stays at the decremented value — it is never restored. The inverse also occurs: if the "winning" device never applied those decrements, `remaining` may be higher than reality.

Observed in backup `gthy-backup-2026-03-26-0708.json`:
- Oak Field Barn: `remaining=45` (same as `qty=45`) but 6 bales exist in surviving feedEntries
- Tarped: `remaining=106` with `qty=40` — physically impossible; likely from a prior manual adjustment followed by a `qty` edit that didn't proportionally update `remaining`
- Peanut Hay: `remaining=17 = qty=17` but 1 bale survives in a feed entry

**Proposed fix:** Add a "Recalculate from feed entries" option to the batch management sheet. Traverses all `S.events[].feedEntries[]` and `S.events[].subMoves[].feedEntries[]`, sums usage per `batchId`, then sets `remaining = qty - consumed`. Should warn the user that manual reconcile adjustments will be overwritten.

---

### OI-0070
**Source:** User report + Claude observation — b20260326.0757
**Area:** Drive Sync (`mergeData()` → `ma()`, ~L2157)
**Severity:** Bug
**Status:** 🔴 Open
**Found:** b20260326.0757
**Closed:** —

Data loss event on 2026-03-26: adding a sub-paddock (K-2) to the K-4 event on desktop bumped `ev.updatedAt` on the desktop copy. When the merge ran, desktop's newer-timestamped K-4 won wholesale — silently discarding mobile's `feedEntries[]` and the closed state of the K-5 sub-move (`durationHours`, `dateOut`). Additionally, ~20 feedback items entered on 2026-03-25 were lost because mobile's S state was overwritten before those items could be written to Drive.

**Partial fix applied b20260326.0757:** `_mergeEventArrays()` now union-merges `feedEntries` and `subMoves` from the losing side regardless of which side wins the `updatedAt` comparison. Closed sub-move state (`durationHours > 0`) is preferred over open state (`0`) when IDs match.

**Remaining risk:** The batch `remaining` field is still a scalar that resolves to the "local-wins" device's value when neither batch record has `updatedAt`. If the winning device's feed entries are missing, `remaining` reflects those missing entries' decrements — see OI-0071. Full mitigation requires either ETag-based Drive locking (true atomicity) or deriving `remaining` from the feedEntries ledger at runtime rather than storing it as a mutable scalar.

---

### OI-0069
**Source:** Claude observation + User report — b20260325.0037
**Area:** Drive Sync (`importDataJSON` ~L2265, `driveSync` ~L1958, new `drivePushLocal`)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260325.0037
**Closed:** b20260325.0037

Three drive sync robustness fixes applied together:

**A — Silent import Drive write failure (root cause of this session's data loss).** `importDataJSON` wrote to Drive in a `.catch()` that only updated the sync status dot for a few seconds — easy to miss, especially while the success toast was also showing. If the PWA token had expired, Drive never received the restored data. Desktop then synced against the stale Drive state (48 items) and wrote 48 back, making both devices wrong.

**Fix A:** Import Drive write failure now shows a persistent red error card at the bottom of Settings. Card does not auto-dismiss. Contains a **"Retry Drive push"** button wired to the new `drivePushLocal()` function. Success path also shows an explicit status message that auto-dismisses after 5s.

**B — No force-push mechanism.** When a device has local truth and Drive is stale, there was no way to explicitly push local state to Drive without relying on the merge cycle.

**Fix B:** New `drivePushLocal()` function. Reads Drive first (so any remote-only data is union-merged in), then writes the merged result back. Called by the import retry button; also callable from console for recovery.

**C — Concurrent-write race in `driveSync()`.** Two devices reading the same stale Drive state both merge and write; whichever writes second overwrites the first device's new data. With the 5-minute poll added in b20260325.0013, this race is more likely — both devices poll around the same interval.

**Fix C:** `driveSync()` re-reads Drive immediately before the final write. If the remote changed between the initial read and the write (i.e. another device wrote in the meantime), it merges again with the fresh data before writing. Shrinks the race window from minutes to ~100ms.

**Data recovery procedure:** Import `Mobile_gthy-backup-2026-03-25-2001.json` directly on desktop via Settings → Import. Watch for "Restored & synced to Drive" confirmation. Mobile then taps Sync Now.

---

### OI-0056
**Source:** In-app feedback — id:1774374875449 (Tim)
**Area:** Animals Screen (`renderAnimalsScreen()`, ~L10830)
**Severity:** 🚧 Roadblock
**Status:** ✅ Closed
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** b20260328.0157

📋 **Todo** button (amber) added to each animal row. Calls `openAnimalTodoSheet(animalId)` → `openTodoSheet(null, false, animalId)`, pre-selecting that animal in the existing `td-animal` dropdown. Open-todo count badge (amber, 📋 N) added to name line when the animal has any non-closed todos. Data model was already in place — this was a missing entry point.

---

### OI-0057
**Source:** In-app feedback — id:1774396779567 (Tim) + Claude observation — b20260325.0013
**Area:** Drive Sync (`mergeData()`, ~L2116; init block, ~L13394)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260325.0013
**Closed:** b20260325.0013

"Feedback is not syncing properly between desktop and mobile. I have 56 items in my mobile data and only 45 on desktop." Backup diff confirmed 11 feedback items, 2 todos, 1 event, and 2 treatment types on mobile that were absent from desktop.

**Root cause A — No periodic sync poll.** `driveSync()` was only triggered by: app load, `visibilitychange` → visible, and the post-save debounce. A desktop tab left open all day without tab-switching never fired `visibilitychange` and never pulled Drive. Everything added on mobile after ~10:41 AM on March 24th was invisible to desktop all day.

**Root cause B — `treatmentTypes` and `aiBulls` absent from `mergeData()` return.** Both arrays were in `ensureDataArrays()` (so they're initialized) but were never present in the merge return object. Any treatment types or AI bulls created on one device were silently dropped on every sync, regardless of the polling gap.

**Root cause C — `_groupsMigrated` and `_paddocksMigrated` flags absent from `mergeData()` return.** These OR'd boolean migration flags could diverge between devices, causing one-time migrations to re-run on a device where they'd already completed.

**Fixes applied (b20260325.0013):**
- `mergeData()` return: added `treatmentTypes: ma(...)` and `aiBulls: ma(...)` — union-merge by `id`, same pattern as `todos` and `feedback`
- `mergeData()` return: added `_groupsMigrated` and `_paddocksMigrated` — OR'd booleans, same pattern as `_herdMigrated`
- Init block: added `setInterval` (5 min / 300,000ms) — fires `driveSync()` when token is valid; ensures open tabs stay current with Drive even without visibility events

**Data recovery note:** Deploy b20260325.0013 to both devices. Load mobile first (it has the complete data — 59 feedback, 2 treatment types, 8 events, 2 todos). It will push to Drive. Desktop will pull on next sync cycle (≤5 min) and merge in all missing items cleanly.

---

### OI-0058
**Source:** In-app feedback — id:1774356724442
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L14205)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** b20260330.2312

"Sub moves that are pasture (versus the primary bale grazing paddock) should be green on the rotation calendar." Currently all sub-move blocks use the same colour as the parent event (hay/tan). A sub-move on a grazing paddock should use the green pasture colour to correctly represent where the animals actually are and what the fertility picture looks like.

**Fix:** In `renderRotationCalendar()`, when rendering a sub-move block, check `sm.noPasture`. If false (or undefined for legacy records), render it with the pasture/green style. If true, render with the hay/tan style.

---

### OI-0059
**Source:** In-app feedback — id:1774356942281
**Area:** Architecture / Calculations — cross-cutting
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** —

"Audit all calculation related functions for proper logic etc. Document all calculations occurring in the application in the architecture document in both equation form as well as narrative so that the reader can understand the context. Will be used to verify calculations are dialed in as they are key to the fertility ledger being useful and accurate."

**Deferred:** Schedule a dedicated calculation audit session. Output: a Calculations section in ARCHITECTURE.md covering DMI inference, NPK attribution, AUD computation, pasture % split, sub-move time-weighting, and per-paddock grass DMI attribution — each with equation + narrative.

---

### OI-0060
**Source:** In-app feedback — id:1774361239173 (Tim)
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L14205)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** b20260329.1708

Active-event cells now render with a white ring (`box-shadow: 0 0 0 2px white, 0 0 0 3.5px ${color}`), a 2s opacity pulse animation (`cal-active` keyframes in CSS), and a `NOW` badge when the cell spans ≥ 3 weeks. Correctly uses `isCurrentlyActive` (window reaches today) rather than `isOpen` so clipped prior-paddock windows on sub-move events are excluded. "Active now" swatch added to legend. Hover tooltip appends "· ACTIVE NOW". Root cause: previous `outline: 2px solid ${color}` was same colour as cell background — invisible.

---

### OI-0061
**Source:** In-app feedback — id:1774375050876 (Tim) + id:1774375067914 (Tim) + id:1774376187163 (Tim)
**Area:** Animal Edit Sheet (`openAnimalEdit`, ~L7579) + Treatment Sheet (`openAnimalEventSheet`, ~L6342)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** —

Three related treatment UX requests, batched together:

**A — Treatment accessible from Edit Animal sheet:** "In edit animal allow for treatment." Launching a treatment entry currently requires going to the animal's action buttons on the list. Should also be accessible from inside the edit sheet.

**B — Multiple treatments at once:** "Allow multiple treatment selection at one time." When treating an animal (e.g. castration + worming on the same day), the user should be able to select and log multiple treatment types in a single health event entry.

**C — Treatment type auto-populates fields:** "Treatment type should populate other treatment fields when appropriate." Selecting a treatment type from the type list should pre-fill relevant fields (dose, unit, withdrawal period) based on the selected treatment type's defaults — requires adding optional default fields to the `treatmentTypes` schema.

**Deferred:** Design session needed for the multi-treatment model (single health event with multiple treatment refs vs multiple events).

---

### OI-0062
**Source:** In-app feedback — id:1774377202625 (Tim)
**Area:** To-Do System (`openTodoSheet`, ~L2921)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** b20260328.0157

Root cause: `openTodoSheet` called `getActive()` → `getAnyActiveEvent()` = `S.events.find(e=>e.status==='open')` — the first open event in the array, regardless of user context. Fix: removed the `getActive()` call. Paddock is now blank by default for all new todos except when launched from the Move Wizard with `fromWiz && wizPaddockForTodo` set.

---

### OI-0063
**Source:** In-app feedback — id:1774375315950 (Tim)
**Area:** Animals Screen (`renderAnimalsScreen()`, ~L10830)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** b20260402.1017

"When selecting animal from list the add to group question jumps the list ahead." `toggleAnimalScreenSelect()` called `renderAnimalsScreen()` which re-rendered the entire list, causing scroll position to jump.

**Fixed:** Option (c) — `toggleAnimalScreenSelect()` now saves `.content` `scrollTop` before `renderAnimalsScreen()` and restores it after re-render.

---

### OI-0064
**Source:** In-app feedback — id:1774381838610 (Tim)
**Area:** Quick Feed Sheet (`openQuickFeedSheet`, ~L3222)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** —

"Add required DMI to feed dialog with progress bar." When entering feed on the Quick Feed sheet, the user should be able to see the event's total DMI target and a progress bar showing how much of that has been covered by feed entries already logged for the current day. Helps the farmer know if they've fed enough.

**Fix:** In `qfSelectEvent()` / the step-2 form render, call `getGroupTotals()` across all active groups in the event to compute total daily DMI target. Show a compact `DMI target: X lbs/day` line and a progress bar filled by `feedEntriesToday / dmiTarget`. Use the same amber progress style as the Feed screen dashboard tile.

---

### OI-0065
**Source:** In-app feedback — id:1774385774185 (Tim)
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L11971)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** —

"Render pasture status on rotation view with green gradient showing survey status of pasture. Single vertical for each inactive pasture with red bar indicating current min max." 

Inactive paddocks (not currently grazed) should be shown as a vertical status bar to the right of the calendar's "today" line. Height of the green fill = current survey rating (% of estimated full growth). A red band = the min–max grazing window. This gives the farmer a full picture — historical occupancy on the left, current forage availability on the right — in one view.

**Related to OI-0066** — the "today" vertical line is a prerequisite.

**Deferred:** Design session needed. Touches calendar layout, pasture survey data (`S.surveys`), and the min–max recovery window computation.

---

### OI-0066
**Source:** In-app feedback — id:1774386129481 (Tim)
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L11971)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** —

"Rotation View — after historic and active paddocks render a vertical line representing 'today' on right side of line is current inactive pasture status bars."

A vertical "today" line should divide the calendar into: left = historical record, right = future / current status. Inactive paddocks' status bars (OI-0065) appear to the right of this line.

**Prerequisite for OI-0065.** Together these two items form a full rotation dashboard.

---

### OI-0067
**Source:** In-app feedback — id:1774386058617 (Tim)
**Area:** Feedback Tab (`renderFeedbackTab()`, ~L6222; `openFeedbackSheet()`, `saveFeedbackItem()`)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260325.0013 (feedback dated 2026-03-24, v1.2)
**Closed:** —

"Feedback — add area field so user can refer to specific functions and they can be grouped for development. Allow editing of feedback with time stamp for edits."

Two sub-features:
**A — Area field:** Free-text or dropdown on the feedback submission form. Stored as `f.area`. Used as a grouping/filter dimension in `renderFeedbackList()` and `generateBrief()`.
**B — Editable feedback:** Allow the user to edit an existing feedback item's note or area after submission. Edit saves an `f.editedAt` timestamp.

---

### OI-0068
**Source:** In-app feedback — id:1774356942281 (idea — see OI-0059) + id:1774351616357 (idea — "Look at feedback architecture to anticipate multiple instances of the app in the future...")
**Area:** Feedback System — future architecture
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260325.0013
**Closed:** —

"Look at feedback architecture to anticipate multiple instances of the app in the future. Store feedback in central repository so that gathering and response can be automated in the future." Long-horizon idea — no immediate action. Logged for awareness when designing any future multi-tenancy or server-side infrastructure.

**Deferred:** No action until multi-instance architecture is on the roadmap.

---

### OI-0041
**Source:** In-app feedback — id:1774290156334
**Area:** Home Screen / Quick Feed Sheet (`closeQuickFeedSheet`, ~L3219)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.0910 (triage)
**Closed:** b20260324.0955

Quick Feed sheet opened from home screen (via Feed button on group card or location card) did not return to home on cancel. The save path (`saveQuickFeed`) already snapshotted `qfFromHome` before calling `closeQuickFeedSheet()` and navigated home correctly. The cancel path — both the Cancel button and backdrop tap — called `closeQuickFeedSheet()` directly, which reset `qfFromHome=false` before the nav check could run, always leaving the user on the Feed screen.

**Fix:** `closeQuickFeedSheet()` now snapshots `_returnHome = qfFromHome` before resetting the flag, then calls `nav('home',...)` when true. The closed-event guard path also benefits.

---

### OI-0040
**Source:** In-app feedback — id:1774290092842 + id:1774290156334 + id:1774290232282
**Area:** Home Screen — `renderLocationCard()` + `renderGroupCard()` (~L2696, ~L2800)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.0910 (triage)
**Closed:** b20260324.0955

Home screen lacked a consistent semantic split between the two views. Key problems:
- Feed button appeared per-group in location view (should be event-level)
- Move button on individual groups in location view launched the full close-event wizard (should open Event Edit for single-group departure)
- Group view contained Feed, Sub-move, and "Edit event" buttons — actions that belong to the event, not the group
- No "Move All" option at location card level

**Fix — Location view (`renderLocationCard`):**
- Per-group rows: **Move** (opens Event Edit) + **⚖ Weights** only. Feed and Split removed.
- Card-level: **Feed** · **Move All** · **Sub-move** · **Edit event**

**Fix — Group view (`renderGroupCard`):**
- Buttons: **Move** (placed → Event Edit; unplaced → Place wizard) · **Split** · **Weights** · **Edit** (opens `openEditGroupSheet`)
- Removed: Feed, Sub-move, Edit event

**New helpers added:**
- `goFeedEvent(evId)` (~L3434) — event-level feed bridge; finds first active group, delegates to `goFeedGroup`
- `moveAllGroupsInEvent(evId)` (~L2930) — collects all active group IDs, sets `wizGroupIds`, launches Move Wizard

---

### OI-0035
**Source:** Claude observation — b20260324.0910
**Area:** Drive Sync — `mergeData()` union-merge identity keys (~L2110)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.0910
**Closed:** b20260324.0910

Both union-merge blocks introduced in b20260324.0235 (equal-timestamp) and b20260324.0859 (no-timestamp) used `i.id` as the identity key for **all** sub-arrays including `groups` and `paddocks`. These arrays do not have an `id` field — `groups` uses `groupId` and `paddocks` uses `pastureId`. Because `i.id` was `undefined` for every element, `seen` = `{undefined}` and `seen.has(undefined)` returned `true` for every remote item — causing all remote `groups` and `paddocks` entries to be silently filtered out. The union-merge appeared to run but produced no additions.

**Confirmed by screenshots:** After deploying b20260324.0859 and restoring the merged backup, Desktop showed "K - 4, K - 5" correctly but Mobile still showed "K - 4" only after syncing — the K-5 paddock was being discarded on every merge despite the fix code running.

**Fix:** Both blocks now use a per-array identity helper: `arrKey==='groups' ? i.groupId : arrKey==='paddocks' ? i.pastureId : i.id`. The `seen` set filters out null/undefined values. Remote items are only added when their identity key is non-null and not already in the seen set.

---

### OI-0034
**Source:** Claude observation — b20260324.0910
**Area:** Drive Sync — `mergeData()` no-timestamp fallback (~L2128)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.0910
**Closed:** b20260324.0910

The `mergeData()` no-timestamp fallback (reached when **neither** record has `updatedAt`) previously compared `feedEntries.length` and `subMoves.length` and replaced the entire record if the remote had more entries. `paddocks` was never checked — so if local had fewer paddocks than remote but equal subMoves and feedEntries counts, local won silently and the remote paddock was dropped.

**Confirmed by live backup diff:** After restoring the merged backup in b20260324.0235, Mobile synced and the K-5 paddock (added to event 1774197894299 on Desktop on March 21) was dropped again. Both devices had the same subMove count (1 each, same ID), so the length check never fired — local (Mobile, K-4 only) won.

**Fix:** Replaced the whole-record length-comparison fallback with the same union-merge logic used by the equal-timestamp path: union-merges `groups`, `paddocks`, `subMoves`, and `feedEntries` by `id`, taking all items from either side. This is now the default for any record without `updatedAt` — guarantees no additions are lost regardless of which device is local.

---

### OI-0033
**Source:** Claude observation — b20260324.0910
**Area:** Drive Sync — `mergeData()` (~L2098)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.0910
**Closed:** b20260324.0910

`mergeData()` used a strict greater-than comparison for `updatedAt` timestamps: when two records had **equal** timestamps the remote changes were silently discarded (local always won). This is the "silent data loss" vector for concurrent edits made within the same second or for records where the stamp wasn't bumped before save.

**Fix:** When both records have identical `updatedAt` values the merge now union-merges their `groups`, `paddocks`, and `subMoves` sub-arrays (new IDs from the remote side are appended; existing IDs kept from local). Scalar fields still default to local. This acts as a safety net even after all timestamp-bump fixes are in place.

---

### OI-0032
**Source:** Claude observation — b20260324.0910
**Area:** Drive Sync — event and animal mutation functions (14 sites)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.0910
**Closed:** b20260324.0910

`mergeData()` resolves conflicts by comparing `ev.updatedAt` / `a.updatedAt`. Fourteen mutation functions were saving changes to events or animals **without bumping these timestamps**, making the merge unable to determine which device had the newer version — causing silent data loss on sync.

**Root cause confirmed by backup diff:** Mac and Mobile diverged on 3 events and 1 animal after their last successful sync. The differing events had identical `updatedAt` on both devices despite different content — Mac had made further edits (added Culls group, changed head/wt snapshot, added K-5 paddock) without bumping the timestamp. Mobile's stale version silently won every merge.

**Sites fixed (14 new stamps added):**

| Function | What changed |
|---|---|
| `wizCloseEvent` | `ae.updatedAt` before `save()` |
| `saveSubMove` | `ev.updatedAt` before `save()` |
| `saveSmClose` | `ev.updatedAt` before `save()` |
| `deleteSubMove` | `ev.updatedAt` before `save()` |
| `saveEventEdit` | `ev.updatedAt` before `save()` |
| `applyEeGroupMoveActions` | `targetEv.updatedAt` when group pushed to destination event |
| `saveAnimalEdit` (edit path) | `a.updatedAt` before `save()` |
| `saveAnimalWeight` | `a.updatedAt` before `save()` |
| Health event save | `a.updatedAt` before `save()` |
| `deleteAnimalEvent` | `a.updatedAt` before `save()` |
| `saveSplit` loop 1 (split-from note) | `a.updatedAt` inside `forEach` |
| `saveSplit` loop 2 (moved-to note) | `a.updatedAt` inside `forEach` |
| `logGroupChange` helper (`saveAnimalMove`) | `a.updatedAt` inside helper — covers both existing and new-group move paths |
| `saveCalving` | `dam.updatedAt` before `save()` |

**Pre-existing stamps (untouched — already correct):** `saveQuickFeed`, `addEeFeedEntry`, `deleteEeFeedEntry`, `saveSplit` srcAe/destAe event snapshots.

**Restore procedure:** Deploy `b20260324.0910` to both devices first, then restore `gthy-merged-2026-03-24-2210.json` on one device. It will push to Drive. Open the other device — it will sync cleanly with the corrected merge logic.

---
**Source:** Claude observation — b20260323.2354
**Area:** Sub-Move System (`openSubMoveSheet`, `saveSubMove`, ~L9030)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260323.2354
**Closed:** b20260324.0054

Active sub-moves (durationHours: 0) can now be closed from the sub-move sheet. Six new functions added: `renderSmExistingList(ev)`, `openSmCloseForm(smId)`, `cancelSmClose()`, `calcSmCloseDuration()`, `saveSmClose()`, `deleteSubMove(evId, smId)`. New `sm.dateOut` field added for multi-day return tracking. `openSubMoveSheet` now calls `renderSmExistingList` and `cancelSmClose` on open. Sheet HTML restructured with "Recorded sub-moves" section at top and inline close form revealed per active sub-move. Full lifecycle documented in ARCHITECTURE Critical Behavioral Notes.

---

### OI-0031
**Source:** Claude observation — b20260323.2354
**Area:** ARCHITECTURE.md — systematic drift
**Severity:** Debt
**Status:** ✅ Closed
**Found:** b20260323.2354
**Closed:** b20260324.0112

Full architecture audit completed. All discrepancies resolved in ARCHITECTURE.md b20260324.0112:

**Line ranges recalibrated** — every section from `renderEventsLog` onward was off by 800–1,600 lines due to ~520 lines of accumulated growth. All corrected to grep-verified actuals. File header updated: `~13,872` → `~14,392` lines.

**Screen Map corrected** — `renderEventsLog` ref `~5013` → `~5805`; `renderRotationCalendar` ref `~L11782` → `~L11971`; duplicate warning block removed.

**Data Model expanded** — `S.treatmentTypes` now documents `category` field; `S.testerName` and legacy `S.version` added; `S.settings` expanded from a one-liner into a full 14-field sub-table.

**Key Utility Functions corrected** — `closeGroup()` (does not exist) replaced with `startMoveGroup()` and three undocumented companion functions: `setMoveGroupExisting()`, `setMoveGroupWizard()`, `cancelGroupMove()`; treatment system functions added: `editTreatmentType()`, `cancelEditTreatment()`, `_mtResetForm()`.

**Two new Critical Behavioral Notes added** — Treatment Type Categories (TREATMENT_CATEGORIES constant, `_editingTreatmentId` state machine, dual list renderer gotcha); Multi-Group Event Departure Flow (`_moveAction` state machine, explicit `closeGroup()` tombstone warning).

---

### OI-0016
**Source:** In-app feedback — id:1774259652890
**Area:** Animals Screen (`renderAnimalsScreen()`, ~L9626)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260323.2336

A delete (✕) button was appearing on each row in the main animal list. Removed the button and its `onclick="deleteAnimalFromScreen()"` call from the row template in `renderAnimalsScreen()`. Cull action remains accessible only from within the animal edit sheet (`#ae-cull-section`).

---

### OI-0017
**Source:** In-app feedback — id:1774259757925
**Area:** Treatments Sheet / Animal Health Events (~L4612 JS, ~L13865 HTML)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260323.2354

**A — Centering:** Not a regression — the `manage-treatments-wrap` uses the standard `.sheet-wrap` / `.sheet` classes which have the correct desktop centering rule (`calc(220px + ((100vw - 220px) / 2))`). Structure is identical to `manage-classes-wrap` which centers correctly.

**B — Existing treatments editable:** Implemented. Each active treatment row now has an Edit button. Tapping populates the form with the existing name and category, changes the button label to "Save changes", and shows a Cancel button. `_editingTreatmentId` tracks edit state. `editTreatmentType(id)`, `cancelEditTreatment()`, `_mtResetForm()` added. Duplicate name check in edit mode excludes the item being edited.

**C — Treatment categories:** Implemented. `TREATMENT_CATEGORIES` constant defines six categories: Vaccine, Parasite Control, Antibiotic, Wound/Surgery, Nutritional, Other. A category `<select>` added to the sheet form alongside the name field. Category stored as `t.category: string | null` on each treatment type. Category badge shown on each row in the manage list.

---

### OI-0018
**Source:** In-app feedback — id:1774259962696
**Area:** Animals Screen / Animal Edit Sheet (`renderAnimalsScreen()`, `closeAnimalEdit()`)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260323.2336

**A — Fixed:** `closeAnimalEdit()` now calls `renderAnimalsScreen()` when `curScreen==='animals'`, so changes in the edit sheet are immediately reflected in the list on close. The save path (`saveAnimalEdit` already called `renderAnimalsScreen()`) now also runs it on close-without-save.

**B — Retag delay:** Not reproduced in code review. The save path calls `save()` + `renderAnimalsScreen()` sequentially with no async gaps. If the delay resurfaces, profile the `save()` call on a large dataset.

---

### OI-0019
**Source:** In-app feedback — id:1774260052866
**Area:** Animals Screen (`renderAnimalsScreen()`, ~L9626)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260324.1030

Animals screen filter area rebuilt.

**A — Compact chip pills:** `<select>` dropdown replaced with `.agc-chips` container of inline-flex pill chips (`.agc-chip`). Chips render All + one per group (with color dot) + Unassigned (when relevant). Active chip highlighted green. Chips wrap horizontally — no vertical stacking. The hidden `<select>` is kept for state compatibility with `filterAnimalsByGroup()`.

**B — Search below chips:** Search bar moved below the chip row. "Show culled" + "+ Add animal" controls sit in a compact row below search.

**C — Sticky header:** The entire filter area (chips + search + controls) is wrapped in `.agc-wrap { position:sticky; top:0; z-index:20; background:var(--bg) }` so it stays anchored while the animal list scrolls below.

---

### OI-0020
**Source:** In-app feedback — id:1774260146466
**Area:** Animals Screen (`renderAnimalsScreen()`)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260323.2336

The toggle-off logic already existed in `filterAnimalsByGroup()` but was not visually communicated. Fixed by updating the active group chip in `renderGroupsList()` to show a `✕ clear filter` badge (green, cursor:pointer) when that group is the active filter. Tapping the chip again deselects it and restores the full list.

---

### OI-0021
**Source:** In-app feedback — id:1774260349182
**Area:** Animal Move / Event Totals (`calcEventTotalsWithSubMoves`, `recalcEventTotals`, `_memberWeightedDays`)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.2207
**Closed:** b20260329.2336

When an animal was moved or culled mid-event, AUD and NPK totals used the snapshot `ae.head × days` regardless of actual membership windows. New `_memberWeightedDays(ae, outDate)` helper sums each membership row's overlap with the event window, clamping to `[ae.dateIn, outDate]`. `dateJoined null` = present from event start. Fallback to `ae.head × days` when no membership data or multi-group event (see OI-0105). Both `calcEventTotalsWithSubMoves` (close path) and `recalcEventTotals` (edit-closed-event path) use `effectiveAUD` for NPK.

---

### OI-0022
**Source:** In-app feedback — id:1774260409016
**Area:** Animal Health Events / BCS Survey (`openAnimalEventSheet`, ~L6342)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260402.0940

Added "Likely cull" checkbox (`#ae-evt-bcs-likely-cull`) to the BCS section of the animal event sheet. Checkbox resets on open, populates from existing `likelyCull` on edit, saves as `evt.likelyCull` boolean. Red "likely cull" badge shown on BCS events in health event history list.

**Note:** `animal_health_events` table needs `ALTER TABLE ADD COLUMN likely_cull boolean DEFAULT false` when health events Supabase write path is wired up. Currently health events save to localStorage only (pre-existing gap). Filterable "Likely cull" list in Reports deferred — revisit when reporting layer is built.

---

### OI-0023
**Source:** In-app feedback — id:1774260536657
**Area:** Pastures Screen (`renderPastures()`, ~L5104)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** —

No way to view the grazing history for a specific pasture/paddock — past events, dates, groups, AUDs, feed applied, survey ratings, and recovery periods. This is directly relevant to the fertility ledger concept: the per-paddock history is the record of fertility transactions for that location.

**Fix:** Add a "View history" action on each pasture card that opens a sheet or navigates to a filtered view of all events (open and closed) for that paddock. Ideally includes: event dates, group(s), AUDs, feed entries, survey ratings pre/post, and recovery period.

**Acceptance criteria:** Tapping "History" on a pasture card shows all historical grazing events for that location, oldest to newest, with key metrics per event.

---

### OI-0024
**Source:** In-app feedback — id:1774260638046
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L11782)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260323.2336

`eventAUDs()` inside `renderRotationCalendar()` returned 0 for open events where `ev.head`/`ev.wt` were not stamped on the event record (group-based events). Fixed: open events now fall back to live group totals via `evGroups(ev)` + `getGroupTotals()` when `ev.head` is missing. Season total AUDs in the right-hand sticky column now populate for open events.

---

### OI-0025
**Source:** In-app feedback — id:1774260688519
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L11782)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260323.2336

Replaced group-color coding with semantic content-based colors: **green (#639922) for pasture grazing events**, **tan (#C4A882) for 100% stored-feed / confinement events**. `grpColor()` helper removed from within `renderRotationCalendar()` and replaced with `evCalColor(ev)`. Legend updated to show "Pasture grazing" / "Hay / stored feed" / "Sub-move" instead of group names.

---

### OI-0026
**Source:** In-app feedback — id:1774260722747
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L11782)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260323.2336

Sub-move locations were never included in `paddockNames` — only main event `ev.paddocks[]` were collected. Fixed in three places: (1) `subMovePaddockNames` now collects all `sm.locationName` values across all events and merges them into `paddockNames`. (2) The week-map builder now creates `windows[]` entries for both main-event paddock spans and sub-move spans, with the main paddock window clipped to end when the first sub-move departs. (3) Sub-move cells render with a dashed top border to visually distinguish them from main-event blocks. Hover tooltip includes `(sub-move)` label.

---

### OI-0027
**Source:** In-app feedback — id:1774260870487
**Area:** Sub-Move System (`saveSubMove`, ~L9257)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.1)
**Closed:** b20260323.2336

Removed the `'\nDuration not set — edit to add hours later.'` branch from the `saveSubMove` success alert. When `hrs === 0`, the alert now simply confirms the location without any warning. The pasture % line only appears when hours were entered, as before.

---

### OI-0028
**Source:** In-app feedback — id:1774271115141
**Area:** Home Screen / Header (`renderHome()` or header HTML, ~L2238)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.2)
**Closed:** b20260324.1030

Mobile header restructured to two-row layout. `.hdr` now uses `flex-direction:column` on mobile — row 1 is full-width title ("Get The Hay Out") + operation name; row 2 is sync indicator, build tag, Field button, and avatar. Desktop overrides back to the original single-row `flex-direction:row` layout via `body.desktop .hdr`. Operation name in `updateHeader()` simplified to show the farm name only — head count and group count removed to reduce character width.

---

### OI-0029
**Source:** In-app feedback — id:1774271246604
**Area:** Events Log (`renderEventsLog()`, ~L6648)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260322.2207 (feedback dated 2026-03-23, v1.2)
**Closed:** b20260329.1751

Sub-moves are now rendered as a teal-threaded visual unit beneath their parent event in the log. Parent row gains an `N sub-moves` teal badge and drops its bottom border; a 2px teal left-rail indented thread shows each sub-move as `⇢ Location · active/returned · date range · duration · feed count`. Sub-moves sorted chronologically. Clicking any row opens `openEventEdit()`. Events without sub-moves render unchanged.

---

### OI-0015
**Source:** Claude observation — b20260322.2021
**Area:** Calving Sheet / Animal Edit Sheet (~L8603 `openCalvingSheet`, ~L12382 sheet HTML)
**Severity:** Polish
**Status:** 🟡 Open
**Found:** b20260322.2021
**Closed:** —

The calving sheet title ("Record calving"), date label ("Calving date"), and calf sex options ("Female (heifer calf)" / "Male (bull/steer calf)") are hardcoded to cattle terminology. The `birthTermForSpecies()` and `youngTermForSpecies()` helpers introduced in b20260322.2021 are already in place but not yet wired to the sheet.

**Fix:** In `openCalvingSheet()`, derive the dam's species from her class, call `birthTermForSpecies()` and `youngTermForSpecies()`, then update the sheet title, date label, and calf sex option text before opening. No data model changes required.

**Affected elements:**
- Sheet title: `<div …>Record calving</div>` → e.g. "Record lambing"
- Date label: `<label>Calving date</label>` → "Lambing date" / "Kidding date" etc.
- Calf sex options: "Female (heifer calf)" → "Female (ewe lamb)" etc.
- `#calving-dam-label` prefix is already dynamic — no change needed there

**Acceptance criteria:** When opening the calving sheet for a sheep dam, the title reads "Record lambing", date field reads "Lambing date", and sex options use lamb terminology. Cattle dams unchanged. Falls back gracefully to "Birth" for unknown species.

---

### OI-0004
**Source:** Claude observation — b20260322.1336
**Area:** Events Screen / Code Organisation (~L3549, ~L5013)
**Severity:** Debt
**Status:** ⚪ Open
**Found:** b20260322.1336
**Closed:** —

`renderEventsLog()` is physically located at ~L5013, roughly 1,400 lines past the `// ─── EVENTS ───` section header at ~L3549. The Batch Adjustment / Reconcile section (~L4796–5011) was inserted between `switchEventsView()` and `renderEventsLog()` at some point, displacing the render function far from its logical home. The JS TOC and ARCHITECTURE.md have been annotated to call this out, but the underlying organisation is confusing for navigation and future editing — a developer searching near the Events header will not find the render function.

**Fix:** Move `renderEventsLog()` (and any helpers it calls that are currently orphaned in that area) up to sit directly after `switchEventsView()` at ~L3796. Verify with `grep -n "renderEventsLog"` before and after to confirm no dangling references.

**Acceptance criteria:** `renderEventsLog()` is within ~50 lines of `switchEventsView()`. TOC and ARCHITECTURE.md line references updated to match. Syntax check passes.

---


### OI-0005
**Source:** Claude observation — b20260322.1930
**Area:** Event Edit / Paddock Feed Attribution
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260322.1930
**Closed:** —

Per-paddock feed and residual tracking. In multi-paddock events (e.g. bale grazing in G1 while also using G2/G3), all `feedEntries[]` currently live at the event level with no paddock attribution. Two sub-features were identified: (A) optional `paddockId` tag on feed entries for reporting which paddock consumed which feed; (B) per-paddock residual % settings for events where animal density differs per paddock. Both require changes to `recalcEventTotals()` and the feed entry UI.

**Deferred:** Flagged during b20260322.1930 paddock lifecycle session. Agreed to leave feed at event level for now and revisit as a dedicated enhancement.

**Acceptance criteria:** Feed entries can optionally be tagged to a paddock. Per-paddock residual % field appears on closed paddock chips. `recalcEventTotals()` apportions DMI by paddock window when tags are present.

---

---

### OI-0006
**Source:** Claude observation — b20260322.1353
**Area:** Field Mode / Home Screen (~renderFieldHome)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.1353
**Closed:** b20260331.2335 (via OI-0128)

`renderFieldHome()` is currently a stub that shows a single "Log Feed" button and a placeholder message. The intended implementation is a large-icon tile grid with per-user configurable modules (feed, pasture survey, move, weight entry). Each tile launches its task handler sheet directly without navigating through the full app.

Three sub-items deferred from the b20260322.1353 field-mode foundation session:

**A — Tile grid UI:** Full-width, 2-column grid of large tappable tiles. Each tile has an icon, a label, and an `onclick` that calls the relevant sheet open function. Touch targets sized for gloved hands / outdoor use (min 80px height).

**B — Per-user module selection:** "Configure field home" sheet accessible from the field home screen or user profile in Settings. User can toggle which modules appear. Config stored in `user.fieldModules[]` (array of module keys, e.g. `['feed','survey','move']`).

**C — Individual task handler sheets:** Each field-mode module may need a simplified version of its sheet (full label text, larger tap targets, no secondary actions). Scope TBD per module — some existing sheets may be usable as-is.

**Fix:** Dedicate a session to field home. Design the tile grid, implement module selection, wire at least Feed and Survey as the first two live tiles. Stub remaining tiles.

**Acceptance criteria:** `renderFieldHome()` renders a configurable tile grid. At minimum Feed and Pasture Survey tiles are functional. Per-user module list persists across sessions. Entering field mode on mobile lands on this screen.

---

### OI-0014
**Source:** In-app feedback — id:1774204169720 (note: "stage the feed prior to actually moving the group of animals to that location...")
**Area:** Events / Move Wizard / Feed Screen — architectural
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260322.1421 (feedback dated 3/22/2026, v1.1)
**Closed:** —

Request for a "suspended" or "staged" event type. The use case: in bale grazing or 100% stored-feed situations, the farmer physically stages feed (places bales) before moving animals. They want to record the feed at staging time, not at move time. The full flow requested:

1. User creates a "suspended" future event — records location and feed entries, but no animal group is attached yet
2. Later, when animals actually move, the user either:
   - Runs the Move Wizard and selects an existing suspended event to "activate" it (attaches the group and opens the event), or
   - Opens the suspended event directly and initiates the Move Wizard from there
3. Suspended events appear in a distinct state in the event list and on the pastures screen

**Architectural note:** This introduces a new event lifecycle state (`suspended` → `open` → `closed`), which touches the event data model, the Move Wizard, the rotation calendar, and possibly the pastures screen. Needs a dedicated design session before any code.

**Deferred:** Schedule a design conversation to spec the data model changes before tackling in code.

**Acceptance criteria:** A suspended event can be created with location and feed data but no group. The Move Wizard can "claim" a suspended event when moving animals to its location. The event list and pastures screen visually distinguish suspended events.

---

### OI-0036
**Source:** In-app feedback — id:1774289826984
**Area:** Move Wizard / Event Model (`initWizFromGroups`, ~L3417)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260324.0955
**Closed:** —

When a group is moved to a location that already has one or more groups with an open event, a new event is created rather than appending the group to the existing event. The expected behavior: if an open event already exists at the destination, the arriving group should be appended to it rather than starting a fresh event.

**Architectural note:** `wizSaveNew` creates a new event at the destination. To append instead, it would need to detect an open event at the target location and call `applyEeGroupMoveActions` or equivalent to add the group to that event. Needs design around conflict cases (confinement vs pasture, different paddocks, etc.).

**Deferred:** Design conversation needed before coding.

---

### OI-0037
**Source:** In-app feedback — id:1774289880099
**Area:** Move Wizard / Event Edit (`applyEeGroupMoveActions`, ~L10320)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260324.0955
**Closed:** b20260402.1017

When adding a group to an existing event via the Event Edit sheet, no time field was offered. Extended scope: date also defaulted to today with no way to override for past events.

**Fixed (b20260402.1017) — three related gaps closed together:**

**A — Group chips: date + time pickers.** `renderEeGroupChips()` now renders editable `dateAdded` + `timeAdded` inputs on new groups, and editable `dateRemoved` + `timeRemoved` inputs on moved groups. `addEeGroup()` initializes `timeAdded`/`timeRemoved` fields. `startMoveGroup()` initializes `timeRemoved`. `cancelGroupMove()`/`reopenGroup()` clear time fields. `applyEeGroupMoveActions()` passes departure date/time as arrival date/time at the destination event. Move wizard group creation includes time from `w-in-time`.

**B — Supabase write path.** `queueEventWrite()` includes `time_added` and `time_removed` in `event_group_memberships` write. Requires `ALTER TABLE event_group_memberships ADD COLUMN time_added text, ADD COLUMN time_removed text`.

**C — Sub-move return date.** Added `sm-date-out` field to sub-move ADD form. `calcSmDuration()` rewritten to use full date+time math (was same-day time diff with midnight wrap). Multi-day sub-moves (e.g. overnight barn) now calculate correctly. `saveSubMove()` stores `dateOut` in both add and edit modes. `renderSmExistingList()` shows return date when it differs from move-in date.

---

### OI-0038
**Source:** In-app feedback — id:1774290012106 (Tim)
**Area:** Event Model / Fertility Ledger — confinement vs pasture NPK capture
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260324.0955
**Closed:** —

Confinement locations with no manure capture should log NPK as **lost** (fertility leaves the system). Pasture locations should log NPK as **deposited** (fertility credited to that paddock). This distinction is fundamental to the fertility ledger concept. An upgrade migration should mark existing events accordingly.

**Architectural note:** Touches the NPK calculation in `renderLocationCard`, `renderGroupCard`, and the fertility reporting layer. Closely related to OI-0005 (per-paddock feed attribution). Needs a design session on how "NPK lost" surfaces in the ledger.

**Deferred:** Design conversation needed.

---

### OI-0039
**Source:** In-app feedback — id:1774290049545 (Tim)
**Area:** Home Screen — `renderLocationCard()` + `renderGroupCard()` (~L2696, ~L2800)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260324.0955
**Closed:** —

Group/location view cards should display the DMI needs of the whole group — same data shown on the event (DMI target, stored feed consumed, estimated pasture %). Currently this data appears in the group card's `dmiLine` block when expanded, but is absent from location cards' per-group rows.

**Fix:** Surface DMI summary (target lbs/day, % from pasture this event) on each group row in `renderLocationCard`, matching the display already present in `renderGroupCard`.

---

### OI-0042
**Source:** In-app feedback — id:1774290232282 (Tim)
**Area:** Home Screen architecture — group view vs location view
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260324.0955
**Closed:** —

Group view should be group-centric — showing the group's status, composition, and actions — rather than presenting the event as the primary entity. The partial fix in OI-0040 addressed buttons; the broader request is that the card layout itself should lead with the group, with event context secondary.

**Deferred:** Design conversation needed — affects card layout, information hierarchy, and potentially the data shown.

---

### OI-0043
**Source:** In-app feedback — id:1774290431038 (Tim)
**Area:** Feed Screen / `addBatch()` (~L6233)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.0955
**Closed:** b20260324.1100

`addBatch()` called `parseInt(document.getElementById('b-type').value)` to get the feed type ID. Feed type IDs are strings formatted as `"FT-00001"` — `parseInt("FT-00001")` returns `NaN`. The subsequent `S.feedTypes.find(f=>f.id===typeId)` compared `"FT-00001" === NaN`, always failing, triggering the "Select a feed type" alert regardless of selection state.

**Secondary bug fixed:** The Unarchive button in `renderFeedTypes()` rendered the onclick as `unarchive('feedType',${ft.id})` — embedding the string ID unquoted in JS, which would cause a `ReferenceError` at runtime. Fixed by quoting: `unarchive('feedType','${ft.id}')`.

**Fix:** Removed `parseInt()` — `typeId` is now read directly as a string. Both `addBatch()` and the Unarchive onclick now handle string IDs correctly.

**Data note:** Feed types lost prior to this session cannot be recovered from the b20260324.0621 backup — only "Alfalfa" was present. Root cause is likely a `setupUpdatedAt` sync merge where a device with a newer setup timestamp but stale feedTypes array won wholesale. Feed types will need to be re-entered manually.

---

### OI-0044
**Source:** In-app feedback — id:1774310373305
**Area:** Sub-Move System / Feed Model (`saveSubMove`, `calcEventTotalsWithSubMoves`, ~L9030)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260324.0955
**Closed:** b20260324.1800

Sub-moves previously inherited the parent event's `noPasture` flag, making it impossible to record a grazing sub-move when the parent was a bale-grazing (noPasture=true) event.

**Changes in b20260324.1800:**

**A — Independent `sm.noPasture` flag:** Each sub-move now stores its own `noPasture: bool`. Confinement locations auto-set to `true`. Pasture locations show a "100% stored feed at this location" toggle checkbox in the UI. When checked, height/recovery fields are hidden for that sub-move.

**B — `effectivelyNoPasture` guard:** `calcEventTotalsWithSubMoves` now checks `ae.noPasture && !hasGrazingSubMoves`. A bale-grazing parent event with at least one grazing sub-move unlocks pasture DMI inference via mass balance. This is the core fix for the mixed bale-graze + adjacent paddock scenario.

**C — Bale feed checkpoint (`sm.parentFeedCheckpointPct`):** When closing a grazing sub-move on a parent event that has bale feed entries, a "Bales remaining right now (%)" slider appears in the Record Return form. This checkpoint enables per-paddock grass DMI attribution via `calcGrassDMIByWindow`.

**D — `calcGrassDMIByWindow(ae, outDate, feedRes)`:** New attribution engine. Builds a timeline of bale-feed checkpoints from sub-move closes and final event close. For each window between checkpoints, computes bale DMI consumed (from feed entries × checkpoint pct) and infers grass DMI by mass balance (expected DMI − bale consumed). Credits each window's grass DMI to the paddock that just closed. Falls back to whole-event balance on primary paddock if no checkpoints recorded. Result stored as `ae.totals.grassDMIByPaddock`.

**E — `calcSubMoveNPKByAcres(ae, outDate)`:** Replaces time-fraction NPK attribution for sub-move locations with acres-weighted, time-windowed calculation. Builds breakpoints from sub-move open/close dates; for each window where sub-moves are active, distributes NPK across primary paddock + active sub-move paddocks proportionally by acres (equal split fallback when acres = 0).

**F — `feedDMIPutOutToDate(entries, cutoffDate)`:** Helper that date-filters feed entries to compute cumulative DMI put out up to a given date. Required by `calcGrassDMIByWindow`.

**G — Sub-move edit capability (see also OI-0055):** `openSmEditForm(smId)` pre-fills the add form with existing sub-move data. `resetSmForm()` returns form to add mode. Save button text toggles between "Record sub-move" and "Save changes". Cancel-edit button appears in edit mode.

**H — "⇢ Manage sub-moves" button in Event Edit sheet:** Calls `openSubMoveSheetFromEdit()` — closes Event Edit and opens the sub-move sheet for the same event. Enables sub-move editing on both open and closed (past) events.

---

### OI-0045
**Source:** In-app feedback — id:1774310457328
**Area:** Settings Screen (`loadSettings()`, ~L6030)
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260324.0955
**Closed:** —

All fertility calculation assumptions (N/P/K excretion rates, fertilizer prices, DMI rates, etc.) are currently scattered or use hardcoded defaults. A dedicated "Fertility assumptions" settings card should consolidate all of these into one editable form launched from Settings.

**Directly serves the project vision** — making the fertility ledger's basis visible and user-configurable is high-value work.

**Acceptance criteria:** Settings screen has a "Fertility assumptions" card. Tapping it opens a sheet where the user can view and edit all coefficients used in NPK and DMI calculations. Values persist in `S.settings`. Defaults remain unchanged if not edited.

---

### OI-0046
**Source:** In-app feedback — id:1774347020494
**Area:** Pastures / Settings — external data integration
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260324.1100
**Closed:** —

Integrate precipitation events from NWS API by zip code. Allow user to edit logged values with local actuals. Long-term feeds into grass growth curve prediction (see OI-0047).

**Deferred:** Needs design session — API integration, data model for weather events, UI for editing actuals.

---

### OI-0047
**Source:** In-app feedback — id:1774347131525
**Area:** Reports / Pastures — pasture productivity engine
**Severity:** Enhancement
**Status:** 🔵 Open
**Found:** b20260324.1100
**Closed:** —

Track grass growth curve via pasture survey rating intervals. Dashboard comparing all pastures over time. Use historical data to compute per-pasture growth coefficients and surface a predictive "Based on historical data, return date is likely to be…" suggestion.

**Directly serves the project vision** — per-paddock productivity trend is one of the highest-value unbuilt features (see §13 Backlog).

**Deferred:** Large feature — needs dedicated design session.

---

### OI-0048
**Source:** In-app feedback — id:1774348833013
**Area:** Quick Feed Sheet (`openQuickFeedSheet`, ~L3222) + Feed Screen flow
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.1100
**Closed:** b20260324.1730

Three issues fixed:

**A — Dialog model:** `qfShowEventStep()` rebuilt to be location-centric. Event picker now shows location name + type badge (🌿 grazing / 🏚 confinement / stored feed) as primary, with group names + day count as secondary. Uses `evGroups()` and `allFeedEntries()` — no longer reads `ev.groupId` directly.

**B — Cancel button on step 1:** `#qf-step1-cancel` div added below the event list. Shown when the picker step is displayed, hidden when the form step is shown. Calls `closeQuickFeedSheet()`. Previously there was no way to dismiss the sheet from step 1 without tapping the backdrop.

**C — Form title consistency:** `qfSelectEvent()` now sets the form title to the location name and the subtitle to group names + day — matching the picker's hierarchy.

---

### OI-0049
**Source:** In-app feedback — id:1774348949041
**Area:** Home Screen cards — `renderLocationCard()` (~L2708)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260324.1100
**Closed:** b20260324.1730

`renderLocationCard()` showed NPK but no DMI information. BW aggregation also used `ae2.head * ae2.wt` (event-level snapshot) which double-counts in multi-group events.

**Fix:** Aggregation now iterates `activeEvGroups` and calls `getGroupTotals(g)` per group — summing `totalHead * avgWeight` for BW and `dmiTarget` for total event DMI. Added `dmiEventLine` block showing: total DMI target across all groups, stored-vs-pasture % split, progress bar (amber fill = stored feed %). Rendered between group rows and NPK line.

---

### OI-0050
**Source:** In-app feedback — id:1774349047766
**Area:** Home Screen — `renderGroupCard()` (~L2822)
**Severity:** Polish
**Status:** ✅ Closed
**Found:** b20260324.1100
**Closed:** b20260324.1730

Group card NPK calculation used `(ae.head||0)*(ae.wt||0)` — the whole-event aggregate head/weight snapshot. In multi-group events this includes all groups' animals, producing inflated per-group NPK figures.

**Fix:** Replaced `bw = ae.head * ae.wt` with `grpBW = t.totalHead * t.avgWeight` where `t = getGroupTotals(g)` — the live totals for this specific group only. DMI (`t.dmiTarget`) was already correct. NPK and NPK value now reflect this group's individual contribution.

---

### OI-0051
**Source:** In-app feedback — id:1774349156596
**Area:** Rotation Calendar (`renderRotationCalendar()`, ~L11971)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.1100
**Closed:** b20260324.1730

`eventAUDs()` inside `renderRotationCalendar()` only applied the group-totals fallback (for missing `ev.head`/`ev.wt`) when `ev.status==='open'`. Closed multi-group events created via `initWizFromGroups()` — where head/weight are stamped as aggregates and may be 0 — returned 0 AUDs and produced blank season totals.

**Fix:** Removed the `ev.status==='open'` condition from the fallback. Group totals are now summed via `evGroups(ev)` + `getGroupTotals()` whenever `ev.head` or `ev.wt` is falsy, regardless of event status.

---

### OI-0052
**Source:** In-app feedback — id:1774349252541
**Area:** Sub-Move System (`openSubMoveSheet`, ~L9133)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260324.1100
**Closed:** b20260324.1730

Sub-move paddock picker and event label fixed:

**A — Event label:** Was using legacy `ev.groupId` (scalar, single-group only) and `ev.pasture`. Now uses `evGroups(ev)` for group names and `evDisplayName(ev)` for location — correct for multi-group multi-paddock events.

**B — Location dropdown:** Was filtering with `p.name !== ev.pasture` — excluded only the legacy primary paddock, left all other event paddocks selectable. Now builds `eventPaddockNames` set from `evPaddocks(ev).map(p=>p.pastureName)` plus `ev.pasture` as fallback. Archived pastures also excluded.

**Remaining design work (deferred to OI-0044):** Sub-moves inheriting the parent event's `noPasture` flag — independent stored-feed vs grazing toggle per sub-move — needs a dedicated design session.

---

### OI-0053
**Source:** In-app feedback — id:1774349379893
**Area:** Event Edit Sheet (`renderEeGroupChips()`, ~L5222) + `saveEventEdit()` (~L10681)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260324.1100
**Closed:** b20260324.1130

Event Edit sheet shows the first group (index 0) as "primary" — locked green pill with no Move Group button, labeled "primary". All groups should be peers — any group can be moved out independently, and the last group moving out should trigger event close.

**Root cause:** `renderEeGroupChips()` applies special treatment to `i===0 && !g._isNew`. The `ev.groupId` legacy field is not structural — `evGroups()` is the authoritative source for all group membership. The "primary" concept is a display artifact from the single-group era.

**Fix applied:**
- `renderEeGroupChips()`: removed `i===0 && !g._isNew` special case. All committed groups now render identically with Move Group button. "primary" label removed.
- `saveEventEdit()`: after `applyEeGroupMoveActions()`, checks `(ev.groups||[]).filter(g=>!g.dateRemoved).length===0`. If open event has zero remaining active groups, sets `ev.status='closed'`, `ev.dateOut=todayStr()`, calls `recalcEventTotals(ev)`. Covers both wizard and direct-move departure paths.
- Paddock "primary" labels intentionally left — paddock hierarchy has different semantics (main location for event accounting).

**Prerequisite for OI-0029** — event log consolidation display should not assume a primary group exists.

---

## Closed Items

### OI-0149 — wizSaveNew does not close group record in old event (multi-group dual-location bug)
**Source:** User report b20260402 — Bull Group appearing in both Corral and Pasture D
**Area:** Move Wizard / wizSaveNew
**Severity:** Bug
**Status:** ✅ Closed b20260402.1048

**Root cause:** `wizSaveNew()` created a new event with the group but never set `dateRemoved` on the group's record in the old event. In multi-group events (e.g. Corral with 4 groups), `wizCloseEvent()` closes the *entire* event which is wrong when other groups remain — so the user skips the close step, and the group ends up active in both events.

**Fix:** `wizSaveNew()` now iterates `wizGroupIds` before creating the new event: finds each group's old active event via `getActiveEventForGroup()`, sets `dateRemoved`/`timeRemoved` to the new event's `inDate`/`inTime`, queues the old event for write. Includes last-group-out auto-close (matching `saveEventEdit()` pattern).

**Additional fixes in same build:**
- `renderEeGroupChips()`: `dateAdded`/`timeAdded` now editable on ALL saved group records (was new-only). Extends OI-0037.
- `wizCloseEvent()`: departure date/time now inherited into step 2 arrival fields.

### OI-0115 — Supabase cascade failure: operations.name column does not exist (42703)
**Source:** Session b20260331
**Area:** Supabase load chain
**Severity:** P0 — blocked all Supabase fetches
**Status:** ✅ Closed b20260331.0304

The `operations` table column is `herd_name`, not `name`. The app was selecting `name,herd_type,...` causing a 42703 error. PostgREST aborts the entire request when a column doesn't exist, which caused every other table in the `Promise.all` batch to also fail with `TypeError: Load failed`. This was misdiagnosed as network outages for hours. Three fixes: (1) SELECT changed to `herd_name,...`, (2) assembly changed to `op.herd_name`, (3) bootstrap INSERT changed to `herd_name:`.

### OI-0116 — RLS recursion: all table policies used self-referential operation_members subquery
**Source:** Session b20260331
**Area:** Supabase RLS
**Severity:** P0 — blocked all authenticated reads/writes
**Status:** ✅ Closed b20260331 (SQL)

All 20+ app table RLS policies used `operation_id IN (SELECT operation_id FROM operation_members WHERE user_id = auth.uid())`. When `operation_members` itself has an RLS policy using the same subquery, Postgres enters infinite recursion and returns a 400. Fixed by creating a `SECURITY DEFINER` helper function `get_my_operation_id()` with `SET search_path = public` that bypasses RLS. All policies replaced to use `operation_id = get_my_operation_id()`.

### OI-0117 — Duplicate Home Farm creation on every failed load
**Source:** Session b20260331
**Area:** `migrateHomeFarm()`
**Severity:** P1 — data corruption
**Status:** ✅ Closed b20260331.1359

`migrateHomeFarm()` created a new Home Farm every time `S.farms` was empty, without checking: (a) whether the farms fetch itself had failed (network/RLS), (b) whether a farm was already pending in the sync queue, (c) whether pastures already had a consistent `farmId` proving a farm exists in Supabase. Combined with the operations 400 cascade causing all loads to fail, this produced 10+ duplicate Home Farm rows. Fixed with a 5-stage guard chain. Also fixed the realtime subscription firing 35 concurrent reloads (one per pasture upsert) — now debounced 2s.

### OI-0118 — Sync queue refills with farm entry after every clear
**Source:** Session b20260331
**Area:** `migrateHomeFarm()` pasture-derivation path
**Severity:** P1
**Status:** ✅ Closed b20260331.1359

The pasture-derivation path in `migrateHomeFarm()` unconditionally re-queued the farm write after reconstructing it from pasture farmIds — even when `_sbFarmsFetchOk=true` (meaning Supabase was reachable and the farm exists there, proven by FK constraint). Fix: only re-queue when `_sbFarmsFetchOk=false`.

### OI-0119 — `_sbLoadInProgress` guard missing from realtime callback
**Source:** Session b20260331
**Area:** `subscribeRealtime()`
**Severity:** P1
**Status:** ✅ Closed b20260331.0150

The realtime callback called `loadFromSupabase()` immediately on every DB change with no guard and no debounce. When the queue flushed 35 pasture rows, 35 realtime events fired → 35 concurrent loads. Fixed with 2s debounce and `_sbLoadInProgress` guard.

### OI-0120 — `sbGetOperationId()` bootstrapping returning users on Supabase error
**Source:** Session b20260331
**Area:** `sbGetOperationId()`
**Severity:** P1 — created duplicate operations
**Status:** ✅ Closed b20260331.0201

When `operation_members` query returned an error (e.g. RLS recursion 400), `maybeSingle()` returned `{data: null, error}`. The old code only checked `data?.operation_id` — if null, it called `sbBootstrapOperation()` regardless of whether an error occurred or whether a cached ID existed. Fix: check for error first (log and return cached ID), then check `_sbOperationId` cache before bootstrapping. Only bootstrap on genuine first sign-in where no cached ID exists at all.

### OI-0121 — `Can't find variable: pFarm` crash in migrateHomeFarm
**Source:** Session b20260331
**Area:** `migrateHomeFarm()`
**Severity:** P0 — crashed every load
**Status:** ✅ Closed b20260331.0250

The `migrateHomeFarm` rewrite dropped `const pFarm = p.farmId ? String(p.farmId) : null` from inside the forEach loop body but left the `if(pFarm !== defaultFarmId)` reference. Fixed by restoring the declaration.


**Source:** User request — b20260324.1730
**Area:** Feedback System (`openFeedbackSheet`, `CAT`, `generateBrief`, `renderFeedbackList`)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260324.1730
**Closed:** b20260324.1730

New `roadblock` feedback category added for operational blockers that stop normal farm work and need immediate developer attention.

**Changes:**
- `CAT` object: `roadblock` entry added (`label:'🚧 Roadblock'`, `cls:'br'` red badge, `pillCls:'cp-roadblock'`)
- CSS: `.cp-roadblock` bold weight + red selected state
- Feedback sheet: `🚧 Roadblock` pill added as **first** option in category picker
- Filter dropdown: `Roadblocks` option added
- `renderFeedbackList()`: `roadblock` added to category filter list
- `generateBrief()`: roadblocks listed first with `← HIGH PRIORITY — FIX BEFORE ANYTHING ELSE` flag; each item prefixed `🚧`; `catOrder` updated to `['roadblock','bug','calc','ux','feature','idea']`; footer hint updated

---

### OI-0055
**Source:** In-app feedback — id:1774352024908
**Area:** Sub-Move System (`openSubMoveSheet`, `renderSmExistingList`, ~L9030)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260324.1800 (feedback exported 2026-03-24 v1.2)
**Closed:** b20260324.1800

"Edit open event needs to allow for editing sub-move events. Particularly to uncheck the stored feed flag on legacy events to be able to update grazing data for past events once the release that makes sub-move properties able to be different from the primary bale grazing event."

**Fix:** Sub-move editing implemented as part of OI-0044 work:
- Edit button added to each row in the existing sub-moves list within the sub-move sheet
- `openSmEditForm(smId)` pre-fills all form fields (date, time, duration, location, noPasture flag, height, recovery, feed lines) from the selected sub-move record
- `resetSmForm()` returns the form to add mode
- Save button label toggles "Record sub-move" ↔ "Save changes"; amber "Cancel edit" button appears in edit mode
- `saveSubMove()` edit path updates the existing sub-move record in place (no new record created)
- "⇢ Manage sub-moves" button added to Event Edit sheet — calls `openSubMoveSheetFromEdit()` to bridge from Event Edit to sub-move sheet; works on both open and closed events, enabling retroactive correction of historical sub-move data

---

### OI-0007
**Source:** In-app feedback — id:1774009850584 (note: "When moving to a confinement location the 100% stored feed flag should be set to yes.")
**Area:** Move Wizard / Confinement Location Handling (~L3125)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.1421 (feedback dated 3/20/2026, v1.1)
**Closed:** b20260322.1511

When a user moves a group to a confinement location via the Move Wizard, the "100% stored feed" flag (`feedResidual` or equivalent) is not automatically set to `true`. Animals in confinement have no access to pasture forage, so leaving this flag unset causes incorrect pasture DMI inference — the system assumes some forage was consumed when none was. User must remember to set it manually, which is an error-prone habit.

**Pair with OI-0008** — both affect confinement location handling in the wizard. Fix in the same session.

**Fix applied:** In `onWizPaddockChange()`, when `isCon` is true, `#w-no-pasture` checkbox is auto-checked. User can still uncheck it manually.

---

### OI-0008
**Source:** In-app feedback — id:1774012610674 (note: "Confinement locations should not show min max, and estimated recovery information.")
**Area:** Move Wizard / Confinement Location Handling (~L3125)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.1421 (feedback dated 3/20/2026, v1.1)
**Closed:** b20260322.1511

When a confinement location is selected in the Move Wizard, fields for min/max grazing days and estimated recovery are still displayed. These fields are meaningless for confinement (no forage is consumed, no recovery period applies). Showing them is confusing and suggests the app doesn't understand the distinction between pasture and confinement contexts.

**Pair with OI-0007** — same screen, same session.

**Fix applied:** Two changes: (1) In `initWizFromGroups()`, `#w-recovery-section` is hidden when the outgoing event is at a confinement location. (2) In `validateRecoveryFields()`, confinement events bypass the "recovery required" validation so move-out is never blocked.

---

### OI-0009
**Source:** In-app feedback — id:1774195666830 (note: "Added feed to an open event. When I did it closed the event and I ended up on the main feed form.")
**Area:** Feed Screen / Quick Feed Sheet / Event Interaction (~L2790)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.1421 (feedback dated 3/22/2026, v1.1)
**Closed:** b20260322.1421 (this session)

Three bugs found and fixed:

**Bug A — `openQuickFeedSheet` used `e.groupId` directly instead of `evGroups()`.**
For multi-group events (or any event using the `groups[]` array), `e.groupId` could be stale or null — the lookup returned `undefined`, so the sheet dropped to the event-picker step instead of auto-selecting the group's event. The rule at L10725 explicitly says "never read `ev.groupId` directly." Fixed: now uses `evGroups(e).some(g=>g.groupId===preselectGroupId&&!g.dateRemoved)`.

**Bug B — After saving, user was left on Feed screen even when entry was via home screen group card.**
`goFeedGroup()` navigates to the Feed screen to open the Quick Feed Sheet. After saving, `saveQuickFeed()` was calling `renderFeedOverview()` and leaving the user on the Feed screen. The user came from Home and expected to return there. "Ended up on the main feed form" = Feed screen. Fixed: added `qfFromHome` flag set in `goFeedGroup`. `saveQuickFeed` reads this flag and calls `nav('home',...)` after save when set.

**Bug C — `saveQuickFeed` toast used `ev.groupId` directly (same `evGroups()` violation).**
Fixed: now uses `evGroups(ev)` to get group name for the toast.

**Additionally:** added a closed-event guard at the top of `saveQuickFeed` — if the event status is not `'open'` at save time (possible via Drive sync race), the function bails with a clear message instead of appending a feed entry to a closed event.

---

### OI-0010
**Source:** In-app feedback — id:1773766618290 + id:1774203959375 (merged: Tim 3/17 + anonymous 3/22 — same request)
**Area:** Pasture Survey Dialog (~L3855)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.1421
**Closed:** b20260322.1530

Two separate feedback entries requested the same feature: expected graze dates shown on the pasture survey card during mass survey mode. Single-paddock mode already had a "Next window" block — mass survey was missing the same context on each rating card.

**Fix applied:** In `renderSurveyPaddocks()` mass survey loop, added `getExpectedGrazeDates(p)` call per paddock. When a recovery window exists and the paddock is not currently active, a compact "↻ Ready: [date] – [date] · [status]" line renders below the rating bar. Status is color-coded: green (✓ ready), amber (⚠ window closing), or neutral text (Xd until ready). Paddocks with an active event skip the line (not relevant while being grazed).

**b20260325.1918 improvement:** The static `gdHtml` label approach above was superseded. With the multi-pasture layout consolidation, each card's `rec-preview-` block is now live and reactive — it updates in real time as the user changes min/max recovery inputs. The graze window preview is now co-located with the inputs that drive it, directly in each paddock card.

---

### OI-0011
**Source:** In-app feedback — id:1774201675357 (note: "Similar to pasture survey, implement an animal survey for a group as well as on the individual animal listing...")
**Area:** Individual Animals (~L6342 openAnimalEventSheet, ~L10500 renderAnimalsScreen)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.1421 (feedback dated 3/22/2026, v1.1)
**Closed:** b20260322.1958

BCS added as a new health event type (`type: 'bcs'`) stored in `animal.healthEvents[]`. Score range 1–10, chip-based selector, optional notes field. Implemented as:
- `#ae-evt-bcs-section` in `animal-event-wrap` sheet with 10 chip buttons
- `bcsChipToggle(el)` — single-select chip handler; `.bcs-chip` / `.bcs-chip.on` CSS
- `📊 BCS` action button on every animal row in `renderAnimalsScreen()`
- BCS events display as `📊 BCS: X/10` in health event history on the animal edit sheet
- `showAnimalEventToast` handles `bcs` type

---

### OI-0012
**Source:** In-app feedback — id:1774201874820 (note: "Create a setting for animals related to weaning target date...")
**Area:** Animals / Settings / Reports — multi-area
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.1421 (feedback dated 3/22/2026, v1.1)
**Closed:** b20260322.2021

Multi-part weaning management feature. Implemented in b20260322.2021:

**A — Species terminology:** `normalizeSpecies()` and `birthTermForSpecies()` helpers map class species strings to canonical terms (cattle/sheep/goat/pig/other) and birth event labels (Calving/Lambing/Kidding/Farrowing/Birth). Used by calving sheet and anywhere birth events are labelled.

**B — Wean target setting:** `S.settings.weanTargets: { cattle, sheep, goat }` — per-species days from birth. Defaults: cattle 205, sheep 60, goat 60. Editable in Settings → "Weaning targets" card. Saved via `saveSettings()`, loaded via `loadSettings()`.

**C — Weaned/unweaned flag:** `animal.weaned: bool | null` — `null` for pre-existing animals (no birth date assumed); `false` for newborns; `true` once marked weaned. `animal.weanedDate: ISO string | null`.

**D — Wean target date computation:** `computeWeanTargetDate(birthDate, species)` computes `birthDate + weanTargetDays`. Set on new calves in `saveCalving()`, on new/edited animals in `saveAnimalEdit()`, and backfilled at init by `migrateWeaningFields()`.

**E — Birth date field:** `animal.birthDate` added to data model. `ae-birthdate` date input in animal edit sheet. `migrateWeaningFields()` derives missing birth dates from dam's `calvingRecords[]` at init.

**F — Weaning dashboard:** New "🍼 Weaning" tab in Reports screen. Filter chips (Overdue / Due ≤14d / Due ≤30d / Pending / Unknown / Weaned ≤14/30/60d). Default filter = all unweaned (Overdue + Due + Pending + Unknown). Multi-select checkboxes with bulk "Mark weaned" action bar + date picker. Unknown animals get "Set birth date" shortcut linking to their edit sheet.

**G — Home screen nudge:** `renderWeaningNudge()` shows a card on the home screen when any animals are overdue or due within 14 days. Card links to the Reports Weaning tab.

---

### OI-0013
**Source:** In-app feedback — id:1774204002068 (note: "On female animals add a confirmed bred flag, with date of confirmation")
**Area:** Individual Animals (~L7334 openNewAnimalSheet, ~L7363 openAnimalEdit, ~L7486 saveAnimalEdit)
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260322.1421 (feedback dated 3/22/2026, v1.1)
**Closed:** b20260322.1958

`confirmedBred: bool` and `confirmedBredDate: ISO string | null` added to the animal data model. Implemented as:
- `#ae-confirmed-bred-section` in `ae-sheet-wrap` (females only) — checkbox + conditional date field
- `onConfirmedBredChange()` — shows/hides date field, pre-fills today on check
- `✓ bred` badge shown on animal card row in `renderAnimalsScreen()` and in `ae-title` of the edit sheet
- Saved in both new-animal and edit-animal paths of `saveAnimalEdit()`
- `openNewAnimalSheet()` resets section to unchecked for new females

---

### OI-0001
**Source:** Claude observation — b20260322.1143
**Area:** Sub-Move System (~L8218)
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.1143
**Closed:** b20260322.1421

`saveSmQuickLocation()` called `saveLocal()` instead of `save()`. Adding or editing a sub-move location saved to localStorage only and did not trigger Drive sync.

**Fix applied:** Replaced `saveLocal()` with `stampSetup(); save();` in `saveSmQuickLocation()` at ~L8876.

---

### OI-0002
**Source:** Claude observation — b20260322.1031
**Area:** HTML Structure / Navigation
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.1031
**Closed:** b20260322.1135

The `</div>` closing `#s-feed` was missing before `#s-animals` opened in the HTML. This caused every screen div from `#s-animals` through `#s-settings` to be nested inside `#s-feed`. Because `.scr { display:none }` and only `.scr.active { display:block }`, when `#s-feed` was not the active screen it hid all its children — making every screen except home invisible regardless of `.active` state. Diagnosed by checking the depth at which each `.scr` div opened using a Python script on the raw HTML.

**Closed:** Added one `</div><!-- /s-feed -->` between the last feed card and the `#s-animals` div. All 10 screens now open at depth 2. Verified with depth-counting script (all show depth=2, final depth=0).

---

### OI-0003
**Source:** Claude observation — b20260322.1031
**Area:** Google Drive Sync / Mobile PWA
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260322.1031
**Closed:** b20260322.1143

When the Google OAuth token expired on mobile (after ~1 hour), the scheduled silent refresh often failed silently in PWA standalone mode because the Google session cookie is not available in that browser context. Drive sync stopped entirely — the mobile device diverged from desktop and showed stale data until the user manually reconnected Drive in Settings. There was no automatic re-sync when the app resumed from background.

**Closed:** Added `onAppResume()` function (~L1771) that checks token validity on call and either syncs immediately or attempts silent re-auth. Registered via `document.addEventListener('visibilitychange', ...)` in the init block (~L11161). This fires on every app resume — phone unlock, tab switch, PWA foreground.

---


### OI-0150
**Source:** In-app feedback — id:1775162461035 (Tim, 2026-04-02)
**Area:** Home Screen / Event Tile / Move Wizard
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260402.1058
**Closed:** b20260403.0022

"Event tile — Move button launches event editor instead of move wizard." The Move button on group rows in the location card was calling `openEventEdit()`, opening the full event editor sheet instead of initiating a move flow.

**Fixed:** `renderLocationCard()` fully rewritten. Move button now calls `openMoveWizSheet(evId, groupId)` which opens the new 3-step move wizard sheet. The old `openEventEdit()` call path is completely removed from move actions.

---

### OI-0152
**Source:** In-app feedback — id:1775162095085 (Tim, 2026-04-02)
**Area:** Sub-move Close Dialog
**Severity:** Bug
**Status:** ✅ Closed
**Found:** b20260402.1058
**Closed:** b20260403.0022

"When closing a sub move paddock... closure dialog renders very narrow." The close-sub-move dialog was rendering inside a constrained-width container.

**Fixed:** New `#close-sub-paddock-wrap` sheet uses standard full-width sheet pattern (`position:fixed`, `width:min(92vw,680px)`). Includes full pasture close-out survey (residual height, forage cover, quality, recovery min/max) and anchor paddock info box.

---

### OI-0154
**Source:** In-app feedback — id:1775161694469 (Tim, 2026-04-02)
**Area:** Home Screen / Event Tile Badge
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260402.1058
**Closed:** b20260403.0022

"Event card indicator should say Stored Feed & Grazing for mixed events." Events with both pasture time and stored feed entries showed only "grazing" badge.

**Fixed:** Badge logic in `renderLocationCard()` now detects mixed events (has feed entries AND `!noPasture && locationType !== 'confinement'`) and shows "stored feed & grazing" badge with a split green/amber gradient background.

---

### OI-0156
**Source:** In-app feedback — id:1775156009406 (Tim, 2026-04-02)
**Area:** Home Screen / Event Tile
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260402.1058
**Closed:** b20260403.0022

"On all events and sub events include acreage on all cards." Acreage was not visible on event cards in the home locations view.

**Fixed:** `renderLocationCard()` now shows acreage from the paddock record next to the location name in the header. Sub-paddock rows also show acreage when available.

---

### OI-0162
**Source:** In-app feedback — id:1775155467858 (Tim, 2026-04-02)
**Area:** Mobile Layout / Feedback FAB
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260402.1058
**Closed:** b20260403.0022

"Add floating feedback button back to mobile." The FAB was hidden on mobile by OI-0147 fix to resolve a badge overflow issue.

**Fixed:** FAB restored on mobile with root fix: `z-index` raised to 150 (above nav bar, below sheets), `overflow:visible` for badge rendering, slightly smaller (44px) on mobile. Field mode still hides FAB.

---


### OI-0159
**Source:** In-app feedback — id:1775127732299 (Tim, 2026-04-02)
**Area:** Feed Management / Feed Check Dialog
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260402.1058
**Closed:** b20260403.0038

"On bale checks allow user to estimate remaining bales or percentage." The old feed check was a single percentage slider with no unit-level precision.

**Fixed:** New `openFeedCheckSheet(evId)` renders per-feed-type cards with: stepper control (−/+/direct entry, 2 decimal places), percentage display, and horizontal slider (0-100%) — all three bidirectionally linked. "Consumed since last check" amber bar shows units consumed + estimated DMI lbs. Saves `typeChecks[]` per-type breakdown alongside backward-compatible overall `balesRemainingPct`.

---

### OI-0145
**Source:** In-app feedback — id:1775002940235 (Tim, 2026-04-01)
**Area:** Field Mode / Home Screen
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260401.2245
**Closed:** b20260403.0038

"Field mode Home — remove all items except for action tiles and To Do's. At section below Field mode action buttons add To Do's list and To Do quick add button."

**Fixed:** `renderFieldHome()` fully rewritten with three sections: (1) Quick-launch tiles (2-col grid, white bg), (2) Tasks section with compact todo list (inline checkbox completion, due date/overdue labels, + Add button, max 4 shown), (3) Events section with collapsed event cards that expand on tap to show full compact location card with teal border and ⌃ collapse handle.

---


### OI-0155
**Source:** In-app feedback — id:1775156385004 (Tim, 2026-04-02)
**Area:** Move Wizard / Feed Management
**Severity:** Enhancement
**Status:** ✅ Closed
**Found:** b20260402.1058
**Closed:** b20260403.0047

"At close of event, allow user to move remaining stored feed to new paddock." No mechanism existed to transfer unconsumed stored feed when closing an event.

**Fixed:** Move wizard step 3 now shows inline feed check + feed disposition when last group is leaving and stored feed is present. Per-feed-type "move feed?" prompt with "Record as residual" / "Move to destination" buttons. When "Move to destination" is selected, remaining feed quantity is transferred as a new feedEntry on the destination event. Feed check is saved as a close-reading on the source event.

---

## Import Log

Tracks which `S.feedback` IDs have been imported to prevent duplicates across sessions.
Upload `gthy-feedback-YYYY-MM-DD-HHMM.json` at session start for Claude to diff against this log.

| Feedback ID | Imported in | OI number | Original note (truncated) |
|---|---|---|---|
| 1775162461035 | b20260402.1058 | OI-0150 | "Event tile — Move button launches event editor instead of move wizard" |
| 1775162387503 | b20260402.1058 | OI-0151 | "Home event cards should list sub paddocks the same way..." (card redesign) |
| 1775162095085 | b20260402.1058 | OI-0152 | "When closing a sub move paddock... closure dialog renders very narrow" |
| 1775161958349 | b20260402.1058 | OI-0153 | "Event card — when moving a group out... flow should be move button → where..." |
| 1775161694469 | b20260402.1058 | OI-0154 | "Event card indicator should say Stored Feed & Grazing for mixed events" |
| 1775156385004 | b20260402.1058 | OI-0155 | "At close of event, allow user to move remaining stored feed to new paddock" |
| 1775156128345 | b20260402.1058 | OI-0161 | "Explore ability to graze portion of paddock on percentage basis" |
| 1775156009406 | b20260402.1058 | OI-0156 | "On all events and sub events include acreage on all cards" |
| 1775155844209 | b20260402.1058 | OI-0157 | "Stored feed line graph... per-feed-type feed check... home dashboard" |
| 1775155467858 | b20260402.1058 | OI-0162 | "Add floating feedback button back to mobile" |
| 1775127863858 | b20260402.1058 | OI-0158 | "Allow user to close entire event... add them to another existing open location" |
| 1775127732299 | b20260402.1058 | OI-0159 | "On bale checks allow user to estimate remaining bales or percentage" |
| 1775125797698 | b20260402.1058 | OI-0163 | "Allow multi selection of tasks for reassignment to other users" |
| 1775125736000 | b20260402.1058 | OI-0164 | "Need a listing of all feed events, filter by date range, animal groups..." |
| 1775124165316 | b20260402.1058 | OI-0160 | "When a group is not placed, allow placing in existing open event or create new" |
| 1775124017705 | b20260402.1058 | OI-0165 | "Tasks don't seem to be connected to logged in user... no user selection list" |
| 1775122257634 | b20260402.1058 | OI-0166 | "Remove the x from animal group tiles" |
| 1775086697793 | b20260402.1058 | OI-0167 | "Active events in rotation view — color too close to pasture grazing color" |
| 1773704569336 | b20260322.1421 | — | "When saved to Home Screen data is not populating" — **closed at source, no OI** |
| 1773766662491 | b20260322.1421 | — | "Pasture with open event is gone, and G-1..." — **closed at source, no OI** |
| 1773766618290 | b20260322.1421 | OI-0010 | "Needs expected graze dates in survey dialogs..." (Tim 3/17 — merged with 3/22 duplicate) |
| 1774009850584 | b20260322.1421 | OI-0007 | "When moving to a confinement location the 100% stored feed flag should be set to yes." |
| 1774012610674 | b20260322.1421 | OI-0008 | "Confinement locations should not show min max, and estimated recovery information." |
| 1774195666830 | b20260322.1421 | OI-0009 | "Added feed to an open event. When I did it closed the event..." |
| 1774201675357 | b20260322.1421 | OI-0011 | "implement an animal survey for a group... Body Condition... choices 1 to 10" |
| 1774201874820 | b20260322.1421 | OI-0012 | "Create a setting for animals related to weaning target date..." |
| 1774203959375 | b20260322.1421 | OI-0010 | "Add expected graze dates on pasture survey card..." (3/22 duplicate — merged into OI-0010) |
| 1774204002068 | b20260322.1421 | OI-0013 | "On female animals add a confirmed bred flag, with date of confirmation" |
| 1774204169720 | b20260322.1421 | OI-0014 | "stage the feed prior to actually moving the group... suspended future event" |
| 1774259652890 | b20260322.2207 | OI-0016 | "There should not be an X for deletion on the main animal list" |
| 1774259757925 | b20260322.2207 | OI-0017 | "Treatments list dialog needs to be centered in display. Existing Treatments need to be editable..." |
| 1774259962696 | b20260322.2207 | OI-0018 | "Refresh after editing animal not occurring upon close. Large delay on retag." |
| 1774260052866 | b20260322.2207 | OI-0019 | "On animal form use smaller tiles to reduce space of groups..." |
| 1774260146466 | b20260322.2207 | OI-0020 | "No way to unselect a group for filtering of animal list." |
| 1774260349182 | b20260322.2207 | OI-0021 | "When moving animals in and out of a group... does the event recalculate..." |
| 1774260409016 | b20260322.2207 | OI-0022 | "On animal body condition survey add a checkbox for 'Likely cull'" |
| 1774260536657 | b20260322.2207 | OI-0023 | "View history for a given pasture" |
| 1774260638046 | b20260322.2207 | OI-0024 | "Season totals not showing in the rotation calendar." |
| 1774260688519 | b20260322.2207 | OI-0025 | "Rotation calendar should show green for pasture, tan for hay" |
| 1774260722747 | b20260322.2207 | OI-0026 | "Rotation calendar not showing active event with sub move." |
| 1774260870487 | b20260322.2207 | OI-0027 | "Sub-move error: Duration not set — Duration not required" |
| 1774271115141 | b20260322.2207 | OI-0028 | "gTHO banner and operation name needs to sit above the version and drive status" |
| 1774271246604 | b20260322.2207 | OI-0029 | "In event log the main event and sub moves should be consolidated" |
| 1774289826984 | b20260324.0910 | OI-0036 | "If a group is placed into a location that already has one or more groups in it..." |
| 1774289880099 | b20260324.0910 | OI-0037 | "Add group to an existing event should offer the time field" |
| 1774290012106 | b20260324.0910 | OI-0038 | "Confinement locations with no capture should capture the NPK as lost." |
| 1774290049545 | b20260324.0910 | OI-0039 | "Group view should include DMI needs of the whole group." |
| 1774290092842 | b20260324.0910 | OI-0040 | "Feed button in location view should apply to all groups not each one." — resolved by OI-0040 (feed moved to card level) |
| 1774290156334 | b20260324.0910 | OI-0041 | "When feeding from group view on Home Screen the dialog does not have a save or cancel" |
| 1774352024908 | b20260324.1800 | OI-0055 | "Edit open event needs to allow for editing sub-move events..." |
| 1774356724442 | b20260325.0013 | OI-0058 | "Sub moves that are pasture should be green on the rotation calendar." |
| 1774356942281 | b20260325.0013 | OI-0059 | "Audit all calculation related functions for proper logic..." |
| 1774361239173 | b20260325.0013 | OI-0060 | "In rotation calendar highlight currently active paddocks." |
| 1774374875449 | b20260325.0013 | OI-0056 | "Need a quick to do on animal list by animal" — 🚧 Roadblock |
| 1774375050876 | b20260325.0013 | OI-0061 | "In edit animal allow for treatment" (batched with 0067/0069 into OI-0061) |
| 1774375067914 | b20260325.0013 | OI-0061 | "Allow multiple treatment selection at one time" (batched into OI-0061) |
| 1774375315950 | b20260325.0013 | OI-0063 | "When selecting animal from list the add to group question jumps the list ahead." |
| 1774376187163 | b20260325.0013 | OI-0061 | "Treatment type should populate other treatment fields when appropriate" (batched into OI-0061) |
| 1774377202625 | b20260325.0013 | OI-0062 | "To do is defaulting to G2" |
| 1774381838610 | b20260325.0013 | OI-0064 | "Add required DMI to feed dialog with progress bar" |
| 1774385774185 | b20260325.0013 | OI-0065 | "Render pasture status on rotation view with green gradient..." |
| 1774386058617 | b20260325.0013 | OI-0067 | "Feedback — add area field, allow editing of feedback" |
| 1774386129481 | b20260325.0013 | OI-0066 | "Rotation View — vertical 'today' line" |
| 1774396779567 | b20260325.0013 | OI-0057 | "Feedback is not syncing properly between desktop and mobile" — ✅ Closed this session |
| 1774290232282 | b20260324.0910 | OI-0042 | "Group view should be group centric not event centric" |
| 1774290431038 | b20260324.0910 | OI-0043 | "When adding batch of feed it keeps saying select feed type when I already selected" |
| 1774310373305 | b20260324.0955 | OI-0044 | "Sub moves should not inherit stored feed settings from the primary pasture event..." |
| 1774310457328 | b20260324.0955 | OI-0045 | "We need a form launched from settings where we consolidate all assumptions around fertility factors..." |
| 1774347020494 | b20260324.1100 | OI-0046 | "Integrate precipitation events from NWS for zip code in question." |
| 1774347131525 | b20260324.1100 | OI-0047 | "Track grass growth curve via pasture survey intervals..." |
| 1774348833013 | b20260324.1100 | OI-0048 | "Feed animals dialog should list locations for feeding the entire event..." |
| 1774348949041 | b20260324.1100 | OI-0049 | "All events should list the DMI required for all groups in that location..." |
| 1774349047766 | b20260324.1100 | OI-0050 | "Group view on Home Screen should list the same information as animal group view..." |
| 1774349156596 | b20260324.1100 | OI-0051 | "Rotation calendar season totals not calculating on all events." |
| 1774349252541 | b20260324.1100 | OI-0052 | "Sub-move paddocks need to be allowed to be different from primary paddock." |
| 1774349379893 | b20260324.1100 | OI-0053 | "In events there is not really a primary animal group..." |
| 1774351616357 | b20260325.0013 | OI-0068 | "Look at feedback architecture to anticipate multiple instances..." |
| 1774818588197 | b20260401.2245 | OI-0141 | "Need to be able to delete a to-do" (merged into OI-0141) |
| 1774820123822 | b20260401.2245 | OI-0141 | "Need to be able to edit and delete an existing to do" (merged into OI-0141) |
| 1775083774847 | b20260401.2245 | OI-0141 + OI-0142 | "To-do's need to be able to be deleted... To-do's are not showing up on my home screen" (CRUD → OI-0141; mobile bug → OI-0142) |
| 1774525756460 | b20260401.2245 | OI-0143 | "when recording a new sub move... the min-max for the paddock being opened should not be shown" |
| 1774826500623 | b20260401.2245 | OI-0144 | "There should not be a delete X on the pastures listing" |
| 1775002940235 | b20260401.2245 | OI-0145 | "Field mode Home- remove all items except for action tiles and To Do's..." (partial; design parts → OI-0146) |
| 1775002527928 | b20260401.2245 | OI-0146 | "Field mode- Move Animals- Launch a streamlined move wizard..." (deferred — design first) |
| 1775003204664 | b20260401.2245 | OI-0147 | "Strange feedback remnant on Home Screen on mobile" |
| 1774820167069 | b20260401.2245 | — | "Need to be able to edit existing feedback and track if it was changed since last import" — **closed at source, no OI** |
| 1775053344478 | b20260401.2245 | — | "Capture inferred DMI from grazing..." — **resolved at source, no OI** |
| 1774899846966 | b20260401.2245 | — | "Force update in settings does not work..." — **resolved at source, no OI** |
| 1775002790303 | b20260401.2245 | — | "Add field mode and harvest to feedback areas" — **resolved at source, no OI** |
| 1774961869662 | b20260401.2245 | — | "The feed batch should be first three of farm name, field number, cutting, and date" — **resolved at source, no OI** |
| 1774899624820 | b20260401.2245 | — | "Display name not sticking in between sessions..." — **resolved at source, no OI** |
| 1774899577986 | b20260401.2245 | — | "Feedback not available on settings screen" — **resolved at source, no OI** |
| 1774818620446 | b20260401.2245 | — | "Need to be able to edit existing open feedback items" — **resolved at source, no OI** |
