-- Project status funnel.
-- Renames the old approved status value and enforces the allowed workflow.

update public.projects
set status = 'Aprovado'
where status = 'Fechado';

alter table public.projects
drop constraint if exists projects_status_check;

alter table public.projects
add constraint projects_status_check
check (
    status in (
        'Em negociação',
        'Aprovado',
        'Em instalação',
        'Concluído',
        'Não aprovado'
    )
);

create or replace function public.project_status_position(status_value text)
returns integer
language sql
immutable
set search_path = public
as $$
    select case status_value
        when 'Em negociação' then 1
        when 'Aprovado' then 2
        when 'Em instalação' then 3
        when 'Concluído' then 4
        when 'Não aprovado' then 99
        else null
    end
$$;

create or replace function public.validate_project_status_transition()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    old_position integer;
    new_position integer;
begin
    if new.status = old.status then
        return new;
    end if;

    if auth.role() = 'service_role' or public.current_profile_is_admin() then
        return new;
    end if;

    old_position := public.project_status_position(old.status);
    new_position := public.project_status_position(new.status);

    if old_position is null or new_position is null then
        raise exception 'Status de projeto invalido.';
    end if;

    if new.status = 'Não aprovado'
       and old.status in (
           'Em negociação',
           'Aprovado',
           'Em instalação',
           'Concluído'
       ) then
        return new;
    end if;

    if new_position = old_position + 1
       and old.status in ('Em negociação', 'Aprovado', 'Em instalação') then
        return new;
    end if;

    raise exception
        'Transicao de status invalida: % -> %.',
        old.status,
        new.status;
end;
$$;

drop trigger if exists validate_project_status_transition_before_update
on public.projects;

create trigger validate_project_status_transition_before_update
before update of status on public.projects
for each row
execute function public.validate_project_status_transition();
