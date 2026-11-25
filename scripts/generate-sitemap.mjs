/* ============================================================
   Abdellatif Dev — Generate sitemap.xml (B3)
   سكريبت مستقل يقرأ بيانات Supabase REST بمفتاح anon
   ويولّد sitemap.xml كاملاً للأقسام والصفحات والعناصر.
   ============================================================ */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const SITEMAP_PATH = path.join(ROOT_DIR, 'sitemap.xml');

const BASE_URL = 'https://gmngmn431-bit.github.io/abdellatif-dev-site/';
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://plapgefuoqjdsnvrgtwg.supabase.co';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY;
if (!SUPABASE_ANON_KEY) {
  console.error('[FATAL] SUPABASE_ANON_KEY is not set. Provide it via environment variable (GitHub secret in CI).');
  process.exit(1);
}

async function fetchAllRows(tableName) {
  const rows = [];
  const limit = 1000;
  let offset = 0;
  let hasMore = true;

  while (hasMore) {
    const url = `${SUPABASE_URL}/rest/v1/${tableName}?select=id,updated_at,created_at,is_published&is_published=eq.true&order=created_at.desc&limit=${limit}&offset=${offset}`;
    try {
      const res = await fetch(url, {
        headers: {
          'apikey': SUPABASE_ANON_KEY,
          'Authorization': `Bearer ${SUPABASE_ANON_KEY}`
        }
      });

      if (!res.ok) {
        console.warn(`[WARN] Failed to fetch ${tableName} at offset ${offset}: HTTP ${res.status}`);
        break;
      }

      const data = await res.json();
      if (!Array.isArray(data) || data.length === 0) {
        hasMore = false;
      } else {
        rows.push(...data);
        offset += data.length;
        if (data.length < limit) hasMore = false;
      }
    } catch (err) {
      console.error(`[ERROR] Network error fetching ${tableName}:`, err.message);
      break;
    }
  }

  return rows;
}

function formatDate(isoStr) {
  if (!isoStr) return new Date().toISOString().split('T')[0];
  try {
    return new Date(isoStr).toISOString().split('T')[0];
  } catch {
    return new Date().toISOString().split('T')[0];
  }
}

async function main() {
  console.log('[INFO] Generating sitemap.xml...');

  const [games, apps] = await Promise.all([
    fetchAllRows('games'),
    fetchAllRows('apps')
  ]);

  console.log(`[INFO] Fetched ${games.length} games and ${apps.length} apps.`);

  const today = new Date().toISOString().split('T')[0];

  // الصفحات الثابتة الأساسية
  const staticRoutes = [
    { loc: '', changefreq: 'daily', priority: '1.0' },
    { loc: '#/phone', changefreq: 'daily', priority: '0.9' },
    { loc: '#/pc', changefreq: 'daily', priority: '0.9' },
    { loc: '#/store', changefreq: 'daily', priority: '0.9' },
    { loc: '#/mods', changefreq: 'weekly', priority: '0.8' },
    { loc: '#/phone/apps', changefreq: 'weekly', priority: '0.8' },
    { loc: '#/library', changefreq: 'monthly', priority: '0.5' },
    { loc: '#/request', changefreq: 'monthly', priority: '0.6' },
    { loc: '#/dev', changefreq: 'weekly', priority: '0.6' },
    { loc: '#/news', changefreq: 'weekly', priority: '0.7' },
    { loc: '#/about', changefreq: 'monthly', priority: '0.5' },
    { loc: '#/contact', changefreq: 'monthly', priority: '0.4' }
  ];

  let xml = '<?xml version="1.0" encoding="UTF-8"?>\n';
  xml += '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n';

  // إضافة الصفحات الثابتة
  for (const r of staticRoutes) {
    xml += '  <url>\n';
    xml += `    <loc>${BASE_URL}${r.loc}</loc>\n`;
    xml += `    <lastmod>${today}</lastmod>\n`;
    xml += `    <changefreq>${r.changefreq}</changefreq>\n`;
    xml += `    <priority>${r.priority}</priority>\n`;
    xml += '  </url>\n';
  }

  // إضافة صفحات الألعاب
  for (const g of games) {
    const modDate = formatDate(g.updated_at || g.created_at);
    xml += '  <url>\n';
    xml += `    <loc>${BASE_URL}#/game/${g.id}</loc>\n`;
    xml += `    <lastmod>${modDate}</lastmod>\n`;
    xml += '    <changefreq>weekly</changefreq>\n';
    xml += '    <priority>0.8</priority>\n';
    xml += '  </url>\n';
  }

  // إضافة صفحات التطبيقات
  for (const a of apps) {
    const modDate = formatDate(a.updated_at || a.created_at);
    xml += '  <url>\n';
    xml += `    <loc>${BASE_URL}#/app/${a.id}</loc>\n`;
    xml += `    <lastmod>${modDate}</lastmod>\n`;
    xml += '    <changefreq>weekly</changefreq>\n';
    xml += '    <priority>0.8</priority>\n';
    xml += '  </url>\n';
  }

  xml += '</urlset>\n';

  // التحقق قبل الكتابة لتفادي commits غير ضرورية
  let currentContent = '';
  try {
    currentContent = fs.readFileSync(SITEMAP_PATH, 'utf8');
  } catch {}

  if (currentContent.trim() === xml.trim()) {
    console.log('[INFO] Sitemap is up to date. No changes needed.');
  } else {
    fs.writeFileSync(SITEMAP_PATH, xml, 'utf8');
    console.log(`[SUCCESS] sitemap.xml successfully written to ${SITEMAP_PATH}`);
  }
}

main().catch((err) => {
  console.error('[FATAL] generate-sitemap failed:', err);
  process.exit(1);
});