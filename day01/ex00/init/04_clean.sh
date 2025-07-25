#!/bin/bash
# This script removes duplicates from the 'customers' table using the
# high-performance CTAS (Create Table As Select) method.

set -e

echo "Starting high-performance deduplication for 'customers' table..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL

    -- Step 1: Create a new, clean table containing only the unique rows.
    -- This is a single, highly optimized operation.
    CREATE TABLE public.customers AS
    WITH NumberedEvents AS (
        SELECT
            *, -- Select all original columns
            ROW_NUMBER() OVER (
                PARTITION BY
                    event_type,
                    product_id,
                    price,
                    user_id,
                    user_session
                ORDER BY
                    event_time ASC
            ) as rn
        FROM
            public.customers_dirty
    )
    SELECT
        event_time,
        event_type,
        product_id,
        price,
        user_id,
        user_session
    FROM NumberedEvents
    WHERE rn = 1; -- Only select the first occurrence of each event.

    -- Step 2: Drop the original, bloated table.
    -- have to check both before DROP TABLE public.customers_dirty;

EOSQL

echo "Deduplication script finished."
