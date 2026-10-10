-- =================================================================
-- 004: سجل تعديلات الأدمن (Audit Log)
-- -----------------------------------------------------------------
-- شغّل الملف ده في: Supabase → SQL Editor → New query → Run (بعد 003).
-- آمن لو اتشغل أكتر من مرة، ومابيمسحش أي بيانات.
--
-- كل مرة الأدمن يغيّر الإعدادات (الأونلاين/الشات/الصوت/الكوينز) بيتسجل:
-- مين (إيميل الأدمن)، إمتى، وإيه اللي اتغير بالظبط (القيمة قبل ← بعد).
-- السجل ده بيتعمل على السيرفر نفسه (trigger)، فمحدش يقدر يعدّله أو يتخطاه من التطبيق.
-- ملحوظة: ده سجل لإعدادات الأدمن بس - مفيش أي بيانات من القعدات أو اللعب بتتحفظ.
-- =================================================================

create table if not exists public.karta_admin_audit (
  id          bigint generated always as identity primary key,
  admin_email text,
  changed_at  timestamptz not null default now(),
  setting_id  text not null,
  changes     jsonb not null default '{}'::jsonb,   -- {"economy.offline.taxPercent": [5, 10], ...}
  before_data jsonb,
  after_data  jsonb
);
alter table public.karta_admin_audit enable row level security;

-- القراءة للأدمن بس، ومفيش كتابة من التطبيق خالص (الـ trigger بس هو اللي بيكتب)
drop policy if exists "audit admin read" on public.karta_admin_audit;
create policy "audit admin read" on public.karta_admin_audit
  for select to authenticated using (public.karta_is_admin());

-- الفرق بين نسختين من الإعدادات (لحد 3 مستويات: section.mode.key)
create or replace function public.karta_json_diff(old_data jsonb, new_data jsonb, prefix text default '')
returns jsonb
language plpgsql
immutable
as $$
declare
  result jsonb := '{}'::jsonb;
  k text;
  o jsonb;
  n jsonb;
begin
  for k in select distinct key from (
    select jsonb_object_keys(coalesce(old_data, '{}'::jsonb)) as key
    union select jsonb_object_keys(coalesce(new_data, '{}'::jsonb))
  ) keys loop
    o := old_data -> k;
    n := new_data -> k;
    if o is distinct from n then
      if jsonb_typeof(o) = 'object' and jsonb_typeof(n) = 'object' then
        result := result || public.karta_json_diff(o, n, prefix || k || '.');
      else
        result := result || jsonb_build_object(prefix || k, jsonb_build_array(o, n));
      end if;
    end if;
  end loop;
  return result;
end;
$$;

create or replace function public.karta_settings_audit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  old_data jsonb := case when tg_op = 'UPDATE' then old.data else null end;
  diff jsonb := public.karta_json_diff(old_data, new.data);
begin
  if diff <> '{}'::jsonb then
    insert into public.karta_admin_audit (admin_email, setting_id, changes, before_data, after_data)
    values (auth.jwt() ->> 'email', new.id, diff, old_data, new.data);
  end if;
  return new;
end;
$$;

drop trigger if exists karta_settings_audit on public.karta_settings;
create trigger karta_settings_audit after insert or update on public.karta_settings
  for each row execute function public.karta_settings_audit();
