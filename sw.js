/* ============================================================
   Abdellatif Dev — Service Worker (PWA v1)
   استراتيجية كاش متوازنة: Precache للملفات الأساسية،
   Stale-while-revalidate للصور، وNetwork-only لبيانات Supabase.
   ============================================================ */

const CACHE_NAME = 'abdellatif-dev-v2';

const PRECACHE_ASSETS = [
  './',
  './index.html',
  './i18n.json',
  './manifest.json',
  './icon.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_ASSETS);
    }).then(() => {
      return self.skipWaiting();
    })
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((name) => {
          if (name !== CACHE_NAME) {
            return caches.delete(name);
          }
        })
      );
    }).then(() => {
      return self.clients.claim();
    })
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  const url = new URL(req.url);

  // طلبات غير GET نتجاهلها
  if (req.method !== 'GET') return;

  // لا نتدخل في الطلبات الخارجية (روابط التحميل والصور من مواقع أخرى) ولا في لوحة الإدارة
  if (url.origin !== self.location.origin || url.pathname.endsWith('/admin.html')) return;

  // طلبات Supabase REST و Functions تبقى Network-only دائماً لضمان دقة البيانات
  if (url.hostname.includes('supabase.co')) {
    event.respondWith(fetch(req));
    return;
  }

  // الموارد الثابتة والصور: Stale-While-Revalidate
  event.respondWith(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.match(req).then((cachedResponse) => {
        const fetchPromise = fetch(req).then((networkResponse) => {
          if (networkResponse && networkResponse.status === 200 && networkResponse.type === 'basic') {
            cache.put(req, networkResponse.clone());
          }
          return networkResponse;
        }).catch(() => {
          // في حال انقطاع الشبكة والمورد غير متاح، نعيد البديل من الكاش
          return cachedResponse;
        });

        return cachedResponse || fetchPromise;
      });
    })
  );
});
