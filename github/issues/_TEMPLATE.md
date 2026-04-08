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
<!-- Comma-separated. See LABELS.md for the full protocol. Use the app category mapping for feedback-sourced issues.
     Type: bug | feature | enhancement | ui-polish | critical | refactor | schema | question
     Area: area:home | area:animals | area:events | area:feed | area:pastures | area:harvest | area:field-mode | area:reports | area:todos | area:settings | area:sync
     Priority: priority:high | priority:medium | priority:low (critical type = implicit highest)
     Source: from:app-feedback | from:design-session
     Status: ready-for-dev | needs-spec | in-progress | blocked | resolved -->

## Linked Feedback
<!-- If this issue originated from in-app feedback, list the IDs here. These are used by the release manifest to auto-resolve feedback items after deploy. Leave blank if not from feedback. -->
- **Feedback ID(s):** <!-- e.g., 1712345678, 1712345679 -->
- **OI Number(s):** <!-- e.g., OI-0042, OI-0043 -->
- **Submitter(s):** <!-- e.g., "John (ranch hand)" — helps contextualize the issue -->

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
