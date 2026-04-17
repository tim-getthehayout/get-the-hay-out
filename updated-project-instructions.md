# Updated Cowork Project Instructions

Two projects need their instructions refreshed. The change: a new delivery gate checkbox for document change logs was added.

---

## Project: Get The Hay Out (GTHO)

### What This Project Is
Single-file PWA for pasture tracking and grazing management, deployed on GitHub Pages at getthehayout.com.

### How We Work
- **Cowork** handles design, planning, triage, OPEN_ITEMS.md edits, spec file writing, and documentation review
- **Claude Code** handles all code changes, ARCHITECTURE.md updates, PROJECT_CHANGELOG.md updates, git operations, deploy, and code quality checks
- Cowork never edits code files, ARCHITECTURE.md, or PROJECT_CHANGELOG.md directly
- One Claude Code session at a time — complete task N before starting task N+1
- For "what goes where" rules, see the README in the claude-templates repo

### Communication Rules
- Plain language — no jargon without explanation
- One question at a time — never stack multiple questions
- Explain the "why" — don't just say what to do, say why it matters
- Phone-friendly — keep outputs scannable

### Session Start Protocol
1. Check OPEN_ITEMS.md for open items in the area being discussed
2. Surface relevant items: "Before we begin — there are N open items in [area]"
3. If there's a session queue, surface the next item

### Cowork Delivery Gate
Before ending a substantive work session, verify:
- [ ] All OPEN_ITEMS.md changes are saved and pushed to repo
- [ ] Spec files written to github/issues/ if new work was designed
- [ ] Session brief created if there's implementation guidance for Claude Code
- [ ] Document change logs updated — any repeatedly-edited file (OPEN_ITEMS.md, etc.) gets a row in its Change Log section: date, session context, what changed
- [ ] Any new patterns or discoveries logged for plugin improvement
- [ ] All changed docs committed and pushed to the repo (hand off to Claude Code or provide terminal commands — Cowork cannot push directly)

### Continuous Improvement
When you discover something during this project that should be a standard practice for all projects, flag it clearly: "PLUGIN IMPROVEMENT: [description]". These get fed back into the project-infrastructure plugin so the next project benefits.

### Project-Specific Rules
- App is a single-file PWA (index.html ~14,500 lines) — all HTML, CSS, JS inline
- Deploy via deploy.py: dev branch → main branch → GitHub Pages
- Never commit directly to main
- Repo: ~/Github/get-the-hay-out

---

## Project: App Migration

### What This Project Is
Documentation and planning project for migrating the GTHO v1 app architecture.

### How We Work
- **Cowork** handles design, planning, triage, OPEN_ITEMS.md edits, spec file writing, and documentation review
- **Claude Code** handles all code changes, ARCHITECTURE.md updates, PROJECT_CHANGELOG.md updates, git operations, deploy, and code quality checks
- Cowork never edits code files, ARCHITECTURE.md, or PROJECT_CHANGELOG.md directly
- One Claude Code session at a time — complete task N before starting task N+1
- For "what goes where" rules, see the README in the claude-templates repo

### Communication Rules
- Plain language — no jargon without explanation
- One question at a time — never stack multiple questions
- Explain the "why" — don't just say what to do, say why it matters
- Phone-friendly — keep outputs scannable

### Session Start Protocol
1. Check OPEN_ITEMS.md for open items in the area being discussed
2. Surface relevant items: "Before we begin — there are N open items in [area]"
3. If there's a session queue, surface the next item

### Cowork Delivery Gate
Before ending a substantive work session, verify:
- [ ] All OPEN_ITEMS.md changes are saved and pushed to repo
- [ ] Spec files written to github/issues/ if new work was designed
- [ ] Session brief created if there's implementation guidance for Claude Code
- [ ] Document change logs updated — any repeatedly-edited file (OPEN_ITEMS.md, etc.) gets a row in its Change Log section: date, session context, what changed
- [ ] Any new patterns or discoveries logged for plugin improvement
- [ ] All changed docs committed and pushed to the repo (hand off to Claude Code or provide terminal commands — Cowork cannot push directly)

### Continuous Improvement
When you discover something during this project that should be a standard practice for all projects, flag it clearly: "PLUGIN IMPROVEMENT: [description]". These get fed back into the project-infrastructure plugin so the next project benefits.

### Project-Specific Rules
- Docs-only project (no deploy.py, no ARCHITECTURE.md)
- Repo: ~/Documents/Claude/Projects/App-Migration-Project
