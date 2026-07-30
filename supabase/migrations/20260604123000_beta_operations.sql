-- SolarPro beta operations foundation.
-- Week 4: manual Pix tracking and in-app beta feedback.

create table if not exists public.manual_payments (
    id bigserial primary key,
    company_id uuid not null references public.companies(id) on delete cascade,
    subscription_id bigint references public.subscriptions(id) on delete set null,
    amount numeric(12,2) not null default 0,
    currency text not null default 'BRL',
    due_date date,
    paid_at timestamptz,
    status text not null default 'pending'
        check (status in ('pending', 'paid', 'overdue', 'canceled')),
    pix_reference text not null default '',
    receipt_url text not null default '',
    notes text not null default '',
    created_by uuid references auth.users(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.beta_feedback (
    id bigserial primary key,
    company_id uuid not null references public.companies(id) on delete cascade,
    profile_id uuid references public.profiles(id) on delete set null,
    rating integer not null default 5 check (rating between 1 and 5),
    area text not null default 'geral'
        check (area in ('geral', 'login', 'crm', 'projetos', 'dimensionamento', 'financeiro', 'sincronizacao', 'visual')),
    message text not null,
    status text not null default 'open'
        check (status in ('open', 'reviewing', 'resolved', 'archived')),
    app_version text not null default 'Solar Pro Mobile 0.1.0',
    device_info text not null default '',
    created_at timestamptz not null default now(),
    resolved_at timestamptz
);

create index if not exists idx_manual_payments_company_id
on public.manual_payments(company_id);

create index if not exists idx_manual_payments_status
on public.manual_payments(status);

create index if not exists idx_manual_payments_due_date
on public.manual_payments(due_date);

create index if not exists idx_beta_feedback_company_id
on public.beta_feedback(company_id);

create index if not exists idx_beta_feedback_status
on public.beta_feedback(status);

create index if not exists idx_beta_feedback_created_at
on public.beta_feedback(created_at desc);

alter table public.manual_payments enable row level security;
alter table public.beta_feedback enable row level security;

drop policy if exists "users read manual payments from own company" on public.manual_payments;
create policy "users read manual payments from own company"
on public.manual_payments for select
to authenticated
using (company_id = public.current_company_id());

drop policy if exists "admins manage manual payments from own company" on public.manual_payments;
create policy "admins manage manual payments from own company"
on public.manual_payments for all
to authenticated
using (company_id = public.current_company_id() and public.current_profile_is_admin())
with check (company_id = public.current_company_id() and public.current_profile_is_admin());

drop policy if exists "users read feedback from own company" on public.beta_feedback;
create policy "users read feedback from own company"
on public.beta_feedback for select
to authenticated
using (company_id = public.current_company_id());

drop policy if exists "users insert feedback from own company" on public.beta_feedback;
create policy "users insert feedback from own company"
on public.beta_feedback for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and (profile_id is null or profile_id = auth.uid())
);

drop policy if exists "admins update feedback from own company" on public.beta_feedback;
create policy "admins update feedback from own company"
on public.beta_feedback for update
to authenticated
using (company_id = public.current_company_id() and public.current_profile_is_admin())
with check (company_id = public.current_company_id() and public.current_profile_is_admin());
