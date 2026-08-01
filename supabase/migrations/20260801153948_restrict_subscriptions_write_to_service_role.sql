-- Restrict direct writes to subscriptions.
-- Billing/subscription changes must go through Edge Functions or internal
-- service-role processes.

drop policy if exists "admins manage subscriptions from own company"
on public.subscriptions;

drop policy if exists "users read subscriptions from own company"
on public.subscriptions;

create policy "users read subscriptions from own company"
on public.subscriptions
for select
to authenticated
using (company_id = public.current_company_id());
