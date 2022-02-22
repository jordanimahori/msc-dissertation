# This file validates (as best I can) the original data sources saved in the 
# Data/Original folder. Validation informs certain processing decisions made in
# the processing file. Namely, I {INSERT WHAT I DID IN RESPONSE TO VALIDATION}


# -------------------- ENVIRONMENT -----------------------
rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(tidyverse)


# ------------------- VALIDATION ------------------------

# NOTES: The original LandMatrix files have a considerable (~335) number of 
# duplicates in them.  

# Extracting the properties table from the GeoJSON.
compare_locations <- locations_spatial$features$properties

# Checking for Deal IDs that appear in only the tabular or spatial files. 
# IDs 3117 and 7648 appear only in the tabular data.
# There are no IDs which appear only in the spatial data.

sum(is.na(match(locations_tabular$deal_id, compare_locations$deal_id))) 

locations_tabular %>% 
  filter(!(locations_tabular$deal_id %in% compare_locations$deal_id)) 

compare_locations %>%
  filter(!(compare_locations$deal_id %in% locations_tabular$deal_id))


# Checking for duplicated IDs in tabular data (not checking spatial since subset).
# There are 175 IDs which have duplicates, and 510 entries matching those IDs. 
# Correspondingly, there are 335 "extra" observations. As a sanity check, 
# 1965 - 335 = 1630, which is the number of (unique) deals we have in our deals data. 
duplicated_ids <- unique(locations_tabular$deal_id[duplicated(locations_tabular$deal_id)])
entries_for_duplicated_ids <- locations_tabular %>% 
  filter(locations_tabular$deal_id %in% duplicated_ids)

# Creating CSV of duplicated entries to send to LandMatrix
write_csv(entries_for_duplicated_ids, "duplicated_entries.csv")

