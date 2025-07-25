#!/bin/bash
# This script dynamically finds all tables matching the 'data_2022_%' pattern
# and merges them into a single 'customers' table.

set -e # Exit immediately if a command exits with a non-zero status.

echo "Starting the dynamic merge process for customer data tables..."

# Use psql to execute a single, powerful PL/pgSQL block.
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

DO \$\$
DECLARE
    first_table_name TEXT;
    t_name TEXT;
BEGIN
    SELECT table_name INTO first_table_name
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name LIKE 'data_2022_%'
    ORDER BY table_name
    LIMIT 1;

    IF first_table_name IS NULL THEN
        RAISE NOTICE 'No tables found matching pattern data_2022_*. Nothing to merge.';
        RETURN;
    END IF;

    RAISE NOTICE 'Using table ''%'' as a template for the customers table structure.', first_table_name;

    DROP TABLE IF EXISTS public.customers_dirty;
    EXECUTE format('CREATE TABLE public.customers_dirty AS SELECT * FROM public.%I WITH NO DATA', first_table_name);

    FOR t_name IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name LIKE 'data_202%_%'
        ORDER BY table_name
    LOOP
        -- The RAISE NOTICE command is helpful for debugging; it prints to the Docker logs.
        RAISE NOTICE 'Merging data from table: %', t_name;
        EXECUTE format('INSERT INTO public.customers_dirty SELECT * FROM public.%I', t_name);
    END LOOP;
END
\$\$;

EOSQL

echo "Successfully merged all data tables into the 'customers_dirty' table."
