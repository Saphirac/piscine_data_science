#!/bin/bash
# This script enriches the 'customers' table by joining it with product data from the 'item' table.

set -e

echo "Starting enrichment process for the 'customers' table..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    -- Step 1: Create a new, temporary table containing the enriched data.
    -- We use a LEFT JOIN to ensure no customer events are lost, even if a product is missing from the item table.
    CREATE TABLE public.customers_enriched AS
    SELECT
        c.event_time,
        c.event_type,
        c.product_id,
        c.price,
        c.user_id,
        c.user_session,
        i.category_id,
        i.category_code,
        i.brand
    FROM
        public.customers AS c
    LEFT JOIN
        public.item AS i ON c.product_id = i.product_id;

    -- Step 2: Drop the original, non-enriched 'customers' table.
    -- donotDROP TABLE public.customers;

    -- Step 3: Rename the new, enriched table to the original name.
    -- donotALTER TABLE public.customers_enriched RENAME TO customers;

EOSQL

echo "Customer data enrichment script finished."
