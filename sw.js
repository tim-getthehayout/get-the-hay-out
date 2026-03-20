// ─────────────────────────────────────────────────────────────────────────────
// GTHY Service Worker
//
// Cache version is derived from the ?v= query param set at registration time.
// The SW does NOT call skipWaiting() on install — it waits for an explicit
// SKIP_WAITING message from the page so the user can back up first.
// ─────────────────────────────────────────────────────────────────────────────

const _swUrl    = new URL(self.location.href);
const _appVer   = _swUrl.searchParams.get('v') || 'v1.0';
const CACHE_NAME = 'gthy-' + _appVer;

const PRECACHE_URLS = ['/', '/index.html'];

// ── Install ──────────────────────────────────────────────────────────────────
// Cache assets but DO NOT skipWaiting — stay in 'waiting' state so the page
// can show the update banner and let the user back up before reloading.
self.addEventListener('install', event => {
  console.log('[SW] Installing cache:', CACHE_NAME);
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE_URLS))
    // No self.skipWaiting() here — wait for explicit message from page
  );
});

// ── Activate ─────────────────────────────────────────────────────────────────
self.addEventListener('activate', event => {
  console.log('[SW] Activating, clearing old caches except:', CACHE_NAME);
  event.waitUntil(
    caches.keys().then(names =>
      Promise.all(
        names
          .filter(n => n.startsWith('gthy-') && n !== CACHE_NAME)
          .map(n => {
            console.log('[SW] Deleting stale cache:', n);
            return caches.delete(n);
          })
      )
    ).then(() => self.clients.claim())
  );
});

// ── Fetch ────────────────────────────────────────────────────────────────────
// Network-first for HTML, cache-first for assets.
self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;
  if (!req.url.startsWith(self.location.origin)) return;

  const isNavigation = req.mode === 'navigate' ||
    (req.headers.get('accept') || '').includes('text/html');

  if (isNavigation) {
    event.respondWith(
      fetch(req)
        .then(res => {
          if (res.ok) {
            caches.open(CACHE_NAME).then(c => c.put(req, res.clone()));
          }
          return res;
        })
        .catch(() =>
          caches.match(req)
            .then(cached => cached || caches.match('/index.html'))
        )
    );
    return;
  }

  event.respondWith(
    caches.match(req).then(cached => {
      if (cached) return cached;
      return fetch(req).then(res => {
        if (res.ok) {
          caches.open(CACHE_NAME).then(c => c.put(req, res.clone()));
        }
        return res;
      });
    })
  );
});

// ── Message handler ──────────────────────────────────────────────────────────
// The page sends SKIP_WAITING when the user clicks "Update now".
self.addEventListener('message', event => {
  if (event.data === 'SKIP_WAITING') {
    console.log('[SW] SKIP_WAITING received — activating new version');
    self.skipWaiting();
  }
});
