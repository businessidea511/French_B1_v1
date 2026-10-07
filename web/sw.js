// PolyLearn offline support.
// - The app itself (index.html, main.dart.js…): network first, so updates
//   arrive at once; the saved copy is used when there is no internet, or
//   when the network is too slow (no answer in 4 s).
// - Other app files and Google-hosted engine/fonts: saved copy first.
// - /api/translate (shared translations, GET): network first, saved copy offline.
// - The rest of /api (AI, duels) and Supabase are never cached.
const CACHE = 'polylearn-offline-v3';
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
const SLOW_NETWORK_MS = 4000;
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

async function networkFirst(request, ignoreSearch = true, slowMs = 0) {
  const cache = await caches.open(CACHE);
  const savedCopy = async () =>
    (await cache.match(request, { ignoreSearch })) ||
    (request.mode === 'navigate' ? await cache.match('index.html') : undefined);
  const network = fetch(request).then((response) => {
    if (response.ok) cache.put(request, response.clone());
    return response;
  });
  if (slowMs > 0) {
    // Slow network: open the saved copy now; the download keeps going and
    // refreshes the saved copy for next time.
    const slow = new Promise((resolve) => setTimeout(resolve, slowMs, 'slow'));
    const first = await Promise.race([network.catch(() => 'failed'), slow]);
    if (first !== 'slow' && first !== 'failed') return first;
    const saved = await savedCopy();
    if (saved) return saved;
  }
  try {
    return await network;
  } catch (e) {
    const saved = await savedCopy();
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
    event.respondWith(appFile ? networkFirst(request, true, SLOW_NETWORK_MS) : cacheFirst(request));
  } else if (CDN.test(request.url)) {
    event.respondWith(cacheFirst(request));
  }
});
