-- ============================================================
-- Abdellatif Dev — schema.sql
-- قاعدة بيانات الموقع (Supabase / PostgreSQL)
-- طريقة الاستعمال: Supabase > SQL Editor > New query >
-- الصق هذا الملف كاملاً > Run
-- آمن عند إعادة التشغيل: كل العبارات تستعمل
-- IF NOT EXISTS / ADD COLUMN IF NOT EXISTS / ON CONFLICT
-- ============================================================

-- ---------- profiles: صلاحية الأدمن ----------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('admin', 'user')),
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------- games ----------
CREATE TABLE IF NOT EXISTS public.games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE,
    category TEXT NOT NULL DEFAULT 'رسمية',
    platform TEXT NOT NULL DEFAULT 'phone' CHECK (platform IN ('pc', 'phone', 'mod-minecraft', 'mod-gta')),
    platform TEXT NOT NULL DEFAULT 'pc' CHECK (platform IN ('pc', 'phone', 'mod-minecraft', 'mod-gta')),
    short_desc TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    features JSONB NOT NULL DEFAULT '[]'::jsonb,
    cover_url TEXT,
    screenshots JSONB NOT NULL DEFAULT '[]'::jsonb,
    version TEXT,
    status TEXT NOT NULL DEFAULT 'in_dev' CHECK (status IN ('available', 'in_dev', 'coming_soon')),
    download_url TEXT,
    requirements TEXT,
    download_count INTEGER NOT NULL DEFAULT 0,
    is_published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------- apps ----------
CREATE TABLE IF NOT EXISTS public.apps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    slug TEXT UNIQUE,
    category TEXT NOT NULL DEFAULT 'رسمية',
    short_desc TEXT NOT NULL DEFAULT '',
    description TEXT NOT NULL DEFAULT '',
    features JSONB NOT NULL DEFAULT '[]'::jsonb,
    cover_url TEXT,
    screenshots JSONB NOT NULL DEFAULT '[]'::jsonb,
    version TEXT,
    status TEXT NOT NULL DEFAULT 'in_dev' CHECK (status IN ('available', 'in_dev', 'coming_soon')),
    download_url TEXT,
    requirements TEXT,
    download_count INTEGER NOT NULL DEFAULT 0,
    is_published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------- projects: مشاريع قيد التطوير ----------
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    image_url TEXT,
    description TEXT NOT NULL DEFAULT '',
    progress INTEGER CHECK (progress IS NULL OR (progress >= 0 AND progress <= 100)),
    latest_update TEXT,
    status TEXT NOT NULL DEFAULT 'قيد التطوير',
    is_published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------- news ----------
CREATE TABLE IF NOT EXISTS public.news (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    cover_url TEXT,
    category TEXT NOT NULL DEFAULT 'أخبار',
    content TEXT NOT NULL DEFAULT '',
    external_url TEXT,
    published_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- ---------- site_settings: hero / about / social ----------
CREATE TABLE IF NOT EXISTS public.site_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL
);

-- ---------- أعمدة ناقصة (لمن شغّل نسخة قديمة) ----------
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS slug TEXT;
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS features JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS screenshots JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS requirements TEXT;
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS download_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS slug TEXT;
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS features JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS screenshots JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS requirements TEXT;
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS download_count INTEGER NOT NULL DEFAULT 0;
ALTER TABLE public.games ADD COLUMN IF NOT EXISTS platform TEXT NOT NULL DEFAULT 'pc' CHECK (platform IN ('pc', 'phone', 'mod-minecraft', 'mod-gta'));
ALTER TABLE public.apps ADD COLUMN IF NOT EXISTS platform TEXT NOT NULL DEFAULT 'phone' CHECK (platform IN ('pc', 'phone', 'mod-minecraft', 'mod-gta'));
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS progress INTEGER;
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS latest_update TEXT;
ALTER TABLE public.news ADD COLUMN IF NOT EXISTS external_url TEXT;
ALTER TABLE public.news ADD COLUMN IF NOT EXISTS published_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL;

-- ---------- دوال: عداد التحميلات ----------
CREATE OR REPLACE FUNCTION increment_game_download(target_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.games SET download_count = download_count + 1 WHERE id = target_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_app_download(target_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.apps SET download_count = download_count + 1 WHERE id = target_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ---------- دالة التحقق من الأدمن ----------
CREATE OR REPLACE FUNCTION is_admin() RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ---------- RLS ----------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.apps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.news ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.site_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Profiles access" ON public.profiles;
DROP POLICY IF EXISTS "Anyone can view published games" ON public.games;
DROP POLICY IF EXISTS "Admins can manage games" ON public.games;
DROP POLICY IF EXISTS "Anyone can view published apps" ON public.apps;
DROP POLICY IF EXISTS "Admins can manage apps" ON public.apps;
DROP POLICY IF EXISTS "Anyone can view published projects" ON public.projects;
DROP POLICY IF EXISTS "Admins can manage projects" ON public.projects;
DROP POLICY IF EXISTS "Anyone can view published news" ON public.news;
DROP POLICY IF EXISTS "Admins can manage news" ON public.news;
DROP POLICY IF EXISTS "Anyone can view settings" ON public.site_settings;
DROP POLICY IF EXISTS "Admins can manage settings" ON public.site_settings;

CREATE POLICY "Profiles access" ON public.profiles FOR ALL USING (auth.uid() = id OR is_admin());
CREATE POLICY "Anyone can view published games" ON public.games FOR SELECT USING (is_published = true OR is_admin());
CREATE POLICY "Admins can manage games" ON public.games FOR ALL USING (is_admin());
CREATE POLICY "Anyone can view published apps" ON public.apps FOR SELECT USING (is_published = true OR is_admin());
CREATE POLICY "Admins can manage apps" ON public.apps FOR ALL USING (is_admin());
CREATE POLICY "Anyone can view published projects" ON public.projects FOR SELECT USING (is_published = true OR is_admin());
CREATE POLICY "Admins can manage projects" ON public.projects FOR ALL USING (is_admin());
CREATE POLICY "Anyone can view published news" ON public.news FOR SELECT USING (is_published = true OR is_admin());
CREATE POLICY "Admins can manage news" ON public.news FOR ALL USING (is_admin());
CREATE POLICY "Anyone can view settings" ON public.site_settings FOR SELECT USING (true);
CREATE POLICY "Admins can manage settings" ON public.site_settings FOR ALL USING (is_admin());

-- ---------- Storage buckets ----------
INSERT INTO storage.buckets (id, name, public) VALUES ('project-images', 'project-images', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('screenshots', 'screenshots', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('app-files', 'app-files', true) ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public Read Project Images" ON storage.objects;
DROP POLICY IF EXISTS "Admin Upload Project Images" ON storage.objects;
DROP POLICY IF EXISTS "Admin Delete Project Images" ON storage.objects;
DROP POLICY IF EXISTS "Public Read Screenshots" ON storage.objects;
DROP POLICY IF EXISTS "Admin Upload Screenshots" ON storage.objects;
DROP POLICY IF EXISTS "Admin Delete Screenshots" ON storage.objects;
DROP POLICY IF EXISTS "Public Read App Files" ON storage.objects;
DROP POLICY IF EXISTS "Admin Upload App Files" ON storage.objects;
DROP POLICY IF EXISTS "Admin Delete App Files" ON storage.objects;

CREATE POLICY "Public Read Project Images" ON storage.objects FOR SELECT USING (bucket_id = 'project-images');
CREATE POLICY "Admin Upload Project Images" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'project-images' AND is_admin());
CREATE POLICY "Admin Delete Project Images" ON storage.objects FOR DELETE USING (bucket_id = 'project-images' AND is_admin());
CREATE POLICY "Public Read Screenshots" ON storage.objects FOR SELECT USING (bucket_id = 'screenshots');
CREATE POLICY "Admin Upload Screenshots" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'screenshots' AND is_admin());
CREATE POLICY "Admin Delete Screenshots" ON storage.objects FOR DELETE USING (bucket_id = 'screenshots' AND is_admin());
CREATE POLICY "Public Read App Files" ON storage.objects FOR SELECT USING (bucket_id = 'app-files');
CREATE POLICY "Admin Upload App Files" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'app-files' AND is_admin());
CREATE POLICY "Admin Delete App Files" ON storage.objects FOR DELETE USING (bucket_id = 'app-files' AND is_admin());

-- ============================================================
-- بيانات أولية (Seed) — المحتوى الحقيقي الوحيد المسموح به:
-- مشروع واحد قيد التطوير + إعدادات الموقع.
-- جداول games و apps و news تبقى فارغة عمداً:
-- تظهر بحالات فارغة جميلة حتى يضيف الأدمن محتوى.
-- ============================================================

INSERT INTO public.projects (name, image_url, description, progress, latest_update, status, is_published)
VALUES (
    'لعبة الكارطة المغربية',
    NULL,
    'لعبة ورق مغربية مبنية بمحرك Unity، تجمع أشهر الألعاب المغربية في مكان واحد: روندا، جبن زروت، لاس غميز، كانتيكوبي. العب ضد البوتات أو مع أصدقائك عبر الواي فاي.',
    NULL,
    'العمل جارٍ على تطوير اللعبة وإضافة الأطوار.',
    'قيد التطوير',
    true
) ON CONFLICT DO NOTHING;

INSERT INTO public.site_settings (key, value) VALUES
('hero', '{"badge": "مطور ألعاب وتطبيقات مستقل", "title": "Abdellatif Dev", "subtitle": "أطوّر ألعاباً وتطبيقات موبايل — من الفكرة إلى النشر، بجودة واحترافية."}'::jsonb),
('about', '{"name": "Abdellatif Dev", "title": "مطور ألعاب وتطبيقات مستقل", "bio": "مطور مستقل من المغرب، أركز على تطوير الألعاب والتطبيقات باستخدام محرك Unity. أعمل حالياً على لعبة الكارطة المغربية، وهي لعبة ورق مغربية تجمع أشهر الألعاب المغربية في مكان واحد.", "tech": ["Unity", "C#", "تطوير ألعاب الموبايل", "Supabase"]}'::jsonb),
('social', '{"facebook": "https://www.facebook.com/abdltif.blmlih.3", "youtube": "", "telegram": "", "github": "", "instagram": "", "x": ""}'::jsonb)
ON CONFLICT (key) DO NOTHING;
