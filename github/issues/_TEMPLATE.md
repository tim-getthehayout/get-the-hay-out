# Issue Template — GTHY

Use this template when speccing features or bugs in Cowork for handoff to Claude Code.

## Workflow

1. **Cowork** creates a spec file in `github/issues/` (e.g., `add-weight-tracking.md`)
2. **Claude Code** picks it up and runs:
   ```
   gh issue create --title "TITLE" --body "$(cat github/issues/FILENAME.md)" --label "LABEL"
   ```
3. **Claude Code** renames the file with the issue number:
   `add-weight-tracking.md` → `GH-42_add-weight-tracking.md`

## File naming convention

- **No `GH-` prefix** → new spec, needs a GitHub issue created
- **`GH-{number}_` prefix** → already filed, linked to that issue number
- Claude Code should process all files without a `GH-` prefix and rename them after filing

---

## Title
<!-- Short, imperative: "Add batch weight tracking" not "Batch weight tracking feature" -->

## Type
<!-- feature | bug | enhancement | refactor -->

## Labels
<!-- Comma-separated: feature, ready-for-dev, screen:events, priority:high -->

## Context
<!-- Why does this matter? What problem does it solve? Link to any Claude.ai design session notes. -->

## Requirements
<!-- What must be true when this is done? Be specific. -->

- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

## Technical Notes
<!-- Architecture details, affected functions, Supabase changes, known traps. Reference ARCHITECTURE.md sections. -->

### Affected Areas
- **Screen(s):**
- **Function(s):**
- **Supabase table(s):**
- **New columns needed:** (if yes, include ALTER TABLE SQL)

### CLAUDE.md Checklist
<!-- Which rules from CLAUDE.md apply to this change? -->
- [ ] queueWrite for all mutations
- [ ] bumpSetupUpdatedAt if setup arrays change
- [ ] Backup/restore congruence check
- [ ] New UI field → Supabase column (all 5 steps)
- [ ] Syntax check before deploy

## Acceptance Criteria
<!-- How do we know it's done? -->

1. ...
2. ...
3. ...

## Open Questions
<!-- Anything unresolved that Claude Code should flag before implementing -->
