#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

CSV_DIR="/data/item"

for csv_file in "$CSV_DIR"/*.csv; do
    [ -e "$csv_file" ] || continue

    table_name=$(basename "$csv_file" .csv)
    # Sanitize the table name to allow only alphanumeric characters and underscores.
    table_name=$(echo "$table_name" | sed 's/[^a-zA-Z0-9_]//g')

    header=$(head -n 1 "$csv_file")

    # --- Logic to build column definitions with specific types ---
    column_defs=""
    IFS=','
    for col_name in $header; do
        case "$col_name" in
            product_id)
                col_type="INTEGER"
                ;;
            category_id)
                col_type="BIGINT"
                ;;
            category_code)
                col_type="TEXT"
                ;;
            brand)
                col_type="TEXT"
                ;;
            *)
                col_type="TEXT"
                ;;
        esac

        if [ -z "$column_defs" ]; then
            column_defs="\"$col_name\" $col_type"
        else
            column_defs="$column_defs, \"$col_name\" $col_type"
        fi
    done
    unset IFS

    create_table_sql="CREATE TABLE public.${table_name} (${column_defs});"

    echo "Creating table '${table_name}' from file '${csv_file}'..."

    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        DROP TABLE IF EXISTS public.${table_name};
        ${create_table_sql}
        COPY public.${table_name} FROM '${csv_file}' DELIMITER ',' CSV HEADER;
EOSQL

    echo "Successfully created and populated table '${table_name}'."
    echo "---"
done

echo "All CSV files have been processed."
