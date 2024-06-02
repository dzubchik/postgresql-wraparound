CREATE DATABASE vacuum_freeze_test;


create or replace function toast_pg_database_datacl() returns text as $body$
declare
mycounter int;
begin
for mycounter in select i from generate_series(1, 2800) i loop
                execute 'create role aaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' || mycounter;
execute 'grant ALL on database vacuum_freeze_test to aaaabbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb' || mycounter;
end loop;
return 'ok';
end;
$body$ language plpgsql volatile strict;



-- create roles and grant on the database
select toast_pg_database_datacl();

CREATE OR REPLACE FUNCTION get_database_xid_ages()
RETURNS TABLE(
  oldest_current_xid int,
  percent_towards_wraparound float,
  percent_towards_emergency_autovac float
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH max_age AS (
        SELECT 2000000000 AS max_old_xid,
               setting::int AS autovacuum_freeze_max_age
        FROM pg_catalog.pg_settings
        WHERE name = 'autovacuum_freeze_max_age'
    ), per_database_stats AS (
        SELECT datname,
               max_age.max_old_xid,
               max_age.autovacuum_freeze_max_age,
               age(d.datfrozenxid) AS xid_age  -- Rename column here to avoid ambiguity
        FROM pg_catalog.pg_database d
        CROSS JOIN max_age
        WHERE d.datallowconn
    )
    SELECT max(xid_age) AS oldest_current_xid,  -- Use the renamed column
           max(ROUND(100 * (xid_age / NULLIF(max_old_xid::float,0)))) AS percent_towards_wraparound,
           max(ROUND(100 * (xid_age / NULLIF(autovacuum_freeze_max_age::float,0)))) AS percent_towards_emergency_autovac
    FROM per_database_stats;
END;
$$