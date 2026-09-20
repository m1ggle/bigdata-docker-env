#!/bin/bash
# ---------------------------------------------------------------------------
# Idempotently create the role + database used by DolphinScheduler metadata.
# Runs as a one-shot service (ds-db-init) against the already-running
# PostgreSQL, so it also works on environments whose postgres-data volume was
# initialised before DolphinScheduler was added (docker-entrypoint-initdb.d
# scripts would never re-run there).
# ---------------------------------------------------------------------------
set -e

# psql defaults dbname to PGUSER (=admin), which doesn't exist; target the
# maintenance database explicitly.
psql -v ON_ERROR_STOP=1 -d postgres <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dolphinscheduler') THEN
            CREATE ROLE dolphinscheduler LOGIN PASSWORD '${DS_DB_PASS}';
        END IF;
    END
    \$\$;
EOSQL

# CREATE DATABASE cannot run inside DO $$ .. $$, so guard it here instead.
if ! psql -tAc "SELECT 1 FROM pg_database WHERE datname = 'dolphinscheduler'" -d postgres | grep -q 1; then
    psql -v ON_ERROR_STOP=1 -d postgres -c "CREATE DATABASE dolphinscheduler OWNER dolphinscheduler"
fi

psql -v ON_ERROR_STOP=1 --dbname dolphinscheduler <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE dolphinscheduler TO dolphinscheduler;
    GRANT ALL ON SCHEMA public TO dolphinscheduler;
EOSQL

echo ">>> DolphinScheduler metadata database ready"
