#!/bin/bash
# This script merges all tables matching the 'data_202*_*' pattern into a single 'customers' table.

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting the merge process for customer data tables..."

# Use psql to execute a series of SQL commands.
# The here-document (<<-EOSQL) passes the multi-line SQL to psql.
# -v ON_ERROR_STOP=1 ensures the script will exit if an SQL error occurs.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    CREATE TABLE public.customers AS
    SELECT * FROM public.data_2022_oct;
        -- (
        --     SELECT table_name
        --     FROM information_schema.tables
        --     WHERE table_schema = 'public' AND table_name LIKE 'data_202_-_%'
        --     ORDER BY table_name
        --     LIMIT 1
        -- );

    DO \$\$
    DECLARE
        t_name TEXT;
    BEGIN
        FOR t_name IN
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = 'public'
              AND table_name LIKE 'data_202_-_%'
              AND table_name <> 'data_2022_oct' --(
                -- SELECT table_name
                -- FROM information_schema.tables
                -- WHERE table_schema = 'public' AND table_name LIKE 'data_202_-_%'
                -- ORDER BY table_name
                -- LIMIT 1
            --)
        LOOP
            RAISE NOTICE 'Merging data from table: %', t_name;
            EXECUTE format('INSERT INTO public.customers SELECT * FROM public.%I', t_name);
        END LOOP;
    END
    \$\$;

EOSQL

echo "Successfully merged all data tables into the 'customers' table."
