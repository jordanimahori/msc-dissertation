# This file imports, cleans and validates (as best I can) the original data 
# sources saved in the Data/Original folder. Subsequent analyses use the cleaned 
# data files, which are created by this script and stored in Data/Processed.

# See end of document for footnotes. 

# ----------------------------- ENVIRONMENT ----------------------------
rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(tidyverse)
library(sf)



# -------------------------------- DATA --------------------------------

# NOTES: The original files from the LandMatrix don't read into R very well. I 
# first opened them in Numbers and re-exported as a CSV. 

# Tabular data on land acquisitions. (Source: LandMatrix) 
filepaths = list.files("./Data/Original/", pattern=".csv")
datasets = list()

for (file in filepaths) {
  datasets[[gsub(".csv", "", file)]] <- read_delim(paste("Data/Original/", file, sep=""))   #(1)
}

# GeoJSON data on land acquisitions. (Source: LandMatrix)
locations_sp <- st_read("./Data/Original/locations.geojson")
areas_sp <- st_read("./Data/Original/areas.geojson")



# ------------------------- CLEAN TABULAR DATA  -------------------------

# Drop vars with majority missing observations & rename for easier referencing
for (i in 1:length(datasets)) {
  datasets[[i]] <- datasets[[i]] %>%
    select(where(~ mean(map_lgl(.x, is.na)) < 0.3)) %>%   # most vars are majority NA
    rename_with(tolower) %>%
    rename_with(~ gsub(" ", "_", .x)) %>%
    rename_with(~ gsub(":", "", .x)) %>%
    rename_with(~ gsub("_\\(.{1,}\\)", "", .x))
}


# Drop additional irrelevant variables & renaming for consistency
datasets$deals <- datasets$deals %>%          
  select(!c("is_public", "not_public")) %>%
  rename("investor_id"="operating_company_investor_id")

colnames(datasets$investors) <- paste("investor_", colnames(datasets$investors), sep="")

datasets$investors <- datasets$investors %>%
  rename("investor_id"="investor_investor_id", "investor_country_of_registration"="investor_country_of_registration/origin")

datasets$locations <- datasets$locations %>%
  separate(col=point, into=c("lat", "lon"), sep=",", remove=TRUE, convert=TRUE)

# Merge Tabular LandMatrix files
lsla <- datasets$deals %>%
  left_join(datasets$contracts, by = "deal_id") %>%
  left_join(datasets$investors, by = "investor_id") %>%
  left_join(datasets$locations, by = "deal_id")
  
# Drop observations missing a location, or where spatial accuracy is not precise
lsla <- lsla %>%
  filter(!(is.na(lsla$lat) | is.na(lsla$lon))) %>%     # five observations were missing coordinates
  filter(!(spatial_accuracy_level %in% c("Administrative region", "Country", NA))) # 1273 obs are imprecise, 1 is NA 

# Convert to sf object
lsla <- st_as_sf(lsla, coords=c("lon", "lat"), crs=4326, na.fail=FALSE)

# Drop intermediate objects
rm(datasets)

# Save file for later use
saveRDS(lsla, file="./Data/lsla.R")




# ---------------------- CLEAN GEOJSON DATA ----------------------------

# Drop observations for which spatial accuracy is low
locations_sp <- locations_sp %>%
  filter(!(spatial_accuracy %in% c("ADMINISTRATIVE_REGION", "COUNTRY", "")))




# Save as RDS
saveRDS(areas_sp, "./Data/areas_sp.R")
saveRDS(locations_sp, "./Data/locations_sp.R")



# ---------------------------- FOOTNOTES -------------------------------

# (1) Some problems with data consistency in unused variables. 
# See: problems(deals_tabular)


