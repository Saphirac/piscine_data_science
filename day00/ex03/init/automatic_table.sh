#!/bin/bash
# This script is executed when the PostgreSQL container is first started.

set -e # Exit immediately if a command exits with a non-zero status.

# The directory inside the container where the CSV files are mounted.
CSV_DIR="/data/customer"

# Loop through each .csv file in the specified directory.
for csv_file in "$CSV_DIR"/*.csv; do
    # Check if the file exists to avoid errors with an empty directory.
    [ -e "$csv_file" ] || continue

    # Extract the base filename without the path and .csv extension for the table name.
    table_name=$(basename "$csv_file" .csv)
    # Sanitize the table name to allow only alphanumeric characters and underscores.
    table_name=$(echo "$table_name" | sed 's/[^a-zA-Z0-9_]//g')

    # Read the header line from the CSV file.
    header=$(head -n 1 "$csv_file")

    # --- Logic to build column definitions with specific types ---
    column_defs=""
    # Set the Internal Field Separator to a comma to loop through column names.
    IFS=','
    for col_name in $header; do
        # Determine the SQL data type based on the column name.
        case "$col_name" in
            event_time)
                col_type="TIMESTAMPTZ"
                ;;
            product_id)
                col_type="INTEGER"
                ;;
            price)
                col_type="NUMERIC(10, 2)"
                ;;
            user_id)
                col_type="BIGINT"
                ;;
            user_session)
                col_type="UUID"
                ;;
            *) # Default case for any other column
                col_type="VARCHAR(255)"
                ;;
        esac

        # Append the column definition "column_name D_TYPE," to the list.
        if [ -z "$column_defs" ]; then
            column_defs="\"$col_name\" $col_type"
        else
            column_defs="$column_defs, \"$col_name\" $col_type"
        fi
    done
    unset IFS # Unset IFS to return to default behavior.

    # Construct the final CREATE TABLE statement.
    create_table_sql="CREATE TABLE public.${table_name} (${column_defs});"

    echo "Creating table '${table_name}' from file '${csv_file}'..."

    # Use psql to execute the CREATE TABLE and COPY commands.
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
        DROP TABLE IF EXISTS public.${table_name};
        ${create_table_sql}
        COPY public.${table_name} FROM '${csv_file}' DELIMITER ',' CSV HEADER;
EOSQL

    echo "Successfully created and populated table '${table_name}'."
    echo "---"
done

echo "All CSV files have been processed."
