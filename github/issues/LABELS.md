# GitHub Label Protocol — GTHY

Labels are aligned with the in-app feedback categories so issues flow seamlessly from user feedback through to resolution.

## Setup command

Run in Claude Code to create all labels on the repo:

```bash
# Type labels (aligned with app f.cat values)
gh label create "bug" --color "d73a4a" --description "Something broken (app cat: bug, calc)" --force
gh label create "feature" --color "a2eeef" --description "New functionality (app cat: feature)" --force
gh label create "enhancement" --color "7057ff" --description "Improvement to existing feature (app cat: idea)" --force
gh label create "ui-polish" --color "f9d0c4" --description "Visual/layout/UX tweak (app cat: ux)" --force
gh label create "critical" --color "b60205" --description "Blocks field testing — fix immediately (app cat: roadblock)" --force
gh label create "refactor" --color "d4c5f9" --description "Code cleanup, tech debt, architecture" --force
gh label create "schema" --color "0e8a16" --description "Supabase/database changes" --force
gh label create "session-brief" --color "c5def5" --description "Spec from a design session" --force
gh label create "question" --color "d876e3" --description "Needs clarification (app cat: question)" --force

# Priority labels
gh label create "priority:high" --color "e11d48" --description "Important, do soon" --force
gh label create "priority:medium" --color "f97316" --description "Normal priority" --force
gh label create "priority:low" --color "6b7280" --description "Nice to have" --force

# Area labels (aligned with app f.area values)
gh label create "area:home" --color "bfdadc" --description "Home screen" --force
gh label create "area:animals" --color "bfdadc" --description "Animals screen" --force
gh label create "area:events" --color "bfdadc" --description "Events screen" --force
gh label create "area:feed" --color "bfdadc" --description "Feed management" --force
gh label create "area:pastures" --color "bfdadc" --description "Pastures screen" --force
gh label create "area:harvest" --color "bfdadc" --description "Harvest screen" --force
gh label create "area:field-mode" --color "bfdadc" --description "Field mode" --force
gh label create "area:reports" --color "bfdadc" --description "Reports screen" --force
gh label create "area:todos" --color "bfdadc" --description "Todos screen" --force
gh label create "area:settings" --color "bfdadc" --description "Settings screen" --force
gh label create "area:sync" --color "bfdadc" --description "Supabase sync" --force

# Status labels
gh label create "ready-for-dev" --color "0e8a16" --description "Spec complete, Claude Code can pick this up" --force
gh label create "needs-spec" --color "fbca04" --description "Needs more design work in Cowork" --force
gh label create "in-progress" --color "1d76db" --description "Actively being worked on" --force
gh label create "blocked" --color "b60205" --description "Waiting on something" --force
gh label create "resolved" --color "0e8a16" --description "Fix deployed, awaiting user confirmation in app" --force

# Source labels
gh label create "from:app-feedback" --color "ededed" --description "Originated from in-app feedback submission" --force
gh label create "from:design-session" --color "ededed" --description "Originated from Cowork/Claude.ai design session" --force
```

## App category → GitHub label mapping

| App `f.cat` | GitHub type label | OI Severity | Priority label |
|---|---|---|---|
| `roadblock` | `critical` | Roadblock | (implicit — always highest) |
| `bug` | `bug` | Bug | `priority:high` |
| `calc` | `bug` | Bug | `priority:high` |
| `ux` | `ui-polish` | Polish | `priority:medium` |
| `feature` | `feature` | Enhancement | `priority:medium` |
| `idea` | `enhancement` | Enhancement | `priority:low` |
| `question` | `question` | — (no OI) | — |

## App area → GitHub label mapping

| App `f.area` | GitHub label |
|---|---|
| `home` | `area:home` |
| `animals` | `area:animals` |
| `events` | `area:events` |
| `feed` | `area:feed` |
| `pastures` | `area:pastures` |
| `harvest` | `area:harvest` |
| `field-mode` | `area:field-mode` |
| `reports` | `area:reports` |
| `todos` | `area:todos` |
| `settings` | `area:settings` |
| `sync` | `area:sync` |

## Label rules

- Every issue gets exactly **one type label** (bug, feature, enhancement, etc.)
- Every issue gets **one area label** if it maps to a specific screen
- **Priority labels** are optional — `critical` type label implies highest priority
- **Source labels** track where the issue originated
- **Status labels** track workflow state (managed by Claude Code)
- Issues from app feedback always get `from:app-feedback` plus the mapped type and area
