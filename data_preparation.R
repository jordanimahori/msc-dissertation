# This file imports, cleans and validates (as best I can) the original data 
# sources saved in the Data/Original folder. Subsequent analyses use the cleaned 
# data files, which are created by this script and stored in Data/Processed.

# See end of document for footnotes. 

# -------------------- ENVIRONMENT -----------------------
rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(tidyverse)
library(sf)

# ---------------------- DATA ----------------------

# NOTES: The original files from the LandMatrix don't read into R very well. I 
# first opened them in Numbers and re-exported as a CSV. 


# Tabular data on land acquisitions. (Source: LandMatrix) 
filepaths = list.files("./Data/Original/", pattern=".csv")
datasets = list()

for (file in filepaths) {
  datasets[[gsub(".csv", "", file)]] <- read_delim(paste("Data/Original/", file, sep=""))   #(1)
}


# Spatial data on land acquisitions. (Source: LandMatrix)
locations_spatial <- st_read("./Data/Original/locations.geojson")
areas_spatial <- st_read("./Data/Original/areas.geojson")



# -------------------- CLEANING -------------------------

# Drop vars with majority missing observations & rename for easier referencing
for (i in 1:length(datasets)) {
  datasets[[i]] <- datasets[[i]] %>%
    select(where(~ mean(map_lgl(.x, is.na)) < 0.3)) %>%   # most vars are majority NA
    rename_with(tolower) %>%
    rename_with(~ gsub(" ", "_", .x)) %>%
    rename_with(~ gsub(":", "", .x)) %>%
    rename_with(~ gsub("_\\(.{1,}\\)", "", .x))
}

# Dropping additional irrelevant variables & renaming for consistency
datasets$deals <- datasets$deals %>%          
  select(!c("is_public", "not_public")) %>%
  rename("investor_id"="operating_company_investor_id")

colnames(datasets$investors) <- paste("investor_", colnames(datasets$investors), sep="")
datasets$investors <- rename(datasets$investors, "investor_id"="investor_investor_id", "investor_country_of_registration"="investor_country_of_registration/origin")

# Merging
lsla <- datasets$deals %>%
  left_join(datasets$contracts, by = "deal_id") %>%
  left_join(datasets$investors, by = "investor_id") %>%
  left_join(datasets$locations, by = "deal_id")

# Dropping intermediate objects
rm(datasets)



# ------------------ FOOTNOTES ------------------------

# (1) Some problems with data consistency in unused variables. 
# See: problems(deals_tabular)


