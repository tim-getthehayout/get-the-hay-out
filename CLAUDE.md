# CLAUDE.md — Claude Code Rules for GTHY

## Project Overview

**Get The Hay Out (GTHY)** is a single-file PWA for pasture tracking and grazing management.
- **App file:** `index.html` (~14,500 lines — all HTML, CSS, and JS inline)
- **Stack:** Vanilla JS, Supabase backend, localStorage offline, GitHub Pages deploy
- **Live site:** getthehayout.com
- **Service worker:** `sw.js` handles caching and update prompts

## Branching & Deploy

- **`dev`** — all work happens here
- **`main`** — production, served by GitHub Pages
- Never commit directly to `main`

### Serial Work — No PRs, No Feature Branches

This is a single-file PWA (`index.html`). Parallel branches and PRs are incompatible with this architecture — every change touches the same file, so parallel work produces conflicts or silent overwrites.

- **Never create feature branches or PRs.** All work is committed directly to `dev`.
- **Never use worktree isolation** (`isolation: "worktree"`) for implementation work.
- **One Claude Code session at a time.** If Cowork or a user hands off multiple tasks, complete them sequentially — finish task N, commit, then start task N+1.
- The only path to production is `dev` → `deploy.py deploy` → `main`.

### Deploy commands (run from `dev` branch)
- `python3 deploy.py` — stamp files only (for WIP commits)
- `python3 deploy.py deploy` — stamp, commit, merge dev→main, push (goes live)
- `python3 deploy.py release` — deploy + git tag + optional GitHub Release

### When to deploy vs release
- **Deploy:** Routine pushes — bug fixes, incremental work
- **Release:** User-facing milestones — new features, significant changes

### Deploy prompt
After completing a bug fix or feature change, always ask the user if they want to deploy to main. Changes in `dev` are not live until deployed.

## GitHub Issues & PR Test Plans

**After creating a PR that references a GitHub Issue, post the test plan as a comment on the linked issue.**

Format:
```
## Test Plan (PR #N)

- [ ] [test item 1]
- [ ] [test item 2]
...

The issue should not be closed until all items above are verified by the user.
```

Rules:
- Extract the test plan from the PR description's `## Test plan` section
- Post the comment using: `gh issue comment <issue-number> --body "..."`
- Do this immediately after `gh pr create` succeeds
- If a PR does not reference any issue, skip this step (no issue to comment on)

## Fix Root Causes, Not Symptoms

When encountering a bug or missing capability, always identify and fix the root cause. Do not use workarounds (overloading existing fields, stuffing data into wrong columns, skipping schema changes) unless the user explicitly chooses that path after seeing the options.

**Before implementing a fix, present the options:**
1. **Root cause fix** — what the correct structural change is (new column, proper field, schema update)
2. **Workaround** (if applicable) — what a quicker but less correct approach would be, and what it sacrifices

Let the user choose. Default to root cause unless time pressure or complexity makes a workaround the pragmatic choice. If you catch yourself mapping new data into an existing field that wasn't designed for it, stop and flag it.

## Before Touching Any Function

1. Read `ARCHITECTURE.md` — check the Screen Map for the authoritative render function
2. Check the Dead Code section — do not edit or re-add removed functions
3. Grep for the DOM element ID the function targets to confirm it exists
4. If two functions appear to do the same thing, check which one is called from the screen router

## Code Quality Checks (before every deploy)

1. **Syntax check:**
   ```bash
   python3 -c "
   import re
   with open('index.html') as f: html = f.read()
   m = re.search(r'<script>(.*?)</script>', html, re.DOTALL)
   if m:
       open('/tmp/app_check.js','w').write(m.group(1))
   import subprocess
   r = subprocess.run(['node','--check','/tmp/app_check.js'], capture_output=True, text=True)
   print('PASS' if r.returncode==0 else 'FAIL: '+r.stderr)
   "
   ```
2. **DOM element existence:** `grep -c 'id="element-id"' index.html` — 0 = missing, >1 = duplicate
3. **Function collision:** `grep -n "function myFunction" index.html` — duplicates silently overwrite
4. **Call site check:** Before removing/renaming a function, grep for all call sites

## Data Integrity — Backup/Restore Congruence

Backup (`exportDataJSON`) serializes the entire `S` object. Restore (`importDataJSON`) replaces `S` wholesale, runs migrations, then pushes to Supabase via `pushAllToSupabase()`. Any change that alters the shape of `S` can break backup/restore if not kept in sync.

**After any change that touches the following, check backup/restore congruence:**

| Change type | What to verify |
|---|---|
| New `S.*` array or field | Added to `ensureDataArrays()`? Will old backups missing this field restore cleanly? |
| Renamed or removed `S.*` key | Migration in `importDataJSON` to map old key → new? Old backups must still import. |
| New Supabase table | Added to `pushAllToSupabase()`? Restore-then-sync must push all data. |
| Changed row shape (new columns) | Shape function (`_*Row()`) updated? `pushAllToSupabase` uses shape functions to write. |
| New migration function | Called in `importDataJSON` restore path? (Currently runs `migrateSystemIds`, `migrateToPaddocksField`, `ensureDataArrays`.) |

**Rule:** If a change touches any of the above, update the backup/restore path in the same deploy. Flag it to the user if uncertain whether a migration is needed for old backups.

## New UI Fields → Supabase Column Rule

**Every new data field displayed in the UI must have a corresponding Supabase column before deploying.** Adding a JS state variable and form input without a Supabase column causes silent data loss — the value is captured locally but never syncs. Checklist for every new field:

1. **Supabase column** — `ALTER TABLE ... ADD COLUMN` SQL ready for user to run
2. **`_SB_ALLOWED_COLS`** — column name added to the table's allowed set
3. **Shape function** — maps JS camelCase → Supabase snake_case
4. **Assembly layer** — `loadFromSupabase` / `assembleEvents` reads the column back
5. **Draft save/hydrate** — if the field is part of a draft system (e.g., surveys), include in both save and hydrate paths

Do NOT deploy UI that captures data without completing all 5 steps.

## Supabase Sync — Mandatory queueWrite Rule

`save()` only writes `S` to localStorage — it does NOT sync to Supabase. Every function that mutates `S.*` data MUST explicitly call `queueWrite()` for each record it creates, updates, or deletes BEFORE calling `save()`.

**Pattern for every mutation:**
```
queueWrite('table_name', _shapeFunction(record, _sbOperationId));  // sync to Supabase
save();                                                             // persist to localStorage
```

**For deletes:**
```
queueWrite('_delete:table_name', {id: recordId, operation_id: _sbOperationId});
```

**For events (parent + 6 child tables):**
```
queueEventWrite(ev);  // handles events + all child tables
```

**Common trap:** Complex functions that touch multiple tables (calving, split, move, input application) often queue some records but forget others. After writing any multi-table mutation, verify EVERY `S.*.push()`, `S.*[idx]=`, or `a.healthEvents.push()` has a corresponding `queueWrite`.

**Safety net:** "Push all to Supabase" button in Settings calls `pushAllToSupabase()` which re-queues everything. But this is a manual recovery tool, not a substitute for correct queueWrite calls.

## Data Mutation Pattern

Always follow this sequence when changing app state:
1. Mutate state object (`S.*`)
2. Call `bumpSetupUpdatedAt()` if change affects setup arrays (pastures, groups, animals, batches, users, settings)
3. Call `save()` (full save — localStorage + Supabase sync), not `saveLocal()`
4. Call render function(s) to update UI

## Naming Conventions

| Type | Pattern | Example |
|---|---|---|
| Screen render | `render[Name]Screen()` or `render[Name]()` | `renderAnimalsScreen()` |
| Sheet open | `open[Name]Sheet()` | `openQuickFeedSheet()` |
| Sheet close | `close[Name]Sheet()` | `closeQuickFeedSheet()` |
| Sheet save | `save[Name]()` or `save[Name]FromSheet()` | `saveGroupFromSheet()` |
| Sheet wrap DOM ID | `[name]-wrap` | `#quick-feed-wrap` |
| Config manage sheet | `openManage[Name]Sheet()` | `openManageClassesSheet()` |
| Private helpers | `_camelCase()` | `_agToggleAnimal()` |

## UI Sheet Pattern

- All sheets are always in the DOM — show/hide by toggling `.open` on the `-wrap` div
- Backdrop click always calls the close function
- New sheet HTML belongs at the bottom of the file
- Never create/destroy DOM elements dynamically for overlays

## Scoped Changes Only

Only modify the specific function(s) needed for the requested change. Do not refactor, rename, or reformat surrounding code unless explicitly asked.

## Doc Ownership

Claude Code owns these docs:
- **ARCHITECTURE.md** — line numbers, function map, screen map, data model
- **PROJECT_CHANGELOG.md** — one row per change, every deploy

Claude.ai owns:
- **SESSION_RULES.md** — design session governance

Cowork owns:
- **OPEN_ITEMS.md** — Cowork edits directly in the repo (add/close/update entries, bump counts). Claude Code may also close items when implementing fixes.
- **`github/issues/`** — spec files for Claude Code handoff. See `_TEMPLATE.md` for format and `LABELS.md` for label protocol.

### Spec File Handoff (from Cowork)
Cowork writes spec files to `github/issues/`. Files without a `GH-` prefix are unfiled — Claude Code should:
1. Create a GitHub issue from the spec: `gh issue create --title "TITLE" --body "$(cat github/issues/FILENAME.md)" --label "LABELS"`
2. Rename the file with the issue number: `FILENAME.md` → `GH-{number}_FILENAME.md`

### Session Brief Handoff (from Claude.ai)
When the user pastes a SESSION_BRIEF from Claude.ai, look for the `## OPEN_ITEMS changes` section and apply all entries to `OPEN_ITEMS.md` before starting implementation work. (This path is used when Cowork is not available.)

### Deploy Gate — Mandatory Before Every Deploy
Before running `deploy.py deploy` or `deploy.py release`, complete ALL of the following:

1. **PROJECT_CHANGELOG.md** — Add one row per change included in this deploy
2. **ARCHITECTURE.md** — Update any affected sections (function map, line ranges, data model, known traps, auth/sync notes)
3. **OPEN_ITEMS.md** — If any items were added, closed, or modified, update the file
4. **Syntax check** — Run the code quality check from the "Code Quality Checks" section

Do NOT run deploy until all four steps are done. If the user asks to deploy, complete the gate first, then deploy.

**This applies to every deploy, including hotfixes.** When multiple deploys happen in a session (e.g., a feature deploy followed by hotfix deploys), each deploy must update the changelog before running `deploy.py`. Do not batch changelog updates — a missing entry means the change is undocumented.

## Build Stamp

- **Format:** `bYYYYMMDD.HHMM` (UTC)
- **Location:** `<meta name="app-version" content="bYYYYMMDD.HHMM">` in index.html
- **`deploy.py` handles stamping automatically** — do not manually edit the stamp
- ARCHITECTURE.md stamp must always match index.html stamp

## Known Traps

- `renderAnimalList()` is DEAD — use `renderAnimalsScreen()`
- `renderEventsLog()` is NOT near the `// EVENTS` section header — search by function name
- `renderRotationCalendar()` is shared by Events screen and Reports screen — only one copy exists
- 14 mutation functions have a history of missing `bumpSetupUpdatedAt()` — always verify
