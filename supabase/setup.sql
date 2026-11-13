-- Vision Forge Workflow: run this once in Supabase → SQL Editor → New query → Run

create table if not exists public.projects (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  type        text not null default 'New'   check (type in ('Change','New')),
  status      text not null default 'To do' check (status in ('To do','In process','Done')),
  person      text,
  client      text,
  deadline    date,
  notes       text,
  position    integer not null default 0,
  created_at  timestamptz not null default now()
);

create index if not exists projects_position_idx on public.projects (position);

-- No login: anyone with the app link can read and edit (as agreed).
alter table public.projects enable row level security;

drop policy if exists "Anyone can read projects"   on public.projects;
drop policy if exists "Anyone can add projects"    on public.projects;
drop policy if exists "Anyone can edit projects"   on public.projects;
drop policy if exists "Anyone can delete projects" on public.projects;

create policy "Anyone can read projects"   on public.projects for select to anon, authenticated using (true);
create policy "Anyone can add projects"    on public.projects for insert to anon, authenticated with check (true);
create policy "Anyone can edit projects"   on public.projects for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete projects" on public.projects for delete to anon, authenticated using (true);

grant select, insert, update, delete on public.projects to anon, authenticated;
