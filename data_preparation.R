# This file imports, cleans and validates (as best I can) the original data 
# sources saved in the Data/Original folder. Subsequent analyses use the cleaned 
# data files, which are created by this script and stored in Data/Processed.

# See end of document for footnotes. 

# ----------------------------- ENVIRONMENT ----------------------------
rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(tidyverse)
library(lubridate)
library(sf)



# -------------------------------- DATA --------------------------------

# NOTES: The original files from the LandMatrix don't read into R very well. I 
# first opened them in Numbers and re-exported as a CSV. 

# Tabular data on land acquisitions. (Source: LandMatrix) 
filepaths = list.files("./Data/Original/", pattern=".csv")
datasets = list()

for (file in filepaths) {
  datasets[[gsub(".csv", "", file)]] <- read_delim(paste("Data/Original/", file, sep=""), 
                                                   show_col_types=FALSE)   #(1)
}

# GeoJSON data on land acquisitions. (Source: LandMatrix)
locations <- st_read("./Data/Original/locations.geojson", quiet=TRUE)
areas <- st_read("./Data/Original/areas.geojson", quiet=TRUE)



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
  select(!c("is_public", "not_public", "size_under_contract")) %>%
  rename("investor_id"="operating_company_investor_id","size_under_contract"="current_size_under_contract", 
         "size_in_operation"="current_size_in_operation")

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

# Fix formats
lsla$deal_id <- as.integer(lsla$deal_id)


# Extracting year of contract signing
lsla <- lsla %>%
  separate(col=negotiation_status, into=c("split_neg_status", "r_neg_status"), 
           sep='#current#') %>%
  separate(col=implementation_status, into=c("split_imp_status", "r_imp_status"), 
           sep='#current#')
  

lsla$year_signed <- lsla$split_neg_status %>%                 # NOT EXACTLY. THIS IS JUST YEAR OF LAST STATUS CHANGE
  str_extract(pattern="[0-9-]{4,10}$") %>%
  ymd(truncated=2) %>%
  year()

lsla$year_implemented <- lsla$split_imp_status %>%            # NOT EXACTLY. THIS IS JUST THE DATE OF LATE STATUS CHANGE
  str_extract(pattern="[0-9-]{4,10}$") %>%
  ymd(truncated=2) %>%
  year()




# Drop intermediate objects
rm(datasets, file, filepaths)

### HACKY TEMPORARY SOLUTION TO DUPLICATES PROBLEM
lsla <- distinct(lsla, deal_id, .keep_all=TRUE)


# ---------------------- CLEAN GEOJSON DATA ----------------------------

# Drop observations where spatial accuracy is low
locations <- locations %>%
  filter(!(spatial_accuracy %in% c("ADMINISTRATIVE_REGION", "COUNTRY", "")))

# Convert deal_id to integer
locations$deal_id <- as.integer(locations$deal_id)

# Merge in additional deal data from tabular files
areas <- areas %>%
  select(c(id, name, type, deal_id, country, region)) %>%
  left_join(lsla, by="deal_id")

locations <- locations %>%
  left_join(lsla, by="deal_id")


### HACKY SOLUTION WHILE I WAIT TO SOLVE DUPLICATES PROBLEM
locations <- distinct(locations, deal_id, .keep_all=TRUE)


# ------------------------------ SAVE ---------------------------------

# Convert to sf object
lsla <- st_as_sf(lsla, coords=c("lon", "lat"), crs=4326)

# Save files for later use
saveRDS(lsla, file="./Data/lsla.RData")
saveRDS(locations, file="./Data/locations.RData")
saveRDS(areas, file="./Data/locations.RData")


# ---------------------------- FOOTNOTES -------------------------------

# (1) Some problems with data consistency in unused variables. 
# See: problems(deals_tabular)


# The GeoJSON and CVS files contain the same observations, but the number of 
# duplicates in each is different, which results in a different number of 
# observations.

# There are duplicates in the areas as well, but that's more complicated to 
# deal with. There are 190 distinct entries.



