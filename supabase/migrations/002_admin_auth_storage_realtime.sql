-- =================================================================
-- كارتة: تحديث 002 - حماية لوحة الأدمن + رفع الصور + التحديث اللايف
-- -----------------------------------------------------------------
-- شغّل الملف ده كله مرة واحدة في: Supabase → SQL Editor → New query → Run
-- آمن لو اتشغل أكتر من مرة، ومش بيمسح أي أنماط أو كروت محفوظة.
--
-- ⚠️ قبل ما تشغّله: غيّر YOUR_ADMIN_EMAIL@example.com تحت لإيميل الأدمن،
--    واعمل للإيميل ده يوزر من: Authentication → Users → Add user (بإيميل وباسورد).
--    ويُفضّل تقفل التسجيل العام من: Authentication → Sign In / Providers → Allow new users to sign up.
-- =================================================================

-- 1) جدول الأدمنز: الإيميلات المسموح لها تعدّل الأنماط والكروت وترفع صور
create table if not exists public.karta_admins (
  email text primary key
);
alter table public.karta_admins enable row level security;

drop policy if exists "karta_admins self read" on public.karta_admins;
create policy "karta_admins self read" on public.karta_admins
  for select to authenticated
  using (lower(email) = lower(auth.jwt() ->> 'email'));

insert into public.karta_admins (email)
values (lower('YOUR_ADMIN_EMAIL@example.com'))
on conflict (email) do nothing;

-- دالة بتقول هل اليوزر الحالي أدمن
create or replace function public.karta_is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.karta_admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- 2) جدول الأنماط: أي حد يقرا، والأدمن بس يكتب
create table if not exists public.karta_modes (
  id         text primary key,
  data       jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.karta_modes enable row level security;

drop policy if exists "karta_modes read" on public.karta_modes;
drop policy if exists "karta_modes insert" on public.karta_modes;
drop policy if exists "karta_modes update" on public.karta_modes;
drop policy if exists "karta_modes delete" on public.karta_modes;
drop policy if exists "karta_modes admin insert" on public.karta_modes;
drop policy if exists "karta_modes admin update" on public.karta_modes;
drop policy if exists "karta_modes admin delete" on public.karta_modes;

create policy "karta_modes read" on public.karta_modes
  for select using (true);
create policy "karta_modes admin insert" on public.karta_modes
  for insert to authenticated with check (public.karta_is_admin());
create policy "karta_modes admin update" on public.karta_modes
  for update to authenticated using (public.karta_is_admin()) with check (public.karta_is_admin());
create policy "karta_modes admin delete" on public.karta_modes
  for delete to authenticated using (public.karta_is_admin());

-- 3) التحديث اللايف: تعديلات الأدمن بتوصل لكل الأجهزة من غير ريفريش
do $$
begin
  alter publication supabase_realtime add table public.karta_modes;
exception
  when duplicate_object then null;
end $$;

-- 4) مكان رفع الصور (bucket عام للقراءة، الأدمن بس يرفع ويمسح)
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('karta-images', 'karta-images', true, 2097152,
        array['image/png', 'image/jpeg', 'image/webp', 'image/gif'])
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "karta images read" on storage.objects;
drop policy if exists "karta images admin insert" on storage.objects;
drop policy if exists "karta images admin update" on storage.objects;
drop policy if exists "karta images admin delete" on storage.objects;

create policy "karta images read" on storage.objects
  for select using (bucket_id = 'karta-images');
create policy "karta images admin insert" on storage.objects
  for insert to authenticated with check (bucket_id = 'karta-images' and public.karta_is_admin());
create policy "karta images admin update" on storage.objects
  for update to authenticated using (bucket_id = 'karta-images' and public.karta_is_admin());
create policy "karta images admin delete" on storage.objects
  for delete to authenticated using (bucket_id = 'karta-images' and public.karta_is_admin());
