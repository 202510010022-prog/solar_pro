create or replace function public.reserve_nominatim_request_slot()
returns void
language plpgsql
security invoker
as $$
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtext('solarpro:nominatim:global')
  );

  perform pg_catalog.pg_sleep(1.1);
end;
$$;

revoke execute on function public.reserve_nominatim_request_slot() from public;
revoke execute on function public.reserve_nominatim_request_slot() from anon;
revoke execute on function public.reserve_nominatim_request_slot() from authenticated;
grant execute on function public.reserve_nominatim_request_slot() to service_role;
