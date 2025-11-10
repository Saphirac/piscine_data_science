#!/bin/bash
# Removes duplicates from 'customers' table, keeping only the first in chains where events are <=1s apart.

set -e

echo "Starting deduplication for 'customers' table..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE TABLE public.customers_clean AS
    WITH Ranked AS (
        SELECT *,
            LAG(event_time) OVER (PARTITION BY event_type, product_id, price, user_id, user_session ORDER BY event_time) AS prev_time
        FROM public.customers
    ),
    Grouped AS (
        SELECT *,
            CASE WHEN prev_time IS NULL OR event_time - prev_time > INTERVAL '1 second' THEN 1 ELSE 0 END AS new_group
        FROM Ranked
    ),
    NumberedEvents AS (
        SELECT *,
            SUM(new_group) OVER (PARTITION BY event_type, product_id, price, user_id, user_session ORDER BY event_time) AS grp
        FROM Grouped
    )
    SELECT event_time, event_type, product_id, price, user_id, user_session, category_id, category_code, brand
    FROM NumberedEvents
    WHERE ROW_NUMBER() OVER (PARTITION BY event_type, product_id, price, user_id, user_session, grp ORDER BY event_time) = 1;

    DROP TABLE public.customers;
    ALTER TABLE public.customers_clean RENAME TO customers;
EOSQL

echo "Deduplication script finished."
