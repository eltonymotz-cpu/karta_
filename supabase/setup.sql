-- =================================================================
-- إعداد Supabase للعبة كارتة
-- انسخ الملف ده كله والصقه في: Supabase → SQL Editor → New query → Run
-- =================================================================
-- ملحوظة: وضع "أكتر من موبايل" بيستخدم Realtime Broadcast ومش محتاج أي جداول.
-- الجدول ده بس عشان الأنماط اللي الأدمن بيضيفها تتحفظ وتظهر على كل الأجهزة.

create table if not exists public.karta_modes (
  id         text primary key,          -- مثلاً custom_1730000000000
  data       jsonb not null,            -- النمط كله (الاسم + الـ 13 كارت)
  updated_at timestamptz not null default now()
);

alter table public.karta_modes enable row level security;

-- أي حد يقدر يقرا الأنماط (عشان تظهر في شاشة الإعداد)
create policy "karta_modes read" on public.karta_modes
  for select using (true);

-- ⚠️ الكتابة مفتوحة لأي حد معاه الـ publishable key، لأن لوحة الأدمن
-- محمية برقم سري جوه التطبيق بس (مش بحساب حقيقي).
-- ده كفاية للعبة بين أصحاب، بس لو التطبيق هيتنشر للناس، الأحسن
-- تضيف Supabase Auth وتخلي الكتابة للأدمن بس.
create policy "karta_modes insert" on public.karta_modes
  for insert with check (true);
create policy "karta_modes update" on public.karta_modes
  for update using (true);
create policy "karta_modes delete" on public.karta_modes
  for delete using (true);
