## Title
Test issue — GitHub integration setup

## Type
enhancement

## Labels
test, infrastructure

## Context
Setting up a workflow where Cowork handles design and spec, and Claude Code handles implementation. GitHub Issues serves as the handoff layer between the two. This test issue verifies the flow works end-to-end.

## Requirements

- [ ] Cowork can write spec files to `github/issues/`
- [ ] Claude Code can read spec files and create GitHub issues from them
- [ ] Issues appear on the GitHub project board

## Technical Notes
No code changes — this is purely a workflow test.

## Acceptance Criteria

1. This spec file exists in `github/issues/`
2. Claude Code creates a GitHub issue from it
3. Issue is visible on the repo's Issues tab

## Open Questions
None — close this after verifying the flow.
