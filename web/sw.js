// PickleTrack PWA Service Worker
// Caches the app shell for instant loads and offline access.

const CACHE_NAME = 'pickletrack-v1';

const APP_SHELL = [
  '/pickletrack/',
  '/pickletrack/index.html',
  '/pickletrack/manifest.json',
  '/pickletrack/flutter_bootstrap.js',
  '/pickletrack/icons/Icon-192.png',
  '/pickletrack/icons/Icon-512.png',
  '/pickletrack/favicon.png',
];

// Install: cache the app shell immediately
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

// Activate: clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

// Fetch: network-first, fall back to cache
self.addEventListener('fetch', (event) => {
  event.respondWith(
    fetch(event.request)
      .then((response) => {
        // Cache fresh responses for future offline use
        if (response.status === 200) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
        }
        return response;
      })
      .catch(() => caches.match(event.request))
  );
});
