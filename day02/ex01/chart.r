library(DBI)
library(RPostgres)
library(tidyverse)
library(nycflights13)
library(lubridate)
library(scales)

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
  customers_df <- tryCatch(
    {
      dbGetQuery(con, "SELECT event_time, event_type, price,
      user_id FROM public.customers_enriched WHERE event_type = 'purchase';")
    },
    error = function(e) {
      message("Failed to execute query.
        Please check your SQL syntax and table name.")
      message("Original error: ", e$message)
    }
  )

  # Step 5: Close the database connection.
  dbDisconnect(con)
  message("Database connection closed successfully.")

  # Step 6: Verify the imported data.
  if (!is.null(customers_df)) {
    print("Successfully imported data. Displaying the first 6 rows:")
    print(head(customers_df))

    print("Summary of the imported data frame:")
    summary(customers_df)
  }
} else {
  message("Could not proceed with query due to connection failure.")
}

make_datetime_100 <- function(year, month, day, time) {
  make_datetime(year, month, day, time %/% 100, time %% 100)
}

# Number of customers by month

# count the number of customers
customers_count <- customers_df %>%
  # round the dttm object to the nearest date
  # mutate add a new day column
  mutate(day = round_date(event_time, "day")) %>%
  group_by(day) %>%
  summarise(customer_count = n_distinct(user_id))

# create the figure
ggplot(
  customers_count,
  aes(x = day, y = customer_count)
) +
  geom_line(color = "royalblue", linewidth = 1) +
  scale_x_datetime(date_breaks = "1 month", date_labels = "%b") +
  labs(y = "Number of customers")

# Total sales by month
# count the sum of each purchased item
sales_count <- customers_df %>%
  mutate(month = floor_date(event_time, "month")) %>%
  group_by(month) %>%
  summarise(sales = sum(price))

# create the figure
ggplot(
  sales_count,
  aes(x = month, y = sales)
) +
  geom_col(color = "royalblue") +
  scale_y_continuous(labels = label_number(
    scale = 1 / 1000000,
    accuracy = 0.1
  )) +
  scale_x_datetime(date_labels = "%b", date_breaks = "1 month")

# Total spend / customers by month
# count the sum of each purchased item
sales_count <- customers_df %>%
  mutate(month = floor_date(event_time, "month")) %>%
  group_by(month) %>%
  summarise(sales = sum(price))

# create the figure
ggplot(
  sales_count,
  aes(x = month, y = sales)
) +
  geom_col(color = "royalblue") +
  scale_y_continuous(labels = label_number(
    scale = 1 / 1000000,
    accuracy = 0.1
  )) +
  scale_x_datetime(date_labels = "%b", date_breaks = "1 month")
