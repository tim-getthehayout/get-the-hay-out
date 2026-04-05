# Get The Hay Out — Session Rules
**Doc version:** 17 — last meaningful update b20260404
**These rules govern every Claude session on this project.**
Upload this file to the Claude Project alongside ARCHITECTURE.md and the current HTML.

> **Doc version** increments when rules change meaningfully (new sections, changed protocol).
> It does NOT increment for build stamp bumps or line number updates.
> The §0 Rules Changelog shows what changed in each version.

---

## 0. Rules Changelog

**Tracks changes to SESSION_RULES.md only.** App development history lives in `PROJECT_CHANGELOG.md`.

Read this to understand why a rule exists or when it was introduced.

| Doc v | Build | Change |
|---|---|---|
| v17 | b20260404 | §4d — SESSION_BRIEF filename convention changed from `SESSION_BRIEF_bYYYYMMDD_HHMM.md` to `SESSION_BRIEF_[subject-slug].md` (subject naming; timestamp lives in file header only). |
| v16 | b20260329 | §8e delivery table — ⚠️ rename-before-copy note + bash snippet added; rename step added to delivery checklist. Root cause of stable-name deliverables documented: HTML/ARCHITECTURE work under stable names during session; OPEN_ITEMS/PROJECT_CHANGELOG carry stamps in filename from creation so never need renaming — that asymmetry is the failure mode. Filename convention updated: underscores throughout (`bYYYYMMDD_HHMM`) replacing dots in all stamped filenames. |
| v15 | b20260329 | §1a resolution table updated for hybrid workflow — HTML and ARCHITECTURE rows changed to stable filenames (`index.html`, `ARCHITECTURE.md`); OPEN_ITEMS/PROJECT_CHANGELOG rows note both stamped and stable naming; MASTER_TEMPLATE rows support both dot and underscore version conventions. §8e delivery table — HTML and ARCHITECTURE rows clarify Claude.ai delivers with stamp, push.command renames in repo. §8f updated — upload reminder now directs user to `upload-to-claude/` subfolder for correctly re-stamped files. |
| v14 | b20260329 | §8e delivery table — Master template row split into two: claude.ai variant (`MASTER_TEMPLATE_vN.N.md`) and hybrid variant (`MASTER_TEMPLATE_hybrid_vN.N.md`). Both use versioned filename convention for deliverables. |
| v13 | b20260328.2241 | §0 — Patterns 11–14 promoted to MASTER_TEMPLATE v2.8: Backend Assembly Contract (shape mapping at assembly layer), Write Queue Mutation Ownership (queueWrite before save), Supabase Nested Select FK Disambiguation, Supabase Realtime REPLICA IDENTITY FULL. No SESSION_RULES rule changes — patterns live in MASTER_TEMPLATE §3. |
| v13 | b20260328.1221 | §1b — version-check pre-step added: before editing any doc, read its version header and state what was found; flag mismatches before proceeding. Propagated from MASTER_TEMPLATE v2.7. |
| v13 | b20260328.1221 | §4d SESSION_BRIEF added — format, when to generate, handoff to Claude Code, cross-session re-orientation pattern. Propagated from MASTER_TEMPLATE v2.7. |
| v12 | b20260328.1140 | §0 — Promotion: MASTER_TEMPLATE v2.6 promoted Pattern 10 (Pre-Migration Backend Guard). No SESSION_RULES rule change — pattern lives in MASTER_TEMPLATE §3. Changelog row added per §5 promotion protocol. |
| v12 | b20260322.1211 | §0 renamed to "Rules Changelog"; app-change rows removed to PROJECT_CHANGELOG.md |
| v12 | b20260322.1211 | §8d split into dual changelog — SESSION_RULES for rules, PROJECT_CHANGELOG for app changes |
| v12 | b20260322.1211 | §8e delivery table — PROJECT_CHANGELOG.md added as standing deliverable |
| v11 | b20260322.1211 | §8e — OPEN_ITEMS filename convention changed to build-stamped |
| v10 | b20260322.1211 | §4b Punch List & Feedback Import added; Session Queue format added |
| v9 | b20260322.1211 | §1 OPEN_ITEMS.md added to session start checklist |
| v8 | b20260322.1211 | §8b explicit edit instruction — Claude edits ARCHITECTURE, user never does |
| v7 | b20260322.1211 | §4a mid-session architecture tracking added |
| v6 | b20260322.1211 | §4a universal candidate column added; §8g Universal Template Review added |
| v5 | b20260322.1211 | §8e DELIVERY GATE mandatory written block added |
| v4 | b20260322.1026 | Doc-version header added; §8e delivery table updated |
| v3 | b20260322.1026 | §7 Code Quality added (10 checks); §12 Project Vision added; §13 Backlog added |
| v2 | b20260322.1026 | §8d Changelog update; §8e filename convention; Build Stamp Protocol |
| v1 | b20260320.1041 | Initial SESSION_RULES created from session cleanup |

---

## 1. Start of Session Checklist

### 1a. Resolve the latest version of each file

Before reading anything, identify the current version of each project file. **The user may have forgotten to delete prior versions when uploading new ones.** Multiple stamped copies may be present. Always use the latest.

**Resolution rules:**

| File pattern | How to identify latest | Action if multiples found |
|---|---|---|
| `index.html` | Internal build stamp in meta tag | Only one — use as-is |
| `ARCHITECTURE.md` | Internal `**Current build:**` line | Only one — use as-is |
| `OPEN_ITEMS.md` or `OPEN_ITEMS_bYYYYMMDD.HHMM.md` | Highest build stamp if stamped; stable name otherwise | Use latest silently |
| `PROJECT_CHANGELOG.md` or `PROJECT_CHANGELOG_bYYYYMMDD.HHMM.md` | Highest build stamp if stamped; stable name otherwise | Use latest silently |
| `SESSION_RULES.md` | Only one — no stamp | Use as-is |
| `MASTER_TEMPLATE_vN.N.md` or `MASTER_TEMPLATE_vN_N.md` | Highest version number (dots and underscores both valid) | Use latest silently |
| `MASTER_TEMPLATE_hybrid_vN.N.md` or `MASTER_TEMPLATE_hybrid_vN_N.md` | Highest version number | Use latest silently |

**"Silently"** = use the correct file without asking. Mention it only if two files have identical stamps and you cannot resolve which is newer.

**Build stamp comparison:** `b20260322.1730` > `b20260322.1211` because 1730 > 1211. The full 12-digit string sorts correctly lexicographically.

### 1b. Verify and load

**Before doing anything else — check the version of every document you are about to work with.**

If you are about to edit or patch a document (MASTER_TEMPLATE, SESSION_RULES, ARCHITECTURE, etc.), read its version header first and state what you found:
> "ARCHITECTURE is b20260328.1221. SESSION_RULES is doc v13. MIGRATION_PLAN is v2.1. Proceeding."

If the user asks you to patch a specific version but a different version is present, stop and flag it:
> "You asked me to patch v2.3 but the file in project knowledge is v2.6. Should I apply the patch to v2.6 instead?"

Never apply a patch written for one version to a different version without explicit confirmation.

1. Search project knowledge for **"ARCHITECTURE"** and read the latest `ARCHITECTURE.md` in full
   ⚠️ **Do NOT read `MASTER_TEMPLATE.md` during normal sessions.** Only used for project setup (Mode 1) and promotion (Mode 2).
2. Note the current build version from the app-version meta tag in the HTML
3. Confirm the HTML build stamp matches the build in `ARCHITECTURE.md` — if they differ, flag it before proceeding
4. Identify the authoritative render function for any screen being modified (see ARCHITECTURE.md Screen Map)
5. Copy `ARCHITECTURE.md` to your working directory — edit it directly and deliver as output
6. Read the latest `OPEN_ITEMS.md` — scan for open items in areas being worked on
7. **Surface relevant open items** before starting: "Before we begin — there are [N] open items in [area]. [OI-XXXX]: [one line]. Want to fold any in?"
8. If the user uploads a feedback export file, run the feedback import (§4b) before surfacing items
9. Run the **migration readiness check** (§4c) — surface a note only if a threshold is crossed

**ARCHITECTURE.md and OPEN_ITEMS.md are files Claude edits, not documents Claude describes changes for.** The user should never manually update either.

---

## 2. Build Stamp Protocol

**Every delivered HTML file must have an updated build stamp. No exceptions.**

**Format:** `bYYYYMMDD.HHMM` using UTC time at the moment of delivery.

**Location:** Near the top of the HTML file in a meta tag:
```html
<meta name="app-version" content="bYYYYMMDD.HHMM" id="app-version-meta"/>
```

**How to generate:**

The sandbox UTC clock is accurate. Use it directly:

```bash
date -u +b%Y%m%d.%H%M
```

This returns a stamp like `b20260322.1530`. Use this as the build stamp. No need to ask the user for the time.

> **Why UTC and not local time?** The sandbox clock is accurate in UTC but its timezone setting is unreliable — it always reports UTC even when the user is in a different timezone. Using UTC directly avoids the ambiguity. Build stamps are only used for ordering (higher = newer), so the timezone offset is irrelevant as long as all stamps use the same reference point.

**The build stamp is the source of truth for versioning.** Any version field stored in app data is unreliable — all runtime version reads should use the meta tag. Bump the stamp as the **very last edit** before copying to outputs so it reflects the actual delivery time.

---

## 3. Before Touching Any Function

- Read `ARCHITECTURE.md` — check the Screen Map for the authoritative render function
- Check the **Dead Code** section — do not edit or re-add removed functions
- Grep for the DOM element ID the function targets to confirm it exists in the HTML before editing
- If two functions appear to do the same thing, check which one is called from the master screen router — that one is authoritative

**GTHY-specific traps:**
> `renderAnimalList()` is DEAD and was removed. The Animals tab uses `renderAnimalsScreen()`. Do not re-add it.
> `renderEventsLog()` is at ~L5805 — not near the `// ─── EVENTS ───` section header (~L3549). Search for the function name; do not assume it's near its section header.
> `renderRotationCalendar()` lives at ~L11971 and is called by both the Events screen and the Reports screen. There is only one copy. Edit it at ~L11971.

---

## 4. Scoped Changes Only

Only modify the specific function(s) needed for the requested change. Do not refactor, rename, or reformat surrounding code unless explicitly asked. In a large single-file codebase, unintended changes are invisible and destructive.

When adding UI elements, check the Screen Map — some screens have multiple render functions covering different layouts (e.g. desktop header vs. mobile strip).

---

## 4a. Mid-Session Architecture Tracking

**As you work through a session, maintain a running note of every change that will require an ARCHITECTURE.md update.** Do not wait until the end to reconstruct what changed — track it as you go.

**After each `str_replace` or code change, immediately append one line to this list.** Do not batch them at the end. One change = one line added immediately.

**Triggers — note these as they happen:**

| Change made | ARCHITECTURE.md update | Universal candidate? |
|---|---|---|
| New function added | Add to Key Functions or Screen Map | If it solves a problem any app would have |
| Function renamed or removed | Update Screen/Sheet Map; add to Dead Code | Rarely — naming is project-specific |
| New sheet/overlay added | Add to Sheet Overlay Map | If the sheet pattern itself is novel |
| New state field added | Add to Data Model table | If it solves a general data design problem |
| Bug fixed with architectural implications | Add to Known Bugs Fixed | **Yes** — bugs from universal patterns almost always qualify |
| New code quality rule discovered | Add to Critical Behavioral Notes | **Yes** — quality rules are almost always universal |
| Migration readiness observation | Add to Coupling Log | **Yes** — migration patterns are always universal |
| **New stateful system or lifecycle implemented** | **Document full state machine in Critical Behavioral Notes** | **Yes — state lifecycle patterns are always universal** |

**State machine documentation rule:** Whenever a feature has data that transitions through phases (open/active/closed, pending/running/complete, etc.), ARCHITECTURE.md must document:
- What each state means semantically
- What field stores the state (and what values represent each state)
- What triggers each transition (which function, which user action)
- What UI surfaces each state
- What operations are and are not valid in each state
- Any states that exist in the data model but have no UI implementation yet

**Format for mid-session notes:**
```
ARCH UPDATES THIS SESSION:
- Added open[X]Sheet() / close[X]Sheet() → Sheet Overlay Map
- S.[newField] added → Data Model table
- render[NewScreen]() added at ~L[N] → Screen Map
- Bug fixed: [description] → Known Bugs Fixed
  ↳ UNIVERSAL CANDIDATE: [one sentence on why it generalises]
```

**This list must be written out verbatim in your response as part of the §8e Delivery Gate, immediately before `present_files` is called.**

---

## 4b. Punch List Capture & Feedback Import

### Mid-session observations
When you notice something that should be fixed but is not the current task, add it to `OPEN_ITEMS.md` immediately.

**Entry format:**
```markdown
### OI-XXXX
**Source:** [Claude observation | In-app feedback | User report | Session regression] — [build/id]
**Area:** [Screen / Sheet / System]
**Severity:** [Bug | Polish | Enhancement | Debt]
**Status:** 🔴 Open
**Found:** [build stamp]
**Closed:** —

[What is wrong, how to reproduce, why it matters.]

**Acceptance criteria:** [What done looks like — one sentence.]
```

**Severity:** Bug (broken) · Polish (rough but correct) · Enhancement (new capability) · Debt (architectural coupling)

### Feedback import
GTHY exports feedback as JSON via `exportFeedbackJSON()` → `gthy-feedback-YYYY-MM-DD-HHMM.json`.

**Field → severity mapping:**
| `f.cat` | OI Severity |
|---|---|
| `roadblock` | Roadblock (surface first with HIGH PRIORITY flag) |
| `bug` | Bug |
| `calc` | Bug |
| `ux` | Polish |
| `feature` | Enhancement |
| `idea` | Enhancement |

When the user uploads a feedback JSON:
1. Read the file — check the feedback/issues array
2. Cross-reference the Import Log in `OPEN_ITEMS.md` — skip already-imported IDs
3. Create `OI-XXXX` entries for new items
4. Add imported IDs to the Import Log
5. Surface a summary: "Imported [N] new items as OI-XXXX through OI-YYYY."

### Closing items
When work this session resolves an open item:
1. Change status to `✅ Closed`, add `**Closed:** b[build]`
2. Add a one-sentence closure note
3. Move entry to "Closed Items" section
4. Update the Status Summary counts

### Session Queue

The Session Queue is a short priority table in `OPEN_ITEMS.md` (just below the Status Summary) that carries the recommended work order from session to session.

**When to write it:** After any session that produces a proposed work order — typically after a feedback import/triage session or when Claude surfaces multiple open items and proposes an order. Claude does **not** write the queue unilaterally. It asks first:

> "Want me to add these to the Session Queue in OPEN_ITEMS.md in this order? Adjust the priorities now if needed."

Only write the queue after the user confirms.

**Format:**
```markdown
## Session Queue
Recommended work order as of [build stamp]. Update after each session.

| Priority | OI | Title | Notes |
|---|---|---|---|
| 1 | OI-XXXX | [title] | [Bug/Enhancement] — pairing note if applicable |
| 2 | OI-XXXX | [title] | [Bug/Enhancement] |
```

**At session start:** If a queue exists, surface it before asking about the session goal:
> "The queue has [N] items. Next up: [OI] — [title]. Continue with this, or change focus?"

### OPEN_ITEMS.md header stamps
Update both stamps on every delivery:
- **Last updated** — current build stamp, always
- **Reconciled against build** — the HTML build items were verified against

---

## 4c. Migration Readiness Check

Run silently at session start. Surface a note **only if at least one threshold is crossed.** Say nothing if all clear.

### Signals to check

| Signal | How to check | Watch | Act |
|---|---|---|---|
| File size | `wc -l` on the main app file | > 13,000 lines | > 15,000 lines |
| Tool call pressure | Did prior sessions regularly hit the limit? | Occasionally near limit | Routine sessions hitting limit |
| Feature type creep | User requesting server-side queries, real-time multi-user, or pagination? | First mention | Second mention |
| Data size | Is the localStorage data model growing rapidly? | > 2MB estimated | > 4MB estimated |

### How to surface a flagged signal

State it once, briefly, before session work begins. Frame as information, not recommendation.

**Watch threshold:** "Note: the app file is at [N] lines — approaching the ~15,000 line migration consideration point. No action needed now."

**Act threshold:** "Before we start — the file is at [N] lines, past the point where migration to a component framework is worth considering. We can continue as-is today, but should migration planning go on the backlog?"

### Rules
- Only raise migration when a threshold is crossed — never as routine commentary
- Do not recommend stopping current work — migration is a backlog item
- Do not add an OPEN_ITEMS entry without asking — offer it, let the user decide

**Note:** A Supabase migration plan (`MIGRATION_PLAN_supabase_v1.0.md`) has been produced and is available in project knowledge. The decision to migrate has been made; timing is TBD. File size threshold still applies for tracking current single-file health.

---

## 4d. Session Brief

A SESSION_BRIEF is a lightweight document generated at the end of any design or planning session. It serves two purposes:
1. **Tool handoff** — bridges a design conversation to an implementation session in Claude Code without context loss.
2. **Session re-orientation** — paste it as the opening message of a new session to restore context without re-uploading all docs.

### When to generate one

Generate a SESSION_BRIEF **when explicitly asked**, or **proactively offer one** at the end of any session that:
- Made significant design decisions not yet formally captured in OPEN_ITEMS.md or ARCHITECTURE.md
- Produced implementation guidance that an implementation session would need
- Would leave a meaningful context gap if resumed cold

Do **not** generate one when the session only produced closed OPEN_ITEMS entries or ARCHITECTURE updates — those are already captured in permanent docs.

### Format

```markdown
# SESSION_BRIEF
**Generated:** bYYYYMMDD.HHMM
**Source:** Claude.ai design conversation | Claude Code session | Mixed
**Session type:** Design | Implementation | Triage

## What was decided
- [Key decision 1 — one sentence each]

## What to build
- OI-XXXX: [task already in OPEN_ITEMS — reference by number]
- [New work not yet in OPEN_ITEMS]: [specific, actionable description]

## Key constraints
[Rules that must not be violated for this specific work — data model invariants,
 naming conventions, architectural rules scoped to this task. Do not repeat rules
 already in ARCHITECTURE.md unless particularly easy to overlook for this task.]

## Implementation notes
[Specific guidance from this conversation not already in ARCHITECTURE.md]

## Traps to avoid
[Known failure modes or risks identified in this conversation]

## Docs to read at session start
- ARCHITECTURE.md §[relevant section(s)]
- OPEN_ITEMS.md OI-XXXX, OI-YYYY
```

### Delivery

- Filename: `SESSION_BRIEF_[subject-slug].md` — subject-named (e.g. `SESSION_BRIEF_auth_overlay.md`); timestamp lives in the file header `**Generated:**` line, not the filename
- Delivered as an output file alongside (not instead of) the normal session deliverables
- **Not uploaded to the Claude Project** — it is transient, session-scoped; overwrite it at the start of each new session
- After implementation: decisions that survived should be promoted to OPEN_ITEMS.md or ARCHITECTURE.md as permanent record

### What SESSION_BRIEF is NOT
- Not a replacement for OPEN_ITEMS entries — fully scoped decisions belong in OPEN_ITEMS with OI numbers
- Not a standing deliverable in the permanent doc set
- Not a substitute for reading SESSION_RULES.md and ARCHITECTURE.md at the start of the next session

---

## 5. Data Mutation Pattern

Always follow this exact sequence when changing app state:
1. Mutate the state object directly (`S.*`)
2. Call `bumpSetupUpdatedAt()` if the change affects setup arrays (pastures, groups, animals, batches, users, settings)
3. Call `save()` — **the full save** (localStorage + Drive sync), not `saveLocal()`
4. Call render function(s) to update the UI

**Exception — Backup Restore:** A restore must be a full replacement, not a merge. After `importDataJSON()`, call `saveLocal()` then `driveWriteFile()` directly — force-write the restored data to Drive before the normal sync cycle runs. See ARCHITECTURE.md "Backup / Restore" for implementation details.

**14 mutation functions have a known history of missing `bumpSetupUpdatedAt()`** — verify this call is present in any function that modifies setup arrays.

---

## 6. UI Overlay / Sheet Pattern

- All sheets are always in the DOM — show/hide by adding/removing `.open` on the `-wrap` div
- Backdrop click always calls the close function
- New sheet HTML belongs at the bottom of the file (~L11100+)
- New sheet JS functions follow the naming pattern: `open[Name]Sheet()` / `close[Name]Sheet()` / `save[Name]()`
- After adding a new sheet, add it to the Sheet Overlay Map in ARCHITECTURE.md

The universal principle: **overlays should be toggled, not created/destroyed.** Creating DOM elements dynamically on every open introduces race conditions and makes the DOM structure unpredictable.

---

## 7. Code Quality & Error Prevention

These practices are mandatory on every session.

### 7a. Verify Every Edit Landed

After every `str_replace`, immediately read back the changed lines before moving on.

```bash
grep -n "your_changed_phrase" get-the-hay-out_bYYYYMMDD.HHMM.html
```

**The stale view problem:** After any successful edit, all previous `view` output for that file is stale. Always re-read the relevant section before making a second edit to the same area.

---

### 7b. Syntax Check Before Delivery

```bash
python3 -c "
import subprocess, re
with open('get-the-hay-out_bYYYYMMDD.HHMM.html') as f:
    html = f.read()
match = re.search(r'<script>(.*?)</script>', html, re.DOTALL)
if match:
    with open('/tmp/app_check.js', 'w') as f:
        f.write(match.group(1))
result = subprocess.run(['node', '--check', '/tmp/app_check.js'],
                        capture_output=True, text=True)
print('PASS' if result.returncode == 0 else 'FAIL: ' + result.stderr)
"
```

If the syntax check fails, **do not deliver the file.** Fix the error first.

---

### 7c. DOM Element Existence Check

```bash
grep -c 'id="your-element-id"' get-the-hay-out_bYYYYMMDD.HHMM.html
```

Result of 0 means the function will silently fail at runtime. Result > 1 means duplicate ID.

---

### 7d. Function Name Collision Check

```bash
grep -n "function myNewFunction" get-the-hay-out_bYYYYMMDD.HHMM.html
```

A duplicate function definition silently overwrites the first.

---

### 7e. Call Site Check Before Removing or Renaming

```bash
grep -n "functionName(" get-the-hay-out_bYYYYMMDD.HHMM.html
```

Remove or update every call site before deleting a function.

---

### 7f. Temporal Dead Zone (TDZ) Awareness

In any function longer than ~30 lines, declare all `const`/`let` variables at the **top of the function**, before any conditional logic.

```javascript
// ✗ Wrong — crashes silently if isCon is referenced above its declaration
function longFunction(){
  if(isCon) { ... }               // ReferenceError
  // ... many lines ...
  const isCon = someCondition;    // declared too late
}

// ✓ Correct
function longFunction(){
  const isCon = someCondition;    // declared first
  if(isCon) { ... }               // safe
}
```

**Known GTHY instance:** `wizCloseEvent()` — `isCon` TDZ was a real bug (see ARCHITECTURE.md Known Bugs Fixed).

---

### 7g. Template Literal Integrity

When editing a large template literal, read the entire block before and after the edit to confirm all backticks and interpolations are balanced.

---

### 7h. Event Propagation in Nested Clickables

```javascript
// ✓ Correct
`<div onclick="openItem(${id})">
  <button onclick="event.stopPropagation();editItem(${id})">Edit</button>
</div>`
```

---

### 7i. Guard Patterns for DOM Queries

```javascript
function renderSomething(){
  const el = document.getElementById('my-element');
  if(!el) return;  // always guard
  // ...
}
```

---

### 7j. Read Before Editing

Before any `str_replace`, view the 10–20 lines around the target. The same pattern often appears in multiple places in a large file.

---

## 8. End-of-Session Protocol

**Do all of the following before delivering the final file — without being asked:**

### 8a. Bump the Build Stamp
Run `date -u +b%Y%m%d.%H%M` in bash to get the current UTC stamp, then update the app-version meta tag. This is the last edit before delivery.

### 8b. Edit and Deliver ARCHITECTURE.md

**Claude edits this file directly. The user never edits it manually.**

Open the working copy of `ARCHITECTURE.md` and make all updates from the mid-session tracking list (§4a). Then deliver the updated file as an output.

Specific edits to make:
- **Build number** — update to the new stamp at the top of the file
- **Screen Map** — update line numbers that moved; add new screens; mark removed render functions as dead
- **Sheet Overlay Map** — add any new overlays with wrap IDs and function names
- **Data Model** — add new state fields; note changed meanings
- **Key Functions** — add new utilities; remove deleted ones
- **Known Bugs Fixed** — add bugs fixed this session with root cause and fix
- **Dead Code** — add removed functions with reason
- **Critical Behavioral Notes / Migration Coupling Log** — any new patterns or cross-domain dependencies

**After editing, verify:**
```bash
grep "Current build" ARCHITECTURE.md   # confirm stamp updated
grep -c "\[REPLACE\]" ARCHITECTURE.md  # should be 0
```

**ARCHITECTURE.md is always delivered with every session — no exceptions.** Its build stamp must always match the HTML build stamp.

**PROJECT_CHANGELOG is always delivered with every session — no exceptions.**

### 8c. Remove Dead Code
List functions made obsolete this session. Remove them from the HTML and all call sites.

### 8d. Update the Changelogs

**Write PROJECT_CHANGELOG first — before bumping the build stamp, before editing ARCHITECTURE.md, before any other end-of-session step.**

**Two separate changelogs — update the right one:**

**`SESSION_RULES.md §0 Rules Changelog`** — only when SESSION_RULES.md itself changes:
- Format: `| vN | bYYYYMMDD.HHMM | [what changed in the rules] |`

**`PROJECT_CHANGELOG_bYYYYMMDD.HHMM.md`** — every session, for all app-level changes:
- Format: `| bYYYYMMDD.HHMM | [File] | [what changed] |`
- Always add at least one row per session

### 8e. Deliver Changed Files

| File | Deliver when | Naming convention |
|---|---|---|
| App HTML | Every session | `get-the-hay-out_bYYYYMMDD_HHMM.html` (Claude.ai delivers with stamp; `push.command` renames to `index.html` in repo) |
| Architecture map | Every session (always gets stamp update) | `ARCHITECTURE_bYYYYMMDD_HHMM.md` (Claude.ai delivers with stamp; `push.command` renames to `ARCHITECTURE.md` in repo) |
| Open items punch list | When any item changed | `OPEN_ITEMS_bYYYYMMDD_HHMM.md` |
| Project changelog | Every session (always has new rows) | `PROJECT_CHANGELOG_bYYYYMMDD_HHMM.md` |
| Session rules | **Only when rules actually changed** | `SESSION_RULES.md` |
| Master template (claude.ai) | On confirmed §8g promotion **or** when SESSION_RULES.md was edited (§8h) | `MASTER_TEMPLATE_vN.N.md` |
| Master template (hybrid) | On confirmed §8g promotion **or** when SESSION_RULES.md was edited (§8h) | `MASTER_TEMPLATE_hybrid_vN.N.md` |

> **Note:** All stamped filenames use underscores throughout — `b20260329_1917`, not `b20260329.1917`. Dots are used inside file content (meta tags, headers) but not in filenames where they cause confusion.

**The user never edits ARCHITECTURE.md, OPEN_ITEMS.md, or SESSION_RULES.md directly.** Claude owns all three.

**⚠️ Rename before copy — mandatory:** HTML and ARCHITECTURE are worked on under stable names (`index.html`, `ARCHITECTURE.md`) during the session. They MUST be renamed to their stamped versions when copying to outputs. The rename is what makes them consistent with OPEN_ITEMS and PROJECT_CHANGELOG. Missing this step is what causes stable names to appear as deliverables.

```bash
# Correct copy-to-outputs pattern:
STAMP=b20260329_1917   # underscores, no dot
cp /home/claude/index.html       /mnt/user-data/outputs/get-the-hay-out_${STAMP}.html
cp /home/claude/ARCHITECTURE.md  /mnt/user-data/outputs/ARCHITECTURE_${STAMP}.md
cp /home/claude/OPEN_ITEMS_${STAMP}.md       /mnt/user-data/outputs/
cp /home/claude/PROJECT_CHANGELOG_${STAMP}.md /mnt/user-data/outputs/
# SESSION_RULES and MASTER_TEMPLATE only if changed — no stamp in their names
```

---

### §8e Delivery Gate — Mandatory Written Block

**Before calling `present_files` for any session that produced changes, write the following block verbatim in your response.**

```
── §8e DELIVERY GATE ──────────────────────────────────────────
ARCH UPDATES THIS SESSION:
- [function / area changed]: [what changed and why → which ARCHITECTURE section]
- [repeat for every change made this session]

DELIVERABLES:
- PROJECT_CHANGELOG  rows written for every item above:  ✓/✗
- HTML               syntax-checked, build stamp bumped:  ✓/✗
- ARCHITECTURE.md    all items above documented,
                     stamp matches HTML:                  ✓/✗
- OPEN_ITEMS         closed items updated, queue current: ✓/✗
- SESSION_RULES /
  MASTER_TEMPLATE    updated only if rules changed:       ✓/✗  (or N/A)
───────────────────────────────────────────────────────────────
```

**If any item shows ✗:** Complete it before proceeding.

**Delivery checklist:**
- [ ] **PROJECT_CHANGELOG written first** — rows for every change this session — always deliver
- [ ] HTML edited, syntax-checked, build stamp bumped
- [ ] ARCHITECTURE.md edited (§8b), build stamp updated — always deliver
- [ ] OPEN_ITEMS updated if items changed — deliver only if changed
- [ ] SESSION_RULES delivered **only if rules changed** this session
- [ ] §8g completed — check for universal candidates
- [ ] §8h completed — if SESSION_RULES changed, MASTER_TEMPLATE updated and included
- [ ] **HTML and ARCHITECTURE renamed to stamped filenames before copy to outputs** — `get-the-hay-out_bYYYYMMDD_HHMM.html` and `ARCHITECTURE_bYYYYMMDD_HHMM.md` (underscores, not dots)
- [ ] All changed files copied to outputs with correct filenames
- [ ] User reminded to deploy + upload changed files to project

### 8f. Remind the User
- Drop all deliverables into `~/Desktop/GTHY-Deliverables/` and run `push.command`
- `push.command` renames files, runs `deploy.py`, commits, and pushes automatically
- After push completes, upload **from `~/Desktop/GTHY-Deliverables/upload-to-claude/`** to this Claude Project:
  - `index.html` — correctly re-stamped by deploy.py at push time
  - `ARCHITECTURE.md` — correctly re-stamped by deploy.py at push time
- Also upload any changed: `OPEN_ITEMS.md`, `PROJECT_CHANGELOG.md`, `SESSION_RULES.md`
- If any universal templates were updated, `push.command` handles sync to claude-templates automatically via GitHub Action

---

### 8g. Universal Template Review

At the end of every session, scan the mid-session tracking list (§4a) for universal candidates.

For each candidate: "I noticed [X] this session. This feels like a universal pattern. Want to promote it to the master template?"

If the user confirms → run §5 Promotion Protocol.
If the user declines or defers → note it in OPEN_ITEMS.md as a future candidate.

---

### 8h. SESSION_RULES Edits Must Propagate to MASTER_TEMPLATE Immediately

**Whenever SESSION_RULES.md is edited in a session, apply the same change to MASTER_TEMPLATE.md §2 in the same session.**

**What qualifies for auto-propagation:**
- New universal session rule or sub-section
- Changed rule wording that corrects a genuine ambiguity
- New §4b import/queue/feedback protocol changes

**What does NOT propagate:**
- GTHY-specific function names, line numbers, screen maps
- GTHY-specific traps, domain knowledge, or vision content
- Bug-history notes or build-stamped changelog rows

---

## 9. The Stale Base Problem

The most common source of bugs across sessions. **Symptoms:** Functions added in a prior session are missing; fixes are lost; features regress.

**Root cause:** Each Claude session has no memory of prior sessions. If the project file is an old version of the HTML, all edits apply to the old base.

**Prevention:**
- Upload the latest deployed HTML to the project after every session
- At session start, verify the build stamp in the project file matches what ARCHITECTURE.md says it should be
- If there is a mismatch, alert the user and ask which version to use before proceeding

### Stale vs. Corrupted — Never Confuse Them

**Stale** = an older but valid version of the file. Tell the user the file is behind, ask them to upload the current version.

**Corrupted** = structural errors — broken tables, missing headers, truncated content. Show the user the specific broken section.

Never silently rewrite a file to match an older format.

---

## 10. Session Efficiency Rules

**Keep sessions focused.** One feature cluster or bug cluster per session.

**Most critical fix first.** If the session hits the tool limit mid-session, the most important change should already be delivered.

**Batch related issues, not unrelated ones.**

**Never re-apply prior fixes without checking.** Always grep for the function or key changed line before re-implementing.

---

## 11. Naming Conventions

| Type | Pattern | Example |
|---|---|---|
| Screen render | `render[Name]Screen()` or `render[Name]()` | `renderAnimalsScreen()` |
| Sheet open | `open[Name]Sheet()` | `openQuickFeedSheet()` |
| Sheet close | `close[Name]Sheet()` | `closeQuickFeedSheet()` |
| Sheet save | `save[Name]()` or `save[Name]FromSheet()` | `saveGroupFromSheet()` |
| Sheet wrap DOM ID | `[name]-wrap` | `#quick-feed-wrap` |
| Config manage sheet | `openManage[Name]Sheet()` | `openManageClassesSheet()` |
| Private helpers | `_camelCase()` | `_agToggleAnimal()` |

State object: `S.*` · Save full: `save()` · Save local only: `saveLocal()` · Setup timestamp: `bumpSetupUpdatedAt()`

---

## 12. Project Vision

### What this app does

**Get The Hay Out (GTHY)** is a farm management app for grass-based livestock operations. The name captures the core goal: to *get the hay out* of a grazing system — using animals, rotational grazing, bale grazing, stored feed fed on pasture, and soil amendments to increase the long-term fertility and productivity of the farm rather than extract it.

### The core insight

**A pasture accumulates a fertility ledger.** Every grazing event, bale grazing session, stored feed delivery, manure spread, and soil amendment is a transaction. Every metric — NPK balance, dry matter intake (DMI), cost basis, rest days, forage productivity — is *derived* by replaying that ledger, never stored directly.

This is how accounting works: the balance sheet is always derived from the transaction log. GTHY is a fertility accounting system for a farm.

### The user's score

A farmer "wins" when:
1. Each paddock is building fertility over time (NPK balance trending positive)
2. Animals are getting adequate dry matter at target cost per AUD
3. Rest periods are long enough for paddocks to recover before re-grazing
4. The ratio of pasture-sourced vs. stored-feed nutrition is improving season over season

### What this means for feature design

Every feature should answer one of these questions:
1. Does this help the farmer record a fertility transaction accurately?
2. Does this help the farmer see the current fertility balance of each paddock?
3. Does this help the farmer make a better grazing decision today?
4. Does this help the farmer see season-over-season trends in farm productivity?

Features that don't serve at least one of these questions belong in a different app.

### Technical context

- **Stack:** Vanilla JS, single HTML file, localStorage for offline, Google Drive JSON sync for multi-device (being replaced by Supabase)
- **Deploy:** GitHub Pages → getthehayout.com. `deploy.py` handles stamp automation.
- **Devices:** Mac + iPhone Safari. Safari Web Inspector for console access.
- **App file:** `get-the-hay-out_bYYYYMMDD.HHMM.html`
- **localStorage key:** `gthy`
- **Backup format:** `gthy-backup-YYYY-MM-DD-HHMM.json` (full data) · `gthy-feedback-YYYY-MM-DD-HHMM.json` (feedback only)
- **Supabase migration:** Plan complete (`MIGRATION_PLAN_supabase_v1.0.md` in project knowledge). M1–M6 phased. Open decisions to resolve before starting M1.

---

## 13. Backlog

The Session Queue in `OPEN_ITEMS.md` is the authoritative short-term work order. This section captures the broader feature vision organized by how directly each item serves the §12 goals.

**Fertility accounting (highest vision alignment)**
- Per-paddock NPK running balance derived from event ledger — the core output of the whole system
- Season-over-season productivity trends (AUDs/acre, DMI cost, rest-period adherence)
- Stored feed cost per AUD split by pasture vs. supplemental

**Grazing operations**
- OI-0029: Event log consolidation — parent + sub-moves in one clean view
- OI-0021: Event AUD recalc when animals move or are culled mid-event
- OI-0056: Per-animal quick to-dos (🚧 roadblock — design pending)
- Rotation calendar improvements (OI-0060, OI-0062)

**Pasture health**
- Survey-derived recovery window refinement
- Forage productivity index per paddock over time

**Multi-farm / multi-user**
- Supabase migration enables proper multi-device sync and eventually multi-farmer tenancy (M6)

When a user asks "what should we build next?" — surface the Session Queue first, then evaluate new proposals against the four feature questions in §12.
