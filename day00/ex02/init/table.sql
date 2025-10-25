DROP TABLE IF EXISTS public.data_2022_oct;

CREATE TABLE public.data_2022_oct (
    event_time      TIMESTAMPTZ,        -- Type 1: Timestamp with Time Zone (mandatory first column)
    event_type      VARCHAR(255),       -- Type 2: Variable-length string
    product_id      INTEGER,            -- Type 3: Standard 4-byte integer
    price           NUMERIC(10, 2),     -- Type 4: Exact decimal number for currency
    user_id         BIGINT,             -- Type 5: Large 8-byte integer
    user_session    UUID                -- Type 6: Universally Unique Identifier
);

COPY public.data_2022_oct FROM '/data/customer/data_2022_oct.csv' DELIMITER ',' CSV HEADER;
