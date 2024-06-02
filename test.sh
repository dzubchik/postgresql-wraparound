#!/bin/bash

su - postgres -c "pgbench -c 50 -s 100 -t 2147483647 -P5 -h localhost -U postgres db -n -f /data/run.sql" &

while true;do su - postgres -c "psql -d db -c \"SELECT * FROM get_database_xid_ages();\"" && sleep 5;done