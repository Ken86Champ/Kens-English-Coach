-- ============================================================
-- English Coach — Supabase Schema
-- Version: 0.1
-- Purpose: Durable learning profile, adaptive review,
--          sentence practice, session logging, and Shadow Mode.
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- ENUMS
-- ------------------------------------------------------------

do $$ begin
  create type public.word_status as enum (
    'new',
    'recognizing',
    'learning',
    'active',
    'conversational',
    'stable',
    'lapsed'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.exercise_type as enum (
    'en_to_de',
    'de_to_en',
    'pronunciation',
    'sentence_building',
    'tense_transform',
    'story_recognition',
    'dialogue',
    'free_speaking'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.case_status as enum (
    'open',
    'problem',
    'solved',
    'verified'
  );
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type public.feedback_rating as enum (
    'correct',
    'near',
    'wrong'
  );
exception
  when duplicate_object then null;
end $$;

-- ------------------------------------------------------------
-- USER PROFILE
-- ------------------------------------------------------------

create table if not exists public.learning_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Ken',
  current_level text not null default 'B1',
  target_level text not null default 'C1 / Business Advanced',
  primary_goal text not null default 'Fluent listening and speaking',
  active_vocabulary_target_min integer not null default 500,
  active_vocabulary_target_max integer not null default 1000,
  free_speaking_target_minutes integer not null default 10,
  primary_context text not null default 'Small talk',
  secondary_context text not null default 'Business, customer calls, meetings, negotiations',
  max_new_words_per_session integer not null default 3,
  preferred_session_minutes integer not null default 15,
  shadow_mode boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ------------------------------------------------------------
-- VOCABULARY MASTER DATA
-- ------------------------------------------------------------

create table if not exists public.vocabulary (
  id uuid primary key default gen_random_uuid(),
  english text not null,
  german text not null,
  word_type text,
  base_form text,
  past_form text,
  past_participle text,
  third_person_form text,
  gerund_form text,
  cefr_level text,
  topic text,
  default_example_sentence text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (english, german)
);

create index if not exists vocabulary_english_idx
  on public.vocabulary (lower(english));

create index if not exists vocabulary_topic_idx
  on public.vocabulary (topic);

-- ------------------------------------------------------------
-- USER-SPECIFIC WORD STATE
-- ------------------------------------------------------------

create table if not exists public.user_word_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  word_id uuid not null references public.vocabulary(id) on delete cascade,
  status public.word_status not null default 'new',

  en_to_de_score numeric(5,2) not null default 0,
  de_to_en_score numeric(5,2) not null default 0,
  sentence_score numeric(5,2) not null default 0,
  conversation_score numeric(5,2) not null default 0,
  tense_score numeric(5,2) not null default 0,
  pronunciation_score numeric(5,2) not null default 0,

  total_attempts integer not null default 0,
  correct_attempts integer not null default 0,
  near_attempts integer not null default 0,
  wrong_attempts integer not null default 0,
  correct_streak integer not null default 0,
  lapse_count integer not null default 0,

  average_response_ms integer,
  last_response_ms integer,

  ease_factor numeric(4,2) not null default 2.50,
  interval_days integer not null default 0,
  repetition_count integer not null default 0,

  last_reviewed_at timestamptz,
  next_review_at timestamptz,
  first_learned_at timestamptz,
  stabilized_at timestamptz,

  typical_mistakes jsonb not null default '[]'::jsonb,
  confusion_word_ids uuid[] not null default '{}',
  coach_notes text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (user_id, word_id),

  check (en_to_de_score between 0 and 100),
  check (de_to_en_score between 0 and 100),
  check (sentence_score between 0 and 100),
  check (conversation_score between 0 and 100),
  check (tense_score between 0 and 100),
  check (pronunciation_score between 0 and 100)
);

create index if not exists user_word_state_due_idx
  on public.user_word_state (user_id, next_review_at);

create index if not exists user_word_state_status_idx
  on public.user_word_state (user_id, status);

-- ------------------------------------------------------------
-- SESSIONS
-- ------------------------------------------------------------

create table if not exists public.learning_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_type text not null default 'voice',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  planned_words uuid[] not null default '{}',
  reviewed_words uuid[] not null default '{}',
  new_words uuid[] not null default '{}',
  total_attempts integer not null default 0,
  correct_attempts integer not null default 0,
  near_attempts integer not null default 0,
  wrong_attempts integer not null default 0,
  accuracy numeric(5,2),
  average_response_ms integer,
  fluency_score numeric(5,2),
  comprehension_score numeric(5,2),
  summary text,
  next_focus text,
  created_at timestamptz not null default now()
);

create index if not exists learning_sessions_user_started_idx
  on public.learning_sessions (user_id, started_at desc);

-- ------------------------------------------------------------
-- ATTEMPTS / SELF-LEARNING DATA
-- ------------------------------------------------------------

create table if not exists public.attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid references public.learning_sessions(id) on delete cascade,
  word_id uuid references public.vocabulary(id) on delete set null,

  exercise_type public.exercise_type not null,
  prompt_text text not null,
  expected_answer text,
  user_answer text,
  normalized_answer text,

  rating public.feedback_rating not null,
  score numeric(5,2) not null default 0,
  response_time_ms integer,
  hint_level integer not null default 0,

  error_type text,
  error_details jsonb not null default '{}'::jsonb,
  coach_feedback text,
  user_self_corrected boolean not null default false,
  used_in_context boolean not null default false,
  tense_used text,

  created_at timestamptz not null default now(),

  check (score between 0 and 100),
  check (hint_level between 0 and 3)
);

create index if not exists attempts_user_created_idx
  on public.attempts (user_id, created_at desc);

create index if not exists attempts_word_created_idx
  on public.attempts (word_id, created_at desc);

-- ------------------------------------------------------------
-- PERSONAL SENTENCE LIBRARY
-- ------------------------------------------------------------

create table if not exists public.sentences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  sentence text not null,
  german_translation text,
  word_ids uuid[] not null default '{}',
  topic text,
  difficulty_level text,
  tense text,
  source text not null default 'coach',
  success_count integer not null default 0,
  failure_count integer not null default 0,
  last_used_at timestamptz,
  next_review_at timestamptz,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists sentences_due_idx
  on public.sentences (user_id, next_review_at);

-- ------------------------------------------------------------
-- SHADOW MODE CASE LOG
-- ------------------------------------------------------------

create table if not exists public.learning_cases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid references public.learning_sessions(id) on delete set null,
  status public.case_status not null default 'open',
  category text not null,
  context text,
  problem text not null,
  coach_behavior text,
  user_correction text,
  proposed_solution text,
  verified_solution text,
  proposed_rule text,
  approved_for_learnings boolean not null default false,
  opened_at timestamptz not null default now(),
  solved_at timestamptz,
  verified_at timestamptz
);

create index if not exists learning_cases_user_status_idx
  on public.learning_cases (user_id, status);

-- ------------------------------------------------------------
-- VERSIONED LEARNINGS
-- ------------------------------------------------------------

create table if not exists public.coach_learnings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null,
  rule text not null,
  priority integer not null default 100,
  active boolean not null default true,
  source_case_id uuid references public.learning_cases(id) on delete set null,
  version integer not null default 1,
  created_at timestamptz not null default now(),
  retired_at timestamptz
);

create index if not exists coach_learnings_active_idx
  on public.coach_learnings (user_id, active, priority);

-- ------------------------------------------------------------
-- SESSION PLANS
-- ------------------------------------------------------------

create table if not exists public.session_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  session_id uuid references public.learning_sessions(id) on delete cascade,
  plan_json jsonb not null,
  generated_at timestamptz not null default now(),
  executed boolean not null default false
);

-- ------------------------------------------------------------
-- UPDATED_AT TRIGGER
-- ------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_learning_profiles_updated_at on public.learning_profiles;
create trigger trg_learning_profiles_updated_at
before update on public.learning_profiles
for each row execute function public.set_updated_at();

drop trigger if exists trg_vocabulary_updated_at on public.vocabulary;
create trigger trg_vocabulary_updated_at
before update on public.vocabulary
for each row execute function public.set_updated_at();

drop trigger if exists trg_user_word_state_updated_at on public.user_word_state;
create trigger trg_user_word_state_updated_at
before update on public.user_word_state
for each row execute function public.set_updated_at();

drop trigger if exists trg_sentences_updated_at on public.sentences;
create trigger trg_sentences_updated_at
before update on public.sentences
for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- SPACED-REPETITION HELPER
-- Simple SM-2-inspired scheduling.
-- quality: 0..5
-- ------------------------------------------------------------

create or replace function public.apply_review_result(
  p_user_id uuid,
  p_word_id uuid,
  p_quality integer,
  p_response_time_ms integer default null
)
returns public.user_word_state
language plpgsql
security invoker
as $$
declare
  v_state public.user_word_state;
  v_new_ease numeric(4,2);
  v_new_interval integer;
  v_new_repetition integer;
  v_new_status public.word_status;
begin
  if p_quality < 0 or p_quality > 5 then
    raise exception 'quality must be between 0 and 5';
  end if;

  select *
  into v_state
  from public.user_word_state
  where user_id = p_user_id and word_id = p_word_id
  for update;

  if not found then
    insert into public.user_word_state (user_id, word_id)
    values (p_user_id, p_word_id)
    returning * into v_state;
  end if;

  v_new_ease := greatest(
    1.30,
    v_state.ease_factor
      + (0.10 - (5 - p_quality) * (0.08 + (5 - p_quality) * 0.02))
  );

  if p_quality < 3 then
    v_new_repetition := 0;
    v_new_interval := 1;
    v_new_status := case
      when v_state.status in ('stable', 'conversational') then 'lapsed'
      else 'learning'
    end;
  else
    v_new_repetition := v_state.repetition_count + 1;

    if v_new_repetition = 1 then
      v_new_interval := 1;
    elsif v_new_repetition = 2 then
      v_new_interval := 3;
    else
      v_new_interval := greatest(
        1,
        round(v_state.interval_days * v_new_ease)::integer
      );
    end if;

    v_new_status := case
      when v_new_repetition >= 6 then 'stable'
      when v_new_repetition >= 4 then 'conversational'
      when v_new_repetition >= 2 then 'active'
      else 'learning'
    end;
  end if;

  update public.user_word_state
  set
    ease_factor = v_new_ease,
    interval_days = v_new_interval,
    repetition_count = v_new_repetition,
    last_reviewed_at = now(),
    next_review_at = now() + make_interval(days => v_new_interval),
    last_response_ms = p_response_time_ms,
    average_response_ms = case
      when p_response_time_ms is null then average_response_ms
      when average_response_ms is null then p_response_time_ms
      else round((average_response_ms * 0.8) + (p_response_time_ms * 0.2))::integer
    end,
    total_attempts = total_attempts + 1,
    correct_attempts = correct_attempts + case when p_quality >= 4 then 1 else 0 end,
    near_attempts = near_attempts + case when p_quality = 3 then 1 else 0 end,
    wrong_attempts = wrong_attempts + case when p_quality < 3 then 1 else 0 end,
    correct_streak = case when p_quality >= 4 then correct_streak + 1 else 0 end,
    lapse_count = lapse_count + case
      when p_quality < 3 and status in ('stable', 'conversational') then 1
      else 0
    end,
    status = v_new_status,
    first_learned_at = coalesce(first_learned_at, case when p_quality >= 3 then now() end),
    stabilized_at = case
      when v_new_status = 'stable' then coalesce(stabilized_at, now())
      else stabilized_at
    end
  where user_id = p_user_id and word_id = p_word_id
  returning * into v_state;

  return v_state;
end;
$$;

-- ------------------------------------------------------------
-- VIEW: WHAT THE COACH SHOULD REVIEW NEXT
-- ------------------------------------------------------------

create or replace view public.review_queue as
select
  uws.user_id,
  uws.word_id,
  v.english,
  v.german,
  v.word_type,
  v.topic,
  uws.status,
  uws.next_review_at,
  uws.average_response_ms,
  uws.correct_streak,
  uws.typical_mistakes,
  case
    when uws.next_review_at is null then 100
    when uws.next_review_at <= now() then 90
    when uws.status in ('lapsed', 'learning') then 80
    when uws.status = 'recognizing' then 70
    when uws.status = 'active' then 50
    when uws.status = 'conversational' then 30
    else 10
  end as priority_score
from public.user_word_state uws
join public.vocabulary v on v.id = uws.word_id;

-- ------------------------------------------------------------
-- RLS
-- ------------------------------------------------------------

alter table public.learning_profiles enable row level security;
alter table public.vocabulary enable row level security;
alter table public.user_word_state enable row level security;
alter table public.learning_sessions enable row level security;
alter table public.attempts enable row level security;
alter table public.sentences enable row level security;
alter table public.learning_cases enable row level security;
alter table public.coach_learnings enable row level security;
alter table public.session_plans enable row level security;

-- Vocabulary is readable by signed-in users.
drop policy if exists "Authenticated users can read vocabulary" on public.vocabulary;
create policy "Authenticated users can read vocabulary"
on public.vocabulary for select
to authenticated
using (true);

-- Optional: allow authenticated users to add vocabulary.
drop policy if exists "Authenticated users can insert vocabulary" on public.vocabulary;
create policy "Authenticated users can insert vocabulary"
on public.vocabulary for insert
to authenticated
with check (true);

drop policy if exists "Authenticated users can update vocabulary" on public.vocabulary;
create policy "Authenticated users can update vocabulary"
on public.vocabulary for update
to authenticated
using (true)
with check (true);

-- User-owned tables.
drop policy if exists "Users manage own learning profile" on public.learning_profiles;
create policy "Users manage own learning profile"
on public.learning_profiles for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own word state" on public.user_word_state;
create policy "Users manage own word state"
on public.user_word_state for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own sessions" on public.learning_sessions;
create policy "Users manage own sessions"
on public.learning_sessions for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own attempts" on public.attempts;
create policy "Users manage own attempts"
on public.attempts for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own sentences" on public.sentences;
create policy "Users manage own sentences"
on public.sentences for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own learning cases" on public.learning_cases;
create policy "Users manage own learning cases"
on public.learning_cases for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own coach learnings" on public.coach_learnings;
create policy "Users manage own coach learnings"
on public.coach_learnings for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "Users manage own session plans" on public.session_plans;
create policy "Users manage own session plans"
on public.session_plans for all
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- ------------------------------------------------------------
-- SEED VOCABULARY
-- ------------------------------------------------------------

insert into public.vocabulary (
  english, german, word_type, base_form, past_form, past_participle,
  third_person_form, gerund_form, cefr_level, topic, default_example_sentence
)
values
  ('negotiate', 'verhandeln', 'verb', 'negotiate', 'negotiated', 'negotiated', 'negotiates', 'negotiating', 'B2', 'business', 'I do not negotiate with people who only want to argue.'),
  ('streamline', 'vereinfachen / straffen', 'verb', 'streamline', 'streamlined', 'streamlined', 'streamlines', 'streamlining', 'B2', 'business', 'I want to streamline customer success.'),
  ('delegate', 'delegieren / Aufgaben abgeben', 'verb', 'delegate', 'delegated', 'delegated', 'delegates', 'delegating', 'B2', 'business', 'I need to delegate tasks to my employees.'),
  ('undertake', 'übernehmen / in Angriff nehmen', 'verb', 'undertake', 'undertook', 'undertaken', 'undertakes', 'undertaking', 'B2', 'business', 'I am undertaking a new project.'),
  ('achieve', 'erreichen / erzielen', 'verb', 'achieve', 'achieved', 'achieved', 'achieves', 'achieving', 'B1', 'goals', 'We need to achieve better results.'),
  ('require', 'erfordern / benötigen', 'verb', 'require', 'required', 'required', 'requires', 'requiring', 'B1', 'business', 'This task requires focus.'),
  ('prioritize', 'priorisieren', 'verb', 'prioritize', 'prioritized', 'prioritized', 'prioritizes', 'prioritizing', 'B2', 'business', 'We need to prioritize before the meeting.'),
  ('align', 'abstimmen / auf eine Linie bringen', 'verb', 'align', 'aligned', 'aligned', 'aligns', 'aligning', 'B2', 'business', 'We need to align on the strategy.'),
  ('clarify', 'klären / verdeutlichen', 'verb', 'clarify', 'clarified', 'clarified', 'clarifies', 'clarifying', 'B2', 'business', 'We need to clarify the timeline.'),
  ('allocate', 'zuteilen / zuweisen', 'verb', 'allocate', 'allocated', 'allocated', 'allocates', 'allocating', 'B2', 'business', 'We need to allocate the budget carefully.'),
  ('optimize', 'optimieren', 'verb', 'optimize', 'optimized', 'optimized', 'optimizes', 'optimizing', 'B2', 'business', 'We need to optimize the process.'),
  ('decide', 'entscheiden', 'verb', 'decide', 'decided', 'decided', 'decides', 'deciding', 'B1', 'general', 'We need to decide today.'),
  ('improve', 'verbessern', 'verb', 'improve', 'improved', 'improved', 'improves', 'improving', 'B1', 'general', 'We need to improve communication.'),
  ('support', 'unterstützen', 'verb', 'support', 'supported', 'supported', 'supports', 'supporting', 'B1', 'general', 'I support my team.'),
  ('prepare', 'vorbereiten', 'verb', 'prepare', 'prepared', 'prepared', 'prepares', 'preparing', 'B1', 'general', 'We need to prepare the next step.'),
  ('develop', 'entwickeln', 'verb', 'develop', 'developed', 'developed', 'develops', 'developing', 'B1', 'general', 'We want to develop a better process.')
on conflict (english, german) do nothing;

-- ------------------------------------------------------------
-- OPTIONAL INITIALIZATION
-- Run this AFTER a user has signed in.
-- Replace <USER_UUID> with auth.users.id.
-- ------------------------------------------------------------

-- insert into public.learning_profiles (user_id)
-- values ('<USER_UUID>')
-- on conflict (user_id) do nothing;

-- insert into public.user_word_state (
--   user_id, word_id, status, typical_mistakes
-- )
-- select
--   '<USER_UUID>'::uuid,
--   id,
--   case
--     when english in ('negotiate', 'undertake', 'allocate', 'align', 'clarify')
--       then 'learning'::public.word_status
--     when english in ('streamline', 'delegate', 'achieve', 'require')
--       then 'active'::public.word_status
--     else 'recognizing'::public.word_status
--   end,
--   case
--     when english = 'negotiate'
--       then '["Uses stop instead of do not", "Drops with before people"]'::jsonb
--     when english = 'require'
--       then '["Confuses require, requires, and required"]'::jsonb
--     when english = 'undertake'
--       then '["Confuses with delegate", "Meaning not yet stable"]'::jsonb
--     when english = 'allocate'
--       then '["Confuses with align and delegate"]'::jsonb
--     when english = 'align'
--       then '["Confuses with clarify and allocate"]'::jsonb
--     when english = 'clarify'
--       then '["Confuses with align and allocate"]'::jsonb
--     else '[]'::jsonb
--   end
-- from public.vocabulary
-- on conflict (user_id, word_id) do nothing;

-- ------------------------------------------------------------
-- SAMPLE SESSION-PLAN QUERY
-- ------------------------------------------------------------

-- select *
-- from public.review_queue
-- where user_id = '<USER_UUID>'
-- order by priority_score desc, next_review_at nulls first
-- limit 10;
