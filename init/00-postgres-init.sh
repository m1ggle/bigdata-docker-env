#!/bin/bash
# ---------------------------------------------------------------------------
# Runs once when the PostgreSQL container is first initialised.
# Creates the role + database used by the Hive metastore.
# ---------------------------------------------------------------------------
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Hive metastore role and database
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'hive') THEN
            CREATE ROLE hive LOGIN PASSWORD '${HIVE_DB_PASS}';
        END IF;
    END
    \$\$;

    SELECT 'CREATE DATABASE metastore OWNER hive'
    WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'metastore')\gexec
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname metastore <<-EOSQL
    GRANT ALL PRIVILEGES ON DATABASE metastore TO hive;
    GRANT ALL ON SCHEMA public TO hive;
EOSQL

echo ">>> PostgreSQL metastore database ready"
