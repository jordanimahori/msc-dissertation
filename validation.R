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
lsla <- readRDS("./Data/lsla.R")
areas_sp <- readRDS("./Data/areas_sp.R")
locations_sp <- readRDS("./Data/locations_sp.R")



# --------------------- VALIDATE TABULAR DATA ------------------------

# NOTES: The original LandMatrix files have a considerable (~335) number of 
# duplicates in them. This falls to 101 (or 71 for the GeoJSON) once we drop 
# observations wherethere is only imprecise coordinates (see: data_preparation.R)


# Check for Deal IDs that appear in only the tabular or spatial files. 
sum(is.na(match(lsla$deal_id, locations_sp$deal_id)))     # no IDs only in lsla
sum(is.na(match(locations_sp$deal_id, lsla$deal_id)))     # no IDs only in locations_sp

# Check for duplicate deal_id in lsla
duplicated_ids <- unique(lsla$deal_id[duplicated(lsla$deal_id)]) # there are 38
duplicated_ids_locations_sp <- unique(locations_sp$deal_id[duplicated(locations_sp$deal_id)]) # there are 34
all(duplicated_ids_locations_sp %in% duplicated_ids) # GeoJSON a subset of CSV

# Identify observations matching duplicated deal_id
duplicated_obs_lsla <- lsla %>% 
  filter(lsla$deal_id %in% duplicated_ids)            # there are 139 in CSV
duplicated_obs_locations_sp <- locations_sp %>%
  filter(locations_sp$deal_id %in% duplicated_ids)    # there are 109 in GeoJSON

# Confirm number of unique obs by deal_id is the same across the two sources.
length(unique(locations_sp$deal_id)) == length(unique(lsla$deal_id))   # is TRUE

# Creating CSV of duplicated entries to send to LandMatrix
write_csv(duplicated_obs, "duplicated_entries_CSV.csv")
write_csv(duplicated_obs_locations_sp, "duplicated_entries_GeoJSON.csv")



# ---------------------- VALIDATE GEOJSON DATA ------------------------

# Here, I check that the non-duplicated observations are identical in deal_id 
# and location between the CSV and GeoJSON. They are, so we can be confident the 
# underlying data is the same. 


# Identify non-duplicated observations for CSV and GeoJSON sources
non_dup_lsla <- lsla %>%
  filter(!(lsla$deal_id %in% duplicated_ids)) %>%
  arrange(deal_id)

non_dup_locations_sp <- locations_sp %>%
  filter(!(locations_sp$deal_id %in% duplicated_ids)) %>%
  arrange(deal_id)

# Check that non-duplicated observations have the same deal_ids
all(non_dup_lsla$deal_id %in% non_dup_locations_sp$deal_id)    # TRUE
all(non_dup_locations_sp$deal_id %in% non_dup_lsla$deal_id)    # TRUE

# Check locations of non-duplicated entries match
st_distance(non_dup_lsla, non_dup_locations_sp, by_element=TRUE)  # result is zero vector






