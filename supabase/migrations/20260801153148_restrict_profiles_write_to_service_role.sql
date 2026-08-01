-- Restrict direct writes to profiles.
-- Team/user management must go through Edge Functions that use service role
-- and enforce permission hierarchy/business rules server-side.

drop policy if exists "admins manage profiles from own company"
on public.profiles;

drop policy if exists "users read profiles from own company"
on public.profiles;

create policy "users read profiles from own company"
on public.profiles
for select
to authenticated
using (company_id = public.current_company_id());
