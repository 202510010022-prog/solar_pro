-- Add idempotency keys to prevent duplicate payment creation.
-- Existing rows may keep null keys; new app/admin flows should send a stable UUID.

alter table public.project_payments
    add column if not exists idempotency_key text;

alter table public.manual_payments
    add column if not exists idempotency_key text;

create unique index if not exists project_payments_idempotency_key_unique
on public.project_payments(idempotency_key)
where idempotency_key is not null;

create unique index if not exists manual_payments_idempotency_key_unique
on public.manual_payments(idempotency_key)
where idempotency_key is not null;
