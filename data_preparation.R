# This file imports, cleans and validates (as best I can) the original data 
# sources saved in the Data/Original folder. Subsequent analyses use the cleaned 
# data files, which are created by this script and stored in Data/Processed.

# See end of document for footnotes. 

# -------------------- ENVIRONMENT -----------------------
rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(tidyverse)
library(jsonlite)


# ---------------------- DATA ----------------------

# NOTES: The original files from the LandMatrix don't read into R very well. I 
# first opened them in Numbers and re-exported as a CSV. 


# Tabular data on land acquisitions. (Source: LandMatrix) 
contracts_tabular <- read_delim("./Data/Original/contracts.csv")
deals_tabular <- read_delim("./Data/Original/deals.csv")                    #(1)
investors_tabular <- read_delim("./Data/Original/investors.csv")
involvements_tabular <- read_delim("./Data/Original/involvements.csv")
locations_tabular <- read_delim("./Data/Original/locations.csv")


# Spatial data on land acquisitions. (Source: LandMatrix)
locations_spatial <- fromJSON("./Data/Original/locations.geojson")
areas_spatial <- fromJSON("./Data/Original/areas.geojson")




# -------------------- CLEANING -------------------------

# Switch column names to lowercase and replace spaces with underscores.
colnames(contracts_tabular) <- gsub(" ", "_", tolower(colnames(contracts_tabular)))
colnames(deals_tabular) <- gsub(" ", "_", tolower(colnames(deals_tabular)))
colnames(investors_tabular) <- gsub(" ", "_", tolower(colnames(investors_tabular)))
colnames(involvements_tabular) <- gsub(" ", "_", tolower(colnames(involvements_tabular)))
colnames(locations_tabular) <- gsub(" ", "_", tolower(colnames(locations_tabular)))



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




# ------------------ FOOTNOTES ------------------------

# (1) Some problems with data consistency in unused variables. 
# See: problems(deals_tabular)


