// ══════════════════════════════════════════════════════════════════════════════
// GTHY Admin Submissions Edge Function
// Deploy: supabase/functions/admin-submissions/index.ts
//
// Required env vars (Supabase Dashboard → Edge Functions → Secrets):
//   ADMIN_SECRET          — generate with: uuidgen  (you hold this, never commit)
//   SUPABASE_SERVICE_ROLE_KEY — from Dashboard → Settings → API → service_role
//   SUPABASE_URL          — auto-injected by Supabase runtime
//
// Actions (all require X-Admin-Secret header matching ADMIN_SECRET):
//   GET  ?action=list      — all submissions cross-tenant, with optional filters
//   PATCH ?action=respond  — write dev_response, append thread entry
//   PATCH ?action=update   — edit cat/type/status/area/priority/oi_number
//   DELETE ?action=delete  — hard delete by id (body: { id })
// ══════════════════════════════════════════════════════════════════════════════

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type, x-admin-secret',
  'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
}

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS, 'Content-Type': 'application/json' },
  })
}

Deno.serve(async (req) => {
  // Preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS })
  }

  // ── Auth ────────────────────────────────────────────────────────────────────
  const secret = req.headers.get('x-admin-secret')
  if (!secret || secret !== Deno.env.get('ADMIN_SECRET')) {
    return json({ error: 'Unauthorized' }, 401)
  }

  // ── Service-role client (bypasses RLS for cross-tenant reads) ───────────────
  const sb = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } }
  )

  const url    = new URL(req.url)
  const action = url.searchParams.get('action') || 'list'

  try {
    // ── LIST ──────────────────────────────────────────────────────────────────
    if (action === 'list') {
      let q = sb.from('submissions').select('*').order('ts', { ascending: false })

      const p = (k: string) => url.searchParams.get(k) || null
      if (p('type'))         q = q.eq('type',         p('type')!)
      if (p('cat'))          q = q.eq('cat',          p('cat')!)
      if (p('status'))       q = q.eq('status',       p('status')!)
      if (p('area'))         q = q.eq('area',         p('area')!)
      if (p('priority'))     q = q.eq('priority',     p('priority')!)
      if (p('operation_id')) q = q.eq('operation_id', p('operation_id')!)

      const { data, error } = await q
      if (error) throw error
      return json({ data })
    }

    // ── RESPOND ───────────────────────────────────────────────────────────────
    if (action === 'respond' && req.method === 'PATCH') {
      const { id, dev_response, append_thread = true } = await req.json()
      if (!id || !dev_response) throw new Error('id and dev_response required')

      // Fetch current thread + first_response_at
      const { data: cur, error: fetchErr } = await sb
        .from('submissions')
        .select('thread, first_response_at')
        .eq('id', id)
        .single()
      if (fetchErr) throw fetchErr

      const thread: object[] = Array.isArray(cur.thread) ? cur.thread : []
      if (append_thread) {
        thread.push({
          role:   'dev',
          text:   dev_response,
          ts:     new Date().toISOString(),
          author: 'developer',
        })
      }

      const update: Record<string, unknown> = {
        dev_response,
        dev_response_ts: new Date().toISOString(),
        thread,
      }
      if (!cur.first_response_at) {
        update.first_response_at = new Date().toISOString()
      }

      const { error } = await sb.from('submissions').update(update).eq('id', id)
      if (error) throw error
      return json({ ok: true })
    }

    // ── UPDATE (cat / type / status / area / priority / oi_number) ────────────
    if (action === 'update' && req.method === 'PATCH') {
      const body = await req.json()
      const { id, ...rest } = body
      if (!id) throw new Error('id required')

      const ALLOWED = new Set([
        'cat', 'type', 'status', 'area', 'priority', 'oi_number',
        // Allow dev_response + thread via this path too (for direct edits)
        'dev_response', 'dev_response_ts', 'thread',
      ])
      const update: Record<string, unknown> = {}
      for (const [k, v] of Object.entries(rest)) {
        if (ALLOWED.has(k)) update[k] = v
      }
      if (!Object.keys(update).length) throw new Error('No valid fields to update')

      const { error } = await sb.from('submissions').update(update).eq('id', id)
      if (error) throw error
      return json({ ok: true })
    }

    // ── DELETE ────────────────────────────────────────────────────────────────
    if (action === 'delete' && req.method === 'DELETE') {
      const { id } = await req.json()
      if (!id) throw new Error('id required')

      const { error } = await sb.from('submissions').delete().eq('id', id)
      if (error) throw error
      return json({ ok: true })
    }

    return json({ error: `Unknown action: ${action}` }, 400)

  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err)
    return json({ error: msg }, 500)
  }
})
