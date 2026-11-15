// ============================================================
// Abdellatif Dev — Supabase Client Configuration
// ============================================================
// ⚠️ مهم: هذه قيم فارغة (Placeholders) — وليست مفاتيح حقيقية.
// بعد إنشاء مشروعك المجاني في Supabase (الشرح الكامل في README.md):
//   1. افتح Supabase > Settings > API
//   2. انسخ Project URL وضعه مكان YOUR-PROJECT
//   3. انسخ anon public key وضعه مكان YOUR-ANON-KEY
// لا تضع هنا أبداً مفتاح service_role (مفتاح الإدارة السري) —
// مفتاح anon وحده يكفي، والصلاحيات محمية بقواعد RLS في schema.sql.
// ============================================================

const SUPABASE_URL = "https://plapgefuoqjdsnvrgtwg.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYXBnZWZ1b3FqZHNudnJndHdnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ3NTE1ODAsImV4cCI6MjExMDMyNzU4MH0.TrjnWqdnCdZNl3t8PfpGwj57F0yjMrv_m0QWoO18E1E";

// هل تم إعداد Supabase؟ (يستعملها الموقع لعرض تنبيه الإعداد بدل الفشل الصامت)
const SUPABASE_CONFIGURED =
    SUPABASE_URL.indexOf('YOUR-PROJECT') === -1 &&
    SUPABASE_ANON_KEY.indexOf('YOUR-ANON-KEY') === -1;

if (typeof window !== 'undefined') {
    window.SUPABASE_CONFIGURED = SUPABASE_CONFIGURED;
    if (SUPABASE_CONFIGURED) {
        window.supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    }
}

async function getCurrentUser() {
    if (!window.supabaseClient) return null;
    const { data: { user } } = await window.supabaseClient.auth.getUser();
    return user;
}

async function checkIsAdmin() {
    const user = await getCurrentUser();
    if (!user) return false;

    const { data, error } = await window.supabaseClient
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    return !error && data && data.role === 'admin';
}
