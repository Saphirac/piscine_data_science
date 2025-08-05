library(DBI)
library(RPostgres)
library(tidyverse)

db_host <- "localhost"
db_port <- 5432
db_name <- "piscineds" # Replace with your database name
db_user <- "mcourtoi" # Replace with your username
db_password <- "mysecretpassword"

con <- tryCatch(
  {
    dbConnect(
      RPostgres::Postgres(),
      dbname = db_name,
      host = db_host,
      port = db_port,
      user = db_user,
      password = db_password
    )
  },
  error = function(e) {
    message("Failed to connect to the database.
    Please check your credentials and network connection.")
    message("Original error: ", e$message)
  }
)

if (!is.null(con)) {
  # Define the SQL query you want to execute.
  # This example selects all data from the 'customers' table.
  sql_query <- "SELECT event_type FROM public.customers_enriched;"


  customers_df <- tryCatch(
    {
      dbGetQuery(con, sql_query)
    },
    error = function(e) {
      message("Failed to execute query.
        Please check your SQL syntax and table name.")
      message("Original error: ", e$message)
    }
  )

  # Step 5: Close the database connection.
  # This is a critical step to release resources on the database server.
  dbDisconnect(con)
  message("Database connection closed successfully.")

  # Step 6: Verify the imported data.
  # If the query was successful, display the first few rows of the data frame.
  if (!is.null(customers_df)) {
    print("Successfully imported data. Displaying the first 6 rows:")
    print(head(customers_df))

    print("Summary of the imported data frame:")
    summary(customers_df)
  }
} else {
  message("Could not proceed with query due to connection failure.")
}

event_summary <- customers_df %>%
  group_by(event_type) %>%
  summarise(count = n()) %>%
  # Ungroup to perform calculations on the whole summary table.
  ungroup() %>%
  # Arrange by count for a more organized plot.
  arrange(desc(count)) %>%
  # Calculate the percentage and create well-formatted labels.
  mutate(
    percentage = count / sum(count),
    label_text = paste0(
      event_type, "\n",
      scales::percent(percentage, accuracy = 0.1)
    )
  )

db_name <- "piscineds"
db_name

# pie(customers_df)
