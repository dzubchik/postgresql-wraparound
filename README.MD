## Run docker-compose
```
docker-compose up -d

```
# Restore backup
```
pg_restore --verbose -U postgres --no-publications --disable-triggers --no-subscriptions -h localhost  -d db backup

```

su postgres 

psql -d db


 

DO $$
DECLARE
    i INT;
    uid_prefix TEXT := 'sfg_';
    uid_suffix TEXT;
BEGIN
    FOR i IN 1000..1600 LOOP
        uid_suffix := lpad(i::text, 10, '0');  -- Pad the counter to maintain length
        EXECUTE format('SELECT create_analytics_user(%L)', uid_prefix || uid_suffix);
    END LOOP;
END $$;

# Set parameters to postgres config
```
ALTER SYSTEM SET synchronous_commit = off;
ALTER SYSTEM SET autovacuum_freeze_max_age = 2000000;
ALTER SYSTEM SET log_autovacuum_min_duration = 0;
ALTER SYSTEM SET full_page_writes = off;
ALTER SYSTEM SET fsync = off;
```
# Restart docker-compose
```docker-compose restart```
# Run pgbench init
pgbench -i -h localhost -U postgres db
# Run a benchmark test on PostgreSQL
```pgbench -c 10 -s 100 -t 100000000000 -P5 -h localhost -U postgres db` -n``
# Check percent_towards_emergency_autovac if it more than 100, wraparound protection does not work
```WITH max_age AS (
       SELECT 2000000000 as max_old_xid,
              setting AS autovacuum_freeze_max_age
       FROM pg_catalog.pg_settings
       WHERE name = 'autovacuum_freeze_max_age' ),
        per_database_stats AS (
            SELECT datname,
                   m.max_old_xid::int,
                   m.autovacuum_freeze_max_age::int,
                   age(d.datfrozenxid) AS oldest_current_xid
            FROM pg_catalog.pg_database d
                     JOIN max_age m ON (true)
            WHERE d.datallowconn )
   SELECT max(oldest_current_xid) AS oldest_current_xid,
          max(ROUND(100*(oldest_current_xid/max_old_xid::float))) AS percent_towards_wraparound,
          max(ROUND(100*(oldest_current_xid/autovacuum_freeze_max_age::float))) AS percent_towards_emergency_autovac  FROM per_database_stats;```
# See docker-compose logs
```docker-compose logs -f```

tee file > /dev/null <<EOF
\set id random(1, 100000)
UPDATE pgbench_accounts SET abalance = abalance + 1 WHERE aid = :id;
EOF

pgbench -c 100 -t 100000000000 -P 5 -h localhost -U postgres -f file db -n
