-- Ensure action_history audit rows cannot spoof the authenticated actor.
-- The database derives company/user identity from auth.uid() before RLS checks.

create or replace function public.set_action_history_actor()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    actor record;
begin
    if auth.uid() is not null then
        select
            id,
            company_id,
            name,
            matricula
        into actor
        from public.profiles
        where id = auth.uid()
          and active = true
        limit 1;

        if actor.id is not null then
            new.company_id := actor.company_id;
            new.user_id := actor.id;
            new.user_name := actor.name;
            new.user_matricula := actor.matricula;
        end if;
    end if;

    return new;
end;
$$;

drop trigger if exists set_action_history_actor_before_insert
on public.action_history;

create trigger set_action_history_actor_before_insert
before insert on public.action_history
for each row
execute function public.set_action_history_actor();

drop policy if exists "users insert history from own company"
on public.action_history;

drop policy if exists "users insert history from active company"
on public.action_history;

create policy "users insert history from active company"
on public.action_history
for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and user_id = auth.uid()
    and public.current_company_can_write()
);
