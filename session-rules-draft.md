# Session Rules — GTHO v1 Documentation Project

## About Tim

Tim is a farmer and non-developer who builds with Claude. He makes the design and architecture decisions. He doesn't need code-level detail unless he asks for it. Explain the "why" behind recommendations, not just the "what."

Keep responses phone-friendly and scannable. One question at a time — never stack multiple questions in one message. Plain language, no jargon without explanation.

## Project Goal

Document the v1 GTHO app thoroughly and accurately so nothing gets missed in the v2 rebuild. The first v2 attempt spec'd only 14 of 38 production tables because the documentation was done from memory and design intent rather than from the actual codebase. This time, work from the production schema and code, not from what we think is there.

**Get The Hay Out (GTHO)** is a grazing management PWA. The core concept: a pasture's fertility is a ledger. Every grazing event, bale grazing session, feed delivery, and amendment is a transaction. Metrics like NPK balance, DMI, cost, and rest days are derived by replaying the ledger.

## How We Work

### Present options, not solutions

When you find something that needs a decision — a workaround that should be fixed, a table that could be consolidated, a naming inconsistency — present the options and let Tim choose. Don't default to a recommendation without showing the tradeoffs.

### Fix root causes, not symptoms

When something looks wrong in the v1 schema or code, identify the root cause. Don't paper over it. Present: (1) what the root cause fix looks like, (2) what a workaround would look like and what it sacrifices. Let Tim choose.

### One thing at a time

When there are multiple decisions to make, go through them one at a time. Don't dump a list of 8 questions. Present the first decision, get an answer, move on.

### Be thorough — work from evidence, not assumptions

The whole reason for this project is that the first pass missed too much. For every table, screen, feature, or calculation:
- Read the actual code and schema, don't assume
- Cross-reference: if the schema has a column, find where it's used in the code
- If something seems unused, check before calling it dead
- Count things. "About 25 tables" is not good enough — the exact number matters

### Verify before writing

Always read a file before overwriting it. Other sessions may have added content. Merge, don't replace.

## Feature Filter

Every feature in GTHO must answer at least one of these:
1. Does this help the farmer record a fertility transaction accurately?
2. Does this help the farmer see the current fertility balance of each paddock?
3. Does this help the farmer make a better grazing decision today?
4. Does this help the farmer see season-over-season trends?

Use this filter when evaluating what's worth documenting in detail vs what's peripheral.

## Documentation Standards

### What good documentation looks like for this project

For each table/entity:
- Every column, its type, whether it's nullable, what it's for
- FK relationships — what it references, what references it
- Where in the code it's created, read, updated, deleted
- What screen(s) display or edit it
- Any workarounds or anti-patterns (JSONB bags, denormalized snapshots, stored computed values, type mismatches)
- The "v2 recommendation" — how it should be built if we were starting clean

For each screen/feature:
- What it does from the user's perspective
- Which tables it reads and writes
- Any calculations it performs
- Known bugs or limitations

### What we already have

Reference docs from the v2 attempt (use as starting points, not gospel):
- **v2-table-gap-and-schema-audit.md** — maps all 38 v1 tables, flags anti-patterns, includes 8 design decisions Tim already made
- **ARCHITECTURE.md** (v2 repo) — has some entity specs but missed 26 tables
- **CALCULATION_REGISTRY.md** (v2 repo) — documents DMI and NPK formulas

### Design decisions already made

These 8 decisions were made during the gap audit and apply to v2:
1. No denormalized name snapshots — link by FK, display from entity cache
2. event_paddock_windows and event_group_memberships are separate ledgers (acreage axis and animal axis for NPK)
3. paddock_observations merged with surveys — one table, source field
4. animal_health mega-table split into separate tables (BCS, treatments, breeding, calving)
5. NPK deposits computed on demand, not stored
6. Settings as columns on operations table, not a separate table
7. input_applications merged into amendments
8. survey_ratings child table — parent survey + per-pasture child records

## v1 Technical Context

- **App:** Single-file PWA, `index.html` (~14,500 lines of HTML/CSS/JS)
- **Backend:** Supabase (38 production tables, 5 flush tiers)
- **Repo:** `~/Github/get-the-hay-out`
- **Live:** getthehayout.com
- **Schema CSV:** `Supabase_Snippet_List_Public_Tables_and_Columns3.csv` (the production schema export — treat as source of truth for what actually exists)

## Session Protocol

### Starting a session
1. Check if there are open items or unfinished work from previous sessions
2. Confirm the focus area before diving in
3. If Tim uploads a file (schema CSV, screenshot, etc.), read it before proceeding

### Ending a session
1. Summarize what was documented or decided
2. Flag any open questions that need Tim's input next time
3. Save deliverables to the workspace so Tim can access them
