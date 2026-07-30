-- SolarPro client-facing message center.
-- Keeps billing notices and product messages inside the customer app.

create table if not exists public.app_messages (
    id bigserial primary key,
    company_id uuid not null references public.companies(id) on delete cascade,
    payment_id bigint references public.manual_payments(id) on delete set null,
    title text not null,
    message text not null,
    type text not null default 'info'
        check (type in ('info', 'billing', 'warning', 'success')),
    status text not null default 'unread'
        check (status in ('unread', 'read', 'archived')),
    created_by uuid references auth.users(id) on delete set null,
    created_at timestamptz not null default now(),
    read_at timestamptz,
    expires_at timestamptz
);

create index if not exists idx_app_messages_company_id
on public.app_messages(company_id);

create index if not exists idx_app_messages_status
on public.app_messages(status);

create index if not exists idx_app_messages_created_at
on public.app_messages(created_at desc);

create index if not exists idx_app_messages_payment_id
on public.app_messages(payment_id);

alter table public.app_messages enable row level security;

drop policy if exists "users read messages from own company" on public.app_messages;
create policy "users read messages from own company"
on public.app_messages for select
to authenticated
using (
    company_id = public.current_company_id()
    and (expires_at is null or expires_at >= now())
);

drop policy if exists "users update own company message status" on public.app_messages;
create policy "users update own company message status"
on public.app_messages for update
to authenticated
using (company_id = public.current_company_id())
with check (
    company_id = public.current_company_id()
    and status in ('read', 'archived')
);

drop policy if exists "admins create messages for own company" on public.app_messages;
create policy "admins create messages for own company"
on public.app_messages for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
);
