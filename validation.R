# This file validates (as best I can) the original data sources saved in the 
# Data/Original folder. Validation informs certain processing decisions made in
# the processing file. Namely, I {INSERT WHAT I DID IN RESPONSE TO VALIDATION}


# --------------------------- ENVIRONMENT ---------------------------
rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(dplyr)
library(magrittr)



# ------------------------------ DATA -------------------------------
# Read pre-cleaned data into memory
lsla <- readRDS("./Data/lsla.R")
areas_sp <- readRDS("./Data/areas_sp.R")
locations_sp <- readRDS("./Data/locations_sp.R")



# --------------------- VALIDATE TABULAR DATA ------------------------

# NOTES: The original LandMatrix files have a considerable (~335) number of 
# duplicates in them.  

# Checking for Deal IDs that appear in only the tabular or spatial files. 
# IDs 3117 and 7648 appear only in the tabular data.
# There are no IDs which appear only in the spatial data.

sum(is.na(match(lsla$deal_id, locations_sp$deal_id))) # two IDs only appear in lsla
sum(is.na(match(locations_sp$deal_id, lsla$deal_id))) # no IDs only appear in locations_sp

missing_from_locations_sp <-lsla %>%      # stores observations for missing locations
  filter(!(lsla$deal_id %in% locations_sp$deal_id)) 

locations_sp %>%
  filter(!(locations_sp$deal_id %in% lsla$deal_id))


# Checking for duplicated IDs in tabular data (not checking spatial since subset).
# There are 175 IDs which have duplicates, and 510 entries matching those IDs. 
# Correspondingly, there are 335 "extra" observations. As a sanity check, 
# 1965 - 335 = 1630, which is the number of (unique) deals we have in our deals data. 
duplicated_ids <- unique(lsla$deal_id[duplicated(lsla$deal_id)])
entries_for_duplicated_ids <- lsla %>% 
  filter(lsla$deal_id %in% duplicated_ids)


# Check whether observations with non-duplicated ID match those in the spatial dataset.
non_dup_lsla <- lsla %>%
  filter(!(lsla$deal_id %in% duplicated_ids)) %>%
  filter(!(deal_id == 3117 | deal_id == 7648)) %>% # some IDs not in other data
  arrange(deal_id)

non_dup_locations_sp <- locations_sp %>%
  filter(!(locations_sp$deal_id %in% duplicated_ids)) %>%
  arrange(deal_id)

non_dup_lsla$point %>%
  sf()



# Creating CSV of duplicated entries to send to LandMatrix
write_csv(entries_for_duplicated_ids, "duplicated_entries.csv")



# ---------------------- VALIDATE GEOJSON DATA ------------------------





