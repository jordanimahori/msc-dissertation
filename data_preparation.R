
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
filepaths = list.files("./Data/Original/", pattern=".csv")
datasets = list()

for (file in filepaths) {
  datasets[[gsub(".csv", "", file)]] <- read_delim(paste("Data/Original/", file, sep=""), 
                                                   show_col_types=FALSE)   #(1)
}


# GeoJSON data on land acquisitions (Source: LandMatrix)
locations <- st_read("./Data/Original/locations.geojson", quiet=TRUE)
areas <- st_read("./Data/Original/areas.geojson", quiet=TRUE)




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
  select(!c(is_public, not_public, size_under_contract,
            comment_on_land_area, `crops_area/yield/export`)) %>%
  rename(investor_id=operating_company_investor_id,
         size_under_contract=current_size_under_contract, 
         size_in_operation=current_size_in_operation)

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


# Drop intermediate variables
lsla <- lsla %>%
  select(!c(intention_of_investment, concluded, implementation_status, 
            imp_status_current, imp_production, sp2, sp1))


# Drop observations missing locations or year information
lsla <- lsla %>% 
  filter(!(is.na(lat) | is.na(lon))) %>%                   # Drop observations without locations
  filter(is.na(year_signed) && is.na(year_operational))    # Drop observations without either signed or operational date





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
    x = mean(st_coordinates(.x)[,1])           # LOGIC CAN BE IMPROVED BY NOT INCLUDING APPROX LOCATION IF OTHERS ARE AVAILABLE
    y = mean(st_coordinates(.x)[,2])
    data.frame(lon = x, lat = y)
  }) %>% st_as_sf(coords=c("lon", "lat"), crs=4326)


# Merge in additional deal data from tabular files
areas <- areas %>%
  select(c(id, name, type, deal_id, country, region)) %>%
  left_join(lsla, by="deal_id")

locations <- locations %>%
  left_join(lsla, by="deal_id")




# ------------------------------ SAVE ---------------------------------


# Convert to sf object
lsla <- st_as_sf(lsla, coords=c("lon", "lat"), crs=4326)


# Save files for later use
saveRDS(lsla, file="./Data/lsla.RData")
saveRDS(locations, file="./Data/locations.RData")
saveRDS(areas, file="./Data/areas.RData")




# ---------------------------- FOOTNOTES -------------------------------

# (1) Some problems with data consistency in unused variables. 
# See: problems(deals_tabular)


# The GeoJSON and CVS files contain the same observations, but the number of 
# duplicates in each is different, which results in a different number of 
# observations.

# There are duplicates in the areas as well, but that's more complicated to 
# deal with. There are 190 distinct entries.


#### Some contracts were later cancelled. I still need to extract the cancelled
#### date if that is important to me.

### Check what warning messages about discarded information is about (not urgent)
