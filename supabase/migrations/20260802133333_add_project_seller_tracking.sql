-- Track the seller responsible for each project without trusting client input.

alter table public.projects
add column if not exists seller_id uuid references public.profiles(id) on delete set null;

create index if not exists idx_projects_seller_id
on public.projects(seller_id);

create or replace function public.validate_project_seller(
    target_seller_id uuid,
    target_company_id uuid
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
    if target_seller_id is null then
        return;
    end if;

    if not exists (
        select 1
        from public.profiles
        where id = target_seller_id
          and company_id = target_company_id
          and active = true
    ) then
        raise exception
            'Vendedor responsavel deve pertencer a mesma empresa do projeto.';
    end if;
end;
$$;

create or replace function public.set_project_seller_on_insert()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    actor_company_id uuid;
begin
    if auth.role() = 'service_role' then
        perform public.validate_project_seller(new.seller_id, new.company_id);
        return new;
    end if;

    select company_id
      into actor_company_id
      from public.profiles
     where id = auth.uid()
       and active = true
     limit 1;

    if actor_company_id is null then
        raise exception 'Usuario autenticado sem perfil ativo.';
    end if;

    if actor_company_id <> new.company_id then
        raise exception 'Empresa do projeto diferente da empresa do usuario.';
    end if;

    -- Ignore any seller_id sent by regular clients. The seller is the
    -- authenticated active profile that created the project.
    new.seller_id := auth.uid();
    return new;
end;
$$;

drop trigger if exists set_project_seller_before_insert
on public.projects;

create trigger set_project_seller_before_insert
before insert on public.projects
for each row
execute function public.set_project_seller_on_insert();

create or replace function public.validate_project_seller_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    if new.seller_id is not distinct from old.seller_id then
        return new;
    end if;

    if auth.role() = 'service_role' then
        perform public.validate_project_seller(new.seller_id, new.company_id);
        return new;
    end if;

    if not public.current_profile_is_admin() then
        raise exception 'Apenas administradores podem reatribuir vendedor do projeto.';
    end if;

    perform public.validate_project_seller(new.seller_id, new.company_id);
    return new;
end;
$$;

drop trigger if exists validate_project_seller_before_update
on public.projects;

create trigger validate_project_seller_before_update
before update of seller_id on public.projects
for each row
execute function public.validate_project_seller_update();
