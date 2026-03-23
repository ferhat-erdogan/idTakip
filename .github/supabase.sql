-- ==========================================
-- 1. TABLOLARI OLUŞTUR (YENİ PROJE)
-- ==========================================

CREATE TABLE IF NOT EXISTS public.kimlikler (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    isim text NOT NULL,
    tarih timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.sokaklar (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    kimlik_id uuid REFERENCES public.kimlikler(id) ON DELETE CASCADE,
    isim text NOT NULL,
    tarih timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.binalar (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sokak_id uuid REFERENCES public.sokaklar(id) ON DELETE CASCADE,
    isim text NOT NULL,
    v62_adet integer DEFAULT 0,
    v62_fiyat numeric DEFAULT 0,
    v63_adet integer DEFAULT 0,
    v63_fiyat numeric DEFAULT 0,
    montaj_durum boolean DEFAULT false,
    notlar text,
    tarih timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.ayarlar (
    id integer PRIMARY KEY DEFAULT 1,
    tg_bot_token text,
    tg_chat_id text,
    tg_bot_status boolean DEFAULT false,
    tarih timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT check_single_row CHECK (id = 1)
);

-- ==========================================
-- 2. RLS GÜVENLİĞİNİ AKTİF ET
-- ==========================================
ALTER TABLE public.kimlikler ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sokaklar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.binalar ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ayarlar ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- 3. KESİN GÜVENLİK FONKSİYONU (Canlı Kontrol)
-- ==========================================
-- Bu fonksiyon, kullanıcı silindiği anda 'false' döner ve erişimi kapatır.
CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM auth.users WHERE id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ==========================================
-- 4. GÜÇLÜ RLS POLİTİKALARI (Fonksiyon Destekli)
-- ==========================================

-- Kimlikler Politikaları
CREATE POLICY "Canlı kontrol oku" ON public.kimlikler FOR SELECT TO authenticated USING (public.is_active_user());
CREATE POLICY "Canlı kontrol ekle" ON public.kimlikler FOR INSERT TO authenticated WITH CHECK (public.is_active_user());
CREATE POLICY "Canlı kontrol sil" ON public.kimlikler FOR DELETE TO authenticated USING (public.is_active_user());

-- Sokaklar Politikaları
CREATE POLICY "Canlı kontrol oku" ON public.sokaklar FOR SELECT TO authenticated USING (public.is_active_user());
CREATE POLICY "Canlı kontrol ekle" ON public.sokaklar FOR INSERT TO authenticated WITH CHECK (public.is_active_user());
CREATE POLICY "Canlı kontrol sil" ON public.sokaklar FOR DELETE TO authenticated USING (public.is_active_user());

-- Binalar Politikaları
CREATE POLICY "Canlı kontrol oku" ON public.binalar FOR SELECT TO authenticated USING (public.is_active_user());
CREATE POLICY "Canlı kontrol ekle" ON public.binalar FOR INSERT TO authenticated WITH CHECK (public.is_active_user());
CREATE POLICY "Canlı kontrol güncelle" ON public.binalar FOR UPDATE TO authenticated USING (public.is_active_user());
CREATE POLICY "Canlı kontrol sil" ON public.binalar FOR DELETE TO authenticated USING (public.is_active_user());

-- Ayarlar Politikaları
CREATE POLICY "Canlı kontrol oku" ON public.ayarlar FOR SELECT TO authenticated USING (public.is_active_user());
CREATE POLICY "Canlı kontrol güncelle" ON public.ayarlar FOR UPDATE TO authenticated USING (public.is_active_user());
CREATE POLICY "Canlı kontrol ekle" ON public.ayarlar FOR INSERT TO authenticated WITH CHECK (public.is_active_user());

-- ==========================================
-- 5. VARSAYILAN AYARLAR VE AÇIKLAMALAR
-- ==========================================
INSERT INTO public.ayarlar (id, tg_bot_token, tg_chat_id, tg_bot_status)
VALUES (
    1,
    'TOKEN',
    'CHAT_ID',
    true
)
ON CONFLICT (id) DO NOTHING;

COMMENT ON COLUMN public.binalar.montaj_durum IS 'Montaj yapılamadı durumu (Toggle)';
COMMENT ON COLUMN public.binalar.notlar IS 'Bina ile ilgili özel notlar';

