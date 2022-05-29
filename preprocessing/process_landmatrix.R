
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


# Tabular data on land acquisitions (Source: LandMatrix) 
filepaths = list.files("./data/raw/landmatrix/", pattern=".csv")
datasets = list()

for (file in filepaths) {
  datasets[[gsub(".csv", "", file)]] <- read_delim(
    paste("data/raw/landmatrix/", file, sep=""), show_col_types=FALSE)   #(1)
}


# GeoJSON data on land acquisitions (Source: LandMatrix)
locations <- st_read("./data/raw/landmatrix/locations.geojson", quiet=TRUE)
areas <- st_read("./data/raw/landmatrix/areas.geojson", quiet=TRUE)





# ------------------------- CLEAN TABULAR DATA  -------------------------


# Drop vars with majority missing observations & rename for easier referencing
for (i in 1:length(datasets)) {
  datasets[[i]] <- datasets[[i]] %>%
    select(where(~ mean(map_lgl(.x, is.na)) < 0.5)) %>%     # most vars are majority NA
    rename_with(tolower) %>%
    rename_with(~ gsub(" ", "_", .x)) %>%
    rename_with(~ gsub(":", "", .x)) %>%
    rename_with(~ gsub("_\\(.{1,}\\)", "", .x))
}


# Drop additional irrelevant variables & rename for consistency
datasets$deals <- datasets$deals %>%          
  select(!c(is_public, not_public, size_under_contract,comment_on_land_area, 
            current_size_under_contract)) %>%
  rename(investor_id=operating_company_investor_id, country=target_country,
         area_in_operation=current_size_in_operation, area_contracted=deal_size,
         area_intended=intended_size, operating_company_registration=`operating_company_country_of_registration/origin`)

colnames(datasets$investors) <- paste("investor_", colnames(datasets$investors), sep="")

datasets$investors <- datasets$investors %>%
  rename("investor_id"="investor_investor_id", 
         "investor_country_of_registration"="investor_country_of_registration/origin")

datasets$locations <- datasets$locations %>%
  separate(col=point, into=c("lat", "lon"), sep=",", remove=TRUE, convert=TRUE) %>%
  filter(!(spatial_accuracy_level %in% c("Administrative region", "Country", NA))) %>%
  filter(!(is.na(lat) | is.na(lon))) %>%
  group_by(deal_id) %>%
  summarise(lat = mean(lat), lon = mean(lon))                                     # set location as average of coordinates

datasets$contracts <- datasets$contracts %>%
  group_by(deal_id) %>%
  summarise(contract_duration=max(duration_of_the_agreement, 0, na.rm=TRUE)) %>%
  filter(!(contract_duration == 0))                                                # where duplicates, keep longest duration


# Merge Tabular LandMatrix files
lsla <- datasets$deals %>%
  left_join(datasets$contracts, by = "deal_id") %>%
  left_join(datasets$investors, by = "investor_id") %>%
  left_join(datasets$locations, by = "deal_id")


# Set deal_id format to integer
lsla$deal_id <- as.integer(lsla$deal_id)





# --------------------- EXTRACT STATUS CHANGES---------------------------

# Changes of status are indicated by '#current#' which divides the status
# and year in which that change occured; and by '##In operation (production)|'
# which follows the year in which that status change occurred. Only concluded
# negotiations are included in the dataset, and consequently the year of change
# to current status is the year of signing. Since projects can become inactive, 
# I need to separate between cases where the project is still active, and where 
# it has since become inactive to assign the year of 'current' to the right 
# characterization.


# Extract year in which the contract was signed
lsla <- lsla %>%
  separate(col=negotiation_status, into=c("neg_status_split", NA), 
           sep='#current#') %>%
  separate(col=neg_status_split, into=c("concluded", NA), 
           sep='##Concluded \\(Contract signed\\)')

lsla$year_signed <- lsla$concluded %>%
  str_extract(pattern="[0-9-]{4,10}$") %>%
  ymd(truncated=2) %>%
  year()


# Extract year in which the project became operational. 
lsla <- lsla %>%
  separate(col=implementation_status, into=c("imp_status_current", "sp1"), 
           sep='#current#', remove=FALSE) %>%
  separate(col=imp_status_current, into=c("imp_production", "sp2"), 
           sep='##In operation \\(production\\)', remove=FALSE)

lsla$imp_status_current <- lsla$imp_status_current %>%
  str_extract(pattern="[0-9-]{4,10}$") %>% 
  ymd(truncated=2) %>%
  year()

lsla$imp_production <- lsla$imp_production %>%
  str_extract(pattern= "[0-9-]{4,10}$") %>%
  ymd(truncated=2) %>%
  year()


lsla$year_operational <- NA
lsla$year_abandoned <- NA

for (i in 1:length(lsla$deal_id)) {
  
  if (lsla$current_implementation_status[i] == 'In operation (production)') {
      lsla$year_operational[i] <- min(lsla$imp_status_current[i], lsla$imp_production[i], 10000, na.rm=TRUE)
      if (lsla$year_operational[i] == 10000) {lsla$year_operational[i] <- NA}         # IDEALLY FIND A LESS HACKY WAY TO DO THIS
  }
  
  if (lsla$current_implementation_status[i] == 'Project abandoned' && !is.na(lsla$sp2[i])) {
    lsla$year_operational[i] <- lsla$imp_production[i]
    lsla$year_abandoned[i] <- lsla$imp_status_current[i]
  }
}


# Extract investment & crop types
lsla$investment_type <- lsla$intention_of_investment %>%
  str_extract(pattern="[A-Za-z- ,/]{1,}$")

lsla$crop_type <- lsla$`crops_area/yield/export` %>%
  str_extract(pattern="[A-Za-z-\\(\\) ,/]{1,}$")

lsla$investment_type <- replace_na(lsla$investment_type, "Other")  # LOOK INTO WHY THIS IS HERE


# Group investment types into broader categories
for (i in 1:length(lsla$investment_type)) {
  candidate <- lsla$investment_type[i]
  if (str_detect(candidate, pattern="(Food crops)|(Agriculture)")) {
    lsla$investment_type[i] <- "Food"
  } else if (str_detect(candidate, pattern = "(Non-food)|(Biofuels)")) {
    lsla$investment_type[i] <- "Non-food"
  } else if (str_detect(candidate, pattern = "Livestock")) {
    lsla$investment_type[i] <- "Livestock"
  } else if (str_detect(candidate, pattern = "(Forest)|(Timber)|(Conservation)")) {
    lsla$investment_type[i] <- "Forestry"
  } else if (str_detect(candidate, pattern = "Mining")) {
    lsla$investment_type[i] <- "Mining"
  } else if (str_detect(candidate, pattern = "Energy")) {
    lsla$investment_type[i] <- "Energy"
  } else if (str_detect(candidate, pattern = "Industry")) {
    lsla$investment_type[i] <- "Industry"
  } else {
    lsla$investment_type[i] <- "Other"
  }
}

lsla$investment_type <- as_factor(lsla$investment_type)


# Create dummies for types of crops
lsla$palm_oil <- as_factor(ifelse(str_detect(lsla$crop_type, pattern = "Oil Palm"), 1, 0))
lsla$rubber <- as_factor(ifelse(str_detect(lsla$crop_type, pattern = "Rubber"), 1, 0))
lsla$staples <- as_factor(ifelse(str_detect(lsla$crop_type, pattern = "(Rice)|(Wheat)|(Corn)|(Casava)|(Soya)|(Beans)|(Potatoes)"), 1, 0))


# Reclassify Rubber Trees as Non-Food Agriculture
lsla$investment_type[lsla$rubber == '1'] <- "Non-food"

# Reclassify Palm Oil Plantations as Food Agriculture
lsla$investment_type[lsla$palm_oil == '1'] <- "Food"


# Manually reclassify investment_type to inferred type based on crop type
lsla$investment_type[lsla$deal_id %in% c(3214, 8906)] <- "Forestry"
lsla$investment_type[lsla$deal_id %in% c(8452, 5899, 1334, 8679)] <- "Food"


# Drop intermediate variables
lsla <- lsla %>%
  select(!c(intention_of_investment, concluded, implementation_status, 
            imp_status_current, imp_production, sp2, sp1, `crops_area/yield/export`))


# Drop observations missing locations or year information
lsla <- lsla %>% 
  filter(!(is.na(lat) | is.na(lon))) %>%                   # Drop observations without locations
  filter(!(is.na(year_signed) & is.na(year_operational)))    # Drop observations without either signed or operational date


# Add indicator if spatial extent is available
lsla$has_extent <- ifelse(lsla$deal_id %in% unique(areas$deal_id), 1, 0)


# Set as missing contracted areas which are zero.
lsla$area_contracted[lsla$area_contracted == 0] <- NA





# ---------------------- CLEAN GEOJSON DATA ----------------------------
# LandMatrix provides data as both GeoJSON and CSV. They are slightly different 
# from each other, although both contain the same underlying data. I clean it here
# so that I can compare the two sources in the validation.R file to confirm
# that there are no observations that appear in only one of the two sources
# (there are not, only additional duplicates)



# Drop observations where spatial accuracy is low
locations <- locations %>%
  filter(!(spatial_accuracy %in% c("ADMINISTRATIVE_REGION", "COUNTRY", "")))


# Set coordinates as the average of coordinates within the same deal_id
locations <- locations %>%
  group_by(deal_id) %>%
  group_modify(~ {
    x = mean(st_coordinates(.x)[,1])           
    y = mean(st_coordinates(.x)[,2])
    data.frame(lon = x, lat = y)
  }) %>% st_as_sf(coords=c("lon", "lat"), crs=4326)


# Merge in additional deal data from tabular files
areas <- areas %>%
  select(c(id, name, type, deal_id, country, region)) %>%
  inner_join(lsla, by="deal_id")

locations <- locations %>%
  inner_join(lsla, by="deal_id")




# ----------------- GENERATE EARTH ENGINE EXPORTS ---------------------


# Creating CSV with countries & coordinates for Earth Engine exports
lsla %>%
  select(deal_id,  lat, lon) %>%
  write_csv("./data/intermediate/earthengine_locs.csv")




# ------------------------------ SAVE ---------------------------------


# Save files for later use
saveRDS(lsla, file="data/intermediate/lsla.RData")
saveRDS(locations, file="data/intermediate/locations.RData")
saveRDS(areas, file="data/intermediate/areas.RData")




# ---------------------------- NOTES -------------------------------

# The GeoJSON and CVS files contain the same observations, but the number of 
# duplicates in each is different, which results in a different number of 
# observations.

# deal_size and size_under_contract are identical except for 10 entries where 
# size_under_contract is implausibly zero. I therefore drop size_under_contract.

# TODO: 
# - Look into whether I can extract any more years operational 
# - Look into whether I can improve logic for dealing with multiple locations
