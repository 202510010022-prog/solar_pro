-- SolarPro test profiles seed
-- Run this file after creating the users in Supabase Auth.
--
-- Test logins created for this project:
--   projetos.teste@solarpro.com.br / SolarPro@2026
--   daf.teste@solarpro.com.br      / SolarPro@2026
--   diretor.teste@solarpro.com.br  / SolarPro@2026
--
-- Important:
-- Do not create Supabase Auth users by inserting directly into auth.users.
-- Use Authentication > Users, Supabase Admin API, or the Supabase dashboard.

insert into public.companies (
    name,
    document,
    plan,
    plan_slug,
    subscription_status,
    trial_ends_at,
    billing_email,
    billing_provider,
    active
)
values (
    'Solar Pro Testes',
    '00.000.000/0001-00',
    'equipe',
    'equipe',
    'trial',
    now() + interval '14 days',
    'financeiro@solarpro.test',
    'manual',
    true
)
on conflict do nothing;

update public.companies
set
    plan = 'equipe',
    plan_slug = 'equipe',
    subscription_status = 'trial',
    trial_ends_at = coalesce(trial_ends_at, now() + interval '14 days'),
    billing_provider = 'manual'
where name = 'Solar Pro Testes';

with company as (
    select id
      from public.companies
     where name = 'Solar Pro Testes'
     order by created_at
     limit 1
),
user_data as (
    select *
      from (
        values
            (
                'projetos.teste@solarpro.com.br',
                'Assessor Projetos Teste',
                '2024101',
                'Assessor de Projetos',
                'assessor_projetos'
            ),
            (
                'daf.teste@solarpro.com.br',
                'Assessor DAF Teste',
                '2024102',
                'Assessor do DAF',
                'assessor_daf'
            ),
            (
                'diretor.teste@solarpro.com.br',
                'Diretor Teste',
                '2024103',
                'Diretor',
                'diretor'
            )
      ) as data(email, name, matricula, role, permission)
)
insert into public.profiles (
    id,
    company_id,
    name,
    matricula,
    email,
    role,
    permission,
    active
)
select
    auth_user.id,
    company.id,
    user_data.name,
    user_data.matricula,
    user_data.email,
    user_data.role,
    user_data.permission,
    true
from user_data
join auth.users auth_user
  on auth_user.email = user_data.email
cross join company
on conflict (id) do update set
    company_id = excluded.company_id,
    name = excluded.name,
    matricula = excluded.matricula,
    email = excluded.email,
    role = excluded.role,
    permission = excluded.permission,
    active = excluded.active;

insert into public.subscriptions (
    company_id,
    plan_slug,
    status,
    provider,
    current_period_start,
    current_period_end,
    notes
)
select
    id,
    plan_slug,
    subscription_status,
    billing_provider,
    now(),
    trial_ends_at,
    'Assinatura beta criada pelo seed de usuarios de teste.'
from public.companies
where name = 'Solar Pro Testes'
  and not exists (
      select 1
      from public.subscriptions
      where subscriptions.company_id = companies.id
  );
