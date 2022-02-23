

# --------------------------- ENVIRONMENT ---------------------------

rm(list = ls())
setwd("~/Projects/Dissertation/agro-welfare")

library(ggplot2)
library(sf)
library(RColorBrewer)



# ------------------------------ DATA -------------------------------

# Read pre-cleaned data into memory
lsla <- readRDS("./Data/lsla.RData")
areas <- readRDS("./Data/areas.RData")
locations <- readRDS("./Data/locations.RData")



# -------------------------- HISTOGRAMS ----------------------------

# Histogram for Year Contract Signed
ggplot(filter(lsla, year_signed > 1970), aes(year_signed)) +
  geom_histogram(binwidth=1, colour='#000000', fill='#1f78b4', size=0.2) + 
  labs(
    x = "Year Signed",
    y = "Count"
  ) +
  theme_light()

# Histogram for Year Production Started
ggplot(filter(lsla, year_implemented > 1970), aes(year_implemented)) +
  geom_histogram(binwidth=1, colour='#000000', fill='#1f78b4', size=0.2) + 
  labs(
    x = "Year Implemented",
    y = "Count"
  ) +
  theme_light()



# ---------------------------- MAPS ------------------------------


# Map of locations
ggplot(locations) + 
  geom_sf(size=0.1, colour='#1f78b4') +
  coord_sf() +
  theme_light()

# Map of locations, scaled by area 
ggplot(locations) + 
  geom_sf(size=locations$size_under_contract*0.000008, colour='#1f78b4') +
  coord_sf() +
  theme_light()

# Map of areas
ggplot(areas) + 
  geom_sf(colour='#1f78b4') +
  coord_sf() +
  theme_light()
  
  
  
  



