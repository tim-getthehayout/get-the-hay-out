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

### Deploy commands (run from `dev` branch)
- `python3 deploy.py` — stamp files only (for WIP commits)
- `python3 deploy.py deploy` — stamp, commit, merge dev→main, push (goes live)
- `python3 deploy.py release` — deploy + git tag + optional GitHub Release

### When to deploy vs release
- **Deploy:** Routine pushes — bug fixes, incremental work
- **Release:** User-facing milestones — new features, significant changes

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

Claude Code owns these docs — update them with every deploy:
- **ARCHITECTURE.md** — line numbers, function map, screen map, data model
- **PROJECT_CHANGELOG.md** — one row per change, every session

Claude.ai owns:
- **SESSION_RULES.md** — design session governance
- **OPEN_ITEMS.md** — shared (Claude.ai adds items, Claude Code closes them)

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
