-- =================================================================
-- 003: إعدادات الأونلاين + الرسايل الصوتية + مكتبة الرسايل المحفوظة
-- -----------------------------------------------------------------
-- شغّل الملف ده كله مرة واحدة في: Supabase → SQL Editor → New query → Run
-- (بعد 002). آمن لو اتشغل أكتر من مرة، ومش بيمسح أي بيانات موجودة.
--
-- ⚠️ لازم كمان تفعّل الدخول كضيف (مجاني):
--    Authentication → Sign In / Providers → Anonymous Sign-ins → On
--    كل موبايل بياخد هوية ضيف، وده اللي بيحمي رفع الصوت والمكتبة.
--
-- الشات النصي مش محتاج جداول: بيعدي على موبايل الهوست (هو اللي بيتأكد من كل رسالة).
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

-- 2) مكتبة الرسايل الصوتية المحفوظة
create table if not exists public.karta_voice_notes (
  id          uuid primary key default gen_random_uuid(),
  owner       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  owner_name  text not null default '' check (char_length(owner_name) <= 30),
  title       text not null default '' check (char_length(title) <= 60),
  path        text not null unique,
  duration_ms integer not null check (duration_ms between 1 and 300000),
  size_bytes  integer not null check (size_bytes between 1 and 5242880),
  mime        text not null check (mime in ('audio/webm', 'audio/ogg', 'audio/mp4', 'audio/aac', 'audio/mpeg', 'audio/wav')),
  visibility  text not null default 'private' check (visibility in ('private', 'public')),
  status      text not null default 'approved' check (status in ('pending', 'approved', 'rejected')),
  created_at  timestamptz not null default now(),
  -- الملف لازم يكون جوه فولدر صاحبه (عشان محدش يحفظ ملف حد تاني باسمه)
  constraint karta_voice_path_owner check (split_part(path, '/', 1) = owner::text)
);
create index if not exists karta_voice_notes_owner on public.karta_voice_notes (owner, created_at desc);
create index if not exists karta_voice_notes_public on public.karta_voice_notes (visibility, status, created_at desc);
alter table public.karta_voice_notes enable row level security;

-- قواعد ثابتة بتتطبق على السيرفر (مش بنصدّق الموبايل):
-- - صاحب الرسالة = اليوزر الحالي
-- - العامة بتبقى "مستنية موافقة" لو المراجعة شغالة، والأدمن بس يغيّر الحالة
-- - أقصى 30 رسالة محفوظة في الساعة لكل يوزر
create or replace function public.karta_voice_guard()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  is_admin boolean := public.karta_is_admin();
begin
  if tg_op = 'INSERT' then
    if not is_admin then
      new.owner := auth.uid();
      if (select count(*) from public.karta_voice_notes
          where owner = auth.uid() and created_at > now() - interval '1 hour') >= 30 then
        raise exception 'Too many saved voice notes, try again later';
      end if;
    end if;
  else
    -- مينفعش يتغير صاحب الرسالة أو ملفها
    new.owner := old.owner;
    new.path := old.path;
  end if;

  if new.visibility = 'public' and public.karta_setting(array['voice', 'allowPublic'], 'true') <> 'true' and not is_admin then
    raise exception 'Public voice notes are disabled';
  end if;

  if not is_admin then
    if new.visibility = 'private' then
      new.status := 'approved';
    elsif tg_op = 'INSERT' or old.visibility <> 'public' then
      new.status := case when public.karta_setting(array['voice', 'moderation'], 'true') = 'true'
                         then 'pending' else 'approved' end;
    else
      new.status := old.status; -- اليوزر مايقدرش يوافق على رسالته بنفسه
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists karta_voice_guard on public.karta_voice_notes;
create trigger karta_voice_guard before insert or update on public.karta_voice_notes
  for each row execute function public.karta_voice_guard();

drop policy if exists "voice read" on public.karta_voice_notes;
drop policy if exists "voice insert" on public.karta_voice_notes;
drop policy if exists "voice update" on public.karta_voice_notes;
drop policy if exists "voice delete" on public.karta_voice_notes;
create policy "voice read" on public.karta_voice_notes
  for select to authenticated
  using (owner = auth.uid() or (visibility = 'public' and status = 'approved') or public.karta_is_admin());
create policy "voice insert" on public.karta_voice_notes
  for insert to authenticated
  with check (owner = auth.uid() or public.karta_is_admin());
create policy "voice update" on public.karta_voice_notes
  for update to authenticated
  using (owner = auth.uid() or public.karta_is_admin())
  with check (owner = auth.uid() or public.karta_is_admin());
create policy "voice delete" on public.karta_voice_notes
  for delete to authenticated
  using (owner = auth.uid() or public.karta_is_admin());

-- 3) مكان ملفات الصوت: bucket خاص (مش عام)، أقصى حجم 2 ميجا، صوت بس
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('karta-voice', 'karta-voice', false, 2097152,
        array['audio/webm', 'audio/ogg', 'audio/mp4', 'audio/aac', 'audio/mpeg', 'audio/wav'])
on conflict (id) do update
  set public = false,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "karta voice upload" on storage.objects;
drop policy if exists "karta voice read" on storage.objects;
drop policy if exists "karta voice delete" on storage.objects;

-- كل يوزر بيرفع في فولدر باسمه بس
create policy "karta voice upload" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'karta-voice' and (storage.foldername(name))[1] = auth.uid()::text);

-- القراءة (وعمل روابط مؤقتة): صاحب الملف، أو ملف رسالة عامة متوافق عليها، أو الأدمن.
-- اللاعيبة في القعدة بيسمعوا الرسالة برابط مؤقت بيعمله صاحبها لما يبعتها.
create policy "karta voice read" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'karta-voice' and (
      (storage.foldername(name))[1] = auth.uid()::text
      or public.karta_is_admin()
      or exists (select 1 from public.karta_voice_notes n
                 where n.path = name and n.visibility = 'public' and n.status = 'approved')
    )
  );

create policy "karta voice delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'karta-voice' and ((storage.foldername(name))[1] = auth.uid()::text or public.karta_is_admin()));

-- 4) مكتبة الصور (أيقونات بيكسل ارت وصور يرفعها الأدمن ويستخدمها في أي مكان)
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
