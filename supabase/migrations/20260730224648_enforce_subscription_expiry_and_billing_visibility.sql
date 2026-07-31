-- Enforce active subscription expiry and restrict manual payment visibility.
-- Companies with expired subscription_ends_at cannot write, even when status is active.
-- Manual payment records are visible only to admins from the same company.

drop policy if exists "users read manual payments from own company"
on public.manual_payments;

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
            when subscription_status = 'active' then
                subscription_ends_at is null or subscription_ends_at >= now()
            when subscription_status = 'trial' then
                trial_ends_at is null or trial_ends_at >= now()
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
