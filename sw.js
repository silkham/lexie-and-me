/* Lexie & Me — service worker (offline + installable PWA)
   Bump VERSION on every deploy so old caches are wiped on activate. */
const VERSION = 'build-15';
const CORE    = 'lexieme-core-'    + VERSION;
const RUNTIME = 'lexieme-runtime-' + VERSION;

/* Same-origin app shell precached on install. */
const CORE_ASSETS = [
  './', './index.html', './manifest.json',
  './icon-192.png', './icon-512.png', './apple-touch-icon.png', './icon.svg'
];

/* Cross-origin libs/fonts we runtime-cache so the app shell renders offline. */
const RUNTIME_HOSTS = ['fonts.googleapis.com', 'fonts.gstatic.com', 'cdn.jsdelivr.net', 'unpkg.com'];

/* Hosts we never intercept — always live network, fail gracefully offline. */
const BYPASS_HOSTS = ['dgbbyijhabjozqrkokrq.supabase.co', 'api.open-meteo.com'];

self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CORE).then(c => c.addAll(CORE_ASSETS)).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CORE && k !== RUNTIME).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;
  if (req.method !== 'GET') return;                       // mutations: straight to network

  const url = new URL(req.url);
  if (BYPASS_HOSTS.includes(url.hostname)) return;        // Supabase + weather: always live

  /* App shell: network-first so a fresh deploy always wins; cached copy is the offline fallback. */
  if (req.mode === 'navigate' || req.destination === 'document') {
    e.respondWith(
      fetch(req)
        .then(res => { caches.open(CORE).then(c => c.put('./index.html', res.clone())); return res; })
        .catch(() => caches.match('./index.html').then(r => r || caches.match('./')))
    );
    return;
  }

  /* Same-origin assets + known CDN libs/fonts: cache-first, fill cache on miss. */
  const sameOrigin = url.origin === self.location.origin;
  if (sameOrigin || RUNTIME_HOSTS.includes(url.hostname)) {
    e.respondWith(
      caches.match(req).then(hit => {
        if (hit) return hit;
        return fetch(req).then(res => {
          if (res && (res.ok || res.type === 'opaque')) {
            const bucket = sameOrigin ? CORE : RUNTIME;
            caches.open(bucket).then(c => c.put(req, res.clone()));
          }
          return res;
        });
      })
    );
    return;
  }

  /* Everything else (e.g. map tiles): straight to network, no caching. */
});
