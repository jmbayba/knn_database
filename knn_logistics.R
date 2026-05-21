# Load in libraries
library(DBI)
library(RMariaDB)
library(class)

# Gets password for local database via ".renviron" file
pwd <- Sys.getenv("MY_DB_PASSWORD")


# Establish connection to local MySQL instance
con <- dbConnect(
  RMariaDB::MariaDB(),
  host     = "127.0.0.1",     
  port     = 3306,              
  user     = "root",            
  password = pwd,  
  dbname   = "logistics"     
)


# Write your SQL statement as a string
query <- "SELECT on_time_flag, detention_minutes, actual_distance_miles FROM delivery_events, trips"

# Pull the data into an R data frame
df <- dbGetQuery(con, query)

# View the dimensions of the data frame (note the size)
dim(df)

# View the first few rows
head(df)

# Close the connection
dbDisconnect(con)

# Variables for prediction
detention <- 130
distance <- 1200
k <- 10

on_time <- knn(df[1:1000,2:3], c(detention, distance), df[1:1000,1], k)
on_time
