-- ============================================================================
-- RLS policies for new-user signup flow
-- Problem: New users get 403 on operations INSERT because no member row exists yet
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor > New Query)
-- ============================================================================

-- ============================================================================
-- PRE-FLIGHT CHECKS — run these SELECT queries first to see what you have
-- ============================================================================

-- 1. Check existing RLS status on both tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('operations', 'operation_members');

-- 2. Check existing policies (so you don't create duplicates)
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('operations', 'operation_members')
ORDER BY tablename, policyname;

-- ============================================================================
-- After reviewing the output above, run the statements below.
-- Skip any policy that already exists (matching name or equivalent logic).
-- ============================================================================

-- ── operations table ────────────────────────────────────────────────────────

-- Enable RLS (safe to run even if already enabled)
ALTER TABLE operations ENABLE ROW LEVEL SECURITY;

-- INSERT: Any authenticated user can create an operation they own
CREATE POLICY "Users can create their own operation"
ON operations FOR INSERT
TO authenticated
WITH CHECK (owner_id = auth.uid());

-- SELECT: Users can read operations they belong to
CREATE POLICY "Members can read their operation"
ON operations FOR SELECT
TO authenticated
USING (
  id IN (
    SELECT operation_id FROM operation_members
    WHERE user_id = auth.uid()
  )
);

-- UPDATE: Only the owner can update their operation
CREATE POLICY "Owner can update their operation"
ON operations FOR UPDATE
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());


-- ── operation_members table ─────────────────────────────────────────────────

-- Enable RLS (safe to run even if already enabled)
ALTER TABLE operation_members ENABLE ROW LEVEL SECURITY;

-- INSERT: Users can create their own member row (bootstrap) OR
--         admins/owners can invite (insert with NULL user_id)
CREATE POLICY "Users can create own member row or admins can invite"
ON operation_members FOR INSERT
TO authenticated
WITH CHECK (
  -- Self-bootstrap: creating your own member row
  user_id = auth.uid()
  OR
  -- Admin invite: inserting a pending row (user_id is NULL)
  -- Caller must be owner/admin of the target operation
  (
    user_id IS NULL
    AND operation_id IN (
      SELECT operation_id FROM operation_members
      WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
    )
  )
);

-- SELECT: Members can see other members of their operation
CREATE POLICY "Members can read their operation members"
ON operation_members FOR SELECT
TO authenticated
USING (
  operation_id IN (
    SELECT operation_id FROM operation_members
    WHERE user_id = auth.uid()
  )
);

-- UPDATE: Users can update their own row; admins can update any row in their operation
CREATE POLICY "Members can update own row or admins can update any"
ON operation_members FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
  OR operation_id IN (
    SELECT operation_id FROM operation_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  )
)
WITH CHECK (
  user_id = auth.uid()
  OR operation_id IN (
    SELECT operation_id FROM operation_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  )
);

-- DELETE: Admins can remove members (not themselves) from their operation
CREATE POLICY "Admins can remove members"
ON operation_members FOR DELETE
TO authenticated
USING (
  user_id != auth.uid()
  AND operation_id IN (
    SELECT operation_id FROM operation_members
    WHERE user_id = auth.uid() AND role IN ('owner', 'admin')
  )
);


-- ── claim_pending_invite RPC ────────────────────────────────────────────────
-- This function runs with SECURITY DEFINER so it bypasses RLS.
-- It lets a newly-signed-in user claim a pending invite row.
-- Check if it already exists first:
--   SELECT proname FROM pg_proc WHERE proname = 'claim_pending_invite';

CREATE OR REPLACE FUNCTION claim_pending_invite(p_email TEXT, p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE operation_members
  SET user_id = p_user_id,
      accepted_at = now()
  WHERE email = lower(p_email)
    AND user_id IS NULL;
END;
$$;
