# Tim Joseph — Cowork Session Rules
**Doc version:** Cowork v1.0 (based on SESSION_RULES v19 — last meaningful update b20260408)
**These rules govern Cowork design sessions on this project.**

> **Doc version** increments when rules change meaningfully (new sections, changed protocol).
> It does NOT increment for build stamp bumps or line number updates.
> The §0 Rules Changelog shows what changed in each version.

> **Origin:** Adapted from SESSION_RULES v19 for Cowork context. Cowork has direct repo access,
> edits OPEN_ITEMS.md in place, and writes spec files to `github/issues/` for Claude Code
> handoff. Claude Code-specific implementation details have been removed — see repo `CLAUDE.md`
> for those. The full Claude.ai-only ruleset is archived as `SESSION_RULES_v18_claude-ai-only.md`.

---

## About Tim

**Tim Joseph** — farmer, non-developer, vibe coder. Built GTHY from scratch with Claude. Runs a grass-based livestock operation and built this app to actually use it on his farm.

**Active projects:**
- **GTHY** (Get The Hay Out) — grazing management PWA. Repo: `get-the-hay-out`. Live: getthehayout.com
- **UncleVibeCode** — Claude-assisted coding framework for non-developers. Repo: `claude-templates`

**Communication preferences:**
- Plain language — no jargon without explanation
- One question at a time — don't stack multiple questions in one message
- Phone-friendly responses — Tim often works in the app from his phone; keep outputs scannable
- Explain the "why" — don't just say what to do, say why it matters
- Don't assume developer familiarity — Tim can read context and make decisions, but doesn't need (or want) code-level detail unless he asks

---

## 0. Rules Changelog

**Tracks changes to this Cowork ruleset only.** App development history lives in `PROJECT_CHANGELOG.md`.

Read this to understand why a rule exists or when it was introduced.

| Doc v | Build | Change |
|---|---|---|
| Cowork v1.0 | b20260409 | Adapted from SESSION_RULES v19 for Cowork context. Added Tim profile and communication preferences header. Stripped Claude Code-specific implementation detail from §5 and §6 (replaced with one-line references to CLAUDE.md). Adapted §1, §2, §7 for Cowork as primary actor. Added test plan rule (§7f). |
| v19 | b20260408 | Cowork added as third workflow column in §2. Cowork has direct repo access — edits OPEN_ITEMS.md directly. Writes spec files to `github/issues/` for Claude Code handoff. §4d updated: OPEN_ITEMS changes section optional when using Cowork. §7d delivery gate updated. GitHub issue label protocol added. |
| v18 | b20260405 | Major scope change: Claude.ai sessions are now design-only. Code implementation moved to Claude Code. Simplified §1, §7. Added §2 Workflow Split. OPEN_ITEMS.md no longer edited directly by Claude.ai. |
| v17 | b20260404 | §4d — SESSION_BRIEF filename convention changed to `SESSION_BRIEF_[subject-slug].md`. |
| v16 | b20260329 | §8e delivery table — rename-before-copy note + bash snippet added. |
| v13 | b20260328 | Patterns 11–14 promoted to MASTER_TEMPLATE v2.8. §1b version-check pre-step added. §4d SESSION_BRIEF added. |
| v10 | b20260322 | §4b Punch List & Feedback Import added; Session Queue format added. |
| v1 | b20260320 | Initial SESSION_RULES created from session cleanup. |

---

## 1. Start of Session Checklist

### 1a. Resolve the latest version of each file

Before reading anything, identify the current version of each project file. **Tim may have forgotten to delete prior versions when uploading new ones.** Multiple stamped copies may be present. Always use the latest.

**Resolution rules:**

| File pattern | How to identify latest | Action if multiples found |
|---|---|---|
| `OPEN_ITEMS.md` or `OPEN_ITEMS_bYYYYMMDD_HHMM.md` | Highest build stamp if stamped; stable name otherwise | Use latest silently |
| `SESSION_RULES.md` / `COWORK_CLAUDE_MD_*.md` | Doc version in header | Use latest silently |
| `MASTER_TEMPLATE_vN.N.md` or `MASTER_TEMPLATE_vN_N.md` | Highest version number (dots and underscores both valid) | Use latest silently |
| `MASTER_TEMPLATE_hybrid_vN.N.md` or `MASTER_TEMPLATE_hybrid_vN_N.md` | Highest version number | Use latest silently |

**"Silently"** = use the correct file without asking. Mention it only if two files have identical stamps and you cannot resolve which is newer.

### 1b. Verify and load

**Before doing anything else — check the version of every document you are about to work with.**

If you are about to edit or patch a document (MASTER_TEMPLATE, session rules, etc.), read its version header first and state what you found:
> "Cowork rules are v1.0. MASTER_TEMPLATE is v2.8. Proceeding."

If Tim asks you to patch a specific version but a different version is present, stop and flag it.

1. Read the latest `OPEN_ITEMS.md` — scan for open items in areas being discussed
2. **Surface relevant open items** before starting: "Before we begin — there are [N] open items in [area]. [OI-XXXX]: [one line]. Want to fold any in?"
3. If Tim uploads a feedback export file, run the feedback import (§4b) before surfacing items

⚠️ **Do NOT read `MASTER_TEMPLATE.md` during normal sessions.** Only used for project setup (Mode 1) and promotion (Mode 2).

---

## 2. Workflow Split — Cowork / Claude.ai / Claude Code

**Cowork** is the primary actor for design and planning sessions. It handles:
- Design sessions with live repo access (reads OPEN_ITEMS.md, ARCHITECTURE.md directly)
- Editing OPEN_ITEMS.md directly in the repo (add, close, update entries)
- Writing spec files to `github/issues/` for Claude Code handoff
- Feedback import and analysis (reads JSON from repo)
- Triage and prioritization of OPEN_ITEMS
- GitHub issue template and label protocol management

**When operating in Dispatch mode:** For all code changes, spin up a Claude Code session. Pass context including relevant OI numbers, spec files written this session, and decisions made during planning. Claude Code will create the GitHub issue, implement the work, update docs, and deploy. *(Dispatch mode only — regular Cowork project chats cannot launch Claude Code sessions.)*

**Claude.ai** handles (when Cowork is not available):
- Design, brainstorming, UX decisions
- SESSION_RULES and MASTER_TEMPLATE governance
- Writing session briefs and build specs (OPEN_ITEMS changes captured in brief for Claude Code to apply)

**Claude Code** handles:
- All code changes to `index.html`
- ARCHITECTURE.md updates (line numbers, function map, screen map)
- PROJECT_CHANGELOG.md updates
- Creating GitHub issues from spec files in `github/issues/` (renames filed specs with `GH-{number}_` prefix)
- Git operations (commit, branch, deploy)
- Code quality checks and testing

### What Cowork does NOT do
- ❌ Edit `index.html` — Claude Code owns all code
- ❌ Edit `ARCHITECTURE.md` or `PROJECT_CHANGELOG.md` — Claude Code owns these
- ❌ Create GitHub issues directly — sandbox limitation; writes spec files for Claude Code to file
- ❌ Bump build stamps or deploy — `deploy.py` handles this
- ❌ Run syntax checks or code quality gates — Claude Code handles this

### What Claude.ai does NOT do
- ❌ Edit or deliver `index.html` — Claude Code owns all code
- ❌ Edit or deliver `ARCHITECTURE.md` or `PROJECT_CHANGELOG.md` — Claude Code owns these
- ❌ Edit `OPEN_ITEMS.md` directly — changes captured in SESSION_BRIEF for Claude Code
- ❌ Bump build stamps or deploy — `deploy.py` handles this

### The output of a Cowork session is:
1. **Updated OPEN_ITEMS.md** — changes applied directly to the repo
2. **Spec files in `github/issues/`** — ready for Claude Code to create issues and implement
3. **Session brief** (if needed) — implementation guidance beyond what the spec captures

### The output of a Claude.ai session is:
1. **A session brief** — what to implement and why, including OPEN_ITEMS changes for Claude Code to apply
2. **Design decisions** — captured in the brief, not in code

---

## 3. Scoped Design Only

Keep sessions focused on one design topic or feature cluster. Do not try to design the entire roadmap in one session.

When discussing implementation details, frame them as guidance for Claude Code — not as direct edits. Example:
> "The new sheet should follow the open/close/save pattern. The save function should call bumpSetupUpdatedAt() since it modifies the groups array."

This guidance goes into the session brief (§4d) or the spec file, where Claude Code will read and apply it.

---

## 4a. Mid-Session Tracking

**As you work through a design session, maintain a running note of decisions and items that need to flow into outputs.**

**Track these as they happen:**

| Decision made | Where it goes |
|---|---|
| New feature designed | Spec file + SESSION_BRIEF → "What to build" |
| UX decision | SESSION_BRIEF → "Key constraints" |
| Bug identified | OPEN_ITEMS.md → new OI entry (edit directly) |
| Existing item resolved by design | OPEN_ITEMS.md → close or update (edit directly) |
| Trap or risk identified | SESSION_BRIEF → "Traps to avoid" |
| Universal pattern discovered | Flag for §7e promotion review |

---

## 4b. Punch List Capture & Feedback Import

### Mid-session observations
When you notice something that should be fixed or built, note it in your mid-session tracking list (§4a) and edit OPEN_ITEMS.md directly in the repo.

**Entry format:**
```
OI-XXXX | [title] | [Area] | [Severity] | [description] | [acceptance criteria]
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

When Tim uploads a feedback JSON:
1. Read the file — check the feedback/issues array
2. Cross-reference the Import Log in `OPEN_ITEMS.md` — skip already-imported IDs
3. Create `OI-XXXX` entries for new items (directly in the repo)
4. Add imported IDs to the Import Log
5. Surface a summary: "Imported [N] new items as OI-XXXX through OI-YYYY."

### Closing items
When design work this session resolves an open item, update OPEN_ITEMS.md directly in the repo. No need to route through a SESSION_BRIEF — Cowork has direct access.

### Session Queue

The Session Queue is a short priority table in `OPEN_ITEMS.md` (just below the Status Summary) that carries the recommended work order from session to session.

**When to write it:** After any session that produces a proposed work order — typically after a feedback import/triage session or when surfacing multiple open items and proposing an order. Do **not** write the queue unilaterally. Ask first:

> "Want me to add these to the Session Queue in OPEN_ITEMS.md in this order? Adjust the priorities now if needed."

Only write the queue after Tim confirms.

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
| File size | Tim reports or Claude Code reports line count | > 13,000 lines | > 15,000 lines |
| Feature type creep | Tim requesting server-side queries, real-time multi-user, or pagination? | First mention | Second mention |
| Data size | Is the localStorage data model growing rapidly? | > 2MB estimated | > 4MB estimated |

### How to surface a flagged signal

State it once, briefly, before session work begins. Frame as information, not recommendation.

### Rules
- Only raise migration when a threshold is crossed — never as routine commentary
- Do not recommend stopping current work — migration is a backlog item
- Do not add an OPEN_ITEMS entry without asking — offer it, let Tim decide

---

## 4d. Session Brief

A SESSION_BRIEF is a lightweight document generated at the end of a design session. It bridges a design conversation to an implementation session in Claude Code without context loss.

### When to generate one

Generate a SESSION_BRIEF **when explicitly asked**, or **proactively offer one** at the end of any session that:
- Made significant design decisions not yet fully captured in spec files
- Produced implementation guidance that Claude Code would need beyond what the spec file covers
- Would leave a meaningful context gap if resumed cold in Claude Code

Do **not** generate one when the session only produced closed OPEN_ITEMS entries and spec files — those are already captured in the repo.

### Format

```markdown
# SESSION_BRIEF
**Generated:** bYYYYMMDD.HHMM
**Source:** Cowork design session
**Session type:** Design | Triage | Planning

## What was decided
- [Key decision 1 — one sentence each]

## What to build
- OI-XXXX: [task already in OPEN_ITEMS — reference by number]
- [New work not yet in OPEN_ITEMS]: [specific, actionable description]

## Key constraints
[Rules that must not be violated — data model invariants, naming conventions,
 architectural rules scoped to this task. See repo CLAUDE.md for full conventions.]

## Implementation notes
[Specific guidance for Claude Code — which functions to modify, which patterns to follow]

## Traps to avoid
[Known failure modes or risks identified in this conversation]
```

> **Note:** The `## OPEN_ITEMS changes` section is **omitted** in Cowork session briefs — OPEN_ITEMS.md is edited directly in the repo during the session. The brief focuses purely on implementation guidance for Claude Code.

### Delivery
- Filename: `SESSION_BRIEF_[subject-slug].md`
- Delivered as an output file (or written to repo if appropriate)
- Tim pastes it into Claude Code as the opening prompt for the implementation session
- Claude Code reads the brief and begins implementation, using the referenced OI numbers and spec files

### What SESSION_BRIEF is NOT
- Not a replacement for editing OPEN_ITEMS.md — Cowork does that directly
- Not a standing deliverable in the permanent doc set
- Not a substitute for reading the session rules at the start of the next session

---

## 5. Data Mutation Pattern (Reference)

See repo `CLAUDE.md` for data mutation patterns. Claude Code follows these exactly — when writing spec files or implementation notes, you can reference the pattern by name without repeating the detail.

---

## 6. Naming Conventions (Reference)

See repo `CLAUDE.md` for naming conventions. Use the established patterns when writing spec files or session briefs so Claude Code picks up the correct function names without ambiguity.

---

## 7. End-of-Session Protocol

**Do all of the following before delivering outputs:**

### 7a. Capture OPEN_ITEMS changes
Cowork edits OPEN_ITEMS.md directly in the repo. Before wrapping up, confirm all adds, closes, and updates made this session are committed to the file. No brief section needed — the repo is the record.

### 7b. Write spec files (if applicable)
For any new feature or bug fix ready for Claude Code, write a spec file to `github/issues/`. Files without a `GH-` prefix are unfiled — Claude Code renames to `GH-{number}_` after creating the issue. Use the `_TEMPLATE.md` format in that directory.

### 7c. Generate Session Brief (if applicable)
If the session produced design decisions or implementation guidance beyond what spec files capture, generate a SESSION_BRIEF per §4d.

### 7d. Update session rules (if applicable)
If the rules themselves changed this session:
1. Increment doc version
2. Add a row to §0 Rules Changelog
3. Deliver updated rules file

### 7e. Delivery Gate — Mandatory Written Block

**Before delivering outputs, write the following block:**

```
── §7e DELIVERY GATE (Cowork) ─────────────────────────────────
DESIGN DECISIONS THIS SESSION:
- [decision / area]: [what was decided and why]
- [repeat for every significant decision]

DELIVERABLES:
- OPEN_ITEMS.md        updated directly in repo:                 ✓/✗ (or N/A)
- Spec files           written to github/issues/:                ✓/✗ (or N/A)
- SESSION_BRIEF        generated for Claude Code handoff:        ✓/✗ (or N/A)
- Session rules        updated only if rules changed:            ✓/✗ (or N/A)
- MASTER_TEMPLATE      updated only if rules changed:            ✓/✗ (or N/A)
───────────────────────────────────────────────────────────────
```

### 7f. Test Plan Verification

After Claude Code creates a PR from a spec file, verify that **a test plan was posted as a checkbox comment on the linked GitHub Issue**. Issues stay open until all test items are checked off. If the PR is merged but the issue has no test plan comment, flag it before closing.

### 7g. Universal Template Review

Scan the session for universal candidates.

For each candidate: "I noticed [X] this session. This feels like a universal pattern. Want to promote it to the master template?"

If Tim confirms → run promotion protocol.
If Tim declines or defers → note it in OPEN_ITEMS.md as a future candidate.

### 7h. SESSION_RULES Edits Must Propagate to MASTER_TEMPLATE Immediately

**Whenever the session rules are edited in a session, apply the same change to MASTER_TEMPLATE.md §2 in the same session.**

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

**One question at a time.** Never stack multiple questions in a single message to Tim. Ask the most important one, wait for the answer, then proceed.

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
- **Deploy:** GitHub Pages → getthehayout.com. Claude Code handles all deploys.
- **Branching:** `dev` branch for work, `main` for production.
- **Devices:** Mac + iPhone Safari
- **Session rules:** `CLAUDE.md` in repo root governs Claude Code sessions. This file governs Cowork design sessions.

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

When Tim asks "what should we build next?" — surface the Session Queue first, then evaluate new proposals against the four feature questions in §9.
