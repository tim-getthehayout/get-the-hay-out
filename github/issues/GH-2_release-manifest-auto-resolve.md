## Title
Release manifest with per-user feedback auto-resolve

## Type
feature

## Labels
feature, area:settings, area:sync, priority:high, from:design-session

## Linked Feedback
- **Feedback ID(s):** N/A — infrastructure feature
- **OI Number(s):** Related to OI-0138 (admin console)
- **Submitter(s):** Tim (design session)

## Context

GTHY has a full feedback loop: users submit feedback in-app → it syncs to Supabase (`submissions` table) → feedback is exported and imported into OPEN_ITEMS.md → specs are created → Claude Code implements fixes → deploys. **The missing link:** after a fix deploys, there's no automatic way to notify the original submitter that their issue was resolved or to prompt them to confirm the fix.

This feature closes that loop. When a deploy includes fixes for feedback items, the app detects it on next load and:
- For the **original submitter**: shows a confirmation prompt ("Your issue was fixed — confirm or reopen")
- For **admin users** (`isAdmin()` = true): also sees anonymous/null-submitter items that need confirmation
- For **all other non-submitter users**: silently auto-closes the item (dev already verified before deploying)

### The full integrated loop after this feature:
1. User submits feedback in app → `S.feedback[]` + Supabase `submissions`
2. Cowork imports feedback → creates OI entries in OPEN_ITEMS.md → writes spec to `github/issues/`
3. Claude Code creates GitHub issue from spec (with `f.id`, `oiNumber`, and labels from `github/issues/LABELS.md`)
4. Claude Code implements fix and deploys
5. **Claude Code calls the existing `admin-submissions` edge function** to write a release manifest
6. **App detects new version** → reads manifest → routes items by submitter
7. Submitter confirms or reopens → loop closed

## Requirements

- [ ] New Supabase table `release_notes` stores per-deploy manifest
- [ ] New action `resolve-release` added to existing `admin-submissions` edge function
- [ ] Claude Code calls edge function after each deploy that resolves feedback items
- [ ] App checks for new release manifest entries on version change detection
- [ ] Feedback items where `submitterId === current user` → show confirmation prompt
- [ ] Feedback items where `submitterId` is null/anonymous AND `isAdmin()` → show confirmation prompt to admin
- [ ] Feedback items where `submitterId !== current user` AND NOT admin → auto-close silently
- [ ] Auto-closed items set `resolvedInVersion`, `resolutionNote`, `resolvedAt`, `confirmedBy='auto-closed'`, and `status = 'closed'`
- [ ] Submitter-prompted items set `status = 'resolved'` (existing confirm/reopen flow handles the rest)
- [ ] All status changes sync to Supabase via `queueWrite`

## Technical Notes

### Existing infrastructure (from SESSION_SUMMARY_b20260401)

The `admin-submissions` Supabase Edge Function is **already deployed** with:
- Auth via `X-Admin-Secret` header (UUID env var, pasted at session start)
- `SUPABASE_SERVICE_ROLE_KEY` held server-side as env var
- JWT verification toggled OFF (auth handled by admin secret)
- Existing actions: `list` (GET), `respond` (PATCH), `update` (PATCH), `delete` (DELETE)
- The `gthy-feedback-batch-resolve.html` tool already demonstrated bulk-resolving 45 items via this edge function

The admin console (`gthy-admin-console.html`) runs locally and connects via the same edge function.

### New Supabase table: `release_notes`

```sql
CREATE TABLE release_notes (
  id              bigserial PRIMARY KEY,
  operation_id    uuid NOT NULL DEFAULT gen_random_uuid(),
  version         text NOT NULL,               -- build stamp, e.g. 'b20260408.1200'
  resolved_items  jsonb NOT NULL DEFAULT '[]',  -- array of resolved item objects
  notes           text,                         -- optional human-readable release notes
  created_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE release_notes ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read release notes (app needs this for checkReleaseUpdates)
CREATE POLICY "release_notes_select" ON release_notes
  FOR SELECT TO authenticated USING (true);

-- Inserts only via edge function (service role key bypasses RLS)
-- No INSERT policy needed for authenticated users — edge function uses service role
```

### `resolved_items` JSONB structure

```json
[
  {
    "feedbackId": 1712345678,
    "oiNumber": "OI-0042",
    "ghIssue": 15,
    "note": "Fixed sync failure on batch move"
  }
]
```

### New edge function action: `resolve-release`

Add to the existing `admin-submissions/index.ts`:

```
PATCH ?action=resolve-release
Header: X-Admin-Secret: <admin-secret>
Body: {
  "version": "b20260408.1200",
  "resolved_items": [
    { "feedbackId": 1712345678, "oiNumber": "OI-0042", "ghIssue": 15, "note": "Fixed sync on batch move" }
  ],
  "notes": "Optional human-readable release notes"
}
```

**Edge function logic for this action:**
1. Validate admin secret (existing pattern)
2. For each item in `resolved_items`:
   - UPDATE `submissions` SET `status = 'resolved'`, `resolved_in_version = version`, `resolution_note = item.note` WHERE `id = item.feedbackId`
3. INSERT into `release_notes` (version, resolved_items JSONB, notes)
4. Return `{ updated: N, releaseNoteId: id }`

**Why use the existing edge function:** The `admin-submissions` function already has the service role client, CORS headers, and admin secret validation. Adding one action is ~20 lines. No new deployment infrastructure.

### Affected Areas
- **Screen(s):** Feedback screen (confirmation UI), app-wide (version check on load)
- **Function(s):**
  - NEW: `checkReleaseUpdates()` — runs on app load when version changes
  - MODIFY: `admin-submissions/index.ts` — add `resolve-release` action
  - MODIFY: `initApp()` or wherever version change is detected — call `checkReleaseUpdates()`
  - EXISTING: `confirmFixed(id)` — unchanged, handles submitter confirmation
  - EXISTING: `reopenIssue(id)` — unchanged, handles submitter reopen
  - EXISTING: `isAdmin()` — used to route anonymous items to admin
- **Supabase table(s):** `release_notes` (new), `submissions` (existing — status updates via edge function)
- **New columns needed:** None on existing tables. New table `release_notes` (SQL above).

### `checkReleaseUpdates()` logic

```
function checkReleaseUpdates():
  1. Get current app version from <meta name="app-version">
  2. Get last-checked version from localStorage key 'lastCheckedReleaseVersion'
  3. If same → return (no update)
  4. Query release_notes where version > lastCheckedVersion, ordered by created_at
     (Use existing Supabase anon client — RLS allows SELECT for authenticated users)
  5. For each release note:
     a. For each resolved_item in resolved_items:
        - Find matching feedback item in S.feedback by feedbackId
        - If not found → skip (item may belong to a different operation)
        - If f.status is already 'closed' → skip
        - ROUTING LOGIC:
          A. If f.submitterId === _sbSession?.user?.id:
              → Set f.status = 'resolved'
              → Set f.resolvedInVersion = releaseNote.version
              → Set f.resolutionNote = resolved_item.note
              → Set f.resolvedAt = new Date().toISOString()
              → queueWrite('submissions', _submissionRow(f, _sbOperationId))
              → Add to pendingConfirmations[]
          B. Else if (f.submitterId is null or undefined) AND isAdmin():
              → Same as A (admin reviews anonymous items)
              → Add to pendingConfirmations[]
          C. Else (different user, not admin, or anonymous with non-admin):
              → Set f.status = 'closed'
              → Set f.resolvedInVersion = releaseNote.version
              → Set f.resolutionNote = resolved_item.note
              → Set f.resolvedAt = new Date().toISOString()
              → Set f.confirmedBy = 'auto-closed'
              → Set f.confirmedAt = new Date().toISOString()
              → queueWrite('submissions', _submissionRow(f, _sbOperationId))
  6. save()
  7. Set localStorage 'lastCheckedReleaseVersion' = current version
  8. If pendingConfirmations.length > 0:
     → Show toast: "{N} of your reported issues were fixed in this update"
     → Optionally navigate to feedback screen filtered to status='resolved'
```

### Claude Code post-deploy workflow

After `deploy.py deploy` or `deploy.py release`, Claude Code should:

1. Check if any OI items or feedback IDs were resolved in this deploy (from the changelog, commit messages, or spec files)
2. Build the `resolved_items` array with feedbackId, oiNumber, ghIssue number, and fix note
3. Call the edge function:
   ```bash
   curl -X PATCH \
     "https://oihivpwftpngbhwpjsqt.supabase.co/functions/v1/admin-submissions?action=resolve-release" \
     -H "X-Admin-Secret: $ADMIN_SECRET" \
     -H "Content-Type: application/json" \
     -d '{
       "version": "b20260408.1200",
       "resolved_items": [...],
       "notes": "Fixed sync on batch move and feed calc"
     }'
   ```
4. The `ADMIN_SECRET` must be available to Claude Code. Options:
   - Environment variable on Tim's Mac (e.g., in `.zshrc` or `.env` — **not committed to repo**)
   - Prompted at deploy time (Claude Code asks for it)
   - Stored in a local config file excluded by `.gitignore`

### CLAUDE.md Checklist
- [ ] queueWrite for all mutations (each feedback status change in checkReleaseUpdates must queueWrite)
- [ ] bumpSetupUpdatedAt — NO, feedback is not a setup array
- [ ] Backup/restore congruence check — `release_notes` is read-only from the app (queried from Supabase on demand, not stored in S). No ensureDataArrays change needed.
- [ ] New UI field → Supabase column (all 5 steps) — new table, not new column on existing table
- [ ] Syntax check before deploy

## Acceptance Criteria

1. The `admin-submissions` edge function accepts `?action=resolve-release` and writes to both `submissions` and `release_notes`
2. After a deploy that fixes feedback items, Claude Code calls the edge function to create a release manifest
3. When the **original submitter** opens the app after the deploy, they see a toast prompting confirmation
4. The submitter can confirm (→ closed) or reopen (→ new linked feedback item) using existing UI
5. **Anonymous/null-submitter items** appear in the admin's (Tim's) confirmation queue
6. **Other non-submitter users** see those items silently auto-closed
7. All status changes sync to Supabase via queueWrite
8. The feedback screen correctly shows updated statuses after the check runs
9. No duplicate processing — items already closed are skipped, `lastCheckedReleaseVersion` prevents re-processing
10. Multiple accumulated deploys are processed in order if the user hasn't opened the app between them

## Implementation Order

1. **Create `release_notes` table** — run SQL migration
2. **Add `resolve-release` action to `admin-submissions` edge function** — redeploy function
3. **Add `checkReleaseUpdates()` to app** — new function + hook into version change detection
4. **Update Claude Code post-deploy workflow** — add edge function call after `deploy.py`
5. **Test end-to-end** — submit feedback → import to OI → create issue → implement → deploy → verify submitter sees prompt

## Open Questions

1. **ADMIN_SECRET storage for Claude Code:** How should the admin secret be made available to Claude Code for the post-deploy curl call? Recommendation: environment variable in `.zshrc` (`export GTHY_ADMIN_SECRET=...`), never committed to repo.
2. **Toast vs. full banner:** Should the "your issues were fixed" notification be a simple toast, or a more prominent banner that persists until dismissed?
3. **Batch behavior:** If multiple deploys happen before a user opens the app, should all accumulated release notes be processed at once? (Recommended: yes, process all in order.)
4. **OI number writeback:** When Cowork assigns an OI number during feedback import, should it also update `f.oiNumber` in Supabase at that time? Currently `oiNumber` is only set manually via the admin console. Automating this during import would strengthen the feedback-to-issue linkage.
