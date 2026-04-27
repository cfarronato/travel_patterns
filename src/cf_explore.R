# Install and load data.table (run install only once)
install.packages("data.table")
library(data.table)
library(ggplot2)

# Define paths
data_dir <- "~/Dropbox/Shared_travel patterns/raw_data"
code_dir <- "~/travel_patterns/src"

# (Optional) set working directory to code folder
setwd(code_dir)

# Read the dataset using data.table
file_path <- file.path(data_dir, "dataset.csv")
dt <- fread(file_path)

# Inspect
head(dt)
str(dt)

# convert to Date
dt[, start_date := as.Date(start_date, format = "%d%b%Y")]

# check
str(dt$start_date)
head(dt$start_date)

dt <- dt[year(start_date) > 1996]

# create year-month date (first day of month)
dt[, ym := as.Date(format(start_date, "%Y-01-01"))]

# count respondents per month
monthly_counts <- dt[, .(N=sum(fpd_viag)) , by = ym][order(ym)]

# plot
ggplot(monthly_counts, aes(x = ym, y = N)) +
  geom_line() +
  labs(x = "Month", y = "Number of respondents") +
  scale_x_date(date_labels = "%Y") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# top 10 regions by total weighted travelers
top_regions <- dt[, .(tot = sum(fpd_viag, na.rm = TRUE)),
                  by = regione_visitata][order(-tot)][1:10, regione_visitata]

# aggregate
yearly_counts <- dt[regione_visitata %in% top_regions,
                    .(N = sum(fpd_viag, na.rm = TRUE)),
                    by = .(ym, regione_visitata)][order(ym)]

# plot
ggplot(yearly_counts,
       aes(x = ym, y = N, color = as.factor(regione_visitata))) +
  geom_line() +
  labs(x = "Year", y = "Number of travelers", color = "Region") +
  scale_x_date(date_labels = "%Y") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# find top 10 provinces (by total weighted travelers)
top_prov <- dt[, .(tot = sum(fpd_viag, na.rm = TRUE)), 
               by = provincia_visitata][order(-tot)][1:10, provincia_visitata]

# aggregate only for top provinces
yearly_counts <- dt[provincia_visitata %in% top_prov,
                    .(N = sum(fpd_viag, na.rm = TRUE)),
                    by = .(ym, provincia_visitata)][order(ym)]

# plot
ggplot(yearly_counts, 
       aes(x = ym, y = N, color = as.factor(provincia_visitata))) +
  geom_line() +
  labs(x = "Year", y = "Number of travelers", color = "Province") +
  scale_x_date(date_labels = "%Y") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
