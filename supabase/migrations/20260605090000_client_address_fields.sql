alter table public.clients
add column if not exists zip_code text not null default '',
add column if not exists street text not null default '',
add column if not exists address_number text not null default '',
add column if not exists neighborhood text not null default '',
add column if not exists address_complement text not null default '';

