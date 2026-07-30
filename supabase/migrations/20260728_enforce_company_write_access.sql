-- Blocks write operations for companies without an active subscription.
-- Blocked companies keep read access to their own data, but cannot mutate it.

create or replace function public.current_company_subscription_active()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select coalesce(
        case
            when active is not true then false
            when subscription_status = 'active' then true
            when subscription_status = 'trial' then trial_ends_at is null or trial_ends_at >= now()
            else false
        end,
        false
    )
    from public.companies
    where id = public.current_company_id()
    limit 1
$$;

create or replace function public.current_company_can_write()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
    select public.current_company_subscription_active()
$$;

drop policy if exists "users manage clients from own company" on public.clients;
drop policy if exists "users read clients from own company" on public.clients;
drop policy if exists "users insert clients from active company" on public.clients;
drop policy if exists "users update clients from active company" on public.clients;
drop policy if exists "users delete clients from active company" on public.clients;

create policy "users read clients from own company"
on public.clients for select
to authenticated
using (company_id = public.current_company_id());

create policy "users insert clients from active company"
on public.clients for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users update clients from active company"
on public.clients for update
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
)
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users delete clients from active company"
on public.clients for delete
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

drop policy if exists "users manage budgets from own company" on public.budgets;
drop policy if exists "users read budgets from own company" on public.budgets;
drop policy if exists "users insert budgets from active company" on public.budgets;
drop policy if exists "users update budgets from active company" on public.budgets;
drop policy if exists "users delete budgets from active company" on public.budgets;

create policy "users read budgets from own company"
on public.budgets for select
to authenticated
using (company_id = public.current_company_id());

create policy "users insert budgets from active company"
on public.budgets for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users update budgets from active company"
on public.budgets for update
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
)
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users delete budgets from active company"
on public.budgets for delete
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

drop policy if exists "users manage projects from own company" on public.projects;
drop policy if exists "users read projects from own company" on public.projects;
drop policy if exists "users insert projects from active company" on public.projects;
drop policy if exists "users update projects from active company" on public.projects;
drop policy if exists "users delete projects from active company" on public.projects;

create policy "users read projects from own company"
on public.projects for select
to authenticated
using (company_id = public.current_company_id());

create policy "users insert projects from active company"
on public.projects for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users update projects from active company"
on public.projects for update
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
)
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users delete projects from active company"
on public.projects for delete
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

drop policy if exists "users manage project payments from own company" on public.project_payments;
drop policy if exists "users read project payments from own company" on public.project_payments;
drop policy if exists "users insert project payments from active company" on public.project_payments;
drop policy if exists "users update project payments from active company" on public.project_payments;
drop policy if exists "users delete project payments from active company" on public.project_payments;

create policy "users read project payments from own company"
on public.project_payments for select
to authenticated
using (company_id = public.current_company_id());

create policy "users insert project payments from active company"
on public.project_payments for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users update project payments from active company"
on public.project_payments for update
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
)
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users delete project payments from active company"
on public.project_payments for delete
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

drop policy if exists "users manage project documents from own company" on public.project_documents;
drop policy if exists "users read project documents from own company" on public.project_documents;
drop policy if exists "users insert project documents from active company" on public.project_documents;
drop policy if exists "users update project documents from active company" on public.project_documents;
drop policy if exists "users delete project documents from active company" on public.project_documents;

create policy "users read project documents from own company"
on public.project_documents for select
to authenticated
using (company_id = public.current_company_id());

create policy "users insert project documents from active company"
on public.project_documents for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users update project documents from active company"
on public.project_documents for update
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
)
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

create policy "users delete project documents from active company"
on public.project_documents for delete
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

drop policy if exists "users insert history from own company" on public.action_history;
drop policy if exists "users insert history from active company" on public.action_history;
create policy "users insert history from active company"
on public.action_history for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

drop policy if exists "users insert feedback from own company" on public.beta_feedback;
drop policy if exists "users insert feedback from active company" on public.beta_feedback;
create policy "users insert feedback from active company"
on public.beta_feedback for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
    and (profile_id is null or profile_id = auth.uid())
);

drop policy if exists "admins update feedback from own company" on public.beta_feedback;
drop policy if exists "admins update feedback from active company" on public.beta_feedback;
create policy "admins update feedback from active company"
on public.beta_feedback for update
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
    and public.current_company_can_write()
)
with check (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
    and public.current_company_can_write()
);

drop policy if exists "users update own company message status" on public.app_messages;
drop policy if exists "users update own company message status from active company" on public.app_messages;
create policy "users update own company message status from active company"
on public.app_messages for update
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_company_can_write()
)
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
);

drop policy if exists "users create follow up messages from own company" on public.app_messages;
drop policy if exists "users create follow up messages from active company" on public.app_messages;
create policy "users create follow up messages from active company"
on public.app_messages for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_company_can_write()
    and payment_id is null
    and type = 'warning'
    and status = 'unread'
    and title = 'Follow-up sugerido'
    and created_by = auth.uid()
);

drop policy if exists "admins create messages for own company" on public.app_messages;
drop policy if exists "admins create messages for active company" on public.app_messages;
create policy "admins create messages for active company"
on public.app_messages for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
    and public.current_company_can_write()
);

drop policy if exists "admins manage manual payments from own company" on public.manual_payments;
drop policy if exists "admins read manual payments from own company" on public.manual_payments;
drop policy if exists "admins insert manual payments from active company" on public.manual_payments;
drop policy if exists "admins update manual payments from active company" on public.manual_payments;
drop policy if exists "admins delete manual payments from active company" on public.manual_payments;

create policy "admins read manual payments from own company"
on public.manual_payments for select
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
);

create policy "admins insert manual payments from active company"
on public.manual_payments for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
    and public.current_company_can_write()
);

create policy "admins update manual payments from active company"
on public.manual_payments for update
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
    and public.current_company_can_write()
)
with check (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
    and public.current_company_can_write()
);

create policy "admins delete manual payments from active company"
on public.manual_payments for delete
to authenticated
using (
    company_id = public.current_company_id()
    and public.current_profile_is_admin()
    and public.current_company_can_write()
);
