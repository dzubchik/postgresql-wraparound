#!/bin/bash


su - postgres -c "psql -d db -f /data/prepare.sql"

su - postgres -c "pgbench -i -h localhost -U postgres db -n"