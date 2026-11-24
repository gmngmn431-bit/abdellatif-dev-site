/* Service Worker — Abdellatif Dev (v3-safe) */
const CACHE_NAME = 'abdellatif-dev-cache-v3';

const PRECACHE_ASSETS = [
  './',
  'index.html',
  'i18n.json',
  'manifest.json',
  'icon.svg',
  'icon-maskable.svg',
  'icon-192.png',
  'icon-512.png',
  'icon-maskable-192.png',
  'icon-maskable-512.png'
];

function isBypassedUrl(url) {
  const u = new URL(url);
  const path = u.pathname.toLowerCase();

  // 1. استثناء صفحات الإدارة تماماً
  if (path.includes('admin.html') || path.includes('/admin')) return true;

  // 2. استثناء استدعاءات Supabase والمصادقة
  if (u.hostname.includes('supabase.co')) {
    if (path.includes('/auth/') || path.includes('/rest/v1/profiles') || path.includes('/functions/v1/')) {
      return true;
    }
  }

  // 3. استثناء ملفات التحميل الضخمة لتجنب استهلاك مساحة التخزين
  if (/\.(apk|xapk|zip|exe|msi|rar|7z|tar\.gz|apks|apkm)$/i.test(path)) {
    return true;
  }

  return false;
}

self.addEventListener('install', (event) => {
  self.skipWaiting();
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS).catch((err) => {
        console.warn('SW: Precache partial notice (PNG icons will cache once generated):', err);
      });
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;

  if (isBypassedUrl(req.url)) {
    return; // تمرير مباشر للشبكة
  }

  event.respondWith(
    caches.match(req).then((cachedResponse) => {
      const fetchPromise = fetch(req).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => {
            cache.put(req, responseToCache);
          });
        }
        return networkResponse;
      }).catch(() => cachedResponse);

      return cachedResponse || fetchPromise;
    })
  );
});