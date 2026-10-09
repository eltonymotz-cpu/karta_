-- =================================================================
-- 003: إعدادات الأونلاين والشات + مكتبة الصور (ومسح أي حاجة قديمة للرسايل الصوتية)
-- -----------------------------------------------------------------
-- شغّل الملف ده كله مرة واحدة في: Supabase → SQL Editor → New query → Run
-- (بعد 002). آمن لو اتشغل أكتر من مرة. مابيمسحش الكروت ولا الأنماط ولا الإعدادات.
--
-- الشات والرسايل الصوتية مش محتاجين جداول: بيعدوا على موبايل الهوست (هو اللي بيتأكد من كل رسالة)
-- ومابيتحفظوش في أي مكان، وبيتمسحوا أول ما اللعبة تتقفل.
-- =================================================================

-- 1) إعدادات عامة يغيّرها الأدمن (الأونلاين، الشات، الرسايل الصوتية)
create table if not exists public.karta_settings (
  id         text primary key,
  data       jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  updated_by text
);
alter table public.karta_settings enable row level security;

drop policy if exists "karta_settings read" on public.karta_settings;
drop policy if exists "karta_settings admin insert" on public.karta_settings;
drop policy if exists "karta_settings admin update" on public.karta_settings;
create policy "karta_settings read" on public.karta_settings
  for select using (true);
create policy "karta_settings admin insert" on public.karta_settings
  for insert to authenticated with check (public.karta_is_admin());
create policy "karta_settings admin update" on public.karta_settings
  for update to authenticated using (public.karta_is_admin()) with check (public.karta_is_admin());

insert into public.karta_settings (id, data) values ('global', '{}'::jsonb)
on conflict (id) do nothing;

-- قيمة إعداد (بترجع القيمة الافتراضية لو مش متسجلة)
create or replace function public.karta_setting(path text[], fallback text)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select data #>> path from public.karta_settings where id = 'global'), fallback);
$$;

-- التحديث اللايف للإعدادات
do $$
begin
  alter publication supabase_realtime add table public.karta_settings;
exception
  when duplicate_object then null;
end $$;

-- 2) مفيش أي بيانات من القعدات بتتحفظ:
--    الشات والرسايل الصوتية بيتبعتوا جوه القعدة على طول (Realtime) ومابيترفعوش ولا بيتحفظوا.
--    لو كنت شغّلت نسخة قديمة من الملف ده، الأوامر دي بتمسح جدول الرسايل الصوتية وقواعده نهائياً.
drop policy if exists "karta voice upload" on storage.objects;
drop policy if exists "karta voice read" on storage.objects;
drop policy if exists "karta voice delete" on storage.objects;
drop table if exists public.karta_voice_notes cascade;
drop function if exists public.karta_voice_guard() cascade;

-- مكان ملفات الصوت القديم (karta-voice): Supabase مابيسمحش يتمسح بـ SQL لو فيه ملفات،
-- فلو ظهرت رسالة تحت، امسحه من: Storage → karta-voice → Delete bucket
do $$
begin
  delete from storage.buckets where id = 'karta-voice';
exception
  when others then raise notice 'Delete the karta-voice bucket from Storage in the dashboard: %', sqlerrm;
end $$;

-- 3) مكتبة الصور (أيقونات بيكسل ارت وصور يرفعها الأدمن ويستخدمها في أي مكان)
--    الملفات نفسها في bucket الصور العام karta-images (من 002) جوه فولدر library/
create table if not exists public.karta_assets (
  id         uuid primary key default gen_random_uuid(),
  name       text not null check (char_length(name) between 1 and 60),
  category   text not null default 'other' check (char_length(category) <= 30),
  tags       text[] not null default '{}',
  url        text not null unique,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.karta_assets enable row level security;

drop policy if exists "karta_assets read" on public.karta_assets;
drop policy if exists "karta_assets admin write" on public.karta_assets;
create policy "karta_assets read" on public.karta_assets
  for select using (true);
create policy "karta_assets admin write" on public.karta_assets
  for all to authenticated using (public.karta_is_admin()) with check (public.karta_is_admin());
