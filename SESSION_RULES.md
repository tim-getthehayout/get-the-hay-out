# Get The Hay Out — Session Rules (Design Sessions)
**Doc version:** 18 — last meaningful update b20260405
**These rules govern Claude.ai design sessions on this project.**
Upload this file to the Claude Project alongside OPEN_ITEMS.md.

> **Doc version** increments when rules change meaningfully (new sections, changed protocol).
> It does NOT increment for build stamp bumps or line number updates.
> The §0 Rules Changelog shows what changed in each version.

> **Scope change (v18):** Code implementation has moved to Claude Code. Claude.ai sessions
> are now exclusively for design, brainstorming, specs, and triage. This file no longer
> governs code delivery, build stamps, or ARCHITECTURE.md updates.

---

## 0. Rules Changelog

**Tracks changes to SESSION_RULES.md only.** App development history lives in `PROJECT_CHANGELOG.md`.

Read this to understand why a rule exists or when it was introduced.

| Doc v | Build | Change |
|---|---|---|
| v18 | b20260405 | Major scope change: Claude.ai sessions are now design-only. Code implementation moved to Claude Code. Removed: §2 Build Stamp Protocol, §3 Before Touching Any Function, §6 UI Sheet Pattern, §7 Code Quality checks, §8a-8c (stamp/ARCHITECTURE/dead code), §8e-8f (file delivery/push.command), §9 Stale Base Problem. Simplified: §1 Start of Session (no HTML or ARCHITECTURE needed), §7 End of Session (deliver briefs only). Added: §2 Workflow Split (Claude.ai vs Claude Code responsibilities). OPEN_ITEMS.md is no longer edited directly by Claude.ai — all changes (add/close/update) are captured in the SESSION_BRIEF and applied by Claude Code. Renumbered remaining sections. |
| v17 | b20260404 | §4d — SESSION_BRIEF filename convention changed from `SESSION_BRIEF_bYYYYMMDD_HHMM.md` to `SESSION_BRIEF_[subject-slug].md` (subject naming; timestamp lives in file header only). |
| v16 | b20260329 | §8e delivery table — rename-before-copy note + bash snippet added; rename step added to delivery checklist. |
| v15 | b20260329 | §1a resolution table updated for hybrid workflow. §8e delivery table — HTML and ARCHITECTURE rows clarify Claude.ai delivers with stamp, push.command renames in repo. §8f updated. |
| v14 | b20260329 | §8e delivery table — Master template row split into two variants. |
| v13 | b20260328.2241 | Patterns 11–14 promoted to MASTER_TEMPLATE v2.8. §1b version-check pre-step added. §4d SESSION_BRIEF added. |
| v12 | b20260322.1211 | §0 renamed to "Rules Changelog". §8d split into dual changelog. §8e — PROJECT_CHANGELOG.md added as standing deliverable. |
| v11 | b20260322.1211 | §8e — OPEN_ITEMS filename convention changed to build-stamped. |
| v10 | b20260322.1211 | §4b Punch List & Feedback Import added; Session Queue format added. |
| v9 | b20260322.1211 | §1 OPEN_ITEMS.md added to session start checklist. |
| v8 | b20260322.1211 | §8b explicit edit instruction — Claude edits ARCHITECTURE, user never does. |
| v7 | b20260322.1211 | §4a mid-session architecture tracking added. |
| v6 | b20260322.1211 | §4a universal candidate column added; §8g Universal Template Review added. |
| v5 | b20260322.1211 | §8e DELIVERY GATE mandatory written block added. |
| v4 | b20260322.1026 | Doc-version header added; §8e delivery table updated. |
| v3 | b20260322.1026 | §7 Code Quality added; §12 Project Vision added; §13 Backlog added. |
| v2 | b20260322.1026 | §8d Changelog update; §8e filename convention; Build Stamp Protocol. |
| v1 | b20260320.1041 | Initial SESSION_RULES created from session cleanup. |

---

## 1. Start of Session Checklist

### 1a. Resolve the latest version of each file

Before reading anything, identify the current version of each project file. **The user may have forgotten to delete prior versions when uploading new ones.** Multiple stamped copies may be present. Always use the latest.

**Resolution rules:**

| File pattern | How to identify latest | Action if multiples found |
|---|---|---|
| `OPEN_ITEMS.md` or `OPEN_ITEMS_bYYYYMMDD_HHMM.md` | Highest build stamp if stamped; stable name otherwise | Use latest silently |
| `SESSION_RULES.md` | Only one — no stamp | Use as-is |
| `MASTER_TEMPLATE_vN.N.md` or `MASTER_TEMPLATE_vN_N.md` | Highest version number (dots and underscores both valid) | Use latest silently |
| `MASTER_TEMPLATE_hybrid_vN.N.md` or `MASTER_TEMPLATE_hybrid_vN_N.md` | Highest version number | Use latest silently |

**"Silently"** = use the correct file without asking. Mention it only if two files have identical stamps and you cannot resolve which is newer.

### 1b. Verify and load

**Before doing anything else — check the version of every document you are about to work with.**

If you are about to edit or patch a document (MASTER_TEMPLATE, SESSION_RULES, etc.), read its version header first and state what you found:
> "SESSION_RULES is doc v18. MASTER_TEMPLATE is v2.8. Proceeding."

If the user asks you to patch a specific version but a different version is present, stop and flag it.

1. Read the latest `OPEN_ITEMS.md` — scan for open items in areas being discussed
2. **Surface relevant open items** before starting: "Before we begin — there are [N] open items in [area]. [OI-XXXX]: [one line]. Want to fold any in?"
3. If the user uploads a feedback export file, run the feedback import (§4b) before surfacing items

⚠️ **Do NOT read `MASTER_TEMPLATE.md` during normal sessions.** Only used for project setup (Mode 1) and promotion (Mode 2).

---

## 2. Workflow Split — Claude.ai vs Claude Code

**Claude.ai** (this session) handles:
- Design, brainstorming, UX decisions
- Writing session briefs and build specs
- Triage and prioritization of OPEN_ITEMS
- Feedback import and analysis
- SESSION_RULES and MASTER_TEMPLATE governance

**Claude Code** handles:
- All code changes to `index.html`
- ARCHITECTURE.md updates (line numbers, function map, screen map)
- PROJECT_CHANGELOG.md updates
- Closing OPEN_ITEMS entries when implemented
- Git operations (commit, branch, deploy)
- Code quality checks and testing

### What Claude.ai does NOT do (as of v18)
- ❌ Edit or deliver `index.html` — code lives in the repo, Claude Code edits it directly
- ❌ Edit or deliver `ARCHITECTURE.md` — Claude Code owns this doc
- ❌ Edit or deliver `PROJECT_CHANGELOG.md` — Claude Code owns this doc
- ❌ Bump build stamps — `deploy.py` handles this automatically
- ❌ Run syntax checks or code quality gates — Claude Code handles this
- ❌ Deliver files via `push.command` — Claude Code commits and pushes directly

### The output of a Claude.ai session is:
1. **A session brief or build spec** — what to implement and why
2. **Updated OPEN_ITEMS.md** — new items added, priorities adjusted
3. **Design decisions** — captured in the brief, not in code

---

## 3. Scoped Design Only

Keep sessions focused on one design topic or feature cluster. Do not try to design the entire roadmap in one session.

When discussing implementation details, frame them as guidance for Claude Code — not as direct edits. Example:
> "The new sheet should follow the open/close/save pattern. The save function should call bumpSetupUpdatedAt() since it modifies the groups array."

This guidance goes into the session brief (§4d), where Claude Code will read and apply it.

---

## 4a. Mid-Session Tracking

**As you work through a design session, maintain a running note of decisions and items that need to flow into outputs.**

**Track these as they happen:**

| Decision made | Where it goes |
|---|---|
| New feature designed | SESSION_BRIEF → "What to build" |
| UX decision | SESSION_BRIEF → "Key constraints" |
| Bug identified | OPEN_ITEMS.md → new OI entry |
| Existing item resolved by design | OPEN_ITEMS.md → close or update |
| Trap or risk identified | SESSION_BRIEF → "Traps to avoid" |
| Universal pattern discovered | Flag for §8g promotion review |

---

## 4b. Punch List Capture & Feedback Import

### Mid-session observations
When you notice something that should be fixed or built, note it in your mid-session tracking list (§4a) and include it in the session brief's `## OPEN_ITEMS changes` section at end of session.

**Entry format for the brief:**
```
- ADD OI-XXXX: [title] | [Area] | [Severity] | [description] | [acceptance criteria]
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
When design work this session resolves an open item, include it in the session brief:
```
- CLOSE OI-XXXX: [one-sentence closure note]
```
Claude Code will apply the status change, move the entry, and update counts.

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
| File size | User reports or Claude Code reports line count | > 13,000 lines | > 15,000 lines |
| Feature type creep | User requesting server-side queries, real-time multi-user, or pagination? | First mention | Second mention |
| Data size | Is the localStorage data model growing rapidly? | > 2MB estimated | > 4MB estimated |

### How to surface a flagged signal

State it once, briefly, before session work begins. Frame as information, not recommendation.

### Rules
- Only raise migration when a threshold is crossed — never as routine commentary
- Do not recommend stopping current work — migration is a backlog item
- Do not add an OPEN_ITEMS entry without asking — offer it, let the user decide

---

## 4d. Session Brief

A SESSION_BRIEF is a lightweight document generated at the end of a design session. It bridges a design conversation to an implementation session in Claude Code without context loss.

### When to generate one

Generate a SESSION_BRIEF **when explicitly asked**, or **proactively offer one** at the end of any session that:
- Made significant design decisions not yet formally captured in OPEN_ITEMS.md
- Produced implementation guidance that Claude Code would need
- Would leave a meaningful context gap if resumed cold

Do **not** generate one when the session only produced closed OPEN_ITEMS entries — those are already captured.

### Format

```markdown
# SESSION_BRIEF
**Generated:** bYYYYMMDD.HHMM
**Source:** Claude.ai design conversation
**Session type:** Design | Triage | Planning

## What was decided
- [Key decision 1 — one sentence each]

## What to build
- OI-XXXX: [task already in OPEN_ITEMS — reference by number]
- [New work not yet in OPEN_ITEMS]: [specific, actionable description]

## Key constraints
[Rules that must not be violated — data model invariants, naming conventions,
 architectural rules scoped to this task.]

## Implementation notes
[Specific guidance for Claude Code — which functions to modify, which patterns to follow]

## Traps to avoid
[Known failure modes or risks identified in this conversation]

## OPEN_ITEMS changes
- ADD OI-XXXX: [title] | [Area] | [Severity] | [description] | [acceptance criteria]
- CLOSE OI-XXXX: [closure note]
- UPDATE OI-XXXX: [what changed]
```

### OPEN_ITEMS changes go in the brief, not in the file

Claude.ai **does not edit OPEN_ITEMS.md directly.** Instead, capture all OPEN_ITEMS changes in the session brief under a dedicated section:

```markdown
## OPEN_ITEMS changes
- ADD OI-XXXX: [title] | [Area] | [Severity] | [description] | [acceptance criteria]
- CLOSE OI-XXXX: [one-sentence closure note]
- UPDATE OI-XXXX: [what changed — priority, description, severity, etc.]
```

When the user pastes the brief into Claude Code, Claude Code applies these changes to `OPEN_ITEMS.md` in the repo. This eliminates file transfer between platforms.

### Delivery
- Filename: `SESSION_BRIEF_[subject-slug].md`
- Delivered as an output file
- **Not uploaded to the Claude Project** — it is transient; the user pastes it into Claude Code as the opening prompt
- Claude Code reads the brief and applies: OPEN_ITEMS changes, implementation work, doc updates
- After implementation: decisions that survived should be promoted to OPEN_ITEMS.md as permanent record

### What SESSION_BRIEF is NOT
- Not a replacement for editing OPEN_ITEMS.md — but it is the **vehicle** for getting those edits into the repo via Claude Code
- Not a standing deliverable in the permanent doc set
- Not a substitute for reading SESSION_RULES.md at the start of the next session

---

## 5. Data Mutation Pattern (Reference)

This section is reference material for writing accurate session briefs. The authoritative version lives in `CLAUDE.md` in the repo.

Always follow this sequence when changing app state:
1. Mutate the state object directly (`S.*`)
2. Call `bumpSetupUpdatedAt()` if the change affects setup arrays (pastures, groups, animals, batches, users, settings)
3. Call `save()` — **the full save** (localStorage + Supabase sync), not `saveLocal()`
4. Call render function(s) to update the UI

---

## 6. Naming Conventions (Reference)

This section is reference material for writing accurate session briefs. The authoritative version lives in `CLAUDE.md` in the repo.

| Type | Pattern | Example |
|---|---|---|
| Screen render | `render[Name]Screen()` or `render[Name]()` | `renderAnimalsScreen()` |
| Sheet open | `open[Name]Sheet()` | `openQuickFeedSheet()` |
| Sheet close | `close[Name]Sheet()` | `closeQuickFeedSheet()` |
| Sheet save | `save[Name]()` or `save[Name]FromSheet()` | `saveGroupFromSheet()` |
| Sheet wrap DOM ID | `[name]-wrap` | `#quick-feed-wrap` |
| Config manage sheet | `openManage[Name]Sheet()` | `openManageClassesSheet()` |
| Private helpers | `_camelCase()` | `_agToggleAnimal()` |

---

## 7. End-of-Session Protocol

**Do all of the following before delivering outputs:**

### 7a. Update OPEN_ITEMS.md
If any items were added, closed, or modified this session, update `OPEN_ITEMS.md` and deliver it.

### 7b. Generate Session Brief (if applicable)
If the session produced design decisions or implementation guidance, generate a SESSION_BRIEF per §4d.

### 7c. Update SESSION_RULES (if applicable)
If the rules themselves changed this session:
1. Increment doc version
2. Add a row to §0 Rules Changelog
3. Deliver updated `SESSION_RULES.md`

### 7d. Delivery Gate — Mandatory Written Block

**Before delivering outputs, write the following block:**

```
── §7d DELIVERY GATE ──────────────────────────────────────────
DESIGN DECISIONS THIS SESSION:
- [decision / area]: [what was decided and why]
- [repeat for every significant decision]

DELIVERABLES:
- SESSION_BRIEF       generated for Claude Code handoff:        ✓/✗ (or N/A)
- OPEN_ITEMS changes  captured in SESSION_BRIEF for Claude Code: ✓/✗ (or N/A)
- SESSION_RULES       updated only if rules changed:             ✓/✗ (or N/A)
- MASTER_TEMPLATE     updated only if rules changed:             ✓/✗ (or N/A)
───────────────────────────────────────────────────────────────
```

### 7e. Universal Template Review

Scan the session for universal candidates.

For each candidate: "I noticed [X] this session. This feels like a universal pattern. Want to promote it to the master template?"

If the user confirms → run promotion protocol.
If the user declines or defers → note it in OPEN_ITEMS.md as a future candidate.

### 7f. SESSION_RULES Edits Must Propagate to MASTER_TEMPLATE Immediately

**Whenever SESSION_RULES.md is edited in a session, apply the same change to MASTER_TEMPLATE.md §2 in the same session.**

**What qualifies for auto-propagation:**
- New universal session rule or sub-section
- Changed rule wording that corrects a genuine ambiguity
- New feedback/queue/import protocol changes

**What does NOT propagate:**
- GTHY-specific function names, line numbers, screen maps
- GTHY-specific traps, domain knowledge, or vision content
- Bug-history notes or build-stamped changelog rows

---

## 8. Session Efficiency Rules

**Keep sessions focused.** One design topic or feature cluster per session.

**Batch related items, not unrelated ones.**

---

## 9. Project Vision

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

- **Stack:** Vanilla JS, single HTML file, Supabase backend, localStorage for offline
- **Deploy:** GitHub Pages → getthehayout.com. Claude Code handles all deploys via `deploy.py`.
- **Branching:** `dev` branch for work, `main` for production. `deploy.py deploy` merges and pushes.
- **Devices:** Mac + iPhone Safari
- **Session rules:** `CLAUDE.md` in repo root governs Claude Code sessions. This file governs Claude.ai design sessions.

---

## 10. Backlog

The Session Queue in `OPEN_ITEMS.md` is the authoritative short-term work order. This section captures the broader feature vision organized by how directly each item serves the §9 goals.

**Fertility accounting (highest vision alignment)**
- Per-paddock NPK running balance derived from event ledger — the core output of the whole system
- Season-over-season productivity trends (AUDs/acre, DMI cost, rest-period adherence)
- Stored feed cost per AUD split by pasture vs. supplemental

**Grazing operations**
- Event log consolidation — parent + sub-moves in one clean view
- Event AUD recalc when animals move or are culled mid-event
- Rotation calendar improvements

**Pasture health**
- Survey-derived recovery window refinement
- Forage productivity index per paddock over time

**Multi-farm / multi-user**
- Supabase migration enables proper multi-device sync and eventually multi-farmer tenancy

When a user asks "what should we build next?" — surface the Session Queue first, then evaluate new proposals against the four feature questions in §9.
