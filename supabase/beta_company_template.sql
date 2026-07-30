-- SolarPro beta company template
-- Use este arquivo como base no Supabase SQL Editor.
-- Troque os valores entre <> antes de executar.

-- 1) Criar empresa beta
insert into public.companies (
    name,
    document,
    plan,
    plan_slug,
    subscription_status,
    trial_ends_at,
    billing_email,
    billing_provider,
    billing_notes,
    active
)
values (
    '<Nome da empresa>',
    '<CNPJ ou documento>',
    'equipe',
    'equipe',
    'trial',
    now() + interval '14 days',
    '<email financeiro>',
    'manual',
    'Empresa cadastrada para beta manual.',
    true
);

-- 2) Depois crie o usuario em Authentication > Users.
-- 3) Copie o UUID do usuario e rode o insert abaixo.

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
    '<uuid do usuario auth>'::uuid,
    companies.id,
    '<Nome do usuario>',
    '<matricula ou identificador>',
    '<email do usuario>',
    'Diretor',
    'diretor',
    true
from public.companies
where companies.name = '<Nome da empresa>';

-- 4) Registrar assinatura beta manual
insert into public.subscriptions (
    company_id,
    plan_slug,
    status,
    provider,
    started_at,
    current_period_end,
    notes
)
select
    companies.id,
    companies.plan_slug,
    companies.subscription_status,
    companies.billing_provider,
    now(),
    companies.trial_ends_at,
    'Assinatura beta criada manualmente.'
from public.companies
where companies.name = '<Nome da empresa>';

-- 5) Registrar cobranca Pix manual quando houver cobranca
insert into public.manual_payments (
    company_id,
    amount,
    due_date,
    status,
    pix_reference,
    notes
)
select
    companies.id,
    99.90,
    current_date + interval '7 days',
    'pending',
    '<chave pix ou identificador da cobranca>',
    'Primeira cobranca manual do beta.'
from public.companies
where companies.name = '<Nome da empresa>';
