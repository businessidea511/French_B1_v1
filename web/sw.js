// PolyLearn offline support.
// - The app itself (index.html, main.dart.js…): network first, so updates
//   arrive at once; the saved copy is used when there is no internet.
// - Other app files and Google-hosted engine/fonts: saved copy first.
// - /api/translate (shared translations, GET): network first, saved copy offline.
// - The rest of /api (AI, duels) and Supabase are never cached.
const CACHE = 'polylearn-offline-v2';
const SHELL = [
  './',
  'index.html',
  'main.dart.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  'assets/assets/logo.png',
];
const NETWORK_FIRST = /(\/|index\.html|main\.dart\.js|flutter_bootstrap\.js|manifest\.json|version\.json)$/;
const CDN = /^https:\/\/(www\.gstatic\.com|fonts\.gstatic\.com|fonts\.googleapis\.com)\//;

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE).then((cache) =>
      Promise.all(SHELL.map((url) => cache.add(new Request(url, { cache: 'reload' })).catch(() => {}))),
    ),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim()),
  );
});

async function networkFirst(request, ignoreSearch = true) {
  const cache = await caches.open(CACHE);
  try {
    const response = await fetch(request);
    if (response.ok) cache.put(request, response.clone());
    return response;
  } catch (e) {
    const saved =
      (await cache.match(request, { ignoreSearch })) ||
      (request.mode === 'navigate' ? await cache.match('index.html') : undefined);
    if (saved) return saved;
    throw e;
  }
}

async function cacheFirst(request) {
  const cache = await caches.open(CACHE);
  const saved = await cache.match(request);
  if (saved) return saved;
  const response = await fetch(request);
  if (response.ok || response.type === 'opaque') cache.put(request, response.clone());
  return response;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin === self.location.origin) {
    // Shared translations: the latest when online, the saved copy offline.
    if (url.pathname === '/api/translate') {
      event.respondWith(networkFirst(request, false));
      return;
    }
    if (url.pathname.startsWith('/api/')) return;
    const appFile = request.mode === 'navigate' || NETWORK_FIRST.test(url.pathname);
    event.respondWith(appFile ? networkFirst(request) : cacheFirst(request));
  } else if (CDN.test(request.url)) {
    event.respondWith(cacheFirst(request));
  }
});
