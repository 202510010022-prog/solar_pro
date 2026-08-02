alter table public.projects
add column if not exists rejection_reason text not null default '';
