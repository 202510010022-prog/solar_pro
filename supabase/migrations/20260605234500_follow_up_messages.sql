-- Allows company users to create internal follow-up messages from stalled projects.
-- Billing/product announcements remain restricted by the existing admin policy.

drop policy if exists "users create follow up messages from own company"
on public.app_messages;

create policy "users create follow up messages from own company"
on public.app_messages for insert
to authenticated
with check (
    company_id = public.current_company_id()
    and payment_id is null
    and type = 'warning'
    and status = 'unread'
    and title = 'Follow-up sugerido'
    and created_by = auth.uid()
);
