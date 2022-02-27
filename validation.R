
# This file validates (as best I can) the original data sources saved in the 
# Data/Original folder. Validation informs certain processing decisions made in
# the processing file. Namely, I {INSERT WHAT I DID IN RESPONSE TO VALIDATION}



# --------------------------- ENVIRONMENT ---------------------------

rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(tidyverse)
library(sf)



# ------------------------------ DATA -------------------------------

# Read pre-cleaned data into memory
lsla <- readRDS("./Data/lsla.RData")
areas_sp <- readRDS("./Data/areas.RData")
locations_sp <- readRDS("./Data/locations.RData")




# --------------------- VALIDATE TABULAR DATA ------------------------


# NOTES: The original LandMatrix files have a considerable (~335) number of 
# duplicates in them. This falls to 101 (or 71 for the GeoJSON) once we drop 
# observations wherethere is only imprecise coordinates (see: data_preparation.R)


# Confirm there are no observations for deals not appearing in both datasets.            # PASS 
sum(is.na(match(lsla$deal_id, locations_sp$deal_id)))     # no IDs only in lsla
sum(is.na(match(locations_sp$deal_id, lsla$deal_id)))     # no IDs only in locations_sp

# Identify observations with duplicated deal_id
dup_ids <- unique(lsla$deal_id[duplicated(lsla$deal_id)])  # there are 38
dup_ids_locations <- unique(locations_sp$deal_id[duplicated(locations_sp$deal_id)]) # there are 34
all(dup_ids_locations %in% dup_ids)              # Duplicates in GeoJSON a subset of CSV

dup_lsla <- lsla %>% 
  filter(deal_id %in% dup_ids)               # there are 139 in CSV
dup_locations <- locations_sp %>%
  filter(deal_id %in% dup_ids)               # there are 109 in GeoJSON

# Creating CSV of duplicated entries to send to LandMatrix
write_csv(dup_lsla, "duplicated_entries_CSV.csv")
write_csv(dup_locations, "duplicated_entries_GeoJSON.csv")





# ---------------------- VALIDATE GEOJSON DATA ------------------------


# Here, I check that the non-duplicated observations are identical in deal_id 
# and location between the CSV and GeoJSON. They are, so we can be confident the 
# underlying data is the same. 



# Identify non-duplicated observations for CSV and GeoJSON sources
not_dup_lsla <- lsla %>%
  filter(!(lsla$deal_id %in% dup_ids)) %>%
  arrange(deal_id)

not_dup_locations <- locations_sp %>%
  filter(!(locations_sp$deal_id %in% dup_ids)) %>%
  arrange(deal_id)

# Confirm locations in set of non-duplicated entries match
all(not_dup_lsla$deal_id %in% not_dup_locations$deal_id)    # TRUE
all(not_dup_locations$deal_id %in% not_dup_lsla$deal_id)    # TRUE

st_distance(not_dup_lsla, not_dup_locations, by_element=TRUE)  # result is zero vector






# NOTES
# There are four duplicates in lsla that are not duplicates in locations_sp



