// ─────────────────────────────────────────────────────────────────────────────
// GTHY Service Worker
//
// The cache version is derived automatically from the app version passed
// as a query parameter when registering: navigator.serviceWorker.register('/sw.js?v=v1.2')
//
// To push an update: bump S.version in Settings → the HTML embeds it as a
// <meta name="app-version"> tag → SW registration reads it → new cache name
// → old cache cleared → users get the fresh version on next open.
//
// You never need to manually edit this file to trigger an update.
// ─────────────────────────────────────────────────────────────────────────────

// Read version from our own registration URL query string (?v=v1.2)
const _swUrl    = new URL(self.location.href);
const _appVer   = _swUrl.searchParams.get('v') || 'v1.0';
const CACHE_NAME = 'gthy-' + _appVer;

// Files to precache on install
const PRECACHE_URLS = [
  '/',
  '/index.html',
];

// ── Install ──────────────────────────────────────────────────────────────────
self.addEventListener('install', event => {
  console.log('[SW] Installing cache:', CACHE_NAME);
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// ── Activate ─────────────────────────────────────────────────────────────────
// Delete every cache that isn't the current version.
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
// Network-first for HTML (always fresh when online).
// Cache-first for everything else (CDN scripts load fast offline).
self.addEventListener('fetch', event => {
  const req = event.request;
  if (req.method !== 'GET') return;
  if (!req.url.startsWith(self.location.origin)) return;

  const isNavigation = req.mode === 'navigate' ||
    (req.headers.get('accept') || '').includes('text/html');

  if (isNavigation) {
    // Network-first: always try to fetch fresh HTML
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

  // Cache-first for assets (CDN scripts, etc.)
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
self.addEventListener('message', event => {
  if (event.data === 'SKIP_WAITING') self.skipWaiting();
});
